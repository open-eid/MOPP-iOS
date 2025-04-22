//
//  MoppLibDigidocManager.m
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import "MoppLibDigidocManager.h"
#import "MoppLibContainer.h"
#import "MoppLibDataFile.h"
#import "MoppLibRoleAddressData.h"
#import "MoppLibSignature.h"
#import <CryptoLib/CryptoLib-Swift.h>
#import <MoppLib/MoppLib-Swift.h>

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/Signer.h>
#include <digidocpp/crypto/X509Cert.h>

#include <set>

digidoc::Exception::ExceptionCode parseException(const digidoc::Exception &e) {
    printLog(@"%u, %s", e.code(), e.msg().c_str());
    digidoc::Exception::ExceptionCode code = e.code();
    for (const digidoc::Exception &ex : e.causes()) {
        code = std::max(code, parseException(ex));
    }
    return code;
}

@implementation MoppLibError (digidocpp)

+ (void)setException:(const digidoc::Exception &)exception toError:(NSError**)error {
    if (error) { *error = [MoppLibError errorWithException:exception]; }
}

+ (NSError*)errorWithException:(const digidoc::Exception &)exception {
    switch (parseException(exception)) {
            using enum digidoc::Exception::ExceptionCode;
        case CertificateRevoked:
        case CertificateUnknown:
            return [MoppLibError error:MoppLibErrorCodeCertRevoked];
        case TSTooManyRequests:
            return [MoppLibError error:MoppLibErrorCodeTooManyRequests];
        case OCSPTimeSlot:
            return [MoppLibError error:MoppLibErrorCodeOCSPTimeSlot];
        case NetworkError:
            if (exception.msg().starts_with("Failed to create ssl connection with host")) {
                return [MoppLibError error:MoppLibErrorCodeSslHandshakeFailed];
            }
            if (exception.msg().starts_with("Failed to create proxy connection with host") ||
                exception.msg().starts_with("Failed to connect to host")) {
                return [MoppLibError error:MoppLibErrorCodeInvalidProxySettings];
            }
            return [MoppLibError error:MoppLibErrorCodeNoInternetConnection];
        case 63:
            return [MoppLibError error:MoppLibErrorCodeFileNameTooLong];
        default:
            return [MoppLibError errorWithMessage:[NSString stringWithUTF8String:exception.msg().c_str()]];
    }
}

@end

class WebSigner: public digidoc::Signer
{
public:
  WebSigner(const digidoc::X509Cert &cert): _cert(cert) {}

private:
  digidoc::X509Cert cert() const override { return _cert; }
  std::vector<unsigned char> sign(const std::string &, const std::vector<unsigned char> &) const override
  {
    // THROW("Not implemented");
    return {};
  }

  digidoc::X509Cert _cert;
};

struct MoppLibDigidocContainerOpenCB: public digidoc::ContainerOpenCB {
    bool validateOnline() const final {
        return MoppLibManager.shared.validateOnline;
    }
};


@interface MoppLibDigidocManager ()
    - (MoppLibSignatureStatus)determineSignatureStatus:(int) status;
@end

@implementation MoppLibDigidocManager

static std::unique_ptr<digidoc::Container> docContainer = nil;
static digidoc::Signature *signature = nil;
static std::unique_ptr<digidoc::Signer> signer{};

+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (BOOL)isSignatureValid:(NSData *)data error:(NSError**)error {
    if (!signature) {
        printLog(@"\nError: Did not find signature\n");
        if (error) {
            *error = [MoppLibError errorWithMessage:@"Did not find signature"];
        }
        return NO;
    }

    if (auto timeStampTime = signature->TimeStampTime(); !timeStampTime.empty()) {
        printLog(@"\nSignature already validated at %s\n", timeStampTime.c_str());
        return YES;
    }

    try {
        printLog(@"\nStarting signature validation...\n");
        printLog(@"\nSetting signature value...\n");
        auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
        signature->setSignatureValue({bytes, bytes + data.length});
        printLog(@"\nExtending signature profile...\n");
        signature->extendSignatureProfile(signer.get());
        printLog(@"\nValidating signature...\n");
        signature->validate();
        printLog(@"\nSaving container...\n");
        docContainer->save();
        printLog(@"\nSignature validated at %s!\n", signature->TimeStampTime().c_str());
        return YES;
    } catch(const digidoc::Exception &e) {
        printLog(@"\nError validating signature: %s\n", e.msg().c_str());
        [MoppLibError setException:e toError:error];
        return NO;
    }
}

