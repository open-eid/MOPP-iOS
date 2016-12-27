//
//  CardActionsManager.m
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "CardActionsManager.h"
#import "CardReaderACR3901U_S1.h"

@interface CardActionsManager()

@property (nonatomic, strong) id<CardReaderWrapper> cardReader;

@end

@implementation CardActionsManager

static CardActionsManager *sharedInstance = nil;

+ (CardActionsManager *)sharedInstance {
  if (sharedInstance == nil) {
    sharedInstance = [CardActionsManager new];
  }
  return sharedInstance;
}

- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure {
  CardReaderACR3901U_S1 *reader = [CardReaderACR3901U_S1 new];
  [reader setupWithPeripheral:peripheral success:^(NSData *responseObject) {
    self.cardReader = reader;
    success(responseObject);
    
  } failure:^(NSError *error) {
    NSLog(@"Failed to set up peripheral: %@", [error localizedDescription]);
    failure(error);
  }];
}


@end
