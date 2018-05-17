//
//  CdocReaderWrapper.h
//  CryptoLib
//
//  Created by Siim Suu on 03/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//


#ifndef CdocWriter_h
#define CdocWriter_h


#endif /* CdocWriter_h */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#if __cplusplus
#import "cdoc/CdocReader.h"
#endif
@interface Decrypt : NSObject
- (BOOL)decryptFile: (NSString *)fullPath withPin :(NSString *) pin withController :(UIViewController *) controller;
@end





