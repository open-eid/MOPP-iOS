//
//  ChangePinViewController.m
//  MoppApp
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

#import "ChangePinViewController.h"
#import <MoppLib/MoppLib.h>
#import "ButtonWithRoundedCorners.h"
#import "UIColor+Additions.h"

@interface ChangePinViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *currentPinField;
@property (weak, nonatomic) IBOutlet UITextField *pinField;
@property (weak, nonatomic) IBOutlet UITextField *pinRepeatedField;
@property (weak, nonatomic) IBOutlet UILabel *CurrentPinLabel;
@property (weak, nonatomic) IBOutlet UILabel *pinLabel;
@property (weak, nonatomic) IBOutlet UILabel *pinRepeatedLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *verificationTitleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (weak, nonatomic) IBOutlet UILabel *currentPinErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel *pinErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatedPinErrorLabel;
@property (weak, nonatomic) IBOutlet ButtonWithRoundedCorners *okButton;
@end

@implementation ChangePinViewController

NSInteger repeatedPinDoesntMatch = 20000;

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self clearErrors];
  
  self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  
  [self setupViewController];
  [self.okButton setTitle:Localizations.ActionEdit forState:UIControlStateNormal];
  [self updateOkButton];
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
  NSString *pinString = [self pinCodeString];
  
  NSString *currentPinPlaceholder;
  NSString *currentPinText;
  NSString *verificationTitle;

  switch (self.type) {
      
    case PinOperationTypeChangePin2:
    case PinOperationTypeChangePin1:
    case PinOperationTypeChangePuk: {
      self.title = Localizations.PinActionsChangingPin(pinString);

      NSString *verificationCode = [self verificationCodeString];
      currentPinPlaceholder = Localizations.PinActionsCurrentPin(verificationCode);
      currentPinText = Localizations.PinActionsCurrentPin(verificationCode);
      verificationTitle = Localizations.PinActionsVerificationTitle(pinString);

      break;
    }
      
    case PinOperationTypeUnblockPin1:
    case PinOperationTypeUnblockPin2: {
      self.title = Localizations.PinActionsTitleUnblockingPin(pinString);

      self.tableView.userInteractionEnabled = NO;
      self.selectedIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];

      [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];

      currentPinPlaceholder = Localizations.PinActionsCurrentPin(Localizations.PinActionsPuk);
      currentPinText = Localizations.PinActionsCurrentPin(Localizations.PinActionsPuk);
      verificationTitle = Localizations.PinActionsUnblockingPin(pinString);
      break;
    }
      
    default:
      break;
  }
  
  self.currentPinField.placeholder = currentPinPlaceholder;
  self.CurrentPinLabel.text = currentPinText;
  self.pinField.placeholder = Localizations.PinActionsNewPin(pinString);
  self.pinRepeatedField.placeholder = Localizations.PinActionsRepeatPin(pinString);
  self.pinLabel.text = Localizations.PinActionsNewPin(pinString);
  self.pinRepeatedLabel.text = Localizations.PinActionsRepeatPin(pinString);
  self.verificationTitleLabel.text = verificationTitle;
}

- (void)clearErrors {
  self.currentPinErrorLabel.text = nil;
  self.pinErrorLabel.text = nil;
  self.repeatedPinErrorLabel.text = nil;
}

- (void)updateOkButton {
  if (self.pinField.text.length > 0 && self.currentPinField.text.length > 0 && self.pinRepeatedField.text.length > 0) {
    self.okButton.enabled = YES;
    self.okButton.alpha = 1;
    self.okButton.backgroundColor = [UIColor darkBlue];
  } else {
    self.okButton.enabled = NO;
    self.okButton.alpha = 0.5;
    self.okButton.backgroundColor = [UIColor grayColor];

  }
}

