//
//  MoppLibDigidocManager.m
//  MoppLib
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

#include <openssl/x509.h>
#include <openssl/asn1t.h>
#include <openssl/pem.h>
#include <openssl/x509v3.h>
#import <CryptoLib/CryptoLib.h>
#include <openssl/x509.h>

#import "MoppLibDigidocManager.h"
#import "MoppLibDataFile.h"
#import "MLDateFormatter.h"
#import "MLFileManager.h"
#import "MoppLibError.h"
#import "CardActionsManager.h"
#import <Security/SecCertificate.h>
#import <Security/SecKey.h>
#import "MoppLibGlobals.h"

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

public:

  DigiDocConf(const std::string& tsUrl, MoppLibConfiguration* moppConfiguration) : m_tsUrl( tsUrl ), moppLibConfiguration( moppConfiguration ) {}

  std::string TSLCache() const override {
    NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
    //    printLog(@"tslCachePath: %@", tslCachePath);
    return tslCachePath.UTF8String;
  }

  std::string xsdPath() const override {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }

  virtual std::string TSUrl() const override {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *tsaUrl = [defaults stringForKey:@"kTimestampUrlKey"];
      return [tsaUrl length] != 0 ? tsaUrl.UTF8String : moppLibConfiguration.TSAURL.UTF8String;
  }

  virtual std::string PKCS12Cert() const override {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:@"798.p12" ofType:@""];
    return path.UTF8String;
  }

  std::string verifyServiceUri() const override {
      return moppLibConfiguration.SIVAURL.UTF8String;
  }

  std::vector<digidoc::X509Cert> TSLCerts() const override {
      return stringsToX509Certs(moppLibConfiguration.TSLCERTS);
  }

  std::string TSLUrl() const override {
      return moppLibConfiguration.TSLURL.UTF8String;
  }
    
  virtual std::vector<digidoc::X509Cert> TSCerts() const override {
      NSMutableArray<NSString *> *certBundle = [NSMutableArray arrayWithArray:moppLibConfiguration.CERTBUNDLE];
      if (moppLibConfiguration.TSACERT != NULL) {
          [certBundle addObject:moppLibConfiguration.TSACERT];
      }
      return stringsToX509Certs(certBundle);
  }

  virtual std::vector<digidoc::X509Cert> verifyServiceCerts() const override {
      return stringsToX509Certs(moppLibConfiguration.CERTBUNDLE);
  }

  virtual std::string ocsp(const std::string &issuer) const override {
    NSString *ocspIssuer = [NSString stringWithCString:issuer.c_str() encoding:[NSString defaultCStringEncoding]];
      printLog(@"Received OCSP url: %@", OCSPUrl);
    if ([moppLibConfiguration.OCSPISSUERS objectForKey:ocspIssuer]) {
        printLog(@"Using issuer: '%@' with OCSP url from central configuration: %s", ocspIssuer, std::string([moppLibConfiguration.OCSPISSUERS[ocspIssuer] UTF8String]).c_str());
        return std::string([moppLibConfiguration.OCSPISSUERS[ocspIssuer] UTF8String]);
    } else {
        printLog(@"Did not find url for issuer: %@. Using received OCSP url: %@", ocspIssuer, OCSPUrl);
        if (OCSPUrl) {
            return std::string([OCSPUrl UTF8String]);
        }
        return std::string();
    }
  }

    std::vector<digidoc::X509Cert> stringsToX509Certs(NSArray<NSString*> *certBundle) const {
        std::vector<digidoc::X509Cert> x509Certs;

        __block std::vector<NSString*> certList;
        [certBundle enumerateObjectsUsingBlock:^(NSString* object, NSUInteger idx, BOOL *stop) {
          certList.push_back(object);
        }];

        __block std::vector<unsigned char> bytes;

        for (auto const& element : certList) {
          std::string cString = std::string([element UTF8String]);
          std::string fullCert = "-----BEGIN CERTIFICATE-----\n" + cString + "\n" + "-----END CERTIFICATE-----";

          for(int i = 0; fullCert[i] != '\0'; i++) {
            bytes.push_back(fullCert[i]);
          }
          x509Certs.push_back(generateX509Cert(bytes));
          bytes.clear();
        }

        return x509Certs;
    }

  digidoc::X509Cert generateX509Cert(std::vector<unsigned char> bytes) const {
    digidoc::X509Cert x509Cert;

    try {
      x509Cert = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Pem);
        return x509Cert;
    } catch (...) {
        try {
          x509Cert = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Der);
          return x509Cert;
        } catch (const digidoc::Exception &e) {
            printLog(@"Unable to generate a X509 certificate object. Code: %u, message: %@", e.code(), [NSString stringWithCString:e.msg().c_str() encoding:[NSString defaultCStringEncoding]]);
            return digidoc::X509Cert();
        } catch(...) {
            printLog(@"Generating a X509 certificate object raised an exception!\n");
            return digidoc::X509Cert();
          }
      }
    return x509Cert;
  }

    bool isDebugMode() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"isDebugMode"];
    }

    bool isLoggingEnabled() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"kIsFileLoggingEnabled"];
    }

    // Comment in / out to see / hide libdigidocpp logs
    // Currently enabled on DEBUG mode

    virtual int logLevel() const override {
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
                // Create folder 'logs' in Documents directory
                BOOL isFolderCreated = [mlFM createFolder:@"logs"];
                if (isFolderCreated) {
                    return logFileLocation(logsUrl);
                } else {
                    // Save log files to 'Documents' directory if creating 'logs' folder was unsuccessful
                    NSURL *url = [[NSURL alloc] initWithString:[mlFM documentsDirectoryPath]];
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
    return std::vector<unsigned char>();
  }

  digidoc::X509Cert _cert;
};


