//
//  MoppLibCryptoActions.h
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import <Foundation/Foundation.h>

@class CdocInfo;
@protocol AbstractSmartToken;

typedef void (^FailureBlock)(NSError *error);
typedef void (^CdocContainerBlock)(CdocInfo * _Nonnull cdocInfo);

@interface MoppLibCryptoActions : NSObject

/**
 * Parse and get info of CDOC container.
 *
 * @param fullPath      Full path of CDOC container file.
 * @param success       Block to be called on successful completion of action. Includes CDOC container info as CdocContainerBlock.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)parseCdocInfo:(NSString *)fullPath success:(CdocContainerBlock)success failure:(FailureBlock)failure;

@end
