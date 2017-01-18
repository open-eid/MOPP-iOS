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
#import "MLFileManager.h"

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
      moppLibSignature.subjectName = [NSString stringWithUTF8String:cert.subjectName("CN").c_str()];
      
      moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
      
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

- (MoppLibContainer *)addFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
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

- (NSArray *)getContainersIsSigned:(BOOL)isSigned {
  NSMutableArray *containers = [NSMutableArray array];
  NSArray *containerPaths = [[MLFileManager sharedInstance] getContainers];
  for (NSString *containerPath in containerPaths) {
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
    
    if (isSigned && moppLibContainer.signatures.count > 0) {
      [containers addObject:moppLibContainer];
    } else if (!isSigned && moppLibContainer.signatures.count == 0){
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

@end
