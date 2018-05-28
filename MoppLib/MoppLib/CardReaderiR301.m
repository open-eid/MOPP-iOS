//
//  CardReaderIR301.m
//  MoppLib
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

#import "CardReaderiR301.h"
#import <Foundation/Foundation.h>
#import "ReaderInterface.h"
#import "winscard.h"
#import "ft301u.h"
#import "wintypes.h"
#import "NSString+Additions.h"
#import "NSData+Additions.h"
#import "MoppLibCardReaderManager.h"
#import "MoppLibError.h"

@interface CardReaderiR301() <ReaderInterfaceDelegate>
@property (nonatomic, strong) DataSuccessBlock successBlock;
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) ReaderInterface *interface;
@property (nonatomic) SCARDHANDLE contextHandle;
@end

@implementation CardReaderiR301

-(id)initWithInterface:(ReaderInterface*)interface andContentHandle:(SCARDHANDLE)contextHandle
{
    if (self = [super init]) {
        _interface = interface;
        _contextHandle = contextHandle;
        return self;
    }
    return nil;
}

-(void)setupWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    _successBlock = success;
    _failureBlock = failure;
}

#pragma mark - CardReaderWrapper

- (void)transmitCommand:(NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSData *apduData = [commandHex toHexData];
    unsigned char response[512];
    unsigned char apdu[512];
    unsigned int responseSize = sizeof(response);
    NSUInteger apduSize = [apduData length];
    
    NSMutableData *responseData = [[NSMutableData alloc] init];
    
    [apduData getBytes:apdu length:apduSize];
    
    SCARD_IO_REQUEST pioSendPci;
    pioSendPci.cbPciLength = sizeof(pioSendPci);
    pioSendPci.dwProtocol = SCARD_PROTOCOL_T1;

    if (SCARD_S_SUCCESS == SCardTransmit(
        _contextHandle,
        &pioSendPci,
        &apdu[0], (DWORD)apduSize,
        NULL,
        &response[0], &responseSize)) {
        
        NSData *respData = [NSData dataWithBytes:&response[0] length:responseSize];
        NSLog(@"IR301 Response: %@", [respData toHexString]);
        
        if ( [respData length] < 2 ) {
            failure (nil);
            return;
        }
        
        unsigned char trailing[2] = {
            response[ responseSize - 2 ],
            response[ responseSize - 1 ]
        };
        
        BOOL needMoreData = ( trailing[0] == 0x61 );
        [responseData appendBytes:&response[0] length: ( needMoreData ? responseSize - 2 : responseSize )];
        
        // While there is additional response data in the chip card: 61 XX
        // where XX defines the size of additional data in bytes)
        while (needMoreData) {
            unsigned char getResponseApdu[5] = { 0x00, 0xC0, 0x00, 0x00, 0x00 };
            
            // Set the size of additional data to get from the chip
            getResponseApdu[4] = trailing[1];
            
            // (Re)set the response size
            responseSize = sizeof(response);
            
            if (SCARD_S_SUCCESS == SCardTransmit(
                _contextHandle,
                &pioSendPci,
                &getResponseApdu[0], sizeof(getResponseApdu),
                NULL,
                &response[0], &responseSize)) {
                
                NSData *respData = [NSData dataWithBytes:&response[0] length:responseSize];
                NSLog(@"IR301 Response: %@", [respData toHexString]);
                
                trailing[0] = response[ responseSize - 2 ];
                trailing[1] = response[ responseSize - 1 ];
                
                needMoreData = ( trailing[0] == 0x61 );
                [responseData appendBytes:&response[0] length: ( needMoreData ? responseSize - 2 : responseSize )];

            } else {
                NSLog(@"FAILED to send APDU");
                failure(nil);
                return;
            }
        }
        
        NSLog(@"------------ %@", [responseData toHexString]);
        success(responseData);
    } else {
        NSLog(@"FAILED to send APDU");
        failure(nil);
    }
}

- (void)powerOnCard:(DataSuccessBlock)success failure:(FailureBlock)failure  {
    success(nil);
}

- (void)isCardInserted:(void(^)(BOOL)) completion {
    DWORD status = [self cardStatus];
    completion(status == SCARD_PRESENT || status == SCARD_POWERED || status == SCARD_SWALLOWED);
}

- (BOOL)isConnected {
    return SCardStatus(_contextHandle, NULL, NULL, NULL, NULL, NULL, NULL ) == SCARD_S_SUCCESS;
}

- (DWORD)cardStatus {
    DWORD status;
    LONG ret = 0;
    
    ret = SCardStatus(_contextHandle, NULL, NULL, &status, NULL, NULL, NULL );
    if (ret != SCARD_S_SUCCESS) {
        return SCARD_ABSENT;
    }
    
    return status;
}

- (void)isCardPoweredOn:(void(^)(BOOL)) completion {
    completion([self cardStatus] == SCARD_PRESENT);
}

- (void)resetReader {
}

- (void)cardInterfaceDidDetach:(BOOL)attached {
    
}

- (void)readerInterfaceDidChange:(BOOL)attached {
    
}

@end
