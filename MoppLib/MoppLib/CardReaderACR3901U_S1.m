//
//  CardReaderACR3901U_S1.m
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "CardReaderACR3901U_S1.h"
#import <ACSBluetooth/ACSBluetooth.h>
#import "NSString+Additions.h"


@interface CardReaderACR3901U_S1() <ABTBluetoothReaderManagerDelegate, ABTBluetoothReaderDelegate>
@property (nonatomic, strong) ABTBluetoothReader *bluetoothReader;
@property (nonatomic, strong) ABTBluetoothReaderManager *bluetoothReaderManager;

@property (nonatomic, strong) ObjectSuccessBlock successBlock;
@property (nonatomic, strong) FailureBlock failureBlock;

@end

@implementation CardReaderACR3901U_S1

- (ABTBluetoothReaderManager *)bluetoothReaderManager {
  if (!_bluetoothReaderManager) {
    _bluetoothReaderManager = [ABTBluetoothReaderManager new];
  }
  
  return _bluetoothReaderManager;
}

- (void)setSuccessBlock:(ObjectSuccessBlock)successBlock {
  if (self.successBlock != nil) {
    NSLog(@"ERROR: tried to start new reader action before previous one was finished");
  } else {
    _successBlock = successBlock;
  }
}

- (void)setFailureBlock:(FailureBlock)failureBlock {
  if (self.failureBlock != nil) {
    NSLog(@"ERROR: tried to start new reader action before previous one was finished");
  } else {
    _failureBlock = failureBlock;
  }
}

- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(ObjectSuccessBlock)success failure:(FailureBlock)failure {
  self.successBlock = success;
  self.failureBlock = failure;
  [self.bluetoothReaderManager detectReaderWithPeripheral:peripheral];
}

- (void)transmitCommand:(NSString *)commandHex success:(ObjectSuccessBlock)success failure:(FailureBlock)failure {

}

- (void)respondWithError:(NSError *)error {
  if (self.failureBlock) {
    self.failureBlock(error);
    self.failureBlock = nil;
  }

  self.successBlock = nil;
}

- (void)respondWithSuccess:(NSObject *)result {
  if (self.successBlock) {
    self.successBlock(result);
    self.failureBlock = nil;
  }

  self.successBlock = nil;
}

#pragma mark - Bluetooth reader manager
- (void)bluetoothReaderManager:(ABTBluetoothReaderManager *)bluetoothReaderManager didDetectReader:(ABTBluetoothReader *)reader peripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  if (error) {
    [self respondWithError:error];
  } else {
    self.bluetoothReader = reader;
    self.bluetoothReader.delegate = self;
    [self.bluetoothReader attachPeripheral:peripheral];
  }
}

#pragma mark - Bluetooth reader

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didAttachPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  if (error) {
    [self respondWithError:error];
  } else {
    NSString *masterKey = @"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF";
    [self.bluetoothReader authenticateWithMasterKey:[masterKey toHexData]];
  }
}

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnAtr:(NSData *)atr error:(NSError *)error {
  if (error) {
    [self respondWithError:error];
  } else {
    [self respondWithSuccess:atr];
  }
}


@end
