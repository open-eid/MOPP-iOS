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
#import "MoppLibError.h"
#import "NSData+Additions.h"

@interface CardReaderACR3901U_S1() <ABTBluetoothReaderManagerDelegate, ABTBluetoothReaderDelegate>
@property (nonatomic, strong) ABTBluetoothReader *bluetoothReader;
@property (nonatomic, strong) ABTBluetoothReaderManager *bluetoothReaderManager;

@property (nonatomic, strong) DataSuccessBlock successBlock;
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, assign) ABTBluetoothReaderCardStatus cardStatus;
@property (nonatomic, strong) NSData *atr;
@property (nonatomic, strong) CBPeripheral *peripheral;
@end

@implementation CardReaderACR3901U_S1

- (ABTBluetoothReaderManager *)bluetoothReaderManager {
  if (!_bluetoothReaderManager) {
    _bluetoothReaderManager = [ABTBluetoothReaderManager new];
    _bluetoothReaderManager.delegate = self;
  }
  
  return _bluetoothReaderManager;
}

- (void)setCardStatus:(ABTBluetoothReaderCardStatus)cardStatus {
  ABTBluetoothReaderCardStatus lastStatus = _cardStatus;
  if (_cardStatus != cardStatus){
    _cardStatus = cardStatus;
    BOOL changedToPresent = lastStatus == ABTBluetoothReaderCardStatusAbsent || lastStatus == ABTBluetoothReaderCardStatusUnknown;
    BOOL changedToAbsent = cardStatus == ABTBluetoothReaderCardStatusAbsent || cardStatus == ABTBluetoothReaderCardStatusUnknown;
    if (changedToPresent) {
      if (self.delegate) {
        [self.delegate cardStatusUpdated:CardStatusPresent];
      }
    } else if (changedToAbsent) {
      if (self.delegate) {
        [self.delegate cardStatusUpdated:CardStatusAbsent];
      }
    }
    
    if (cardStatus == ABTBluetoothReaderCardStatusPowerSavingMode || changedToAbsent) {
      self.atr = nil;
    }
  }
}

- (void)setSuccessBlock:(DataSuccessBlock)successBlock {
  @synchronized (self) {
    if (self.successBlock != nil && successBlock != nil) {
      MLLog(@"ERROR: tried to start new reader action before previous one was finished");
    } else {
      _successBlock = successBlock;
    }
  }
}

- (void)setFailureBlock:(FailureBlock)failureBlock {
  @synchronized (self) {
    
    if (self.failureBlock != nil && failureBlock != nil) {
      MLLog(@"ERROR: tried to start new reader action before previous one was finished");
    } else {
      _failureBlock = failureBlock;
    }
  }
}

- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  self.successBlock = success;
  self.failureBlock = failure;
  self.peripheral = peripheral;
  [self.bluetoothReaderManager detectReaderWithPeripheral:peripheral];
}

- (void)transmitCommand:(NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  MLLog(@"Transmit command %@", commandHex);
  //void (^transmit)(void) = ^(void) {
    self.successBlock = success;
    self.failureBlock = failure;
    BOOL isReaderAttached = [self.bluetoothReader transmitApdu:[commandHex toHexData]];
    if (!isReaderAttached) {
      [self respondWithError:[MoppLibError readerNotFoundError]];
    }
}

/*- (void)updateCardStatusWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  self.successBlock = success;
  self.failureBlock = failure;
  BOOL updated = [self.bluetoothReader getCardStatus];
  if (!updated) {
    [self respondWithError:[MoppLibError cardNotFoundError]];
  }
}*/

- (void)respondWithError:(NSError *)error {
  @synchronized (self) {
    FailureBlock failure = self.failureBlock;
    self.failureBlock = nil;
    self.successBlock = nil;

    if (failure) {
      failure(error);
    }
  }
}

- (void)respondWithSuccess:(NSObject *)result {
  @synchronized (self) {
    DataSuccessBlock success = self.successBlock;
    self.failureBlock = nil;
    self.successBlock = nil;

    if (success) {
      success(result);
    }
  }
}

