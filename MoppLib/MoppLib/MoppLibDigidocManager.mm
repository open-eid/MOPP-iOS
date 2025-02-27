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

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/X509Cert.h>
#include <digidocpp/XmlConf.h>
#include <digidocpp/crypto/Signer.h>
#include <fstream>

#import "MoppLibDigidocManager.h"
#import "MoppLibManager.h"
#import "MoppLibDataFile.h"
#import "MLDateFormatter.h"
#import "MLFileManager.h"
#import "MoppLibError.h"
#import "CardActionsManager.h"
#import <Security/SecCertificate.h>
#import <Security/SecKey.h>
#import "MoppLibDigidocValidateOnline.h"
#import "MoppLibProxyConfiguration.h"

#include <CryptoLib/CryptoLib.h>

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#include <string>
#include <sstream>
#include <iostream>
#import <CommonCrypto/CommonDigest.h>
#import <ExternalAccessory/ExternalAccessory.h>

class DigiDocConf: public digidoc::ConfCurrent {

private:
  std::string m_tsUrl;
  MoppLibConfiguration *moppLibConfiguration;
  MoppLibProxyConfiguration *proxyConfiguration;

public:

  DigiDocConf(const std::string& tsUrl, MoppLibConfiguration* moppConfiguration, MoppLibProxyConfiguration* proxyConfiguration) : m_tsUrl( tsUrl ), moppLibConfiguration( moppConfiguration ), proxyConfiguration( proxyConfiguration ) {}

  std::string TSLCache() const override {
    NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
    //    printLog(@"tslCachePath: %@", tslCachePath);
    return tslCachePath.UTF8String;
  }

  std::string TSUrl() const override {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *tsaUrl = [defaults stringForKey:@"kTimestampUrlKey"];
      return [tsaUrl length] != 0 ? tsaUrl.UTF8String : moppLibConfiguration.TSAURL.UTF8String;
  }

  std::string verifyServiceUri() const override {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *sivaUrl = [defaults stringForKey:@"kSivaUrl"];
      NSString *usingSivaUrl = [sivaUrl length] != 0 ? sivaUrl : moppLibConfiguration.SIVAURL;
      printLog(@"Using SiVa URL: %@", usingSivaUrl);
      NSLog(@"Using SiVa URL: %@", usingSivaUrl);
      return [sivaUrl length] != 0 ? sivaUrl.UTF8String : moppLibConfiguration.SIVAURL.UTF8String;
  }

  std::vector<digidoc::X509Cert> TSLCerts() const override {
      return stringsToX509Certs(moppLibConfiguration.TSLCERTS);
  }

  std::string TSLUrl() const override {
      return moppLibConfiguration.TSLURL.UTF8String;
  }
    
  std::vector<digidoc::X509Cert> TSCerts() const override {
      NSMutableArray<NSString *> *certBundle = [NSMutableArray arrayWithArray:moppLibConfiguration.CERTBUNDLE];
      if (moppLibConfiguration.TSACERT != NULL) {
          [certBundle addObject:moppLibConfiguration.TSACERT];
      }
      return stringsToX509Certs(certBundle);
  }

    virtual std::vector<digidoc::X509Cert> verifyServiceCerts() const override {
        NSMutableArray<NSString*> *certs = [NSMutableArray arrayWithArray:moppLibConfiguration.CERTBUNDLE];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *sivaFileName = [defaults stringForKey:@"kSivaFileCertName"];
        if (!(sivaFileName == nil || [sivaFileName isEqualToString:@""])) {
            NSString *sivaCert = getSivaCert(sivaFileName);
            
            if (!(sivaCert == nil || [sivaCert isEqualToString:@""])) {
                // Remove certificate header, footer, whitespaces and newlines
                NSCharacterSet *characterSetToRemove = [NSCharacterSet characterSetWithCharactersInString:@" \n\r\t"];
                
                NSString * formattedSivaCert = [sivaCert stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
                formattedSivaCert = [formattedSivaCert stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
                formattedSivaCert = [[formattedSivaCert componentsSeparatedByCharactersInSet:characterSetToRemove] componentsJoinedByString:@""];
                
                [certs addObject:formattedSivaCert];
            }
        }
        
        return stringsToX509Certs(certs);
    }

  std::string ocsp(const std::string &issuer) const override {
    NSString *ocspIssuer = [NSString stringWithCString:issuer.c_str() encoding:[NSString defaultCStringEncoding]];
    if ([moppLibConfiguration.OCSPISSUERS objectForKey:ocspIssuer]) {
        printLog(@"Using issuer: '%@' with OCSP url from central configuration: %s", ocspIssuer, std::string([moppLibConfiguration.OCSPISSUERS[ocspIssuer] UTF8String]).c_str());
        return std::string([moppLibConfiguration.OCSPISSUERS[ocspIssuer] UTF8String]);
    }
    printLog(@"Did not find url for issuer: %@.", ocspIssuer);
    return digidoc::ConfCurrent::ocsp(issuer);
  }
    
    virtual std::string proxyHost() const override {
        NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"kProxyHost"];
        if (host == nil) {
            return std::string("");
        }
        return std::string([host UTF8String]);
    }
    
    virtual std::string proxyPort() const override {
        NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:@"kProxyPort"];
        return std::to_string(port);
    }
    
