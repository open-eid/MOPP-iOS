//
//  CBManagerHelper.h
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
