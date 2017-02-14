//
//  MLCertificateHelper.h
//  MoppLib
//
//  Created by Olev Abel on 2/13/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLCertificateHelper : NSObject

+ (NSURLCredential *)getCredentialsFormCert;
@end
