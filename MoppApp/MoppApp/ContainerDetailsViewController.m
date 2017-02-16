//
//  ContainerDetailsViewController.m
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ContainerDetailsViewController.h"
#import "ContainerDetailsHeaderCell.h"
#import "ContainerDetailsDataFileCell.h"
#import "ContainerDetailsSignatureCell.h"
#import "DateFormatter.h"
#import "SimpleHeaderView.h"
#import "UIColor+Additions.h"
#import "UIViewController+MBProgressHUD.h"
#import "DefaultsHelper.h"
#import "Constants.h"
#import <MoppLib/MoppLibConstants.h>
#import "FileManager.h"

typedef enum : NSUInteger {
  ContainerDetailsSectionHeader,
  ContainerDetailsSectionDataFile,
  ContainerDetailsSectionSignature
} ContainerDetailsSection;

@interface ContainerDetailsViewController ()<UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UIDocumentInteractionController *previewController;
@property (nonatomic, strong) NSString *tempFilePath;
@end

@implementation ContainerDetailsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.ContainerDetailsTitle];
  
  [self.view setBackgroundColor:[UIColor whiteColor]];
  
  UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(shareButtonPressed)];
  [self.navigationItem setRightBarButtonItems:@[shareButton, self.editButtonItem]];
  
  [self setEditing:NO]; // Update edit button title.
  
  [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  [self.tableView reloadData];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveAdesSignatureAddedToContainer:) name:kSignatureAddedToContainerNotificationName object:nil];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self.tableView reloadData];
}

- (IBAction)addSignatureTapped:(id)sender {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ContainerDetailsSigningMethodAlertTitle message:Localizations.ContainerDetailsSigningMethodAlertMessage preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ContainerDetailsSigningMethodMobileId style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self showIDCodeAndPhoneAlert];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ContainerDetailsSigningMethodIdCard style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self displayCardSignatureAlert];
  }]];
  
  [self presentViewController:alert animated:YES completion:nil];
  
}

- (IBAction)editContainerName:(id)sender {
  
  NSString *extenstion = self.container.fileName.pathExtension;
  NSString *currentName = [self.container.fileName substringToIndex:self.container.fileName.length - extenstion.length - 1];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ContainerDetailsRename message:Localizations.ContainerDetailsEnterNewName preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    textField.text = currentName;
    textField.placeholder = Localizations.ContainerDetailsName;
    textField.keyboardType = UIKeyboardTypeDefault;
  }];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UITextField *nameTextField = [alert.textFields firstObject];
    NSString *newName = [nameTextField.text stringByAppendingString:[NSString stringWithFormat:@".%@", extenstion]];
    NSString *newPath = [[FileManager sharedInstance] filePathWithFileName:newName];
    [[FileManager sharedInstance] moveFileWithPath:self.container.filePath toPath:newPath];
    [[MoppLibContainerActions sharedInstance] getContainerWithPath:newPath success:^(MoppLibContainer *container) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContainerChanged object:nil userInfo:@{kKeyContainer:container}];
      self.container = container;
      [self.tableView reloadData];
    } failure:^(NSError *error) {
      
    }];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionCancel style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showIDCodeAndPhoneAlert {
  __weak typeof(self) weakSelf = self;
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ContainerDetailsIdcodePhoneAlertTitle message:Localizations.ContainerDetailsIdcodePhoneAlertMessage preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    textField.text = [DefaultsHelper getIDCode];
    textField.placeholder = Localizations.ContainerDetailsIdcodePhoneAlertIdcodePlacholder;
    textField.keyboardType = UIKeyboardTypeNumberPad;
  }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    textField.text = [DefaultsHelper getPhoneNumber];
    textField.placeholder = Localizations.ContainerDetailsIdcodePhoneAlertPhonenumberPlacholder;
    textField.keyboardType = UIKeyboardTypePhonePad;
  }];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UITextField *idCodeTextField = [alert.textFields firstObject];
    UITextField *phoneNumberTextField = [alert.textFields objectAtIndex:1];
    NSMutableString *phoneNumberWithCountryCode;
    if (![phoneNumberTextField.text hasPrefix:@"+372"] && ![phoneNumberTextField.text hasPrefix:@"372"] && ![phoneNumberTextField.text hasPrefix:@"+374"] && ![phoneNumberTextField.text hasPrefix:@"374"]) {
      if([phoneNumberTextField.text hasPrefix:@"5"]) {
        phoneNumberWithCountryCode = [NSMutableString stringWithString:@"372"];
        [phoneNumberWithCountryCode appendString:phoneNumberTextField.text];
      } else {
        [weakSelf displayPhoneNumberError];
        return;
      }
    }else {
      phoneNumberWithCountryCode = [phoneNumberTextField.text mutableCopy];
    }
    if([[DefaultsHelper getIDCode] length] == 0) {
      [DefaultsHelper setIDCode:idCodeTextField.text];
    } if ([[DefaultsHelper getPhoneNumber] length] == 0) {
      [DefaultsHelper setPhoneNumber:phoneNumberTextField.text];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsChanged object:nil];
    [weakSelf mobileCreateSignatureWithIDCode:idCodeTextField.text phoneNumber:phoneNumberWithCountryCode];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)displayPhoneNumberError {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ContainerDetailsPhoneNumberErrorAlertTitle message:Localizations.ContainerDetailsPhoneNumberErrorAlertMessage preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)mobileCreateSignatureWithIDCode:(NSString *)idCode phoneNumber:(NSString *)phoneNumber {
  [[MoppLibService sharedInstance] mobileCreateSignatureWithContainer:self.container idCode:idCode language:[self decideLanguageBasedOnPreferredLanguages] phoneNumber:phoneNumber];
}

