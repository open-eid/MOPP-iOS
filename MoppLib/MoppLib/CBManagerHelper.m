//
//  CBManagerHelper.m
//  MoppLib
//
//  Created by Katrin Annuk on 30/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "CBManagerHelper.h"

@interface CBManagerHelper()
@property (nonatomic, strong) CBCentralManager *cbCentralManager;
@property (nonatomic, strong) NSMutableArray *delegates;
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
  [self.cbCentralManager scanForPeripheralsWithServices:nil options:nil];
  self.foundPeripherals = [NSMutableArray new];
}

- (void)stopScan {
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
      NSLog(@"Central manager state powered off");
      break;
      
    case CBManagerStateUnknown:
      NSLog(@"Central manager state unknown");
      break;
      
    case CBManagerStatePoweredOn:
      NSLog(@"Central manager state powered on");
      break;
      
    case CBManagerStateResetting:
      NSLog(@"Central manager state resetting");
      break;
      
    case CBManagerStateUnsupported:
      NSLog(@"Central manager state unsupported");
      break;
      
    case CBManagerStateUnauthorized:
      NSLog(@"Central manager state unauthorized");
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
