//
//  MoppLibCardReaderManager.m
//  MoppLib
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
#import "MoppLibPrivateConstants.h"

@interface MoppLibCardReaderManager()<ReaderInterfaceDelegate>

@property (nonatomic) SCARDCONTEXT contextHandle;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic, strong) NSTimer *cardStatusPollingTimer;
@property (nonatomic) MoppLibCardReaderStatus status;
@property (nonatomic, strong) CardReaderiR301 *feitianReader;
@property (nonatomic) int timerCounter;

@property (nonatomic) BOOL wasReaderConnected;
@property (nonatomic) BOOL wasCardConnected;
@property (nonatomic) BOOL isReaderReset;
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
    printLog(@"ID-CARD: Checking if card reader is supported");
    return [modelName hasPrefix:@"iR301"];
}

- (void)startDiscoveringReaders {
    printLog(@"ID-CARD: Starting reader discovery");
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(revokeUnsupportedReader) name:kMoppLibNotificationRevokeUnsupportedReader object:nil];
    self->_isReaderReset = FALSE;
    [self startDiscoveringFeitianReader];
}

- (void)revokeUnsupportedReader {
    printLog(@"ID-CARD: Unsupported reader, stopping reader discovery");
    [self stopDiscoveringReaders];
}

- (void)stopDiscoveringReaders {
    printLog(@"ID-CARD: Stopping reader discovery");
    [self stopDiscoveringFeitianReader];
    
    [[CardActionsManager sharedInstance] setReader:nil];
    [[CardActionsManager sharedInstance] resetCardActions];
    if (![PrivateConstants getIDCardRestartedValue]) {
        _status = Initial;
    } else {
        _status = ReaderProcessFailed;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:@{}];
}

- (void)stopDiscoveringReadersWithStatus:(MoppLibCardReaderStatus)status {
    printLog(@"ID-CARD: Stopping reader discovery with status %lu", (unsigned long)status);
    [self stopDiscoveringFeitianReader];
    
    [[CardActionsManager sharedInstance] setReader:nil];
    [[CardActionsManager sharedInstance] resetCardActions];
    _status = status;
    
    [NSNotificationCenter.defaultCenter removeObserver:@{}];
}

- (void)startDiscoveringFeitianReader {
    printLog(@"ID-CARD: Starting Feitian reader discovering");
    dispatch_async(dispatch_get_main_queue(), ^{
        SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &self->_contextHandle);
    });
}

- (void)stopDiscoveringFeitianReader {
    printLog(@"ID-CARD: Stopping Feitian reader discovering");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_status == CardConnected) {
            [self disconnectCard];
        }
        
        if (self->_cardStatusPollingTimer != nil) {
            [self->_cardStatusPollingTimer invalidate];
            self->_cardStatusPollingTimer = nil;
        }
        
        FtDidEnterBackground(1);
        SCardCancel(self->_contextHandle);
        SCardReleaseContext(self->_contextHandle);
        
        self->_feitianReader = nil;
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
        ret = SCardStatus(_contextHandle, NULL, NULL, &dwState, NULL, NULL, NULL);
        if (ret != SCARD_S_SUCCESS) {
            // No luck on getting card status. Reconnect the reader.
            [self updateStatus:ReaderNotConnected];
            return;
        }
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
                    [[MoppLibCardReaderManager sharedInstance] resetReaderRestart];
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

- (void)resetReaderRestart {
    printLog(@"ID-CARD: Resetting reader restart");
    self->_timerCounter = 0;
    [PrivateConstants setIDCardRestartedValue:FALSE];
    self->_isReaderReset = TRUE;
}

- (void)disconnectCard {
    printLog(@"ID-CARD: Disconnecting card");
    SCardDisconnect(_contextHandle,SCARD_UNPOWER_CARD);
    [self updateStatus:ReaderConnected];
}

