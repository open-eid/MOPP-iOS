//
//  MoppLibDigidocManager.m
//  MoppLib
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
        } catch(...) {
            printf("\nCreating a X509 certificate object raised an exception!\n");
            return digidoc::X509Cert();
          }
      }
    return x509Cert;
  }

    bool isDebugMode() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"isDebugMode"];
    }

    // Comment in / out to see / hide libdigidocpp logs
    // Currently enabled on DEBUG mode

    virtual int logLevel() const override {
        if (isDebugMode()) {
            return 4;
        } else {
            return 0;
        }
    }

    std::string logFile() const override {
        if (isDebugMode()) {
            MLFileManager *mlFM = [[MLFileManager alloc] init];
            NSURL *url = [[NSURL alloc] initWithString:[mlFM documentsDirectoryPath]];
            return std::string([[[url URLByAppendingPathComponent: @"libdigidocpp.log"] path] UTF8String]);
        } else {
            return std::string();
        }
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
            NSString *appInfo = [NSString stringWithFormat:@"%s/%@ (iOS %@)", "qdigidocclient", [self moppAppVersion], [self iOSVersion]];
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
    digidoc::X509Cert x509Certs;
    try {
        std::vector<unsigned char> bytes = base64_decode(std::string([certString UTF8String]));
        x509Certs = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Der);
    } catch (const digidoc::Exception &e) {
        parseException(e);
        x509Certs = digidoc::X509Cert();
    }

    return x509Certs;
}

+ (digidoc::X509Cert)getPemCert:(NSString *)certString {
    digidoc::X509Cert x509Certs;
    try {
        std::vector<unsigned char> bytes = base64_decode(std::string([certString UTF8String]));
        x509Certs = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Pem);
    } catch (const digidoc::Exception &e) {
        parseException(e);
        x509Certs = digidoc::X509Cert();
    }

    return x509Certs;
}

+ (digidoc::X509Cert)getCertFromBytes:(const unsigned char *)bytes certData:(NSData *)certData {
    digidoc::X509Cert x509Cert;
    
    x509Cert = digidoc::X509Cert(bytes, certData.length, digidoc::X509Cert::Format::Der);
    
    if (x509Cert == digidoc::X509Cert()) {
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
        } catch(...) {
            printf("create X509 certificate object raised exception\n");
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
    std::vector<unsigned char> calculatedSignatureBase64 = base64_decode(signatureValue.UTF8String);

    digidoc::X509Cert x509Cert = [MoppLibDigidocManager getDerCert:cert];

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

+ (NSString *)prepareSignature:(NSString *)cert containerPath:(NSString *)containerPath {
    digidoc::X509Cert x509Cert = [MoppLibDigidocManager getDerCert:cert];
    WebSigner *signer = new WebSigner(x509Cert);

    docContainer = NULL;
    signature = NULL;

    docContainer = digidoc::Container::openPtr(containerPath.UTF8String);

    NSMutableArray *profiles = [NSMutableArray new];
    for (auto signature : docContainer->signatures()) {
        printLog(@"Signature ID: %@", [NSString stringWithUTF8String:signature->id().c_str()]);
        [profiles addObject:[[NSString alloc] initWithBytes:signature->profile().c_str() length:signature->profile().size() encoding:NSUTF8StringEncoding]];
    }

    printLog(@"\nSetting profile info...\n");
    signer->setProfile(profile);
    signer->setSignatureProductionPlace("", "", "", "");
    signer->setSignerRoles(std::vector<std::string>());
    printLog(@"\nProfile info set successfully\n");

    printLog(@"\nSetting signature...\n");
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
        *error = [MoppLibError generalError];
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
        moppLibDataFile.fileName = [MoppLibDigidocManager sanitize:[NSString stringWithUTF8String:dataFile->fileName().c_str()]];
        moppLibDataFile.fileSize = dataFile->fileSize();

        [dataFiles addObject:moppLibDataFile];
      }
      moppLibContainer.dataFiles = [dataFiles copy];


      // Signatures
      NSMutableArray *signatures = [NSMutableArray array];
      // Timestamp tokens
      NSMutableArray *timeStampTokens = [NSMutableArray array];
      for (digidoc::Signature *signature: doc->signatures()) {
        [signatures addObject:[self getSignatureData:signature->signingCertificate() signature:signature]];
        [timeStampTokens addObject:[self getSignatureData:signature->TimeStampCertificate() signature:signature]];
      }

      moppLibContainer.signatures = [signatures copy];
      moppLibContainer.timestampTokens = [timeStampTokens copy];
      return moppLibContainer;

    } catch(const digidoc::Exception &e) {
      parseException(e);
      *error = [MoppLibError generalError];
      return nil;
    }

  }
}