    virtual std::string proxyUser() const override {
        return std::string([proxyConfiguration.USERNAME UTF8String]);
    }
    
    virtual std::string proxyPass() const override {
        return std::string([proxyConfiguration.PASSWORD UTF8String]);
    }

    std::vector<digidoc::X509Cert> stringsToX509Certs(NSArray<NSString*> *certBundle) const {
        __block std::vector<digidoc::X509Cert> x509Certs;

        [certBundle enumerateObjectsUsingBlock:^(NSString* object, NSUInteger idx, BOOL *stop) {
            try {
                NSData *data = [[NSData alloc] initWithBase64EncodedString:object options:NSDataBase64DecodingIgnoreUnknownCharacters];
                auto bytes = reinterpret_cast<const unsigned char*>(data.bytes);
                x509Certs.emplace_back(bytes, data.length);
            } catch (const digidoc::Exception &e) {
                printLog(@"Unable to generate a X509 certificate object. Code: %u, message: %s", e.code(), e.msg().c_str());
            } catch(...) {
                printLog(@"Generating a X509 certificate object raised an exception!\n");
            }
        }];

        return x509Certs;
    }

    bool isDebugMode() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"isDebugMode"];
    }

    bool isLoggingEnabled() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"kIsFileLoggingEnabled"];
    }

    // Comment in / out to see / hide libdigidocpp logs
    // Currently enabled on DEBUG mode

    int logLevel() const override {
        if (isDebugMode() || isLoggingEnabled()) {
            return 4;
        } else {
            return 0;
        }
    }

    std::string logFile() const override {
        if (isDebugMode() || isLoggingEnabled()) {
            MLFileManager *mlFM = [[MLFileManager alloc] init];
            NSURL *logsUrl = [[NSURL alloc] initFileURLWithPath:[mlFM logsDirectoryPath]];
            if (![mlFM folderExists:logsUrl.path]) {
                // Create folder 'logs' in Library/Cache directory
                BOOL isFolderCreated = [mlFM createFolder:@"logs"];
                if (isFolderCreated) {
                    return logFileLocation(logsUrl);
                } else {
                    // Save log files to 'Library/Cache' directory if creating 'logs' folder was unsuccessful
                    NSURL *url = [[NSURL alloc] initWithString:[mlFM cacheDirectoryPath]];
                    return logFileLocation(url);
                }
            } else {
                return logFileLocation(logsUrl);
            }
        }
        return std::string();
    }

    std::string logFileLocation(NSURL *logsFolderUrl) const {
        return std::string([[[logsFolderUrl URLByAppendingPathComponent: @"libdigidocpp.log"] path] UTF8String]);
    }
    
    NSString* getSivaCert(NSString *fileName) const {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths objectAtIndex:0];
        NSString *subfolderName = @"siva-cert";
        
        NSString *subfolderPath = [cachesDirectory stringByAppendingPathComponent:subfolderName];
        
        NSString *filePath = [subfolderPath stringByAppendingPathComponent:fileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *error = nil;
            NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            
            if (fileContents) {
                return fileContents;
            } else {
                NSLog(@"Error reading file '%@': %@", fileName, [error localizedDescription]);
                return nil;
            }
        } else {
            NSLog(@"File '%@' not found at path: %@", fileName, filePath);
            return nil;
        }
        return nil;
    }
};


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