+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData error:(NSError **)error {
    try {
        signer = std::make_unique<WebSigner>(digidoc::X509Cert(reinterpret_cast<const unsigned char *>(cert.bytes), cert.length));
        signature = NULL;
        MoppLibDigidocContainerOpenCB cb;
        docContainer = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

        printLog(@"\nSetting profile info...\n");
        printLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
        signer->setProfile("time-stamp");
        signer->setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
        signer->setUserAgent(MoppLibManager.userAgent.UTF8String);

        std::vector<std::string> roles;
        for (NSString *role in roleData.ROLES) {
            if (role != (id)[NSNull null] && [role length] != 0) {
                roles.push_back(std::string([role UTF8String] ?: ""));
            }
        }
        signer->setSignerRoles(roles);
        printLog(@"\nProfile info set successfully\n");

        printLog(@"\nSetting signature...\n");
        signature = docContainer->prepareSignature(signer.get());
        printLog(@"\nSignature ID set to %s...\n", signature->id().c_str());
        return [MoppLibDigidocManager getNSDataFromVector:signature->dataToSign()];
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
        return nil;
    }
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error {

  // Having two container instances of the same file is causing crashes. Should synchronize all container operations?
  @synchronized (self) {

    MoppLibContainer *moppLibContainer = [MoppLibContainer new];

    [moppLibContainer setFileName:[containerPath lastPathComponent]];
    [moppLibContainer setFilePath:containerPath];

    std::unique_ptr<digidoc::Container> doc;
    try {
      MoppLibDigidocContainerOpenCB cb;
      doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
      return nil;
    }
    try {
      // DataFiles
      NSMutableArray *dataFiles = [NSMutableArray array];

      for (digidoc::DataFile *dataFile: doc->dataFiles()) {
        MoppLibDataFile *moppLibDataFile = [MoppLibDataFile new];
        moppLibDataFile.fileId = [NSString stringWithUTF8String:dataFile->id().c_str()];
        moppLibDataFile.mediaType = [NSString stringWithUTF8String:dataFile->mediaType().c_str()];
        moppLibDataFile.fileName = [NSString stringWithUTF8String:dataFile->fileName().c_str()];
        moppLibDataFile.fileSize = dataFile->fileSize();
        [dataFiles addObject:moppLibDataFile];
      }
      moppLibContainer.dataFiles = dataFiles;


      // Signatures
      NSMutableArray *signatures = [NSMutableArray array];
      // Timestamp tokens
      NSMutableArray *timeStampTokens = [NSMutableArray array];
      for (digidoc::Signature *signature: doc->signatures()) {
        [signatures addObject:[self getSignatureData:signature->signingCertificate() signature:signature mediaType:doc->mediaType() dataFileCount:doc->dataFiles().size()]];
          [timeStampTokens addObject:[self getSignatureData:signature->TimeStampCertificate() signature:signature mediaType:doc->mediaType() dataFileCount:doc->dataFiles().size()]];
      }

      moppLibContainer.signatures = [signatures copy];
      moppLibContainer.timestampTokens = [timeStampTokens copy];
      return moppLibContainer;

    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
      return nil;
    }
  }
}

- (MoppLibSignature *)getSignatureData:(const digidoc::X509Cert&)cert signature:(digidoc::Signature *)signature mediaType:(const std::string&)mediaType dataFileCount:(NSInteger)dataFileCount {

    digidoc::X509Cert signingCert = signature->signingCertificate();
    digidoc::X509Cert ocspCert = signature->OCSPCertificate();
    digidoc::X509Cert timestampCert = signature->TimeStampCertificate();

    std::string givename = cert.subjectName("GN");
    std::string surname = cert.subjectName("SN");
    std::string serialNR = [self getSerialNumber:cert.subjectName("serialNumber")];

    std::string name = givename.empty() || surname.empty() ? cert.subjectName("CN") :
        surname + ", " + givename + ", " + serialNR;
    if (name.empty()) {
        name = signature->signedBy();
    }

    MoppLibSignature *moppLibSignature = [MoppLibSignature new];
    moppLibSignature.trustedSigningTime = [NSString stringWithUTF8String:signature->trustedSigningTime().c_str()];
    moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];

    moppLibSignature.signersCertificateIssuer = [NSString stringWithUTF8String:signingCert.issuerName("CN").c_str()];
    moppLibSignature.issuerName = [NSString stringWithCString:signingCert.issuerName().c_str() encoding:[NSString defaultCStringEncoding]];
    moppLibSignature.signingCertificate = [self getCertDataFromX509:signingCert];
    moppLibSignature.signatureMethod = [NSString stringWithUTF8String:signature->signatureMethod().c_str()];
    moppLibSignature.containerFormat = [NSString stringWithUTF8String:mediaType.c_str()];
    moppLibSignature.signatureFormat = [NSString stringWithUTF8String:signature->profile().c_str()];
    moppLibSignature.signedFileCount = dataFileCount;
    moppLibSignature.signatureTimestamp = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->TimeStampTime().c_str()]];
    moppLibSignature.signatureTimestampUTC = [NSString stringWithUTF8String:signature->TimeStampTime().c_str()];
    moppLibSignature.hashValueOfSignature = [MoppLibDigidocManager getNSDataFromVector:signature->messageImprint()];
    moppLibSignature.tsCertificateIssuer = [NSString stringWithUTF8String:timestampCert.issuerName("CN").c_str()];
    moppLibSignature.tsCertificate = [self getCertDataFromX509:timestampCert];
    moppLibSignature.ocspCertificateIssuer = [NSString stringWithUTF8String:ocspCert.issuerName("CN").c_str()];
    moppLibSignature.ocspCertificate = [self getCertDataFromX509:ocspCert];
    moppLibSignature.ocspTime = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
    moppLibSignature.ocspTimeUTC = [NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()];
    moppLibSignature.signersMobileTimeUTC = [NSString stringWithUTF8String:signature->claimedSigningTime().c_str()];
    moppLibSignature.timestamp = [NSString stringWithUTF8String:signature->trustedSigningTime().c_str()];

    // Role and address data
    std::vector<std::string> signatureRoles = signature->signerRoles();
    NSMutableArray* signatureRolesList = [NSMutableArray arrayWithCapacity: signatureRoles.size()];
    for (auto const& signatureRole: signatureRoles) {
        [signatureRolesList addObject: [NSString stringWithUTF8String:signatureRole.c_str()]];
    }

    MoppLibRoleAddressData *moppLibRoleAddressData = [MoppLibRoleAddressData new];
    moppLibRoleAddressData.ROLES = signatureRolesList;
    moppLibRoleAddressData.CITY = [NSString stringWithUTF8String:signature->city().c_str()];
    moppLibRoleAddressData.STATE = [NSString stringWithUTF8String:signature->stateOrProvince().c_str()];
    moppLibRoleAddressData.COUNTRY = [NSString stringWithUTF8String:signature->countryName().c_str()];
    moppLibRoleAddressData.ZIP = [NSString stringWithUTF8String:signature->postalCode().c_str()];
    moppLibSignature.roleAndAddressData = moppLibRoleAddressData;

    try {
      digidoc::Signature::Validator validator(signature);
      digidoc::Signature::Validator::Status status = validator.status();
      moppLibSignature.diagnosticsInfo = [NSString stringWithUTF8String:validator.diagnostics().c_str()];
      moppLibSignature.status = [self determineSignatureStatus:status];
    } catch(const digidoc::Exception &e) {
      moppLibSignature.status = Invalid;
    }

    return moppLibSignature;
}

