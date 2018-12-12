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

#import "MoppLibDigidocManager.h"
#import "MoppLibSOAPManager.h"
#import "MoppLibDataFile.h"
#import "MLDateFormatter.h"
#import "MLFileManager.h"
#import "MoppLibError.h"
#import "CardActionsManager.h"
#import <Security/SecCertificate.h>
#import <Security/SecKey.h>

NSString *kDefaultTSUrl = @"http://dd-at.ria.ee/tsa";

class DigiDocConf: public digidoc::ConfCurrent {
private:
  std::string m_tsUrl;
  
public:

#ifdef TEST_ENV
  std::string TSLUrl() const {
    return "https://open-eid.github.io/test-TL/EE_T.xml";
  }
#endif

  DigiDocConf(const std::string& tsUrl) : m_tsUrl( tsUrl ) {}

  std::string TSLCache() const
  {
    NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
    //    NSLog(@"tslCachePath: %@", tslCachePath);
    return tslCachePath.UTF8String;
  }
  
  std::string xsdPath() const
  {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
  
  virtual std::string TSUrl() const {
    if (m_tsUrl.empty()) {
        return std::string([kDefaultTSUrl cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return m_tsUrl;
  }
  
  virtual std::string PKCS12Cert() const {
    std::string certPath = Conf::PKCS12Cert();
    NSString *encodedCertPath = [NSString stringWithUTF8String:certPath.c_str()];
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:encodedCertPath ofType:@""];
    return path.UTF8String;
  }
  
  // Comment in to see libdigidocpp logs
  /*virtual int logLevel() const {
   return 3;
   }*/
  
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

+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString*)tsUrl {
  
  MoppLibSOAPManager.sharedInstance.useTestDigiDocService = useTestDDS;
  
  // Copy initial TSL cache for libdigidocpp if needed.
  NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
  NSString *eeTslCachePath = [NSString stringWithFormat:@"%@/EE.xml", tslCachePath];
  if (![[MLFileManager sharedInstance] fileExistsAtPath:eeTslCachePath]) {
    MLLog(@"Copy TSL cache: true");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *tslCache = @[[bundle pathForResource:@"EE" ofType:@"xml"],
                          [bundle pathForResource:@"FI" ofType:@"xml"],
                          [bundle pathForResource:@"tl-mp" ofType:@"xml"]];
    
    for (NSString *sourcePath in tslCache) {
      NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", tslCachePath, [sourcePath lastPathComponent]];
      [[MLFileManager sharedInstance] copyFileWithPath:sourcePath toPath:destinationPath];
    }
  } else {
    MLLog(@"Copy TSL cache: false");
  }
  
  
  // Initialize libdigidocpp.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    try {
      std::string timestampUrl = tsUrl == nil ?
        [[MoppLibDigidocManager defaultTSUrl] cStringUsingEncoding:NSUTF8StringEncoding] :
        [tsUrl cStringUsingEncoding:NSUTF8StringEncoding];
      digidoc::Conf::init(new DigiDocConf(timestampUrl));
      digidoc::initialize("qdigidocclient");
      
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

+ (NSArray *)certificatePolicyIdentifiers:(NSData *)certData withCertFormat:(X509CertFormat)certFormat {
    digidoc::X509Cert x509Cert;
    digidoc::X509Cert::Format x509CertFormat;
    
    switch (certFormat) {
    case X509CertFormatDer:
        x509CertFormat = digidoc::X509Cert::Format::Der;
        break;
    case X509CertFormatPem:
        x509CertFormat = digidoc::X509Cert::Format::Pem;
        break;
    }
    
    try {
        const unsigned char *bytes = (const unsigned  char *)[certData bytes];
        x509Cert = digidoc::X509Cert(bytes, certData.length, x509CertFormat);
        auto policies = x509Cert.certificatePolicies();
        NSMutableArray *result = [NSMutableArray new];
        for (auto p : policies) {
            [result addObject:[NSString stringWithUTF8String:p.c_str()]];
        }
        return result;
    } catch(...) {
        printf("create X509 certificate object raised exception\n");
        return @[];
    }
}

+ (NSString *)defaultTSUrl {
    return kDefaultTSUrl;
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

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert success:(ContainerBlock)success andFailure:(FailureBlock)failure {
  digidoc::Container *container;
  
  try {
    const unsigned char *certBytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(certBytes, cert.length, digidoc::X509Cert::Format::Der);
    
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

- (NSString *)pkcs12Cert {
    DigiDocConf *conf = new DigiDocConf(std::string());
    std::string certPath = conf->PKCS12Cert();
    return [NSString stringWithUTF8String:certPath.c_str()];
}

@end
