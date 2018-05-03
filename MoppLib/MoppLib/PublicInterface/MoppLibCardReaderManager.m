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

@interface MoppLibCardReaderManager() <ReaderInterfaceDelegate, CBCentralManagerDelegate>
@property (nonatomic) SCARDCONTEXT contextHandle;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic, strong) NSTimer *cardStatusPollingTimer;
@property (nonatomic) MoppLibCardReaderStatus status;
@property (nonatomic, strong) CardReaderiR301 *reader;
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

- (void)startDetecting {
    [self updateStatus:ReaderNotConnected];
    SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &_contextHandle);
}

- (void)stopDetecting {
    if (_status == CardConnected) {
        [self disconnectCard];
    }
    
    if (_cardStatusPollingTimer != nil) {
        [_cardStatusPollingTimer invalidate];
        _cardStatusPollingTimer = nil;
    }
    
    [[CardActionsManager sharedInstance] setCardReader:nil];
    FtDidEnterBackground(1);
    SCardReleaseContext(_contextHandle);
}

- (void)handleCardStatus {
    DWORD dwState;
    LONG ret = 0;
    
    ret = SCardStatus(_contextHandle, NULL, NULL, &dwState, NULL, NULL, NULL );
    if (ret != SCARD_S_SUCCESS) {
        // No luck on getting card status. Reconnect the reader.
        [self updateStatus:ReaderNotConnected];
        return;
    }
    
    switch (dwState) {
    case SCARD_PRESENT:
        [self updateStatus:CardConnected];
        break;
    case SCARD_ABSENT:
        [self updateStatus:ReaderConnected];
        break;
    case SCARD_SWALLOWED:
        [self connectCard];
        break;
    }
}

- (BOOL)connectCard {
    LONG iRet = 0;
    DWORD dwActiveProtocol = -1;
    char mszReaders[128] = "";
    DWORD dwReaders = -1;
  
    iRet = SCardListReaders(_contextHandle, NULL, mszReaders, &dwReaders);
    if(iRet != SCARD_S_SUCCESS) {
        NSLog(@"SCardListReaders error %08x",iRet);
        return NO;
    }

    iRet = SCardConnect(_contextHandle,mszReaders,SCARD_SHARE_SHARED,SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,&_contextHandle,&dwActiveProtocol);
    if (iRet != SCARD_S_SUCCESS) {
        return NO;
    }
    
    _reader = [[CardReaderiR301 alloc] initWithInterface:_readerInterface andContentHandle:_contextHandle];
    [[CardActionsManager sharedInstance] setCardReader:_reader];
    
    return YES;
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
    if (_status == status) return;
    
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
            [_delegate moppLibCardReaderStatusDidChange: ReaderConnected];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:ReaderNotConnected];
            [self stopPollingCardStatus];
            [_delegate moppLibCardReaderStatusDidChange: ReaderNotConnected];
        });
    }
}

#pragma mark Bluetooth

- (void)startScanningBluetoothPeripherals {
    _peripherals = nil;
    _scanningBluetoothPeripherals = YES;
    _coreBluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: [NSNumber numberWithBool:YES]}];
}

- (void)stopScanningBluetoothPeripherals {
    [_coreBluetoothManager stopScan];
    _coreBluetoothManager = nil;
}

#pragma mark CBCentralManagerDelegate

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
      if (self.scanningBluetoothPeripherals) {
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
      
    default:
      break;
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Did connect %@", peripheral.name);
    CardReaderACR3901U_S1 *reader = [[CardReaderACR3901U_S1 alloc] init];
    [reader setupWithPeripheral:_currentPeripheral success:^(NSData *responseData) {
        NSLog(@"SUCCESS");
        
        [reader setCardReaderManagerDelegate:_delegate];
        [_delegate moppLibCardReaderStatusDidChange: ReaderConnected];
        [[CardActionsManager sharedInstance] setCardReader:reader];
        
    } failure:^(NSError *error) {
        NSLog(@"FAILURE %@", error);
    }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"%@", peripheral.name);
    if (peripheral.name != nil && [peripheral.name hasPrefix:@"ACR3901U-S1"]) {
        NSLog(@"Card ACR3901U-S1 found");
        _currentPeripheral = peripheral;
        [central connectPeripheral:_currentPeripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [_delegate moppLibCardReaderStatusDidChange:ReaderNotConnected];
    NSLog(@"%@", peripheral.name);
    if (peripheral.name != nil && [peripheral.name hasPrefix:@"ACR3901U-S1"]) {
        NSLog(@"Card ACR3901U-S1 found");
    }
}

@end
