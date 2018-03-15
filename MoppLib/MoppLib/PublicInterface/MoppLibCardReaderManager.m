//
//  MoppLibCardReaderManager.m
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
#import "MoppLibCardReaderManager.h"
#import "CardActionsManager.h"
#import "CardReaderiR301.h"
#import "ReaderInterface.h"
#import "winscard.h"
#import "wintypes.h"
#import "ft301u.h"

@interface MoppLibCardReaderManager() <ReaderInterfaceDelegate>
@property (nonatomic) SCARDCONTEXT contextHandle;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic, strong) NSTimer *cardStatusPollingTimer;
@property (nonatomic) BOOL cardConnected;
@end

@implementation MoppLibCardReaderManager

+ (MoppLibCardReaderManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibCardReaderManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.readerInterface = [ReaderInterface new];
    [sharedInstance.readerInterface setDelegate:sharedInstance];
  });
  return sharedInstance;
}

- (void)startDetecting {
    SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &_contextHandle);
}

- (void)stopDetecting {
    if (_cardConnected) {
        [self disconnectCard];
    }
    
    if (_cardStatusPollingTimer != nil) {
        [_cardStatusPollingTimer invalidate];
        _cardStatusPollingTimer = nil;
    }
    
    FtDidEnterBackground(1);
    SCardReleaseContext(_contextHandle);
}

- (BOOL)isCardInserted {
    DWORD dwState;
    LONG rv = 0;
    rv = SCardStatus(_contextHandle, NULL, NULL, &dwState, NULL, NULL, NULL );
    
    switch (dwState) {
    case SCARD_PRESENT:
        NSLog(@"Present");
        break;
    case SCARD_ABSENT:
        NSLog(@"Absent");
        break;
    case SCARD_SWALLOWED:
        NSLog(@"Swallowed");
        [self connectCard];
        break;
    }
    
    // card absent = SCARD_ABSENT; should we handle SCARD_SWALLOWED (card not powered)
    return rv == 0 && dwState == SCARD_PRESENT;
}

- (BOOL)connectCard {
    LONG iRet = 0;
    DWORD dwActiveProtocol = -1;
    char mszReaders[128] = "";
    DWORD dwReaders = -1;
  
    iRet = SCardListReaders(_contextHandle, NULL, mszReaders, &dwReaders);
    if(iRet != SCARD_S_SUCCESS)
    {
        NSLog(@"SCardListReaders error %08x",iRet);
    }

    iRet = SCardConnect(_contextHandle,mszReaders,SCARD_SHARE_SHARED,SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,&_contextHandle,&dwActiveProtocol);
    _cardConnected = iRet == SCARD_S_SUCCESS;
    
    if (_cardConnected) {
        [[CardActionsManager sharedInstance] setCardReader:[[CardReaderiR301 alloc] init]];
    }
    
    return _cardConnected;
}

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

- (void)disconnectCard {
    SCardDisconnect(_contextHandle,SCARD_UNPOWER_CARD);
    _cardConnected = NO;
}

- (void)pollCardStatus {
    dispatch_async(dispatch_get_main_queue(), ^{
        _cardStatusPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(cardStatusPollingTimerCallback:) userInfo:nil repeats:YES];
    });
}

- (void)cardStatusPollingTimerCallback:(NSTimer *)timer {
    if (_delegate) {
        BOOL cardInserted = [self isCardInserted];
        if (cardInserted) {
            [_cardStatusPollingTimer invalidate];
            _cardStatusPollingTimer = nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate moppLibCardReaderStatusDidChange:cardInserted];
        });
    }
}

#pragma mark - ReaderInterfaceDelegate

- (void) readerInterfaceDidChange:(BOOL)attached {
    if (attached) {
        _cardConnected = NO;
        [self pollCardStatus];
    } else {
        _cardConnected = NO;
        [_cardStatusPollingTimer invalidate];
        _cardStatusPollingTimer = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate moppLibCardReaderStatusDidChange:false];
        });
    }
}

- (void) cardInterfaceDidDetach:(BOOL)attached {

}

@end
