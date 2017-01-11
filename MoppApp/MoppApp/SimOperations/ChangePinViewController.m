//
//  ChangePinViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 10/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ChangePinViewController.h"
#import <MoppLib/MoppLib.h>

@interface ChangePinViewController ()
@property (weak, nonatomic) IBOutlet UITextField *currentPinField;
@property (weak, nonatomic) IBOutlet UITextField *pinField;
@property (weak, nonatomic) IBOutlet UITextField *pinRepeatedField;
@property (weak, nonatomic) IBOutlet UILabel *CurrentPinLabel;
@property (weak, nonatomic) IBOutlet UILabel *pinLabel;
@property (weak, nonatomic) IBOutlet UILabel *pinRepeatedLabel;

@end

@implementation ChangePinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
  [self setupViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setType:(PinOperationType)type {
  _type = type;
  [self setupViewController];
}

- (void)setupViewController {
  NSString *pinString;
  if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
    pinString = Localizations.PinActionsPin1;
  } else {
    pinString = Localizations.PinActionsPin2;
  }

  switch (self.type) {
      
    case PinOperationTypeChangePin2:
    case PinOperationTypeChangePin1: {
      self.currentPinField.placeholder = Localizations.PinActionsCurrentPin(pinString);
      self.CurrentPinLabel.text = Localizations.PinActionsCurrentPin(pinString);
      break;
    }
      
    case PinOperationTypeUnblockPin1:
    case PinOperationTypeUnblockPin2: {
      self.currentPinField.placeholder = Localizations.PinActionsCurrentPin(Localizations.PinActionsPuk);
      self.CurrentPinLabel.text = Localizations.PinActionsCurrentPin(Localizations.PinActionsPuk);
      break;
    }
      
    default:
      break;
  }
  
  self.pinField.placeholder = Localizations.PinActionsNewPin(pinString);
  self.pinRepeatedField.placeholder = Localizations.PinActionsRepeatPin(pinString);
  self.pinLabel.text = Localizations.PinActionsNewPin(pinString);
  self.pinRepeatedLabel.text = Localizations.PinActionsRepeatPin(pinString);
}

- (IBAction)infoTapped:(id)sender {
  NSString *message;
  if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
    message = Localizations.PinActionsRulesPin1;

  } else {
    message = Localizations.PinActionsRulesPin2;
  }
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.PinActionsRulesTitle message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:^{
    
  }];
}

- (IBAction)okTapped:(id)sender {
  
  void (^successBlock)(void) = ^void (void) {
    [self displaySuccessMessage];
  };
  
  void (^errorBlock)(NSError *) = ^void (NSError *error) {
    [self displayErrorMessage:error];
  };

  switch (self.type) {
      
    case PinOperationTypeChangePin2: {
      [MoppLibPinActions changePin2To:self.pinField.text withOldPin2:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
      break;
    }
    case PinOperationTypeChangePin1: {
      [MoppLibPinActions changePin1To:self.pinField.text withOldPin1:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
      break;
    }
      
    case PinOperationTypeUnblockPin1: {
      [MoppLibPinActions unblockPin1WithPuk:self.currentPinField.text newPin1:self.pinField.text viewController:self success:successBlock failure:errorBlock];
      break;
    }
    case PinOperationTypeUnblockPin2: {
      [MoppLibPinActions unblockPin2WithPuk:self.currentPinField.text newPin2:self.pinField.text viewController:self success:successBlock failure:errorBlock];
      break;
    }
      
    default:
      break;
  }
}

- (void)displaySuccessMessage {
  
  NSString *pinString;
  if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
    pinString = Localizations.PinActionsPin1;
    
  } else {
    pinString = Localizations.PinActionsPin2;
  }
  
  NSString *message;
  if (self.type == PinOperationTypeUnblockPin2 || self.type == PinOperationTypeUnblockPin1) {
    message = Localizations.PinActionsSuccessPinUnblocked(pinString);
  } else {
    message = Localizations.PinActionsSuccessPinChanged(pinString);
  }
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.PinActionsSuccessTitle message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.navigationController popViewControllerAnimated:YES];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)displayErrorMessage:(NSError *)error {
  NSString *pinString;
  NSString *verifyCode;
  
  if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
    pinString = Localizations.PinActionsPin1;
    
  } else {
    pinString = Localizations.PinActionsPin2;
  }
  
  if (self.type == PinOperationTypeUnblockPin2 || self.type == PinOperationTypeUnblockPin1) {
    verifyCode = Localizations.PinActionsPuk;
    
  } else {
    verifyCode = pinString;
  }
  
  NSString *message;
  BOOL dismissOnConfirm = NO;
  
  if (error.code == moppLibErrorWrongPin) {
    int retryCount = [[error.userInfo objectForKey:kMoppLibUserInfoRetryCount] intValue];
    
    if (retryCount == 0) {
      dismissOnConfirm = YES;
      message = Localizations.PinActionsWrongPinBlocked(verifyCode, pinString);

    } else {
      message = Localizations.PinActionsWrongPinRetry(verifyCode, retryCount);
    }
    
  } else if (error.code == moppLibErrorInvalidPin) {
    message = Localizations.PinActionsInvalidFormat(pinString);
    
  } else if (error.code == moppLibErrorPinMatchesVerificationCode) {
    message = Localizations.PinActionsSameAsCurrent(pinString, verifyCode);
    
  } else if (error.code == moppLibErrorIncorrectPinLength) {
    message = Localizations.PinActionsIncorrectLength(pinString);
    
  } else {
    message = Localizations.PinActionsGeneralError(pinString);
  }
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.PinActionsErrorTitle message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    if (dismissOnConfirm) {
      [self.navigationController popViewControllerAnimated:YES];
    }
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)backgroundTapped:(id)sender {
  [self.pinField resignFirstResponder];
  [self.currentPinField resignFirstResponder];
  [self.pinRepeatedField resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
