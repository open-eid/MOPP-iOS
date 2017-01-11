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

#import "MoppLibManager.h"
#import "MoppLibDataFile.h"
#import "MoppLibSignature.h"
#import "MLDateFormatter.h"

class DigiDocConf: public digidoc::XmlConf {
public:
  std::string TSLCache() const
  {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSLog(@"libraryDirectory: %@", libraryDirectory);
    return libraryDirectory.UTF8String;
  }
  
  std::string xsdPath() const
  {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibManager class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    try {
      digidoc::Conf::init(new DigiDocConf);
      digidoc::initialize();
      
      dispatch_async(dispatch_get_main_queue(), ^{
        success();
      });
    } catch(const digidoc::Exception &e) {
      NSLog(@"setup failed: %s", e.msg().c_str());
      
      dispatch_async(dispatch_get_main_queue(), ^{
        failure(nil);
      });
    }
  });
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath {
  MoppLibContainer *moppLibContainer = [MoppLibContainer new];
  try {
    
    digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);
    
    // DataFiles
    NSMutableArray *dataFiles = [NSMutableArray array];
    
    for (int i = 0; i < doc->dataFiles().size(); i++) {
      digidoc::DataFile *dataFile = doc->dataFiles().at(i);
      
      MoppLibDataFile *moppLibDataFile = [MoppLibDataFile new];
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
      NSLog(@"Signature: %@", [NSString stringWithUTF8String:cert.subjectName("CN").c_str()]);
      
      MoppLibSignature *moppLibSignature = [MoppLibSignature new];
      moppLibSignature.subjectName = [NSString stringWithUTF8String:cert.subjectName("CN").c_str()];
      
      moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
      
      try {
        signature->validate();
        moppLibSignature.isValid = YES;
      }
      catch(const digidoc::Exception &e) {
        moppLibSignature.isValid = NO;
      }
      
      [signatures addObject:moppLibSignature];
    }
    moppLibContainer.signatures = [signatures copy];
    
    return moppLibContainer;
    
  } catch(const digidoc::Exception &e) {
    NSLog(@"%s", e.msg().c_str());
    
    return nil;
  }
}

//- (void)getContainerWithPath:(NSString *)containerPath withSuccess:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure {
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    
//    MoppLibContainer *moppLibContainer = [MoppLibContainer new];
//    try {
//      
//      digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);
//      
//      // DataFiles
//      NSMutableArray *dataFiles = [NSMutableArray array];
//      
//      for (int i = 0; i < doc->dataFiles().size(); i++) {
//        digidoc::DataFile *dataFile = doc->dataFiles().at(i);
//        
//        MoppLibDataFile *moppLibDataFile = [MoppLibDataFile new];
//        moppLibDataFile.fileName = [NSString stringWithUTF8String:dataFile->fileName().c_str()];
//        moppLibDataFile.fileSize = dataFile->fileSize();
//        
//        [dataFiles addObject:moppLibDataFile];
//      }
//      moppLibContainer.dataFiles = [dataFiles copy];
//      
//      
//      // Signatures
//      NSMutableArray *signatures = [NSMutableArray array];
//      for (int i = 0; i < doc->signatures().size(); i++) {
//        digidoc::Signature *signature = doc->signatures().at(i);
//        digidoc::X509Cert cert = signature->signingCertificate();
//        NSLog(@"Signature: %@", [NSString stringWithUTF8String:cert.subjectName("CN").c_str()]);
//        
//        MoppLibSignature *moppLibSignature = [MoppLibSignature new];
//        moppLibSignature.subjectName = [NSString stringWithUTF8String:cert.subjectName("CN").c_str()];
//        
//        moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
//        
//        try {
//          signature->validate();
//          moppLibSignature.isValid = YES;
//        }
//        catch(const digidoc::Exception &e) {
//          moppLibSignature.isValid = NO;
//        }
//        
//        [signatures addObject:moppLibSignature];
//      }
//      moppLibContainer.signatures = [signatures copy];
//      
//      dispatch_async(dispatch_get_main_queue(), ^{
//        success(moppLibContainer);
//      });
//      
//    } catch(const digidoc::Exception &e) {
//      NSLog(@"%s", e.msg().c_str());
//      
//      dispatch_async(dispatch_get_main_queue(), ^{
//        failure(nil);
//      });
//    }
//    
//  });
//}


- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath {
  
  NSLog(@"createContainerWithPath: %@", containerPath);
  digidoc::Container *doc = digidoc::Container::create(containerPath.UTF8String);
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  return moppLibContainer;
}

@end