- (void)displayCardSignatureAlert {
  [self showHUD];
  [[MoppLibContainerActions sharedInstance] addSignature:self.container controller:self success:^(MoppLibContainer *container) {
    [self hideHUD];
    [self displaySigningSuccessMessage];
    self.container = container;
    [self.tableView reloadData];
    
  } failure:^(NSError *error) {
    [self hideHUD];
    [self displayErrorMessage:error];
  }];
}

- (void)displayErrorMessage:(NSError *)error {
  NSString *verifyCode = Localizations.PinActionsPin2;
  NSString *message;
  
  BOOL dismissViewcontroller = NO;
  
  if (error.code == moppLibErrorWrongPin) {
    int retryCount = [[error.userInfo objectForKey:kMoppLibUserInfoRetryCount] intValue];
    
    if (retryCount == 0) {
      message = Localizations.PinActionsWrongPinBlocked(verifyCode, verifyCode);
      dismissViewcontroller = YES;
      
    } else {
      message = Localizations.PinActionsWrongPinRetry(verifyCode, retryCount);
    }
    
  } else if(error.code == moppLibErrorSignatureAlreadyExists) {
    message = Localizations.ContainerDetailsSignatureAlreadyExists;
    
  } else if(error.code == moppLibErrorReaderNotFound) {
    message = Localizations.ContainerDetailsReaderNotFound;
    
  } else if(error.code == moppLibErrorCardNotFound) {
    message = Localizations.ContainerDetailsCardNotFound;
    
  } else if(error.code == moppLibErrorPinBlocked) {
    message = Localizations.PinActionsPinBlocked(verifyCode);
    
  } else if(error.code == moppLibErrorPinNotProvided) {
    message = Localizations.ContainerDetailsPinNotProvided;
    
  } else {
    message = Localizations.ContainerDetailsGeneralError;
  }
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.PinActionsErrorTitle message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    if (dismissViewcontroller) {
      [self.navigationController popViewControllerAnimated:YES];
    }
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)decideLanguageBasedOnPreferredLanguages {
  NSString *language;
  NSArray<NSString *> *prefLanguages = [NSLocale preferredLanguages];
  for (int i = 0; i < [prefLanguages count]; i++) {
    if ([[prefLanguages objectAtIndex:i] hasPrefix:@"et-"]) {
      language = @"EST";
      break;
    } else if ([[prefLanguages objectAtIndex:i] hasPrefix:@"lt-"]) {
      language = @"LIT";
      break;
    } else if ([[prefLanguages objectAtIndex:i] hasPrefix:@"ru-"]) {
      language = @"RUS";
      break;
    }
  }
  if (!language) {
    language = @"ENG";
  }
  return language;
}
- (void)displaySigningSuccessMessage {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ContainerDetailsSigningSuccess message:Localizations.ContainerDetailsSignatureAdded preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    //[self.navigationController popViewControllerAnimated:YES];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  
  if (editing) {
    self.editButtonItem.title = Localizations.ActionCancel;
  } else {
    self.editButtonItem.title = Localizations.ActionEdit;
  }
}

