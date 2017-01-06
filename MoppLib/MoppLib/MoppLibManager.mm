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

#import "MoppLibManager.h"
#import "MoppLibConf.h"
#import "MoppLibDataFile.h"
#import "MoppLibSignature.h"

@interface MoppLibManager ()

@end

@implementation MoppLibManager

+ (MoppLibManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    [sharedInstance setup];
  });
  return sharedInstance;
}

- (void)setup {
  [MoppLibConf setup];
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
      [signatures addObject:moppLibSignature];
    }
    moppLibContainer.signatures = [signatures copy];
    
    
  } catch(const digidoc::Exception &e) {
    NSLog(@"%s", e.msg().c_str());
  }

  return moppLibContainer;
}

@end
