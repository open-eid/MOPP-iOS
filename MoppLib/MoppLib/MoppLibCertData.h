//
//  MoppLibCertData.h
//  MoppLib
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoppLibCertData : NSObject

@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong) NSDate *expiryDate;
@property (nonatomic, assign) int usageCount;
@end
