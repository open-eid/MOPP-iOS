//
//  MoppLibDigidocManager.m
//  MoppLib
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
#import "MoppLibSOAPManager.h"
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
    //    NSLog(@"tslCachePath: %@", tslCachePath);
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
    std::vector<digidoc::X509Cert> x509Certs;

    __block std::vector<NSString*> certList;
    [moppLibConfiguration.TSLCERTS enumerateObjectsUsingBlock:^(NSString* object, NSUInteger idx, BOOL *stop) {
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

    std::string TSLUrl() const override {
      return moppLibConfiguration.TSLURL.UTF8String;
  }

  virtual std::string ocsp(const std::string &issuer) const override {
    NSString *ocspIssuer = [NSString stringWithCString:issuer.c_str() encoding:[NSString defaultCStringEncoding]];
      NSLog(@"%@", OCSPUrl);
    if ([moppLibConfiguration.OCSPISSUERS objectForKey:ocspIssuer]) {
        return std::string([moppLibConfiguration.OCSPISSUERS[ocspIssuer] UTF8String]);
    } else {
        return std::string([OCSPUrl UTF8String]);
    }
  }

  digidoc::X509Cert generateX509Cert(std::vector<unsigned char> bytes) const {
    digidoc::X509Cert x509Cert;

    try {
      x509Cert = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Der);
        return x509Cert;
    } catch (...) {
        try {
          x509Cert = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Pem);
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
            return 4;
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
    
static digidoc::Signature *signature = nil;
static digidoc::Container *doc = nil;
static WebSigner *signer = nil;
static BOOL isSignatureValidated = false;


+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString*)tsUrl withMoppConfiguration:(MoppLibConfiguration*)moppConfiguration {

  MoppLibSOAPManager.sharedInstance.useTestDigiDocService = useTestDDS;

  // Initialize libdigidocpp.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    try {
      std::string timestampUrl = tsUrl == nil ?
        [moppConfiguration.TSAURL cStringUsingEncoding:NSUTF8StringEncoding] :
        [tsUrl cStringUsingEncoding:NSUTF8StringEncoding];
      digidoc::Conf::init(new DigiDocConf(timestampUrl, moppConfiguration));
      NSString *appInfo = [NSString stringWithFormat:@"%s/%@ (iOS %@)", "qdigidocclient", [self moppAppVersion], [self iOSVersion]];
      std::string appInfoObjcString = std::string([appInfo UTF8String]);
      digidoc::initialize(appInfoObjcString, appInfoObjcString);

      dispatch_async(dispatch_get_main_queue(), ^{
        success();
      });
    } catch(const digidoc::Exception &e) {
      parseException(e);

      dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = [NSError errorWithDomain:@"MoppLib" code:e.code() userInfo:@{@"message":[NSString stringWithUTF8String:e.msg().c_str()]}];
        failure(error);
      });
    }
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
        std::vector<unsigned char> bytes;

        NSString* removeBegin = [certString stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
        NSString* removeEnd = [removeBegin stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];

        NSArray* whitespacedString = [removeEnd componentsSeparatedByCharactersInSet : [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString* noWhitespaceCertString = [whitespacedString componentsJoinedByString:@""];

        std::string decodedCert = base64_decode(std::string([noWhitespaceCertString UTF8String]));

        for(int i = 0; i < decodedCert.length(); i++) {
            bytes.push_back(decodedCert[i]);
        }

        x509Certs = digidoc::X509Cert(bytes, digidoc::X509Cert::Format::Der);
    } catch (...) {
        printf("\nCreating a X509 certificate object raised an exception!\n");
        x509Certs = digidoc::X509Cert();
    }

    return x509Certs;
}

+ (NSArray *)certificatePolicyIdentifiers:(NSData *)certData {
    digidoc::X509Cert x509Cert;

    NSString* certString = [[NSString alloc] initWithData:certData encoding:NSUTF8StringEncoding];

    const unsigned char *bytes = (const unsigned char *)[certData bytes];
    try {
        x509Cert = digidoc::X509Cert(bytes, certData.length, digidoc::X509Cert::Format::Der);
    } catch(...) {
        try {
            x509Cert = digidoc::X509Cert(bytes, certData.length, digidoc::X509Cert::Format::Pem);
        } catch(...) {
            try {
                [self getDerCert:certString];
            } catch(...) {
                printf("create X509 certificate object raised exception\n");
                return @[];
            }
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

+ (BOOL)isSignatureValid:(NSString *)cert signatureValue:(NSString *)signatureValue {
    std::string calculatedSignatureBase64 = std::string(base64_decode(signatureValue.UTF8String));
    
    std::vector<unsigned char> vec;
    std::copy(calculatedSignatureBase64.begin(), calculatedSignatureBase64.end(), std::back_inserter(vec));
    
    digidoc::X509Cert x509Cert = [MoppLibDigidocManager getDerCert:cert];
    
    try {
        std::string profile = "time-stamp";
        
        if ((!signer || !signature) && !isSignatureValidated) {
            NSLog(@"\nError: Received empty value with 'signer' or 'signature'\n");
            return false;
        }
        
        if ((!signer || !signature) && isSignatureValidated) {
            NSLog(@"\nSignature is already validated\n");
            isSignatureValidated = false;
            return true;
        }
        
        NSLog(@"\nSetting profile info...\n");
        signer->setProfile(profile);
        signer->setSignatureProductionPlace("", "", "", "");
        signer->setSignerRoles(std::vector<std::string>());
        NSLog(@"\nProfile info set successfully\n");
        
        try {
            NSLog(@"\nStarting signature validation...\n");
            signature->setSignatureValue(vec);
            signature->extendSignatureProfile(profile);
            signature->validate();
            doc->save();
            delete doc;
            signature = nil;
            signer = nil;
            NSLog(@"\nSignature validated!\n");
            
            isSignatureValidated = true;
            
            return true;
        } catch(const digidoc::Exception &e) {
            parseException(e);
            delete doc;
            NSLog(@"\nError validating signature\n");
            return false;
        }
    } catch(const digidoc::Exception &e) {
        delete doc;
        parseException(e);
        NSLog(@"\nError setting profile info\n");
        return false;
    }
}

+ (NSString *)getContainerHash:(NSString *)cert containerPath:(NSString *)containerPath {
    
    digidoc::X509Cert x509Cert = [MoppLibDigidocManager getDerCert:cert];
    signer = new WebSigner(x509Cert);
    
    doc = digidoc::Container::open(containerPath.UTF8String);
    
    std::string profile = "time-stamp";
    NSMutableArray *profiles = [NSMutableArray new];
    for (auto signature : doc->signatures()) {
        NSLog(@"Signature ID: %s", signature->id().c_str());
        [profiles addObject:[[NSString alloc] initWithBytes:signature->profile().c_str() length:signature->profile().size() encoding:NSUTF8StringEncoding]];
    }
    
    signer->setProfile(profile);
    signer->setSignatureProductionPlace("", "", "", "");
    signer->setSignerRoles(std::vector<std::string>());
    
    signature = doc->prepareSignature(signer);
    
    std::vector<unsigned char> dataToSign = signature->dataToSign();
    std::string dataToSignBase64 = base64_encode(dataToSign.data(), (uint32_t)dataToSign.size());
    NSString *dataToSignEncoded = [NSString stringWithUTF8String:dataToSignBase64.c_str()];
    
    return dataToSignEncoded;
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error {

  // Having two container instances of the same file is causing crashes. Should synchronize all container operations?
  @synchronized (self) {

    MoppLibContainer *moppLibContainer = [MoppLibContainer new];

    [moppLibContainer setFileName:[containerPath lastPathComponent]];
    [moppLibContainer setFilePath:containerPath];
    [moppLibContainer setFileAttributes:[[MLFileManager sharedInstance] fileAttributes:containerPath]];

    digidoc::Container *doc;
    try {

      doc = digidoc::Container::open(containerPath.UTF8String);

    } catch(const digidoc::Exception &e) {
      parseException(e);

      if (e.code() == 63) {
        *error = [MoppLibError fileNameTooLongError];
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
        moppLibDataFile.fileName = [NSString stringWithUTF8String:dataFile->fileName().c_str()];
        moppLibDataFile.fileSize = dataFile->fileSize();

        [dataFiles addObject:moppLibDataFile];
      }
      moppLibContainer.dataFiles = [dataFiles copy];


      // Signatures
      NSMutableArray *signatures = [NSMutableArray array];
      for (int i = 0; i < doc->signatures().size(); i++) {
        digidoc::Signature *signature = doc->signatures().at(i);
        digidoc::X509Cert cert = signature->signingCertificate();
        //      NSLog(@"Signature: %@", [NSString stringWithUTF8String:cert.subjectName("CN").c_str()]);

        MoppLibSignature *moppLibSignature = [MoppLibSignature new];

        std::string name  = cert.subjectName("CN");
        if (name.empty()) {
            name = signature->signedBy();
        }

        moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];

        std::string timestamp = signature->OCSPProducedAt();
        if (timestamp.length() <= 0) {
          timestamp = signature->trustedSigningTime();
        }

        moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:timestamp.c_str()]];

        try {
          digidoc::Signature::Validator *validator =  new digidoc::Signature::Validator(signature);
          digidoc::Signature::Validator::Status status = validator->status();
          moppLibSignature.status = [self determineSignatureStatus:status];

        } catch(const digidoc::Exception &e) {
          moppLibSignature.status = Invalid;
        }

        moppLibSignature.issuerName = [NSString stringWithCString:signature->signingCertificate().issuerName().c_str() encoding:[NSString defaultCStringEncoding]];

        [signatures addObject:moppLibSignature];
      }
      moppLibContainer.signatures = [signatures copy];
      delete doc;
      return moppLibContainer;

    } catch(const digidoc::Exception &e) {
      parseException(e);
      if (doc != nil) {
        delete doc;
      }
      *error = [MoppLibError generalError];
      return nil;
    }

  }
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
    else if(digidoc::Signature::Validator::Status::Test==status){
        return ValidTest;
    }
    return Invalid;
}

- (NSString *)dataFileCalculateHashWithDigestMethod:(NSString *)method container:(MoppLibContainer *)moppContainer dataFileId:(NSString *)dataFileId {
  MLLog(@"dataFileCalculateHashWithDigestMehtod %@", method);
  digidoc::Container *container;
  try {
    container = digidoc::Container::open(moppContainer.filePath.UTF8String);
    for (int i = 0; i < container->dataFiles().size(); i ++) {
      digidoc::DataFile *dataFile = container->dataFiles().at(i);
      NSString *currentId = [NSString stringWithUTF8String:dataFile->id().c_str()];
      if ([currentId isEqualToString:dataFileId]) {
        NSData * data = [NSData dataWithBytes:dataFile->calcDigest([method UTF8String]).data() length:dataFile->calcDigest([method UTF8String]).size()];
        delete container;
        return [data base64EncodedStringWithOptions:0];
      }
    }
  } catch (const digidoc::Exception &e) {
    if (container) {
      delete container;
    }
    parseException(e);
  }
  delete container;
  return nil;
}
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  MLLog(@"createContainerWithPath: %@, dataFilePaths: %@", containerPath, dataFilePaths);

  digidoc::Container *container;
  try {
    container = digidoc::Container::create(containerPath.UTF8String);
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
  delete container;
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  digidoc::Container *container;

  try {
    container = digidoc::Container::open(containerPath.UTF8String);

    for (NSString *dataFilePath in dataFilePaths) {
      [self addDataFileToContainer:container withDataFilePath:dataFilePath error: error];
    }

    container->save(containerPath.UTF8String);

  } catch(const digidoc::Exception &e) {
    parseException(e);
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
  }

  NSError *error2;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error2];
  delete container;

  return moppLibContainer;
}

- (void)addDataFileToContainer:(digidoc::Container *)container withDataFilePath:(NSString *)dataFilePath error:(NSError **)error  {

  NSString *fileName = [dataFilePath lastPathComponent];

  std::ifstream *stream;
  try {
    stream = new std::ifstream(dataFilePath.UTF8String);

    container->addDataFile(stream, [fileName lastPathComponent].UTF8String, @"application/octet-stream".UTF8String);

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
  digidoc::Container *container;
  try {

    container = digidoc::Container::open(containerPath.UTF8String);
    container->removeDataFile(dataFileIndex);

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
  delete container;
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
  NSLog(@"%s", e.msg().c_str());
  for (const digidoc::Exception &ex : e.causes()) {
    parseException(ex);
  }
}

- (BOOL)container:(NSString *)containerPath containsSignatureWithCert:(NSData *)cert {
  digidoc::Container *doc;

  try {
    const unsigned char *bytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(bytes, cert.length, digidoc::X509Cert::Format::Der);

    doc = digidoc::Container::open(containerPath.UTF8String);

    // Checking if signature with same certificate already exists
    for (int i = 0; i < doc->signatures().size(); i++) {
      digidoc::Signature *signature = doc->signatures().at(i);

      digidoc::X509Cert signatureCert = signature->signingCertificate();

      if (x509Cert == signatureCert) {
        delete doc;
        return YES;
      }
    }

  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  if (doc) {
    delete doc;
  }

  return NO;

}

  std::string getOCSPUrl(X509 *x509)  {
    std::string ocspUrl;
    STACK_OF(OPENSSL_STRING) *ocsps = X509_get1_ocsp(x509);
    ocspUrl = std::string(sk_OPENSSL_STRING_value(ocsps, 0));
    X509_email_free(ocsps);
    return ocspUrl;
  }

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert success:(ContainerBlock)success andFailure:(FailureBlock)failure {
  digidoc::Container *container;

  try {
    const unsigned char *certBytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(certBytes, cert.length, digidoc::X509Cert::Format::Der);

    OCSPUrl = [NSString stringWithCString:getOCSPUrl(x509Cert.handle()).c_str() encoding:[NSString defaultCStringEncoding]];

    container = digidoc::Container::open(containerPath.UTF8String);

    // Check if key type in certificate supports ECC algorithm
    CFDataRef cfData = CFDataCreateWithBytesNoCopy(nil, (const UInt8 *)certBytes, cert.length, kCFAllocatorNull);
    SecCertificateRef certRef = SecCertificateCreateWithData(kCFAllocatorDefault, cfData);
    SecKeyRef publicKey = SecCertificateCopyPublicKey(certRef);
    CFStringRef descrRef = CFCopyDescription(publicKey);
    NSString *publicKeyInfo = (NSString *)CFBridgingRelease(descrRef);
    BOOL useECC = [publicKeyInfo containsString:@"ECPublicKey"];

    WebSigner *signer = new WebSigner(x509Cert);

    NSMutableArray *profiles = [NSMutableArray new];
    for (auto signature : container->signatures()) {
        [profiles addObject:[[NSString alloc] initWithBytes:signature->profile().c_str() length:signature->profile().size() encoding:NSUTF8StringEncoding]];
    }

    std::string profile = "time-stamp";

    signer->setProfile(profile);
    signer->setSignatureProductionPlace("", "", "", "");
    signer->setSignerRoles(std::vector<std::string>());

    digidoc::Signature *signature = container->prepareSignature(signer);
    std::vector<unsigned char> dataToSign = signature->dataToSign();

    [[CardActionsManager sharedInstance] calculateSignatureFor:[NSData dataWithBytes:dataToSign.data() length:dataToSign.size()] pin2:pin2 useECC: useECC success:^(NSData *calculatedSignature) {
      try {
        unsigned char *buffer = (unsigned char *)[calculatedSignature bytes];
        std::vector<unsigned char>::size_type size = calculatedSignature.length;
        std::vector<unsigned char> vec(buffer, buffer + size);

        signature->setSignatureValue(vec);
        signature->extendSignatureProfile(profile);
        signature->validate();
        container->save();
        NSError *error;
        MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
        success(moppLibContainer);
        delete container;
      } catch(const digidoc::Exception &e) {
        parseException(e);
        delete container;
        failure([MoppLibError generalError]); // TODO try to find more specific error codes
      }
    } failure:^(NSError *error) {
      delete container;
      failure(error);
    }];


  } catch(const digidoc::Exception &e) {
    delete container;
    parseException(e);
    failure([MoppLibError generalError]);  // TODO try to find more specific error codes
  }
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error {
  digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);
  for (int i = 0; i < doc->signatures().size(); i++) {
    digidoc::Signature *signature = doc->signatures().at(i);
    digidoc::X509Cert cert = signature->signingCertificate();
    NSString *name = [NSString stringWithUTF8String:cert.subjectName("CN").c_str()];
    if ([name isEqualToString:[moppSignature subjectName]]) {
      NSDate *timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
      if ([[moppSignature timestamp] compare:timestamp] == NSOrderedSame) {
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
  }
  delete doc;

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
  digidoc::Container *container;
  try {
    container = digidoc::Container::open(moppContainer.filePath.UTF8String);
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
  delete container;
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path {
  digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);

  for (int i = 0; i < doc->dataFiles().size(); i++) {
    digidoc::DataFile *dataFile = doc->dataFiles().at(i);

    if([fileName isEqualToString:[NSString stringWithUTF8String:dataFile->fileName().c_str()]]) {
      dataFile->saveAs(path.UTF8String);
      break;
    }
  }
  delete doc;

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