- (IBAction)infoTapped:(id)sender {
  NSString *message;
  NSString *pinString = [self pinCodeString];

  NSString *rule1 = Localizations.PinActionsRuleDifferentFromPrevious(pinString);
  NSString *rule2 = Localizations.PinActionsRuleNumbersOnly(pinString);
  
  int min;
  int max;
  NSArray *forbiddenPins;
  
  if (self.type == PinOperationTypeChangePuk) {
    min = [MoppLibPinActions pukMinLength];
    max = [MoppLibPinActions pukMaxLength];
    forbiddenPins = [MoppLibPinActions forbiddenPuks];
    
  } else if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
    min = [MoppLibPinActions pin1MinLength];
    max = [MoppLibPinActions pin1MaxLength];
    forbiddenPins = [MoppLibPinActions forbiddenPin1s];

  } else {
    min = [MoppLibPinActions pin2MinLength];
    max = [MoppLibPinActions pin2MaxLength];
    forbiddenPins = [MoppLibPinActions forbiddenPin2s];
  }
  
  NSString *rule3 = Localizations.PinActionsRulePinLength(pinString, min, max);
  NSString *rule4 = Localizations.PinActionsRuleForbiddenPins(pinString, [forbiddenPins componentsJoinedByString:@", "]);


  message = [NSString stringWithFormat:@"* %@\n\n* %@\n\n* %@\n\n* %@", rule1, rule2, rule3, rule4];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.PinActionsRulesTitle message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:^{
    
  }];
}