- (void)shareButtonPressed {
  //  MSLog(@"shareButtonPressed");
  
  NSURL *containerUrl = [[NSURL alloc] initFileURLWithPath:self.container.filePath];
  UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[containerUrl] applicationActivities:nil];
  activityViewController.popoverPresentationController.sourceView = self.view;
  CGRect sourceRect = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, 0.0, 0.0);
  activityViewController.popoverPresentationController.sourceRect = sourceRect;
  
  [activityViewController.popoverPresentationController setPermittedArrowDirections:0]; // Remove arrow on iPad.
  
  [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case ContainerDetailsSectionHeader:
      return 1;
      break;
      
    case ContainerDetailsSectionDataFile:
      return self.container.dataFiles.count;
      break;
      
    case ContainerDetailsSectionSignature: {
      int count = self.container.signatures.count;
      if (![[self.container.filePath pathExtension] isEqualToString:ContainerFormatDdoc]) {
        count++;
      }

      return count;
      break;
    }
      
    default:
      break;
  }
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  switch (indexPath.section) {
      
    case ContainerDetailsSectionHeader: {
      ContainerDetailsHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerDetailsHeaderCell class]) forIndexPath:indexPath];
      
      [cell.titleLabel setText:self.container.fileName];
      [cell.detailsLabel setText:Localizations.ContainerDetailsHeaderDetails([self.container.filePath pathExtension], [self.container.fileAttributes fileSize] / 1024)];
      [cell.editButton addTarget:self action:@selector(editContainerName:) forControlEvents:UIControlEventTouchUpInside];
      [cell.editButton setTitle:Localizations.ContainerDetailsRename forState:UIControlStateNormal];
      return cell;
      
      break;
    }
      
    case ContainerDetailsSectionDataFile: {
      ContainerDetailsDataFileCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerDetailsDataFileCell class]) forIndexPath:indexPath];
      
      MoppLibDataFile *dataFile = [self.container.dataFiles objectAtIndex:indexPath.row];
      [cell.fileNameLabel setText:dataFile.fileName];
      [cell.detailsLabel setText:Localizations.ContainerDetailsDatafileDetails(dataFile.fileSize / 1024)];
      
      return cell;
      
      break;
    }
      
    case ContainerDetailsSectionSignature: {
      if (self.container.signatures.count <= indexPath.row) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddSignatureCell"];
        return cell;
      }
      
      ContainerDetailsSignatureCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerDetailsSignatureCell class]) forIndexPath:indexPath];
      
      MoppLibSignature *signature = [self.container.signatures objectAtIndex:indexPath.row];
      [cell.signatureNameLabel setText:signature.subjectName];
      [cell.detailsLabel setText:[[DateFormatter sharedInstance] HHmmssddMMYYYYToString:signature.timestamp]];
      
      NSString *postfix;
      UIColor *postfixColor;
      if (signature.isValid) {
        postfix = Localizations.ContainerDetailsSignatureValid;
        postfixColor = [UIColor darkGreen];
      } else {
        postfix = Localizations.ContainerDetailsSignatureInvalid;
        postfixColor = [UIColor red];
      }
      NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:Localizations.ContainerDetailsSignaturePrefix(postfix)];
      [attributedString addAttribute:NSForegroundColorAttributeName value:postfixColor range:NSMakeRange(attributedString.length - postfix.length, postfix.length)];
      [cell.signatureValidityLabel setAttributedText:attributedString];
      
      return cell;
      
      break;
    }
      
    default:
      break;
  }
  
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  switch (section) {
    case ContainerDetailsSectionDataFile:
    case ContainerDetailsSectionSignature:
      return 40;
      break;
      
    default:
      return CGFLOAT_MIN;
      break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  
  SimpleHeaderView *header = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SimpleHeaderView class]) owner:self options:nil] objectAtIndex:0];
  
  switch (section) {
    case ContainerDetailsSectionDataFile: {
      [header.titleLabel setText:Localizations.ContainerDetailsDatafileSectionHeader];
      break;
    }
    case ContainerDetailsSectionSignature: {
      [header.titleLabel setText:Localizations.ContainerDetailsSignatureSectionHeader];
      break;
    }
      
    default:
      header = nil;
      break;
  }
  
  return header;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case ContainerDetailsSectionHeader:
      return NO;
      break;
      
    case ContainerDetailsSectionDataFile:
      if (self.container.dataFiles.count > 1 && ![self.container isSigned]) {
        return YES;
      }
      break;
      
    case ContainerDetailsSectionSignature:
      if (self.container.signatures.count > indexPath.row) {
        
        return YES;
      }
      break;
      
    default:
      return NO;
      break;
  }
  return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  return Localizations.ActionDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    
    switch (indexPath.section) {
      case ContainerDetailsSectionDataFile: {
        //        MoppLibDataFile *dataFile = [self.container.dataFiles objectAtIndex:indexPath.row];
        [[MoppLibContainerActions sharedInstance] removeDataFileFromContainerWithPath:self.container.filePath atIndex:indexPath.row success:^(MoppLibContainer *container) {
          [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContainerChanged object:nil userInfo:@{kKeyContainer:container}];

          self.container = container;
          [self.tableView reloadData];

        } failure:^(NSError *error) {
          
        }];
        break;
      }
      case ContainerDetailsSectionSignature: {
        MoppLibSignature *signature = [self.container.signatures objectAtIndex:indexPath.row];
        [[MoppLibContainerActions sharedInstance] removeSignature:signature fromContainerWithPath:self.container.filePath success:^(MoppLibContainer *container) {
          [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContainerChanged object:nil userInfo:@{kKeyContainer:container}];

          self.container = container;
          [self.tableView reloadData];
        } failure:^(NSError *error) {
          
        }];
        break;
      }
        
      default:
        break;
    }
  }
}