- (void)isCardInserted:(void(^)(BOOL)) completion {
  NSLog(@"******* card status %i", self.cardStatus);

  //if (self.cardStatus == ABTBluetoothReaderCardStatusPowerSavingMode) {
    [self getCardStatusWithSuccess:^(NSData *responseObject) {
      completion(self.cardStatus == ABTBluetoothReaderCardStatusPresent || self.cardStatus == ABTBluetoothReaderCardStatusPowered);
      
    } failure:^(NSError *error) {
      completion(NO);
    }];
 // } else {
 //   completion(self.cardStatus == ABTBluetoothReaderCardStatusPresent || self.cardStatus == ABTBluetoothReaderCardStatusPowered);
 // }
}

- (BOOL)isConnected {
  NSLog(@"****** peripheral state is %i", self.peripheral.state);
  if (self.peripheral && self.peripheral.state == CBPeripheralStateConnected) {
    return YES;
  }
  
  return NO;
}

- (void)isCardPoweredOn:(void(^)(BOOL)) completion {
  
  if (self.cardStatus == ABTBluetoothReaderCardStatusPowerSavingMode) {
    [self getCardStatusWithSuccess:^(NSData *responseObject) {
      completion(self.atr.length > 0 || self.cardStatus == ABTBluetoothReaderCardStatusPowered);
      
    } failure:^(NSError *error) {
      completion(NO);
    }];
  } else {
    completion(self.atr.length > 0 || self.cardStatus == ABTBluetoothReaderCardStatusPowered);
  }
}

- (void)powerOnCard:(DataSuccessBlock)success failure:(FailureBlock)failure  {
  MLLog(@"Power on card");
  self.successBlock = success;
  self.failureBlock = failure;
  BOOL isReaderAttached = [self.bluetoothReader powerOnCard];
  if (!isReaderAttached) {
    [self respondWithError:[MoppLibError readerNotFoundError]];
  }
}

- (void)powerOffCard:(DataSuccessBlock)success failure:(FailureBlock)failure  {
  
  self.successBlock = success;
  self.failureBlock = failure;
  BOOL isReaderAttached = [self.bluetoothReader powerOffCard];
  if (!isReaderAttached) {
    [self respondWithError:[MoppLibError readerNotFoundError]];
  }
}

- (void)getCardStatusWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  self.successBlock = success;
  self.failureBlock = failure;
  BOOL isReaderAttached = [self.bluetoothReader getCardStatus];
  if (!isReaderAttached) {
    [self respondWithError:[MoppLibError readerNotFoundError]];
  }
}

#pragma mark - Bluetooth reader manager
- (void)bluetoothReaderManager:(ABTBluetoothReaderManager *)bluetoothReaderManager didDetectReader:(ABTBluetoothReader *)reader peripheral:(CBPeripheral *)peripheral error:(NSError *)error {

  if (error) {
    [self respondWithError:error];
  } else {
    MLLog(@"Did detect reader");

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
    MLLog(@"Did attach reader");

    NSString *masterKey = @"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF";
    [self.bluetoothReader authenticateWithMasterKey:[masterKey toHexData]];
  }
}

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didAuthenticateWithError:(NSError *)error {
  if (error) {
    [self respondWithError:error];
  } else {
    MLLog(@"Did authenticate reader");

    [self respondWithSuccess:nil];
  }
}

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnAtr:(NSData *)atr error:(NSError *)error {
  MLLog(@"Did power on card");

  self.atr = atr;
  if (error) {
    [self respondWithError:error];
  } else {
    [self respondWithSuccess:atr];
  }
}

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnResponseApdu:(NSData *)apdu error:(NSError *)error {
  if (error) {
    MLLog(@"Apdu error %i %@", error.code, error.localizedDescription);

    [self respondWithError:error];
  } else {
    
    MLLog(@"Respnded with apdu %@", [apdu toHexString]);
    [self respondWithSuccess:apdu];
  }
}

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeCardStatus:(ABTBluetoothReaderCardStatus)cardStatus error:(NSError *)error {
  MLLog(@"Card status changed to %i", cardStatus);
  self.cardStatus = cardStatus;
}

- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnCardStatus:(ABTBluetoothReaderCardStatus)cardStatus error:(NSError *)error {
  MLLog(@"Card status changed to %i", cardStatus);
  self.cardStatus = cardStatus;
  
  if (error) {
    [self respondWithError:error];
  } else {
    [self respondWithSuccess:nil];
  }
}


- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didPowerOffCardWithError:(NSError *)error {
  if (error) {
    [self respondWithError:error];
  } else {
    [self respondWithSuccess:nil];
  }
}

- (void)resetReader {
  self.failureBlock = nil;
  self.successBlock = nil;
}

@end