class MoppLibDigidocContainerOpenCB: public digidoc::ContainerOpenCB {
private:
    bool validate;

public:
    MoppLibDigidocContainerOpenCB(bool validate)
        : validate(validate) {}

    virtual bool validateOnline() const {
        return validate;
    }
};


@interface MoppLibDigidocManager ()
    - (MoppLibSignatureStatus)determineSignatureStatus:(int) status;
@end

@implementation MoppLibDigidocManager

static std::unique_ptr<digidoc::Container> docContainer = nil;
static digidoc::Signature *signature = nil;
static digidoc::Signer* signer = nil;

+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString*)tsUrl withMoppConfiguration:(MoppLibConfiguration*)moppConfiguration andProxyConfiguration:(MoppLibProxyConfiguration*)proxyConfiguration {

    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);

        // Initialize libdigidocpp.
        try {
            std::string timestampUrl = tsUrl == nil ?
            [moppConfiguration.TSAURL cStringUsingEncoding:NSUTF8StringEncoding] :
            [tsUrl cStringUsingEncoding:NSUTF8StringEncoding];
            digidoc::Conf::init(new DigiDocConf(timestampUrl, moppConfiguration, proxyConfiguration));
            NSString *appInfo = [self userAgent];
            std::string appInfoObjcString = std::string([appInfo UTF8String]);
            digidoc::initialize(appInfoObjcString, appInfoObjcString);

            dispatch_semaphore_signal(sem);

            dispatch_async(dispatch_get_main_queue(), ^{
                success();
            });
        } catch(const digidoc::Exception &e) {
            dispatch_semaphore_signal(sem);

            parseException(e);

            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:@"MoppLib" code:e.code() userInfo:@{@"message":[NSString stringWithUTF8String:e.msg().c_str()]}];
                failure(error);
            });
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });
}

+ (digidoc::X509Cert)getCertFromData:(NSData *)data {
    return digidoc::X509Cert(reinterpret_cast<const unsigned char *>(data.bytes), data.length);
}

+ (NSData *)getDataToSign {
    std::vector<unsigned char> dataTosign = signature->dataToSign();
    return [NSData dataWithBytes:dataTosign.data() length:dataTosign.size()];
}

+ (void)isSignatureValid:(NSData *)cert signatureValue:(NSString *)signatureValue success:(BoolBlock)success failure:(FailureBlock)failure {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:signatureValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
    auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
    std::vector<unsigned char> calculatedSignatureBase64(bytes, bytes + data.length);

    if (!signature) {
        std::string signatureId = signature->id();
        printLog(@"\nError: Did not find signature with an ID of %s\n", signatureId.c_str());
        NSError *signatureError;
        signatureError = [NSError errorWithDomain:[NSString stringWithFormat:@"Did not find signature with an ID of %s\n", signature->id().c_str()] code:-1 userInfo:nil];
        failure(signatureError);
    }

    NSString *timeStampTime = [NSString stringWithUTF8String:signature->TimeStampTime().c_str()];
    if ([timeStampTime length] != 0) {
        printLog(@"\nSignature already validated at %@\n", timeStampTime);
        success(true);
    }

    try {
        printLog(@"\nStarting signature validation...\n");
        printLog(@"\nSetting signature value...\n");
        signature->setSignatureValue(calculatedSignatureBase64);
        printLog(@"\nExtending signature profile...\n");
        signature->extendSignatureProfile(signer);
        printLog(@"\nValidating signature...\n");
        digidoc::Signature::Validator *validator = new digidoc::Signature::Validator(signature);
        printLog(@"\nValidator status: %u\n", validator->status());
        printLog(@"\nSaving container...\n");
        docContainer->save();
        printLog(@"\nSignature validated at %s!\n", signature->TimeStampTime().c_str());
        success(true);
    } catch(const digidoc::Exception &e) {
        parseException(e);
        NSError *error;
        NSString *signatureId = [NSString stringWithCString:signature->id().c_str() encoding:[NSString defaultCStringEncoding]];
        [self removeSignature:docContainer.get() signatureId:signatureId error:&error];
        printLog(@"\nError validating signature: %s\n", e.msg().c_str());
        NSError *validationError;
        validationError = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
        failure(validationError);
    }
}

