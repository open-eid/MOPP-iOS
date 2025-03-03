//
//  MoppLibCardReaderManager.m
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

#import "MoppLibCardReaderManager.h"
#import "CardActionsManager.h"
#import "CardReaderiR301.h"
#import "NSString+Additions.h"
#import "ReaderInterface.h"

@interface MoppLibCardReaderManager()<ReaderInterfaceDelegate>

@property (nonatomic) SCARDCONTEXT contextHandle;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic) MoppLibCardReaderStatus status;
@end

@implementation MoppLibCardReaderManager

+ (MoppLibCardReaderManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibCardReaderManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.status = Initial;
    sharedInstance.readerInterface = [ReaderInterface new];
    [sharedInstance.readerInterface setDelegate:sharedInstance];
  });
  return sharedInstance;
}

- (void)startDiscoveringReaders {
    printLog(@"ID-CARD: Starting reader discovery");
    [self updateStatus:_status == Initial ? Initial : ReaderRestarted];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->_contextHandle) {
            SCardReleaseContext(self->_contextHandle);
        }
        SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &self->_contextHandle);
    });
}

- (void)stopDiscoveringReaders {
    [self stopDiscoveringReadersWithStatus:Initial];
}

- (void)stopDiscoveringReadersWithStatus:(MoppLibCardReaderStatus)status {
    printLog(@"ID-CARD: Stopping reader discovery with status %lu", (unsigned long)status);
    CardActionsManager.sharedInstance.reader = nil;
    _status = status;
    dispatch_async(dispatch_get_main_queue(), ^{
        FtDidEnterBackground(1);
        SCardCancel(self->_contextHandle);
        SCardReleaseContext(self->_contextHandle);
        self->_contextHandle = 0;
    });
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
        [self updateStatus:ReaderConnected];
    } else {
        [[CardActionsManager sharedInstance] setReader:nil];
        [self updateStatus:Initial];
    }
}

- (void)cardInterfaceDidDetach:(BOOL)attached {
    printLog(@"ID-CARD: Card (interface) attached: %d", attached);
    if (!attached) {
        [[CardActionsManager sharedInstance] setReader:nil];
        return [self updateStatus:ReaderConnected];
    }

    DWORD dwState;
    LONG ret = SCardStatus(_contextHandle, NULL, NULL, &dwState, NULL, NULL, NULL);
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
            if (CardActionsManager.sharedInstance.reader == nil) {
                id cardReader = [[CardReaderiR301 alloc] initWithContextHandle:_contextHandle];
                if (cardReader != nil) {
                    CardActionsManager.sharedInstance.reader = cardReader;
                    [self updateStatus:CardConnected];
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


- (void)didGetBattery:(NSInteger)battery {
    
}


- (void)findPeripheralReader:(NSString *)readerName {
    printLog(@"ID-CARD: Reader name: %@", readerName);
}


@end