@interface MoppLibDigidocManager ()
    - (MoppLibSignatureStatus)determineSignatureStatus:(int) status;
@end

@implementation MoppLibDigidocManager

static std::unique_ptr<digidoc::Container> docContainer = nil;
static digidoc::Signature *signature = nil;

static std::string profile = "time-stamp";



+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString*)tsUrl withMoppConfiguration:(MoppLibConfiguration*)moppConfiguration {

    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);

        // Initialize libdigidocpp.
        try {
            std::string timestampUrl = tsUrl == nil ?
            [moppConfiguration.TSAURL cStringUsingEncoding:NSUTF8StringEncoding] :
            [tsUrl cStringUsingEncoding:NSUTF8StringEncoding];
            digidoc::Conf::init(new DigiDocConf(timestampUrl, moppConfiguration));
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

+ (NSString *)removeBeginAndEndFromCertificate:(NSString *)certString {
    NSString* removeBegin = [certString stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
    NSString* removeEnd = [removeBegin stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];

    NSArray* whitespacedString = [removeEnd componentsSeparatedByCharactersInSet : [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* noWhitespaceCertString = [whitespacedString componentsJoinedByString:@""];

    return noWhitespaceCertString;
}

+ (digidoc::X509Cert)getDerCert:(NSString *)certString {
    try {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:certString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
        return digidoc::X509Cert(bytes, data.length, digidoc::X509Cert::Format::Der);
    } catch (const digidoc::Exception &e) {
        parseException(e);
        return digidoc::X509Cert();
    }
}

+ (digidoc::X509Cert)getPemCert:(NSString *)certString {
    try {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:certString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
        return digidoc::X509Cert(bytes, data.length, digidoc::X509Cert::Format::Pem);
    } catch (const digidoc::Exception &e) {
        parseException(e);
        return digidoc::X509Cert();
    }
}

+ (digidoc::X509Cert)getCertFromBytes:(const unsigned char *)bytes certData:(NSData *)certData {
    digidoc::X509Cert x509Cert;

    try {
        x509Cert = digidoc::X509Cert(bytes, certData.length, digidoc::X509Cert::Format::Der);
    } catch(...) {
        x509Cert = digidoc::X509Cert(bytes, certData.length, digidoc::X509Cert::Format::Pem);
    }

    return x509Cert;
}

+ (NSArray *)certificatePolicyIdentifiers:(NSData *)certData {
    digidoc::X509Cert x509Cert;

    NSString* certString = [[NSString alloc] initWithData:certData encoding:NSUTF8StringEncoding];

    const unsigned char *bytes = (const unsigned char *)[certData bytes];
    try {
        if ([certString length] != 0) {
            digidoc::X509Cert derCert = [self getDerCert:certString];
            x509Cert = (derCert != digidoc::X509Cert()) ? derCert : [self getPemCert:certString];
            if (x509Cert == digidoc::X509Cert()) {
                x509Cert = [self getCertFromBytes:bytes certData:certData];
            }
        } else {
            x509Cert = [self getCertFromBytes:bytes certData:certData];
        }
    } catch(...) {
        try {
            x509Cert = digidoc::X509Cert(bytes, certData.length, digidoc::X509Cert::Format::Pem);
        } catch(const digidoc::Exception &e) {
            parseException(e);
            printLog(@"Unable to create a X509 certificate object for Certificate Policy Identifiers. Code: %u, message: %@", e.code(), [NSString stringWithCString:e.msg().c_str() encoding:[NSString defaultCStringEncoding]]);
            return @[];
        } catch(...) {
            printLog(@"Creating a X509 certificate object raised exception\n");
            return @[];
        }
    }

    auto policies = x509Cert.certificatePolicies();
    NSMutableArray *result = [NSMutableArray new];
    for (auto p : policies) {
        [result addObject:[NSString stringWithUTF8String:p.c_str()]];
    }
    return result;
}

+ (NSArray *)getDataToSign {
    std::vector<unsigned char> dataTosign = signature->dataToSign();

    NSMutableArray *dataToSignArray = [NSMutableArray arrayWithCapacity: dataTosign.size()];

    for (auto value : dataTosign) {
        [dataToSignArray addObject:@(value)];
    }

    return dataToSignArray;
}

+ (void)isSignatureValid:(NSString *)cert signatureValue:(NSString *)signatureValue success:(BoolBlock)success failure:(FailureBlock)failure {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:signatureValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
    auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
    std::vector<unsigned char> calculatedSignatureBase64(bytes, bytes + data.length);

    digidoc::X509Cert x509Cert;
    try {
        x509Cert = [MoppLibDigidocManager getDerCert:cert];
    } catch (const digidoc::Exception &e) {
        parseException(e);
        NSError *certError;
        certError = [NSError errorWithDomain:[NSString stringWithFormat:@"Did not get a DER cert\n"] code:-1 userInfo:nil];
        failure(certError);
    }

    OCSPUrl = [NSString stringWithCString:getOCSPUrl(x509Cert.handle()).c_str() encoding:[NSString defaultCStringEncoding]];

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
        signature->extendSignatureProfile(profile);
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

+ (NSString *)prepareSignature:(NSString *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData {
    digidoc::X509Cert x509Cert;

    try {
        x509Cert = [MoppLibDigidocManager getDerCert:cert];
    } catch (const digidoc::Exception &e) {
        parseException(e);
        return nil;
    }
    WebSigner *signer = new WebSigner(x509Cert);

    docContainer = NULL;
    signature = NULL;

    try {
        docContainer = digidoc::Container::openPtr(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
        parseException(e);
        return nil;
    }

    NSMutableArray *profiles = [NSMutableArray new];
    for (auto signature : docContainer->signatures()) {
        printLog(@"Signature ID: %@", [NSString stringWithUTF8String:signature->id().c_str()]);
        [profiles addObject:[[NSString alloc] initWithBytes:signature->profile().c_str() length:signature->profile().size() encoding:NSUTF8StringEncoding]];
    }
    
    NSLog(@"\nSetting profile info...\n");
    NSLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
    signer->setProfile(profile);
    signer->setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
    
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
      doc = digidoc::Container::openPtr(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);

      if (e.code() == 63) {
          *error = [MoppLibError fileNameTooLongError];
      } else if (e.code() == digidoc::Exception::NetworkError) {
          *error = [MoppLibError noInternetConnectionError];
      } else {
          *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
      }
      return nil;
    }
    try {
      // DataFiles
      NSMutableArray *dataFiles = [NSMutableArray array];

      for (int i = 0; i < doc->dataFiles().size(); i++) {
        digidoc::DataFile *dataFile = doc->dataFiles().at(i);

        MoppLibDataFile *moppLibDataFile = [MoppLibDataFile new];
        moppLibDataFile.fileId = [NSString stringWithUTF8String:dataFile->id().c_str()];
        moppLibDataFile.mediaType = [NSString stringWithUTF8String:dataFile->mediaType().c_str()];
        moppLibDataFile.fileName = [NSString stringWithUTF8String:dataFile->fileName().c_str()];
        moppLibDataFile.fileSize = dataFile->fileSize();

        [dataFiles addObject:moppLibDataFile];
      }
      moppLibContainer.dataFiles = [dataFiles copy];


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

- (MoppLibSignature *)getSignatureData:(digidoc::X509Cert)cert signature:(digidoc::Signature *)signature mediaType:(std::string)mediaType dataFileCount:(NSInteger)dataFileCount {

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
    moppLibSignature.signingCertificate = [self pemToDer:signingCert];
    moppLibSignature.signatureMethod = [NSString stringWithUTF8String:signature->signatureMethod().c_str()];
    moppLibSignature.containerFormat = [NSString stringWithUTF8String:mediaType.c_str()];
    moppLibSignature.signatureFormat = [NSString stringWithUTF8String:signature->profile().c_str()];
    moppLibSignature.signedFileCount = dataFileCount;
    moppLibSignature.signatureTimestamp = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->TimeStampTime().c_str()]];
    moppLibSignature.signatureTimestampUTC = [NSString stringWithUTF8String:signature->TimeStampTime().c_str()];
    moppLibSignature.hashValueOfSignature = [self getHexStringFromVectorData:signature->messageImprint()];
    moppLibSignature.tsCertificateIssuer = [NSString stringWithUTF8String:timestampCert.issuerName("CN").c_str()];
    moppLibSignature.tsCertificate = [self pemToDer:timestampCert];
    moppLibSignature.ocspCertificateIssuer = [NSString stringWithUTF8String:ocspCert.issuerName("CN").c_str()];
    moppLibSignature.ocspCertificate = [self pemToDer:ocspCert];
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
      digidoc::Signature::Validator *validator = new digidoc::Signature::Validator(signature);
      digidoc::Signature::Validator::Status status = validator->status();
      moppLibSignature.diagnosticsInfo = [NSString stringWithUTF8String:validator->diagnostics().c_str()];
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

- (NSData *)getCertDataFromX509:(digidoc::X509Cert)cert {
    BIO *bio = BIO_new(BIO_s_mem());
    PEM_write_bio_X509(bio, cert.handle());
    BUF_MEM *bufMem;
    BIO_get_mem_ptr(bio, &bufMem);
    NSData *data = [NSData dataWithBytes:bufMem->data length:bufMem->length];
    BIO_free(bio);

    return data;
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

- (NSData *)pemToDer:(digidoc::X509Cert)cert {
    NSData *dataCert = [self getCertDataFromX509:cert];
    NSString *dataCertAsString = [[NSString alloc] initWithData:dataCert encoding:NSASCIIStringEncoding];
    NSString *removeCertHeader = [dataCertAsString stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----\n" withString:@""];
    NSString *removeCertFooter = [removeCertHeader stringByReplacingOccurrencesOfString:@"\n-----END CERTIFICATE-----\n" withString:@""];

    NSData* derCertString = [removeCertFooter dataUsingEncoding:NSUTF8StringEncoding];

    return [[NSData alloc]initWithBase64EncodedString:[[NSString alloc] initWithData:derCertString encoding:NSASCIIStringEncoding] options:NSDataBase64DecodingIgnoreUnknownCharacters];
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

- (NSString *)dataFileCalculateHashWithDigestMethod:(NSString *)method container:(MoppLibContainer *)moppContainer dataFileId:(NSString *)dataFileId {
  MLLog(@"dataFileCalculateHashWithDigestMehtod %@", method);
  std::unique_ptr<digidoc::Container> container;
  try {
    container = digidoc::Container::openPtr(moppContainer.filePath.UTF8String);
    for (int i = 0; i < container->dataFiles().size(); i ++) {
      digidoc::DataFile *dataFile = container->dataFiles().at(i);
      NSString *currentId = [NSString stringWithUTF8String:dataFile->id().c_str()];
      if ([currentId isEqualToString:dataFileId]) {
        NSData * data = [NSData dataWithBytes:dataFile->calcDigest([method UTF8String]).data() length:dataFile->calcDigest([method UTF8String]).size()];
        return [data base64EncodedStringWithOptions:0];
      }
    }
  } catch (const digidoc::Exception &e) {
    parseException(e);
  }
  return nil;
}
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  MLLog(@"createContainerWithPath: %@, dataFilePaths: %@", containerPath, dataFilePaths);

  std::unique_ptr<digidoc::Container> container;
  try {
    container = digidoc::Container::createPtr(containerPath.UTF8String);
    for (NSString *dataFilePath in dataFilePaths) {
      container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    }

    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
      *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
    }

  } catch(const digidoc::Exception &e) {
    parseException(e);
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
    std::unique_ptr<digidoc::Container> container;

  try {
    container = digidoc::Container::openPtr(containerPath.UTF8String);

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
    container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
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
    std::unique_ptr<digidoc::Container> container;
  try {
    container = digidoc::Container::openPtr(containerPath.UTF8String);
    container->removeDataFile((int)dataFileIndex);

    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
      parseException(e);
    }

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

- (BOOL)container:(NSString *)containerPath containsSignatureWithCert:(NSData *)cert {
  std::unique_ptr<digidoc::Container> doc;

  try {
    const unsigned char *bytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(bytes, cert.length, digidoc::X509Cert::Format::Der);

    doc = digidoc::Container::openPtr(containerPath.UTF8String);

    // Checking if signature with same certificate already exists
    for (int i = 0; i < doc->signatures().size(); i++) {
      digidoc::Signature *signature = doc->signatures().at(i);

      digidoc::X509Cert signatureCert = signature->signingCertificate();

      if (x509Cert == signatureCert) {
        return YES;
      }
    }

  } catch(const digidoc::Exception &e) {
    parseException(e);
  }

  return NO;

}

  std::string getOCSPUrl(X509 *x509)  {
    std::string ocspUrl = "";
    STACK_OF(OPENSSL_STRING) *ocsps = X509_get1_ocsp(x509);
    if (ocsps != NULL) {
      ocspUrl = std::string(sk_OPENSSL_STRING_value(ocsps, 0));
      X509_email_free(ocsps);
    }
    return ocspUrl;
  }

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert roleData:(MoppLibRoleAddressData *)roleData success:(ContainerBlock)success andFailure:(FailureBlock)failure {

  try {
    const unsigned char *certBytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(certBytes, cert.length, digidoc::X509Cert::Format::Der);

    OCSPUrl = [NSString stringWithCString:getOCSPUrl(x509Cert.handle()).c_str() encoding:[NSString defaultCStringEncoding]];

    // Create unique_ptr that manages a container in this scope
    std::unique_ptr<digidoc::Container> managedContainer;

    // Load the container
    managedContainer = digidoc::Container::openPtr(containerPath.UTF8String);


    // Check if key type in certificate supports ECC algorithm
    CFDataRef cfData = CFDataCreateWithBytesNoCopy(nil, (const UInt8 *)certBytes, cert.length, kCFAllocatorNull);
    SecCertificateRef certRef = SecCertificateCreateWithData(kCFAllocatorDefault, cfData);
    SecKeyRef publicKey = SecCertificateCopyKey(certRef);
    CFStringRef descrRef = CFCopyDescription(publicKey);
    NSString *publicKeyInfo = (NSString *)CFBridgingRelease(descrRef);
    BOOL useECC = [publicKeyInfo containsString:@"ECPublicKey"];

    WebSigner *signer = new WebSigner(x509Cert);

    NSMutableArray *profiles = [NSMutableArray new];
    for (auto signature : managedContainer->signatures()) {
        [profiles addObject:[[NSString alloc] initWithBytes:signature->profile().c_str() length:signature->profile().size() encoding:NSUTF8StringEncoding]];
    }

    std::string profile = "time-stamp";

    NSLog(@"\nSetting profile info...\n");
    NSLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
    signer->setProfile(profile);
    signer->setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
  
    std::vector<std::string> roles;
    for (NSString *role in roleData.ROLES) {
        if (role != (id)[NSNull null] && [role length] != 0) {
            roles.push_back(std::string([role UTF8String] ?: ""));
        }
    }
    signer->setSignerRoles(roles);

    digidoc::Signature *signature;
    try {
        signature = managedContainer->prepareSignature(signer);
    } catch (const digidoc::Exception &e) {
        parseException(e);
        failure([MoppLibError generalError]);
    }

    std::vector<unsigned char> dataToSign = signature->dataToSign();

    // Release the container from the unique_ptr and obtain the raw pointer for the callback
    digidoc::Container * const unmanagedContainerPointer = managedContainer.release();

    [[CardActionsManager sharedInstance] calculateSignatureFor:[NSData dataWithBytes:dataToSign.data() length:dataToSign.size()] pin2:pin2 useECC: useECC success:^(NSData *calculatedSignature) {

        // Wrap the raw container pointer into a local unique_ptr as the first thing to do
        std::unique_ptr<digidoc::Container> successManagedContainer(unmanagedContainerPointer);

      try {
        unsigned char *buffer = (unsigned char *)[calculatedSignature bytes];
        std::vector<unsigned char>::size_type size = calculatedSignature.length;
        std::vector<unsigned char> vec(buffer, buffer + size);

        signature->setSignatureValue(vec);
        signature->extendSignatureProfile(profile);
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
  std::unique_ptr<digidoc::Container> doc = digidoc::Container::openPtr(containerPath.UTF8String);
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


- (void)addMobileIDSignatureToContainer:(MoppLibContainer *)moppContainer
                              signature:(NSString *)signature
                                success:(ContainerBlock)success
                             andFailure:(FailureBlock)failure {
    std::unique_ptr<digidoc::Container> container;
  try {
    container = digidoc::Container::openPtr(moppContainer.filePath.UTF8String);
    NSData *data = [signature dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char bytes[[data length]];
    [data getBytes:bytes length:data.length];
    std::vector<unsigned char> signatureVector(bytes, bytes + data.length);
    container->addAdESSignature(signatureVector);
    container->save();
    MLLog(@"Mobile ID signature added");
    NSError *error;
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:moppContainer.filePath error:&error];
    success(moppLibContainer);
  } catch(const digidoc::Exception &e) {
    parseException(e);
    NSError *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
    failure(error);
  }
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure {
    std::unique_ptr<digidoc::Container> doc;
    try {
        doc = digidoc::Container::openPtr(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
        parseException(e);
    }

    if (doc != nil) {
        for (int i = 0; i < doc->dataFiles().size(); i++) {
            digidoc::DataFile *dataFile;
            try {
                dataFile = doc->dataFiles().at(i);
            } catch (const digidoc::Exception &e) {
                parseException(e);
                break;
            }
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
}

-(BOOL)isFileInContainer:(NSString *)fileName dataFile:(NSString *)dataFileName {
    return [fileName isEqualToString:dataFileName];
}

- (BOOL)isContainerFileSaveable:(NSString *)containerPath saveDataFile:(NSString *)fileName {
    std::unique_ptr<digidoc::Container> doc;
    try {
        doc = digidoc::Container::openPtr(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
        parseException(e);
    }

    if (doc != nil) {
        for (int i = 0; i < doc->dataFiles().size(); i++) {
            digidoc::DataFile *dataFile;
            try {
                dataFile = doc->dataFiles().at(i);
            } catch (const digidoc::Exception &e) {
                parseException(e);
                break;
            }

            if([self isFileInContainer:fileName dataFile:[NSString stringWithUTF8String:dataFile->fileName().c_str()]]) {
                return TRUE;
            }
        }
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
    NSString *appInfo = [NSString stringWithFormat:@"%s/%@ (iOS %@)", "riadigidoc", [self moppAppVersion], [self iOSVersion]];
    NSArray *connectedDevices = [self connectedDevices];
    if (connectedDevices.count > 0) {
        appInfo = [NSString stringWithFormat:@"%@ Devices: %@", appInfo, [connectedDevices componentsJoinedByString:@", "]];
    }
    return appInfo;
}

- (NSString *)pkcs12Cert {
    DigiDocConf *conf = new DigiDocConf(std::string(), nil);
    std::string certPath = conf->PKCS12Cert();
    return [NSString stringWithUTF8String:certPath.c_str()];
}

@end
