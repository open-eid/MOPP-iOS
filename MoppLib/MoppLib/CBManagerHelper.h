//
//  CBManagerHelper.h
//  MoppLib
//
//  Created by Katrin Annuk on 30/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol CBManagerHelperDelegate;

@interface CBManagerHelper : NSObject
@property (nonatomic, strong) NSMutableArray *foundPeripherals;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;

+ (CBManagerHelper *)sharedInstance;

- (void)startScan;
- (void)stopScan;
- (void)connectPeripheral:(CBPeripheral *)peripheral;

- (void)addDelegate:(id<CBManagerHelperDelegate>)delegate;
- (void)removeDelegate:(id<CBManagerHelperDelegate>)delegate;

@end

@protocol CBManagerHelperDelegate <NSObject>

@optional
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI;
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
@end
