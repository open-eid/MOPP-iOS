//
//  CardReaderiR301.h
//  MoppLib
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
#import "CardReaderWrapper.h"
#import "MoppLibConstants.h"
#import "ReaderInterface.h"
#import "winscard.h"

@interface CardReaderiR301 : NSObject <CardReaderWrapper>

@property (nonatomic, strong) id<CardReaderWrapperDelegate> delegate;
-(id)initWithInterface:(ReaderInterface*)interface andContextHandle:(SCARDHANDLE)contextHandle;
-(void)setupWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;
-(void)updateContextHandle:(SCARDCONTEXT) contextHandle;
-(NSString *)atr;
@end