- (void)receiveAdesSignatureAddedToContainer:(NSNotification *)notification {
  MoppLibContainer *resultContainer = [[notification userInfo] objectForKey:kContainerKey];
  [self displaySigningSuccessMessage];
  self.container = resultContainer;
  [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case ContainerDetailsSectionDataFile: {
      [self showHUD];
      MoppLibDataFile *dataFile = [self.container.dataFiles objectAtIndex:indexPath.row];
      self.tempFilePath = [[FileManager sharedInstance] filePathWithFileName:dataFile.fileName];
      [[MoppLibContainerActions sharedInstance] container:self.container.filePath saveDataFile:dataFile.fileName to:self.tempFilePath success:^{
        NSURL *fileUrl = [NSURL fileURLWithPath:self.tempFilePath];
        self.previewController = [UIDocumentInteractionController interactionControllerWithURL:fileUrl];
        self.previewController.delegate = self;
        [self hideHUD];

        BOOL success = [self.previewController presentPreviewAnimated:YES];
        if (!success) {
          [self.previewController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES];

        }
      } failure:^(NSError *error) {
        [self hideHUD];
      }];
      break;
    }
      
    default:
      break;
  }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController {
  return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
  [[FileManager sharedInstance] removeFileWithPath:self.tempFilePath];
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
  [[FileManager sharedInstance] removeFileWithPath:self.tempFilePath];
}



@end
