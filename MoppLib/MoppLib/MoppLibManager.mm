//
//  MoppLibManager.m
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/X509Cert.h>
#include <digidocpp/XmlConf.h>
#include <digidocpp/crypto/Signer.h>

#import "MoppLibManager.h"
#import "MoppLibDataFile.h"
#import "MoppLibSignature.h"
#import "MLDateFormatter.h"
#import "MLFileManager.h"
#import "MoppLibError.h"
#import "CardActionsManager.h"

class DigiDocConf: public digidoc::ConfCurrent {
public:
  std::string TSLCache() const
  {
    NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
//    NSLog(@"tslCachePath: %@", tslCachePath);
    return tslCachePath.UTF8String;
  }
  
  std::string xsdPath() const
  {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibManager class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
  
  virtual std::string PKCS12Cert() const {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibManager class]];
    NSString *path = [bundle pathForResource:@"878252.p12" ofType:@""];
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


@interface MoppLibManager ()
@end

@implementation MoppLibManager

+ (MoppLibManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure {

  // Copy initial TSL cache for libdigidocpp if needed.
  NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
  NSString *eeTslCachePath = [NSString stringWithFormat:@"%@/EE.xml", tslCachePath];
  if (![[MLFileManager sharedInstance] fileExistsAtPath:eeTslCachePath]) {
    NSLog(@"Copy TSL cache: true");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *tslCache = @[[bundle pathForResource:@"EE" ofType:@"xml"],
                          [bundle pathForResource:@"FI" ofType:@"xml"],
                          [bundle pathForResource:@"tl-mp" ofType:@"xml"]];
    
    for (NSString *sourcePath in tslCache) {
      NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", tslCachePath, [sourcePath lastPathComponent]];
      [[MLFileManager sharedInstance] copyFileWithPath:sourcePath toPath:destinationPath];
    }
  } else {
    NSLog(@"Copy TSL cache: false");
  }
  
  
  // Initialize libdigidocpp.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    try {
      digidoc::Conf::init(new DigiDocConf);
      digidoc::initialize();
      
      dispatch_async(dispatch_get_main_queue(), ^{
        success();
      });
    } catch(const digidoc::Exception &e) {
      parseException(e);
      
      dispatch_async(dispatch_get_main_queue(), ^{
        failure(nil);
      });
    }
  });
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath {
  MoppLibContainer *moppLibContainer = [MoppLibContainer new];
  
  [moppLibContainer setFileName:[containerPath lastPathComponent]];
  [moppLibContainer setFilePath:containerPath];
  [moppLibContainer setFileAttributes:[[MLFileManager sharedInstance] fileAttributes:containerPath]];
  
  try {
    
    digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);
    
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
      if (name.length() <= 0) {
        name = signature->signedBy();
      }
      moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];
      
      std::string timestamp = signature->OCSPProducedAt();
      if (timestamp.length() <= 0) {
        timestamp = signature->trustedSigningTime();
      }
      
      moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:timestamp.c_str()]];
      
      try {
        signature->validate();
        moppLibSignature.isValid = YES;
      } catch(const digidoc::Exception &e) {
        parseException(e);
        moppLibSignature.isValid = NO;
      }
      
      [signatures addObject:moppLibSignature];
    }
    moppLibContainer.signatures = [signatures copy];
    
    return moppLibContainer;
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
    return nil;
  }
}
- (NSString *)dataFileCalculateHashWithDigestMethod:(NSString *)method container:(MoppLibContainer *)moppContainer dataFileId:(NSString *)dataFileId {
  NSLog(@"dataFileCalculateHashWithDigestMehtod %@", method);
  try {
    digidoc::Container *container = digidoc::Container::open(moppContainer.filePath.UTF8String);
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
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  NSLog(@"createContainerWithPath: %@, dataFilePath: %@", containerPath, dataFilePath);
  
  try {
    
    digidoc::Container *container = digidoc::Container::create(containerPath.UTF8String);
    container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }

  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  try {
    
    digidoc::Container *container = digidoc::Container::open(containerPath.UTF8String);
    container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  return moppLibContainer;
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex {
  try {
    
    digidoc::Container *container = digidoc::Container::open(containerPath.UTF8String);
    container->removeDataFile(dataFileIndex);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  return moppLibContainer;
}

- (NSArray *)getContainersIsSigned:(BOOL)isSigned {
  NSMutableArray *containers = [NSMutableArray array];
  NSArray *containerPaths = [[MLFileManager sharedInstance] getContainers];
  for (NSString *containerPath in containerPaths) {
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
    
    if (isSigned && [moppLibContainer isSigned]) {
      [containers addObject:moppLibContainer];
    } else if (!isSigned && ![moppLibContainer isSigned]){
      [containers addObject:moppLibContainer];
    }
  }
  return containers;
}

void parseException(const digidoc::Exception &e) {
  NSLog(@"%s", e.msg().c_str());
  for (const digidoc::Exception &ex : e.causes()) {
    parseException(ex);
  }
}

- (void)addSignature:(MoppLibContainer *)moppContainer pin2:(NSString *)pin2 cert:(NSData *)cert success:(void (^)(MoppLibContainer *))success andFailure:(FailureBlock)failure {
  
  try {
    const unsigned char *bytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(bytes, cert.length, digidoc::X509Cert::Format::Der);
    
    digidoc::Container *doc = digidoc::Container::open(moppContainer.filePath.UTF8String);
    
    // Checking if signature with same certificate already exists
    for (int i = 0; i < doc->signatures().size(); i++) {
      digidoc::Signature *signature = doc->signatures().at(i);
      
      digidoc::X509Cert signatureCert = signature->signingCertificate();
      
      if (x509Cert == signatureCert) {
        failure([MoppLibError signatureAlreadyExistsError]);
        return;
      }
    }
    
    WebSigner *signer = new WebSigner(x509Cert);
    
    std::string profile;
    if (doc->signatures().size() > 0) {
      std::string containerProfile = doc->signatures().at(0)->profile();
      
      if (containerProfile.find("time-stamp") != std::string::npos) {
        profile = "time-stamp";
      } else if (containerProfile.find("time-mark") != std::string::npos) {
        profile = "time-mark";
      }
    } else {
      // No signatures. bdoc should use time-mark
      if ([[moppContainer.filePath pathExtension] isEqualToString:@"bdoc"]) {
        profile = "time-mark";
      }
    }
    
    if (profile.length() <= 0) {
      profile = "time-stamp";
    }
        
    signer->setProfile(profile);
    signer->setSignatureProductionPlace("", "", "", "");
    signer->setSignerRoles(std::vector<std::string>());
    
    digidoc::Signature *signature = doc->prepareSignature(signer);
    std::vector<unsigned char> dataToSign = signature->dataToSign();
    
    [[CardActionsManager sharedInstance] calculateSignatureFor:[NSData dataWithBytes:dataToSign.data() length:dataToSign.size()] pin2:pin2 controller:nil success:^(NSData *calculatedSignature) {
      try {
        unsigned char *buffer = (unsigned char *)[calculatedSignature bytes];
        std::vector<unsigned char>::size_type size = calculatedSignature.length;
        std::vector<unsigned char> vec(buffer, buffer + size);
        
        signature->setSignatureValue(vec);
        signature->extendSignatureProfile(profile);
        signature->validate();
        doc->save();
        MoppLibContainer *moppLibContainer = [self getContainerWithPath:moppContainer.filePath];
        success(moppLibContainer);
      } catch(const digidoc::Exception &e) {
        parseException(e);
        failure([MoppLibError generalError]); // TODO try to find more specific error codes
      }
    } failure:failure];
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
    failure([MoppLibError generalError]);  // TODO try to find more specific error codes
  }
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath {
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
        }
        break;
      }
    }
  }
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  return moppLibContainer;
}

- (NSString *)getMoppLibVersion {
  NSMutableString *resultString = [[NSMutableString alloc] initWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
  [resultString appendString:[NSString stringWithFormat:@".%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
  return resultString;
}

@end