- (std::string)getSerialNumber:(std::string)serialNumber {
    static const std::set<std::string> types {"PAS", "IDC", "PNO", "TAX", "TIN"};
    if (serialNumber.length() > 6 && (types.find(serialNumber.substr(0, 3)) != types.cend() || serialNumber[2] == ':') && serialNumber[5] == '-') {
        return serialNumber.substr(6);
    }
    return serialNumber;
}

- (NSData *)getCertDataFromX509:(const digidoc::X509Cert&)cert {
    return [MoppLibDigidocManager getNSDataFromVector:cert];
}

- (NSString *)getDateTimeInCurrentTimeZoneFromDateString:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *systemTimeZone = [NSTimeZone systemTimeZone];
    [dateFormatter setTimeZone:systemTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    NSString *dateStringSystemTimeZone = [dateFormatter stringFromDate:date];

    return dateStringSystemTimeZone;
}

+ (NSData *)getNSDataFromVector:(const std::vector<unsigned char>&)vectorData {
    return [NSData dataWithBytes:vectorData.data() length:vectorData.size()];
}

- (MoppLibSignatureStatus)determineSignatureStatus:(int) status{

    if(digidoc::Signature::Validator::Status::Valid==status){
        return Valid;
    }
    else if(digidoc::Signature::Validator::Status::NonQSCD==status){
        return NonQSCD;
    }
    else if(digidoc::Signature::Validator::Status::Warning==status){
        return Warning;
    }
    else if(digidoc::Signature::Validator::Status::Unknown==status){
        return UnknownStatus;
    }
    return Invalid;
}

- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  printLog(@"createContainerWithPath: %@, dataFilePaths: %@", containerPath, dataFilePaths);

  try {
    auto container = digidoc::Container::createPtr(containerPath.UTF8String);
    for (NSString *dataFilePath in dataFilePaths) {
      container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    }
    container->save(containerPath.UTF8String);
  } catch(const digidoc::Exception &e) {
      [MoppLibError setException:e toError:error];
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  try {
    MoppLibDigidocContainerOpenCB cb;
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

    for (NSString *dataFilePath in dataFilePaths) {
      [self addDataFileToContainer:container.get() withDataFilePath:dataFilePath error: error];
    }

    container->save(containerPath.UTF8String);

  } catch(const digidoc::Exception &e) {
      [MoppLibError setException:e toError:error];
  }

  NSError *error2;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error2];

  return moppLibContainer;
}

- (void)addDataFileToContainer:(digidoc::Container *)container withDataFilePath:(NSString *)dataFilePath error:(NSError **)error  {

  try {
    container->addDataFile(dataFilePath.UTF8String, "application/octet-stream");
  } catch(const digidoc::Exception &e) {
    NSString *message = [NSString stringWithCString:e.msg().c_str() encoding:NSUTF8StringEncoding];

    // libdigidoc doesn't send specific error code when file with same name already exists.
    if (e.code() == 0 && [message hasPrefix:@"Document with same file name"] && error) {
        *error = [MoppLibError error:MoppLibErrorCodeDuplicatedFilename];
    } else {
        [MoppLibError setException:e toError:error];
    }
  }
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex error:(NSError **)error {
  try {
    MoppLibDigidocContainerOpenCB cb;
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    container->removeDataFile((int)dataFileIndex);
    container->save(containerPath.UTF8String);
  } catch(const digidoc::Exception &e) {
      [MoppLibError setException:e toError:error];
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error {
  MoppLibDigidocContainerOpenCB cb;
  auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
  for (int i = 0; i < doc->signatures().size(); i++) {
    digidoc::Signature *signature = doc->signatures().at(i);
    digidoc::X509Cert cert = signature->signingCertificate();

    // Estonian signatures
    NSString *name = [self trimWhitespace:[NSString stringWithUTF8String:cert.subjectName("CN").c_str()]];
    NSString *trustedTimeStamp = [self trimWhitespace:[NSString stringWithUTF8String:signature->trustedSigningTime().c_str()]];

    NSString *givenName = [self trimWhitespace:[NSString stringWithUTF8String:cert.subjectName("GN").c_str()]];
    NSString *surname = [self trimWhitespace:[NSString stringWithUTF8String:cert.subjectName("SN").c_str()]];
    NSString *serialNR = [self trimWhitespace:[NSString stringWithUTF8String:[self getSerialNumber:cert.subjectName("serialNumber")].c_str()]];

    NSString* subjectName = [self trimWhitespace:[moppSignature subjectName]];
    NSString* trustedSigningTime = [self trimWhitespace:[moppSignature trustedSigningTime]];

    // Foreign signatures
    NSString *foreignName = [NSString stringWithFormat:@"%@, %@, %@", surname, givenName, serialNR];

    if (([name isEqualToString:subjectName] || [foreignName isEqualToString:subjectName]) && [trustedTimeStamp isEqualToString:trustedSigningTime]) {
        try {
            doc->removeSignature(i);
            doc->save(containerPath.UTF8String);
        } catch(const digidoc::Exception &e) {
            [MoppLibError setException:e toError:error];
        }
        break;
    }
  }

    NSError *err;
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
    return moppLibContainer;
}

- (NSString *)trimWhitespace:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure {
    try {
        MoppLibDigidocContainerOpenCB cb;
        if (auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb)) {
            const char *fileNameUTF8 = fileName.UTF8String;
            for (digidoc::DataFile *dataFile: doc->dataFiles()) {
                if (dataFile->fileName() == fileNameUTF8) {
                    dataFile->saveAs(path.UTF8String);
                    success();
                    return;
                }
            }
            failure([MoppLibError error:MoppLibErrorCodeGeneral]);
        } else {
            failure([MoppLibError error:MoppLibErrorCodeGeneral]);
        }
    } catch(const digidoc::Exception &e) {
        failure([MoppLibError errorWithException:e]);
    }
}

@end
