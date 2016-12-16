//
//  ObjCPP.m
//  MoppLib
//
//  Created by Ants Käär on 16.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ObjCPP.h"

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/X509Cert.h>
#include <digidocpp/XmlConf.h>

class DigiDocConf: public digidoc::XmlConf
{
  public:
  std::string TSLCache() const
  {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    return libraryDirectory.UTF8String;
  }
  
  std::string xsdPath() const
  {
    NSBundle *bundle = [NSBundle bundleForClass:[ObjCPP class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
};


@interface ObjCPP () {
//  digidoc::Container *doc;
}
  @end
  

@implementation ObjCPP
  
  + (void)testMethod {
    
    try {
      digidoc::Conf::init(new DigiDocConf);
      digidoc::initialize();
    } catch(const digidoc::Exception &e) {
      NSLog(@"%s", e.msg().c_str());
    }
    
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    try {
      NSString *path = [bundle pathForResource:@"test" ofType:@"bdoc"];
      digidoc::Container *doc = digidoc::Container::open(path.UTF8String);
      
      
//      std::vector<Signature*> *signatures = doc->signatures();
      
      
      NSLog(@"Signatures count: %d", doc->signatures().size());
      
      for (int i = 0; i < doc->signatures().size(); i++) {

        digidoc::Signature *signature = doc->signatures().at(i);
        digidoc::X509Cert cert = signature->signingCertificate();
        NSLog(@"Signature: %@", [NSString stringWithUTF8String:cert.subjectName("CN").c_str()]);
        
      }
      
    } catch(const digidoc::Exception &e) {
      NSLog(@"%s", e.msg().c_str());
    }
    
  }

@end