- (IBAction)okTapped:(id)sender {
  
  [self clearErrors];
  
  if (![self.pinField.text isEqualToString:self.pinRepeatedField.text]) {
    NSError *newError = [[NSError alloc] initWithDomain:@"Mopp app" code:repeatedPinDoesntMatch userInfo:nil];
    [self displayErrorMessage:newError];
    return;
  }

  void (^successBlock)(void) = ^void (void) {
    [self displaySuccessMessage];
  };
  
  void (^errorBlock)(NSError *) = ^void (NSError *error) {
    [self displayErrorMessage:error];
  };

  switch (self.type) {
      
    case PinOperationTypeChangePin2: {
      if (self.selectedIndexPath.row == 0) {
        [MoppLibPinActions changePin2To:self.pinField.text withOldPin2:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
      } else {
        [MoppLibPinActions changePin2To:self.pinField.text withPuk:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
      }
      break;
    }
    case PinOperationTypeChangePin1: {
      if (self.selectedIndexPath.row == 0) {
        [MoppLibPinActions changePin1To:self.pinField.text withOldPin1:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
      } else {
        [MoppLibPinActions changePin1To:self.pinField.text withPuk:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
      }
      break;
    }
      
    case PinOperationTypeChangePuk: {
        [MoppLibPinActions changePukTo:self.pinField.text withOldPuk:self.currentPinField.text viewController:self success:successBlock failure:errorBlock];
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
  
  NSString *pinString = [self pinCodeString];
  
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
  NSString *pinString = [self pinCodeString];
  NSString *verifyCode = [self verificationCodeString];
  NSString *message;
  
  BOOL dismissViewcontroller = NO;
  
  if(error.code == repeatedPinDoesntMatch) {
    message = Localizations.PinActionsRepeatedPinDoesntMatch(pinString, pinString);
    self.repeatedPinErrorLabel.text = message;

  } else if (error.code == moppLibErrorWrongPin) {
    int retryCount = [[error.userInfo objectForKey:kMoppLibUserInfoRetryCount] intValue];
    
    if (retryCount == 0) {
      if (self.type == PinOperationTypeChangePin1) {
        self.type = PinOperationTypeUnblockPin1;
      } else if (self.type == PinOperationTypeChangePin2) {
        self.type = PinOperationTypeUnblockPin2;
      }
      
      message = Localizations.PinActionsWrongPinBlocked(verifyCode, verifyCode);
      dismissViewcontroller = YES;
      
    } else {
      message = Localizations.PinActionsWrongPinRetry(verifyCode, retryCount);
      self.currentPinErrorLabel.text = message;
    }
    
  } else if (error.code == moppLibErrorInvalidPin) {
    message = Localizations.PinActionsInvalidFormat(pinString);
    self.pinErrorLabel.text = message;
    
  } else if (error.code == moppLibErrorPinMatchesVerificationCode) {
    message = Localizations.PinActionsSameAsCurrent(pinString, verifyCode);
    self.pinErrorLabel.text = message;
    
  } else if (error.code == moppLibErrorPinMatchesOldCode) {
    message = Localizations.PinActionsSameAsCurrent(pinString, pinString);
    self.pinErrorLabel.text = message;
    
  } else if (error.code == moppLibErrorIncorrectPinLength) {
    
    int min;
    int max;
    if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
      min = [MoppLibPinActions pin1MinLength];
      max = [MoppLibPinActions pin1MaxLength];
      
    } else if (self.type == PinOperationTypeChangePuk) {
      min = [MoppLibPinActions pukMinLength];
      max = [MoppLibPinActions pukMaxLength];
      
    } else {
      min = [MoppLibPinActions pin2MinLength];
      max = [MoppLibPinActions pin2MaxLength];
    }
    
    message = Localizations.PinActionsRulePinLength(pinString, min, max);
    self.pinErrorLabel.text = message;
    
  } else if (error.code == moppLibErrorPinTooEasy) {
    NSArray *forbiddenPins;
    if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
      forbiddenPins = [MoppLibPinActions forbiddenPin1s];
      
    } else if (self.type == PinOperationTypeChangePuk) {
      forbiddenPins = [MoppLibPinActions forbiddenPuks];
      
    } else {
      forbiddenPins = [MoppLibPinActions forbiddenPin2s];
    }
    message = Localizations.PinActionsRuleForbiddenPins(pinString, [forbiddenPins componentsJoinedByString:@", "]);
    self.pinErrorLabel.text = message;
    
  } else if (error.code == moppLibErrorPinContainsInvalidCharacters) {
    message = Localizations.PinActionsRuleNumbersOnly(pinString);
    self.pinErrorLabel.text = message;

  } else if (error.code == moppLibErrorCardNotFound) {
    message = Localizations.ContainerDetailsCardNotFound;
    self.pinErrorLabel.text = message;
    
  } else {
    message = Localizations.PinActionsGeneralError(pinString);
    self.pinErrorLabel.text = message;
  }
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.PinActionsErrorTitle message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    if (dismissViewcontroller) {
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

/**
 * String for pin code that we are changing
 */
- (NSString *)pinCodeString {
  if (self.type == PinOperationTypeChangePin1 || self.type == PinOperationTypeUnblockPin1) {
    return Localizations.PinActionsPin1;
    
  } else if (self.type == PinOperationTypeChangePin2 || self.type == PinOperationTypeUnblockPin2) {
    return Localizations.PinActionsPin2;
    
  } else {
    return Localizations.PinActionsPuk;
  }
}

/**
 * String for pin/puk code that we are using for verification
 */
- (NSString *)verificationCodeString {
  if (self.type == PinOperationTypeChangePuk || self.type == PinOperationTypeUnblockPin2 || self.type == PinOperationTypeUnblockPin1 || self.selectedIndexPath.row == 1) {
    return Localizations.PinActionsPuk;
    
  } else {
    return [self pinCodeString];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (self.type == PinOperationTypeChangePuk) {
    return 1;
  }
  return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  BOOL isActiveCell = indexPath.row == 1 || self.tableView.userInteractionEnabled || self.type == PinOperationTypeChangePuk;
  NSString *identifyer = isActiveCell ? @"VerifyOptionCell" : @"VerifyOptionDisabledCell";
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifyer forIndexPath:indexPath];

  
  if (indexPath.row == 0) {
    NSString *pinString = [self pinCodeString];
    cell.textLabel.text = Localizations.PinActionsVerificationOption(pinString);
    
  } else {
    cell.textLabel.text = Localizations.PinActionsVerificationOption(Localizations.PinActionsPuk);
  }
  
  [self updateCell:cell selected:self.selectedIndexPath.row == indexPath.row];
  
  return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSArray *cells = [tableView visibleCells];
  for (UITableViewCell *cell in cells) {
    NSIndexPath *cellIndex = [tableView indexPathForCell:cell];
    [self updateCell:cell selected:cellIndex.row == indexPath.row];
  }
  
  return indexPath;
}

- (void)updateCell:(UITableViewCell *)cell selected:(BOOL)isSelected {
  if (isSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = [UIColor blueColor];
    
  } else if(!self.tableView.userInteractionEnabled) {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textColor = [UIColor lightGrayColor];

  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.textColor = [UIColor blackColor];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.selectedIndexPath = indexPath;
  
  [self setupViewController];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 30;
}

- (void)keyboardWillShow:(NSNotification*)aNotification {
  
  NSDictionary* info = [aNotification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, kbSize.height, 0);
  self.scrollView.contentInset = contentInsets;
  self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  self.scrollView.contentInset = contentInsets;
  self.scrollView.scrollIndicatorInsets = contentInsets;
}
- (IBAction)textFieldEditingChanged:(id)sender {
  [self updateOkButton];
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
