//
//  MoppLibConf.m
//  MoppLib
//
//  Created by Ants Käär on 20.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "MoppLibConf.h"
#include <digidocpp/XmlConf.h>
#include <digidocpp/Container.h>
#include <digidocpp/Exception.h>

class DigiDocConf: public digidoc::XmlConf {
public:
  std::string TSLCache() const
  {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    return libraryDirectory.UTF8String;
  }
  
  std::string xsdPath() const
  {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibConf class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
};

@implementation MoppLibConf

+ (void)setup {
  try {
    digidoc::Conf::init(new DigiDocConf);
    digidoc::initialize();
  } catch(const digidoc::Exception &e) {
    NSLog(@"%s", e.msg().c_str());
  }
}

@end
