//
//  MoppLibDigidocManager.m
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
#include <fstream>

#import "MoppLibDigidocManager.h"
#import "MoppLibDataFile.h"
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
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
  
  virtual std::string PKCS12Cert() const {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
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


@interface MoppLibDigidocManager ()
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

- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure {
  
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
    parseException(e);
  }
  delete container;
  return nil;
}
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  MLLog(@"createContainerWithPath: %@, dataFilePath: %@", containerPath, dataFilePath);
  
  digidoc::Container *container;
  try {
    
    container = digidoc::Container::create(containerPath.UTF8String);
    container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  NSError *error;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
  delete container;
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  return [self addDataFileToContainerWithPath:containerPath withDataFilePath:dataFilePath duplicteCount:0];
}

- (MoppLibContainer *)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath duplicteCount:(int)count {
  digidoc::Container *container;
  
  NSString *fileName = [dataFilePath lastPathComponent];
  if (count > 0) {
    NSString *extension = [fileName pathExtension];
    NSString *withoutExtension = [fileName stringByDeletingPathExtension];
    fileName = [withoutExtension stringByAppendingString:[NSString stringWithFormat:@"(%i).%@", count, extension]];
  }
  std::ifstream *stream;
  try {
    
    container = digidoc::Container::open(containerPath.UTF8String);
    stream = new std::ifstream(dataFilePath.UTF8String);
    
    container->addDataFile(stream, [fileName lastPathComponent].UTF8String, @"application/octet-stream".UTF8String);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
  } catch(const digidoc::Exception &e) {
    NSString *message = [NSString stringWithCString:e.msg().c_str() encoding:NSNonLossyASCIIStringEncoding];
    
    // libdigidoc doesn't send specific error code when file with same name already exists.
    if (e.code() == 0 && [message hasPrefix:@"Document with same file name"]) {
      return [self addDataFileToContainerWithPath:containerPath withDataFilePath:dataFilePath duplicteCount:count + 1];
    } else {
      parseException(e);
    }
  }
  
  NSError *error2;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error2];
  delete container;

  return moppLibContainer;
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex {
  digidoc::Container *container;
  try {
    
    container = digidoc::Container::open(containerPath.UTF8String);
    container->removeDataFile(dataFileIndex);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  NSError *error;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
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
    delete doc;
    parseException(e);
  }
  return NO;

}

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert success:(ContainerBlock)success andFailure:(FailureBlock)failure {
  digidoc::Container *doc;
  
  try {
    const unsigned char *bytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(bytes, cert.length, digidoc::X509Cert::Format::Der);
    
    doc = digidoc::Container::open(containerPath.UTF8String);
    
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
      if ([[containerPath pathExtension] isEqualToString:@"bdoc"]) {
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
        NSError *error;
        MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
        success(moppLibContainer);
        delete doc;
      } catch(const digidoc::Exception &e) {
        parseException(e);
        delete doc;
        failure([MoppLibError generalError]); // TODO try to find more specific error codes
      }
    } failure:^(NSError *error) {
      delete doc;
      failure(error);
    }];
    
    
  } catch(const digidoc::Exception &e) {
    delete doc;
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
  delete doc;
  
  NSError *error;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error];
  return moppLibContainer;
}

- (NSString *)getMoppLibVersion {
  NSMutableString *resultString = [[NSMutableString alloc] initWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
  [resultString appendString:[NSString stringWithFormat:@".%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
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

@end
