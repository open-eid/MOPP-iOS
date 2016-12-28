//
//  MoppLibConstants.h
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
  
  moppLibReaderNotFoundError = 10001,
  moppLibCardNotFoundError = 10002
  
  
} MoppLibErrorCode;

typedef void (^DataSuccessBlock)(NSData *responseObject);
typedef void (^ObjectSuccessBlock)(NSObject *responseObject);
typedef void (^FailureBlock)(NSError *error);