+ (void)removeSignature:(digidoc::Container *)container signatureId:(NSString *)signatureId error:(NSError **)error {

    for (int i = 0; i < container->signatures().size(); i++) {
        digidoc::Signature *signature = container->signatures().at(i);
        try {
            if ([NSString stringWithUTF8String:signature->id().c_str()] == signatureId) {
                container->removeSignature(i);
                container->save();
                break;
            }
        } catch(const digidoc::Exception &e) {
            parseException(e);
            *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
            break;
        }
    }
}

+ (NSString *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData {
    digidoc::X509Cert x509Cert;

    try {
        x509Cert = [self getCertFromData:cert];
    } catch (const digidoc::Exception &e) {
        parseException(e);
        return nil;
    }

    docContainer = NULL;
    signature = NULL;
    signer = NULL;
    
    signer = new WebSigner(x509Cert);

    try {
        MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
        BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
        MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
        docContainer = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    } catch(const digidoc::Exception &e) {
        parseException(e);
        return nil;
    }

    NSLog(@"\nSetting profile info...\n");
    NSLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
    signer->setProfile("time-stamp");
    signer->setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
    signer->setUserAgent(std::string([MoppLibManager.sharedInstance.userAgent UTF8String]));
    
    std::vector<std::string> roles;
    for (NSString *role in roleData.ROLES) {
        if (role != (id)[NSNull null] && [role length] != 0) {
            roles.push_back(std::string([role UTF8String] ?: ""));
        }
    }
    
    signer->setSignerRoles(roles);
    NSLog(@"\nProfile info set successfully\n");
    
    NSLog(@"\nSetting signature...\n");
    signature = docContainer->prepareSignature(signer);
    NSString *signatureId = [NSString stringWithCString:signature->id().c_str() encoding:[NSString defaultCStringEncoding]];
    printLog(@"\nSignature ID set to %@...\n", signatureId);

    std::vector<unsigned char> dataToSign = signature->dataToSign();
    NSData *data = [NSData dataWithBytesNoCopy:dataToSign.data() length:dataToSign.size() freeWhenDone:NO];
    return [data base64EncodedStringWithOptions:0];
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error {

  // Having two container instances of the same file is causing crashes. Should synchronize all container operations?
  @synchronized (self) {

    MoppLibContainer *moppLibContainer = [MoppLibContainer new];

    [moppLibContainer setFileName:[containerPath lastPathComponent]];
    [moppLibContainer setFilePath:containerPath];
    [moppLibContainer setFileAttributes:[[MLFileManager sharedInstance] fileAttributes:containerPath]];

    std::unique_ptr<digidoc::Container> doc;
    try {
      MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
      BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
      MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
      doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    } catch(const digidoc::Exception &e) {
      parseException(e);

      if (e.code() == 63) {
          *error = [MoppLibError fileNameTooLongError];
      } else if (e.code() == digidoc::Exception::NetworkError) {
          NSString *message = [NSString stringWithUTF8String:e.msg().c_str()];
          if ([message hasPrefix:@"Failed to create ssl connection with host"]) {
              *error = [MoppLibError sslHandshakeError];
          } else {
              *error = [MoppLibError noInternetConnectionError];
          }
      } else {
          *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
      }
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
      parseException(e);
      *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
      return nil;
    }
  }
}

- (MoppLibSignature *)getSignatureData:(const digidoc::X509Cert&)cert signature:(digidoc::Signature *)signature mediaType:(std::string)mediaType dataFileCount:(NSInteger)dataFileCount {

    MoppLibSignature *moppLibSignature = [MoppLibSignature new];

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

    moppLibSignature.trustedSigningTime = [NSString stringWithUTF8String:signature->trustedSigningTime().c_str()];
    moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];

    moppLibSignature.signersCertificateIssuer = [NSString stringWithUTF8String:signingCert.issuerName("CN").c_str()];
    moppLibSignature.signingCertificate = [self getCertDataFromX509:signingCert];
    moppLibSignature.signatureMethod = [NSString stringWithUTF8String:signature->signatureMethod().c_str()];
    moppLibSignature.containerFormat = [NSString stringWithUTF8String:mediaType.c_str()];
    moppLibSignature.signatureFormat = [NSString stringWithUTF8String:signature->profile().c_str()];
    moppLibSignature.signedFileCount = dataFileCount;
    moppLibSignature.signatureTimestamp = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->TimeStampTime().c_str()]];
    moppLibSignature.signatureTimestampUTC = [NSString stringWithUTF8String:signature->TimeStampTime().c_str()];
    moppLibSignature.hashValueOfSignature = [self getHexStringFromVectorData:signature->messageImprint()];
    moppLibSignature.tsCertificateIssuer = [NSString stringWithUTF8String:timestampCert.issuerName("CN").c_str()];
    moppLibSignature.tsCertificate = [self getCertDataFromX509:timestampCert];
    moppLibSignature.ocspCertificateIssuer = [NSString stringWithUTF8String:ocspCert.issuerName("CN").c_str()];
    moppLibSignature.ocspCertificate = [self getCertDataFromX509:ocspCert];
    moppLibSignature.ocspTime = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
    moppLibSignature.ocspTimeUTC = [NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()];
    moppLibSignature.signersMobileTimeUTC = [NSString stringWithUTF8String:signature->claimedSigningTime().c_str()];

    std::string timestamp = signature->trustedSigningTime();
    moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:timestamp.c_str()]];
    
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

    moppLibSignature.issuerName = [NSString stringWithCString:signature->signingCertificate().issuerName().c_str() encoding:[NSString defaultCStringEncoding]];

    return moppLibSignature;
}

