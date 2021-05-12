//
//  MoppLibCardReaderManager.m
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
#import "MoppLibCardReaderManager.h"
#import "CardActionsManager.h"
#import "CardReaderiR301.h"
#import "ReaderInterface.h"
#import "winscard.h"
#import "wintypes.h"
#import "ft301u.h"

@interface MoppLibCardReaderManager()<ReaderInterfaceDelegate>

@property (nonatomic) SCARDCONTEXT contextHandle;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic, strong) NSTimer *cardStatusPollingTimer;
@property (nonatomic) MoppLibCardReaderStatus status;
@property (nonatomic, strong) CardReaderiR301 *feitianReader;
@end

@implementation MoppLibCardReaderManager

+ (MoppLibCardReaderManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibCardReaderManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.status = ReaderNotConnected;
    sharedInstance.readerInterface = [ReaderInterface new];
    [sharedInstance.readerInterface setDelegate:sharedInstance];
  });
  return sharedInstance;
}

+ (MoppLibCardChipType)atrToChipType:(NSData *)atr {
    static NSString *idemiaAtr = @"3B DB 96 00 80 B1 FE 45 1F 83 00 12 23 3F 53 65 49 44 0F 90 00 F1";
    static NSString *esteid34cold = @"3B FE 18 00 00 80 31 FE 45 45 73 74 45 49 44 20 76 65 72 20 31 2E 30 A8";
    static NSString *esteid34warm = @"3B FE 18 00 00 80 31 FE 45 80 31 80 66 40 90 A4 16 2A 00 83 0F 90 00 EF";
    static NSString *esteid35 = @"3B FA 18 00 00 80 31 FE 45 FE 65 49 44 20 2F 20 50 4B 49 03";
    
    // ordered newest first
    if([atr isEqualToData:[idemiaAtr toHexData]]) {
        return ChipType_Idemia;
    }
    else if([atr isEqualToData:[esteid35 toHexData]]) {
        return ChipType_EstEID35;
    }
    else if([atr isEqualToData:[esteid34cold toHexData]]) {
        return ChipType_EstEID34;
    }
    else if([atr isEqualToData:[esteid34warm toHexData]]) {
        return ChipType_EstEID34;
    }

    return ChipType_Unknown;
}

+ (BOOL)isCardReaderModelSupported:(NSString *)modelName {
    return [modelName isEqualToString:@"iR301"] || [modelName isEqualToString:@"iR301-UL"];
}

- (void)startDiscoveringReaders {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(revokeUnsupportedReader) name:kMoppLibNotificationRevokeUnsupportedReader object:nil];
    [self startDiscoveringFeitianReader];
}

- (void)revokeUnsupportedReader {
    [self stopDiscoveringReaders];
}

- (void)stopDiscoveringReaders {
    [self stopDiscoveringFeitianReader];
    
    [[CardActionsManager sharedInstance] setReader:nil];
    [[CardActionsManager sharedInstance] resetCardActions];
    _status = ReaderNotConnected;
    
    [NSNotificationCenter.defaultCenter removeObserver:nil];
}

- (void)startDiscoveringFeitianReader {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatus:ReaderNotConnected];
        SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &_contextHandle);
    });
}

- (void)stopDiscoveringFeitianReader {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_status == CardConnected) {
            [self disconnectCard];
        }
        
        if (_cardStatusPollingTimer != nil) {
            [_cardStatusPollingTimer invalidate];
            _cardStatusPollingTimer = nil;
        }
        
        FtDidEnterBackground(1);
        SCardCancel(_contextHandle);
        SCardReleaseContext(_contextHandle);
        
        _feitianReader = nil;
        if ([[[CardActionsManager sharedInstance] reader] isKindOfClass:[CardReaderiR301 class]]) {
            [[CardActionsManager sharedInstance] setReader:nil];
        }
    });
}

- (void)handleCardStatus {
    DWORD dwState;
    LONG ret = 0;
    
    ret = SCardStatus(_contextHandle, NULL, NULL, &dwState, NULL, NULL, NULL);
    if (ret != SCARD_S_SUCCESS) {
        // No luck on getting card status. Reconnect the reader.
        [self updateStatus:ReaderNotConnected];
        return;
    }
    
    switch (dwState) {
        // There is no card in the reader.
        case SCARD_ABSENT:
            [self updateStatus:ReaderConnected];
        
        // There is a card in the reader, but it has not been moved into position for use.
        case SCARD_PRESENT:
            break;

        // There is a card in the reader in position for use. The card is not powered.
        case SCARD_SWALLOWED:
            {
                id<CardReaderWrapper> cardReader = [[CardActionsManager sharedInstance] reader];
                if (cardReader == nil || ![cardReader isKindOfClass:[CardReaderiR301 class]]) {
                    cardReader = [[CardReaderiR301 alloc] initWithInterface:_readerInterface andContextHandle:_contextHandle];
              
                    [[CardActionsManager sharedInstance] setReader:cardReader];
                    [self updateStatus:CardConnected];
                    
                    [self stopPollingCardStatus];
                }
            }
            break;
            
        // Power is being provided to the card, but the reader driver is unaware of the mode of the card.
        case SCARD_POWERED:
            break;
        
        // The card has been reset and is awaiting PTS negotiation.
        case SCARD_NEGOTIABLE:
            break;
            
        // The card has been reset and specific communication protocols have been established.
        case SCARD_SPECIFIC:
            break;
    }
}

- (void)disconnectCard {
    SCardDisconnect(_contextHandle,SCARD_UNPOWER_CARD);
    [self updateStatus:ReaderConnected];
}

- (void)startPollingCardStatus {
    _cardStatusPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(cardStatusPollingTimerCallback:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_cardStatusPollingTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopPollingCardStatus {
    if (_cardStatusPollingTimer != nil) {
        [_cardStatusPollingTimer invalidate];
        _cardStatusPollingTimer = nil;
    }
}

- (void)cardStatusPollingTimerCallback:(NSTimer *)timer {
    [self handleCardStatus];
}

- (void)updateStatus:(MoppLibCardReaderStatus)status {
    if (_status == status) {
        MLLog(@"WARNING: trying to set state that manager is already in: %lu", (unsigned long)_status);
        return;
    }
    
    _status = status;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate moppLibCardReaderStatusDidChange:status];
    });
}

#pragma mark - ReaderInterfaceDelegate

- (void) readerInterfaceDidChange:(BOOL)attached bluetoothID:(NSString *)bluetoothID {
    if (attached) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderConnected];
            [self startPollingCardStatus];
            [_delegate moppLibCardReaderStatusDidChange:ReaderConnected];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderNotConnected];
            [self stopPollingCardStatus];
            [_delegate moppLibCardReaderStatusDidChange: ReaderNotConnected];
        });
    }
}

@end
