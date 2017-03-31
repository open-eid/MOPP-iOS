//
//  CBManagerHelper.m
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

#import "CBManagerHelper.h"

@interface CBManagerHelper()
@property (nonatomic, strong) CBCentralManager *cbCentralManager;
@property (nonatomic, strong) NSMutableArray *delegates;
@property (nonatomic, assign) BOOL scanInProgress;
@end

@implementation CBManagerHelper
static CBManagerHelper *sharedInstance = nil;

+ (CBManagerHelper *)sharedInstance {
  if (sharedInstance == nil) {
    sharedInstance = [CBManagerHelper new];
    [sharedInstance cbCentralManager];
  }
  return sharedInstance;
}

- (CBCentralManager *)cbCentralManager {
  if (!_cbCentralManager) {
    _cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: [NSNumber numberWithBool:YES]}];
  }
  
  return _cbCentralManager;
}

- (NSMutableArray *)delegates {
  if (!_delegates) {
    _delegates = [[NSMutableArray alloc] init];
  }
  return _delegates;
}

- (void)startScan {
  // TODO can we scan for card readers only?
  self.scanInProgress = YES;
  self.foundPeripherals = [NSMutableArray new];
  [self.cbCentralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScan {
  self.scanInProgress = NO;
  [self.cbCentralManager stopScan];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
  // Make sure previous connection is cancelled
  if (self.connectedPeripheral) {
    [self.cbCentralManager cancelPeripheralConnection:self.connectedPeripheral];
  }
  [self.cbCentralManager connectPeripheral:peripheral options:nil];
}

- (void)addDelegate:(id<CBManagerHelperDelegate>)delegate {
  if ([self.delegates indexOfObject:delegate] == NSNotFound) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<CBManagerHelperDelegate>)delegate {
  [self.delegates removeObject:delegate];
}

#pragma mark - CBCentralManager

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
      if (self.scanInProgress) {
        [self startScan];
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
  
  for (id<CBManagerHelperDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:@selector(centralManagerDidUpdateState:)]) {
      [delegate centralManagerDidUpdateState:central];
      
    }
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  for (id<CBManagerHelperDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
      [delegate centralManager:central didConnectPeripheral:peripheral];
      
    }
  }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  for (id<CBManagerHelperDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
      [delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
      
    }
  }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
  
  if ([self.foundPeripherals indexOfObject:peripheral] == NSNotFound) {
    [self.foundPeripherals addObject:peripheral];
    
    for (id<CBManagerHelperDelegate> delegate in self.delegates) {
      if ([delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];

      }
    }
  }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  for (id<CBManagerHelperDelegate> delegate in self.delegates) {
    if ([delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
      [delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
      
    }
  }
}
@end
