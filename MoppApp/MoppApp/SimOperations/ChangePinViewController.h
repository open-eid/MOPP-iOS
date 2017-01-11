//
//  ChangePinViewController.h
//  MoppApp
//
//  Created by Katrin Annuk on 10/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
  PinOperationTypeChangePin1,
  PinOperationTypeChangePin2,
  PinOperationTypeUnblockPin1,
  PinOperationTypeUnblockPin2
} PinOperationType;

@interface ChangePinViewController : UIViewController

@property (nonatomic, assign) PinOperationType type;
@end