+ (NSString *)sanitize:(NSString *)text {
    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet illegalCharacterSet];
    [characterSet addCharactersInString:@"@%:^?[]\'\"”’{}#&`\\~«»/´"];
    NSArray* rtlChars = @[@"\u200E", @"\u200F", @"\u202E", @"\u202A", @"\u202B"];

    for (int i = 0; i < [rtlChars count]; i++) {
        [characterSet addCharactersInString:[rtlChars objectAtIndex:i]];
    }

    while ([text hasPrefix:@"."]) {
        if ([text length] > 1) {
            text = [text substringFromIndex:1];
        } else {
            NSRange replaceRange = [text rangeOfString:@"."];
            if (replaceRange.location != NSNotFound) {
                text = [text stringByReplacingCharactersInRange:replaceRange withString:@"_"];
            }
        }
    }

    return [[text componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
}

- (std::string)getSerialNumber:(std::string)serialNumber {
    static const std::set<std::string> types {"PAS", "IDC", "PNO", "TAX", "TIN"};
    if (serialNumber.length() > 6 && (types.find(serialNumber.substr(0, 3)) != types.cend() || serialNumber[2] == ':') && serialNumber[5] == '-') {
        return serialNumber.substr(6);
    }
    return serialNumber;
}

- (NSData *)getCertDataFromX509:(const digidoc::X509Cert&)cert {
    std::vector<unsigned char> data = cert;
    return [NSData dataWithBytes:data.data() length:data.size()];
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

- (NSString *)getHexStringFromVectorData:(std::vector<unsigned char>)vectorData {
    NSData *data = [NSData dataWithBytes:vectorData.data() length:vectorData.size()];
    return data.hexString;
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
  MLLog(@"createContainerWithPath: %@, dataFilePaths: %@", containerPath, dataFilePaths);

  try {
    auto container = digidoc::Container::createPtr(containerPath.UTF8String);
    for (NSString *dataFilePath in dataFilePaths) {
      container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    }
    container->save(containerPath.UTF8String);
  } catch(const digidoc::Exception &e) {
    parseException(e);
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  try {
    MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
    BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
    MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

    for (NSString *dataFilePath in dataFilePaths) {
      [self addDataFileToContainer:container.get() withDataFilePath:dataFilePath error: error];
    }

    container->save(containerPath.UTF8String);

  } catch(const digidoc::Exception &e) {
    parseException(e);
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
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
    if (e.code() == 0 && [message hasPrefix:@"Document with same file name"]) {
        *error = [MoppLibError duplicatedFilenameError];
    } else {
      parseException(e);
      *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
    }
  }
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex error:(NSError **)error {
  try {
    MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
    BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
    MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    container->removeDataFile((int)dataFileIndex);
    container->save(containerPath.UTF8String);
  } catch(const digidoc::Exception &e) {
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
    parseException(e);
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

- (NSArray *)getContainers {

  NSMutableArray *containers = [NSMutableArray array];
  NSArray *containerPaths = [[MLFileManager sharedInstance] getContainers];
  for (NSString *containerPath in containerPaths) {
    NSError *error;
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
    [containers addObject:moppLibContainer];
  }
  return containers;
}

void parseException(const digidoc::Exception &e) {
  printLog(@"%u, %s", e.code(), e.msg().c_str());
  for (const digidoc::Exception &ex : e.causes()) {
    parseException(ex);
  }
}

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert roleData:(MoppLibRoleAddressData *)roleData success:(ContainerBlock)success andFailure:(FailureBlock)failure {

  try {
    // Load the container
    MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
    BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
    MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
    // Create unique_ptr that manages a container in this scope
    auto managedContainer = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

    // Check if key type in certificate supports ECC algorithm
    SecCertificateRef certRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)cert);
    SecKeyRef publicKey = SecCertificateCopyKey(certRef);
    CFRelease(certRef);
    NSString *publicKeyInfo = CFBridgingRelease(CFCopyDescription(publicKey));
    CFRelease(publicKey);
    BOOL useECC = [publicKeyInfo containsString:@"ECPublicKey"];

    std::unique_ptr<WebSigner> signer = std::make_unique<WebSigner>([MoppLibDigidocManager getCertFromData:cert]);

    NSLog(@"\nSetting profile info...\n");
    NSLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
    signer->setProfile("time-stamp");
    signer->setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
    signer->setUserAgent(std::string([[MoppLibManager.sharedInstance userAgent:true] UTF8String]));
  
    std::vector<std::string> roles;
    for (NSString *role in roleData.ROLES) {
        if (role != (id)[NSNull null] && [role length] != 0) {
            roles.push_back(std::string([role UTF8String] ?: ""));
        }
    }
    signer->setSignerRoles(roles);

    digidoc::Signature *signature;
    try {
        signature = managedContainer->prepareSignature(signer.get());
    } catch (const digidoc::Exception &e) {
        parseException(e);
        failure([MoppLibError generalError]);
    }

    std::vector<unsigned char> dataToSign = signature->dataToSign();

    // Release the container from the unique_ptr and obtain the raw pointer for the callback
    digidoc::Container * const unmanagedContainerPointer = managedContainer.release();
      
    WebSigner * const unmanagedSignerPointer = signer.release();

    [[CardActionsManager sharedInstance] calculateSignatureFor:[NSData dataWithBytes:dataToSign.data() length:dataToSign.size()] pin2:pin2 useECC: useECC success:^(NSData *calculatedSignature) {

        // Wrap the raw container pointer into a local unique_ptr as the first thing to do
        std::unique_ptr<digidoc::Container> successManagedContainer(unmanagedContainerPointer);
        std::unique_ptr<WebSigner> successManagedSigner(unmanagedSignerPointer);

      try {
        unsigned char *buffer = (unsigned char *)[calculatedSignature bytes];
        std::vector<unsigned char>::size_type size = calculatedSignature.length;
        std::vector<unsigned char> vec(buffer, buffer + size);
          
        signature->setSignatureValue(vec);
        signature->extendSignatureProfile(successManagedSigner.get());
        signature->validate();
          successManagedContainer->save();
        NSError *error;
        MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
        success(moppLibContainer);
      } catch(const digidoc::Exception &e) {
        parseException(e);
        if (e.code() == 18) {
            failure([MoppLibError tooManyRequests]);
        } else if (e.code() == digidoc::Exception::ExceptionCode::OCSPTimeSlot) {
            failure([MoppLibError ocspTimeSlotError]);
        } else if (e.code() == digidoc::Exception::ExceptionCode::NetworkError && ([[NSString stringWithUTF8String:e.msg().c_str()] hasPrefix:@"Failed to create proxy connection with host"] || [[NSString stringWithUTF8String:e.msg().c_str()] hasPrefix:@"Failed to connect to host"])) {
            failure([MoppLibError invalidProxySettingsError]);
        } else {
            NSError *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
            failure(error);
        }
      }
    } failure:^(NSError *error) {
      std::unique_ptr<digidoc::Container> failureManagedContainer(unmanagedContainerPointer);
      failure(error);
    }];


  } catch(const digidoc::Exception &e) {
    parseException(e);
    NSError *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
    failure(error);
  }
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error {
  MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
  BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
  MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
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
            parseException(e);
            *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
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

- (NSString *)getMoppLibVersion {
  NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
  NSMutableString *resultString = [[NSMutableString alloc] initWithString:[[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
  [resultString appendString:[NSString stringWithFormat:@".%@", [[bundle infoDictionary] objectForKey:@"CFBundleVersion"]]];
  return resultString;
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure {
    try {
        MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
        BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
        MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
        if (auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb)) {
            for (digidoc::DataFile *dataFile: doc->dataFiles()) {
                if ([self isFileInContainer:fileName dataFile:[NSString stringWithUTF8String:dataFile->fileName().c_str()]]) {
                    dataFile->saveAs(path.UTF8String);
                    success();
                    return;
                }
            }
            failure([MoppLibError generalError]);
        } else {
            failure([MoppLibError generalError]);
        }
    } catch(const digidoc::Exception &e) {
        parseException(e);
    }

    failure([MoppLibError generalError]);
}

-(BOOL)isFileInContainer:(NSString *)fileName dataFile:(NSString *)dataFileName {
    return [fileName isEqualToString:dataFileName];
}

- (BOOL)isContainerFileSaveable:(NSString *)containerPath saveDataFile:(NSString *)fileName {
    try {
        MoppLibDigidocValidateOnline *validateOnlineInstance = [MoppLibDigidocValidateOnline sharedInstance];
        BOOL isValidatedOnline = validateOnlineInstance.validateOnline;
        MoppLibDigidocContainerOpenCB cb(isValidatedOnline);
        if (auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb)) {
            for (digidoc::DataFile *dataFile: doc->dataFiles()) {
                if([self isFileInContainer:fileName dataFile:[NSString stringWithUTF8String:dataFile->fileName().c_str()]]) {
                    return TRUE;
                }
            }
        }
    } catch(const digidoc::Exception &e) {
        parseException(e);
    }
    return FALSE;
}

- (NSString *)digidocVersion {
    std::string version = digidoc::version();
    return [[NSString alloc] initWithBytes:version.c_str() length:version.length() encoding:NSUTF8StringEncoding];
}

- (NSString *)moppAppVersion {
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    return [NSString stringWithFormat:@"%@.%@", version, build];
}

- (NSString *)iOSVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)appLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *language = [defaults stringForKey:@"kMoppLanguage"];
    return [language length] != 0 ? [NSString stringWithFormat:@"%@", language] : [NSString stringWithFormat:@"%s", "N/A"];
}

- (NSArray *)connectedDevices {
    EAAccessoryManager* accessoryManager = [EAAccessoryManager sharedAccessoryManager];
    NSMutableArray *devices = [NSMutableArray new];
    if (accessoryManager) {
        NSArray<EAAccessory *> *connectedAccessories = [accessoryManager connectedAccessories];
        for (int i = 0; i < connectedAccessories.count; i++) {
            EAAccessory *device = connectedAccessories[i];
            NSString *manufacturer = device.manufacturer;
            NSString *name = device.name;
            NSString *modelNumber = device.modelNumber;
            NSString *deviceName = [NSString stringWithFormat:@"%@ %@ (%@)", manufacturer, name, modelNumber];
            [devices addObject:deviceName];
        }
        return [devices copy];
    }

    return [devices copy];
}

- (NSString *)userAgent {
    return [self userAgent:false];
}

- (NSString *)userAgent:(BOOL)shouldIncludeDevices {
    NSString *appInfo = [NSString stringWithFormat:@"%s/%@ (iOS %@) Lang: %@", "riadigidoc", [self moppAppVersion], [self iOSVersion], [self appLanguage]];
    if (shouldIncludeDevices) {
        NSArray *connectedDevices = [self connectedDevices];
        if (connectedDevices.count > 0) {
            appInfo = [NSString stringWithFormat:@"%@ Devices: %@", appInfo, [connectedDevices componentsJoinedByString:@", "]];
        }
    }
    return appInfo;
}

@end