- (MoppLibSignature *)getSignatureData:(digidoc::X509Cert)cert signature:(digidoc::Signature *)signature {

    MoppLibSignature *moppLibSignature = [MoppLibSignature new];

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

    std::string timestamp = signature->trustedSigningTime();
    moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:timestamp.c_str()]];

    try {
      digidoc::Signature::Validator *validator =  new digidoc::Signature::Validator(signature);
      digidoc::Signature::Validator::Status status = validator->status();
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
    NSString *message = [NSString stringWithCString:e.msg().c_str() encoding:NSNonLossyASCIIStringEncoding];

    // libdigidoc doesn't send specific error code when file with same name already exists.
    if (e.code() == 0 && [message hasPrefix:@"Document with same file name"]) {
        *error = [MoppLibError duplicatedFilenameError];
    } else {
      parseException(e);
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
  printLog(@"%s", e.msg().c_str());
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

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert success:(ContainerBlock)success andFailure:(FailureBlock)failure {

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
    SecKeyRef publicKey = SecCertificateCopyPublicKey(certRef);
    CFStringRef descrRef = CFCopyDescription(publicKey);
    NSString *publicKeyInfo = (NSString *)CFBridgingRelease(descrRef);
    BOOL useECC = [publicKeyInfo containsString:@"ECPublicKey"];

    WebSigner *signer = new WebSigner(x509Cert);

    NSMutableArray *profiles = [NSMutableArray new];
    for (auto signature : managedContainer->signatures()) {
        [profiles addObject:[[NSString alloc] initWithBytes:signature->profile().c_str() length:signature->profile().size() encoding:NSUTF8StringEncoding]];
    }

    std::string profile = "time-stamp";

    signer->setProfile(profile);
    signer->setSignatureProductionPlace("", "", "", "");
    signer->setSignerRoles(std::vector<std::string>());

    digidoc::Signature *signature = managedContainer->prepareSignature(signer);
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
            failure([MoppLibError generalError]); // TODO try to find more specific error codes
        }
      }
    } failure:^(NSError *error) {
      std::unique_ptr<digidoc::Container> failureManagedContainer(unmanagedContainerPointer);
      failure(error);
    }];


  } catch(const digidoc::Exception &e) {
    parseException(e);
    failure([MoppLibError generalError]);  // TODO try to find more specific error codes
  }
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error {
  std::unique_ptr<digidoc::Container> doc = digidoc::Container::openPtr(containerPath.UTF8String);
  for (int i = 0; i < doc->signatures().size(); i++) {
    digidoc::Signature *signature = doc->signatures().at(i);
    digidoc::X509Cert cert = signature->signingCertificate();

    // Estonian signatures
    NSString *name = [NSString stringWithUTF8String:cert.subjectName("CN").c_str()];
    NSString *trustedTimeStamp = [NSString stringWithUTF8String:signature->trustedSigningTime().c_str()];

    std::string givename = cert.subjectName("GN");
    std::string surname = cert.subjectName("SN");
    std::string serialNR = [self getSerialNumber:cert.subjectName("serialNumber")];

    // Foreign signatures
    NSString *foreignName = [NSString stringWithFormat:@"%s, %s, %s", surname.c_str(), givename.c_str(), serialNR.c_str()];

    if (([name isEqualToString:[moppSignature subjectName]] || [foreignName isEqualToString:[moppSignature subjectName]]) && [trustedTimeStamp isEqualToString:[moppSignature trustedSigningTime]]) {
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
    failure([MoppLibError generalError]);
  }
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path {
    std::unique_ptr<digidoc::Container> doc = digidoc::Container::openPtr(containerPath.UTF8String);

  for (int i = 0; i < doc->dataFiles().size(); i++) {
    digidoc::DataFile *dataFile = doc->dataFiles().at(i);

    if([fileName isEqualToString:[MoppLibDigidocManager sanitize:[NSString stringWithUTF8String:dataFile->fileName().c_str()]]]) {
      dataFile->saveAs(path.UTF8String);
      break;
    }
  }

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

- (NSString *)pkcs12Cert {
    DigiDocConf *conf = new DigiDocConf(std::string(), nil);
    std::string certPath = conf->PKCS12Cert();
    return [NSString stringWithUTF8String:certPath.c_str()];
}

@end
