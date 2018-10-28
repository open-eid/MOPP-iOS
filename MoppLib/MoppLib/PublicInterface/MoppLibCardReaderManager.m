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
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "MoppLibCardReaderManager.h"
#import "CardActionsManager.h"
#import "CardReaderiR301.h"
#import "CardReaderACR3901U_S1.h"
#import "ReaderInterface.h"
#import "winscard.h"
#import "wintypes.h"
#import "ft301u.h"

@interface MoppLibCardReaderManager()<ReaderInterfaceDelegate, CBCentralManagerDelegate, CardReaderACR3901U_S1Delegate>

@property (nonatomic) SCARDCONTEXT contextHandle;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic, strong) NSTimer *cardStatusPollingTimer;
@property (nonatomic) MoppLibCardReaderStatus status;
@property (nonatomic, strong) CardReaderiR301 *feitianReader;
#pragma mark BlueTooth
@property (nonatomic, strong) CBCentralManager *coreBluetoothManager;
@property (nonatomic) BOOL scanningBluetoothPeripherals;
@property (nonatomic, strong) NSArray *peripherals; // of type CBPeripheral*
@property (nonatomic, strong) CBPeripheral *currentPeripheral;
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

- (void)startDiscoveringReaders {
    [self startDiscoveringFeitianReader];
    [self startDiscoveringBluetoothPeripherals];
}

- (void)stopDiscoveringReaders {
    [self stopDiscoveringFeitianReader];
    [self stopDiscoveringBluetoothPeripherals];
    
    [[CardActionsManager sharedInstance] setReader:nil];
    [[CardActionsManager sharedInstance] resetCardActions];
    _status = ReaderNotConnected;
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

- (void) readerInterfaceDidChange:(BOOL)attached {
    if (attached) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderConnected];
            [self startPollingCardStatus];
            [_delegate moppLibCardReaderStatusDidChange:ReaderConnected];
            
            [self stopDiscoveringBluetoothPeripherals];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderNotConnected];
            [self stopPollingCardStatus];
            [_delegate moppLibCardReaderStatusDidChange: ReaderNotConnected];
            
            [self startDiscoveringBluetoothPeripherals];
        });
    }
}

#pragma mark Bluetooth

- (void)startDiscoveringBluetoothPeripherals {
    dispatch_async(dispatch_get_main_queue(), ^{
        _peripherals = nil;
        _scanningBluetoothPeripherals = YES;
        _coreBluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: [NSNumber numberWithBool:YES]}];
    });
}

- (void)stopDiscoveringBluetoothPeripherals {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_coreBluetoothManager stopScan];
        _coreBluetoothManager = nil;
        
        if ([[[CardActionsManager sharedInstance] reader] isKindOfClass:[CardReaderACR3901U_S1 class]]) {
            [[CardActionsManager sharedInstance] setReader:nil];
        }
    });
}

#pragma mark CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    //
    //  Connect ACR3901U-S1
    //
    if (peripheral.name != nil && [peripheral.name hasPrefix:@"ACR3901U-S1"]) {
        MLLog(@"Discovered ACR3901U-S1");
        _currentPeripheral = peripheral;
        [central connectPeripheral:_currentPeripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    //
    //  Setup ACR3901U-S1 interface
    //
    [central stopScan];
    
    CardReaderACR3901U_S1 *reader = [[CardReaderACR3901U_S1 alloc] init];
    [reader setCr3901U_S1Delegate:self];
    [[CardActionsManager sharedInstance] setReader:reader];
    
    [reader setupWithPeripheral:_currentPeripheral success:^(NSData *responseData) {
        MLLog(@"Successfully set up ACR3901U-S1 interface");
        
        [self cardReaderACR3901U_S1StatusDidChange: ReaderConnected];
    } failure:^(NSError *error) {
        MLLog(@"Failed to set up ACR3901U-S1 interface with error %@", error);
    }];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  switch (central.state) {
    case CBManagerStatePoweredOff:
      MLLog(@"Central manager state powered off");
      break;
    case CBManagerStateUnknown:
      MLLog(@"Central manager state unknown");
      break;
    case CBManagerStatePoweredOn:
      MLLog(@"Central manager state powered on");
      if (_scanningBluetoothPeripherals) {
        [_coreBluetoothManager scanForPeripheralsWithServices:nil options:nil];
      }
      break;
    case CBManagerStateResetting:
      MLLog(@"Central manager state resetting");
      break;
    case CBManagerStateUnsupported:
      MLLog(@"Central manager state unsupported");
      break;
    case CBManagerStateUnauthorized:
      MLLog(@"Central manager state unauthorized");
      break;
  }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    //
    //  Cleanup ACR3901U-S1 connection
    //
    [self startDiscoveringBluetoothPeripherals];
    
    if (peripheral.name != nil && [peripheral.name hasPrefix:@"ACR3901U-S1"]) {
        MLLog(@"Disconnected ACR3901U-S1");
        [self cardReaderACR3901U_S1StatusDidChange:ReaderNotConnected];
        [[CardActionsManager sharedInstance] setReader:nil];
        _status = ReaderNotConnected;
        _currentPeripheral = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    MLLog(@"didFailToConnectPeripheral: %@", error);
}

#pragma mark CardReaderACR3901U_S1Delegate

- (void)cardReaderACR3901U_S1StatusDidChange:(MoppLibCardReaderStatus)status {
    // Stop scanning other readers when Bluetooth reader is connected
    if (status == ReaderConnected) {
        [self stopDiscoveringFeitianReader];
    }
    // Start scanning other reader when Bluetooth reader is disconnected
    else if (status == ReaderNotConnected) {
        [self startDiscoveringFeitianReader];
    }
    // Propagate status
    [_delegate moppLibCardReaderStatusDidChange:status];
}

@end