- (void)startPollingCardStatus {
    printLog(@"ID-CARD: Started polling ID-Card status");
    _cardStatusPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(cardStatusPollingTimerCallback:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_cardStatusPollingTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopPollingCardStatus {
    printLog(@"ID-CARD: Stopping card status polling");
    if (_cardStatusPollingTimer != nil) {
        [_cardStatusPollingTimer invalidate];
        _cardStatusPollingTimer = nil;
    }
}

- (void)discoverReaders:(NSTimer *)timer {
    printLog(@"ID-CARD: Restarting card reader discovery");
    self->_timerCounter = 0;
    [PrivateConstants setIDCardRestartedValue:TRUE];
    [self startDiscoveringReaders];
}

- (void)cardStatusPollingTimerCallback:(NSTimer *)timer {
    [self handleCardStatus];
    
    _timerCounter++;
    printLog(@"ID-CARD: Timer counter: %d", _timerCounter);
        
    if (_timerCounter >= 20) {
        if ([PrivateConstants getIDCardRestartedValue]) {
            if (self->_wasReaderConnected && self->_wasCardConnected) {
                [PrivateConstants setIDCardRestartedValue:FALSE];
                [self restartDiscoveringReaders:2.0f];
            }
            [self stopPollingCardStatus];
            [self updateStatus:ReaderProcessFailed];
            [self->_delegate moppLibCardReaderStatusDidChange:ReaderProcessFailed];
            return;
        } else {
            [self updateStatus:ReaderRestarted];
            [self->_delegate moppLibCardReaderStatusDidChange:ReaderRestarted];
            [self restartDiscoveringReaders:2.0f];
            return;
        }
    }
}

- (void)restartDiscoveringReaders:(float)delaySeconds {
    if (![PrivateConstants getIDCardRestartedValue]) {
        printLog(@"Restarting reader discovery");
        self->_timerCounter = 0;
        [PrivateConstants setIDCardRestartedValue:TRUE];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderRestarted];
            [self->_delegate moppLibCardReaderStatusDidChange: ReaderRestarted];
        });
        [self stopPollingCardStatus];
        [self stopDiscoveringReaders];
        [NSTimer scheduledTimerWithTimeInterval:delaySeconds
                                         target:self
                                       selector:@selector(discoverReaders:)
                                       userInfo:nil
                                        repeats:NO];
    } else {
        [self updateStatus:ReaderProcessFailed];
        [self->_delegate moppLibCardReaderStatusDidChange: ReaderProcessFailed];
        [PrivateConstants setIDCardRestartedValue:FALSE];
    }
}


- (void)updateStatus:(MoppLibCardReaderStatus)status {
    if (_status == status) {
        return;
    }
    
    _status = status;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_delegate)
            [self->_delegate moppLibCardReaderStatusDidChange:status];
    });
}

#pragma mark - ReaderInterfaceDelegate

- (void) readerInterfaceDidChange:(BOOL)attached bluetoothID:(NSString *)bluetoothID {
    printLog(@"ID-CARD attached: %d", attached);
    if (attached) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderConnected];
            [self startPollingCardStatus];
            [self->_delegate moppLibCardReaderStatusDidChange:ReaderConnected];
            self->_wasReaderConnected = TRUE;
        });
    } else {
        if (self->_wasReaderConnected && self->_isReaderReset) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self updateStatus:Initial];
                [self stopPollingCardStatus];
                [self->_delegate moppLibCardReaderStatusDidChange: Initial];
                self->_wasReaderConnected = FALSE;
            });
        } else if (![PrivateConstants getIDCardRestartedValue] && self->_wasReaderConnected) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self updateStatus:ReaderRestarted];
                [self stopPollingCardStatus];
                [self->_delegate moppLibCardReaderStatusDidChange: ReaderRestarted];
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self stopPollingCardStatus];
                self->_wasReaderConnected = FALSE;
            });
        }
    }
}

- (void)cardInterfaceDidDetach:(BOOL)attached {
    printLog(@"ID-CARD: Card (interface) attached: %d", attached);
    if (attached) {
        if (_cardStatusPollingTimer == nil) {
            [self startPollingCardStatus];
        }
        self->_wasCardConnected = TRUE;
    } else {
        if (self->_wasCardConnected) {
            self->_wasCardConnected = FALSE;
            if ([PrivateConstants getIDCardRestartedValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateStatus:ReaderProcessFailed];
                    [self stopPollingCardStatus];
                    [self->_delegate moppLibCardReaderStatusDidChange: ReaderProcessFailed];
                });
            }
        }
    }
}


- (void)didGetBattery:(NSInteger)battery {
    
}


- (void)findPeripheralReader:(NSString *)readerName {
    printLog(@"ID-CARD: Reader name: %@", readerName);
}


@end
