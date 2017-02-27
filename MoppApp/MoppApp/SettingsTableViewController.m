//
//  SettingsTableViewController.m
//  MoppApp
//
//  Created by Ants Käär on 11.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "FileManager.h"
#import "DefaultsHelper.h"
#import "AppDelegate.h"
#import <MoppLib/MoppLib.h>
#import "AboutViewController.h"
#import "Constants.h"

typedef NS_ENUM(NSUInteger, SettingsCellType) {
  SettingsCellTypeNewContainerFormat,
  SettingsCellTypeImportFile,
  SettingsCellTypeDuplicateContainer,
  SettingsCellTypeApplicationVersion,
  SettingsCellTypeAbout,
  SettingsCellTypeIDCode,
  SettingsCellTypePhoneNumber
};

NSString *const CellIdentifier = @"CellIdentifier";

@interface SettingsTableViewController ()

@property (strong, nonatomic) NSArray *settingsArray;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabSettings];
  
  self.settingsArray = @[@[@(SettingsCellTypeNewContainerFormat)],
                         @[@(SettingsCellTypeApplicationVersion)],
                         @[@(SettingsCellTypeAbout)],
                         @[@(SettingsCellTypeIDCode),@(SettingsCellTypePhoneNumber)],
                         @[@(SettingsCellTypeImportFile),
                           @(SettingsCellTypeDuplicateContainer)]];
  [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveSettingsChangedNotification:) name:kNotificationSettingsChanged object:nil];
}

- (void)showNewContainerFormatActionSheet {
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:Localizations.SettingsNewContainerFormat
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
  [actionSheet addAction:[UIAlertAction actionWithTitle:ContainerFormatBdoc
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  [DefaultsHelper setNewContainerFormat:ContainerFormatBdoc];
                                                  [self.tableView reloadData];
                                                }]];
  [actionSheet addAction:[UIAlertAction actionWithTitle:ContainerFormatAsice
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  [DefaultsHelper setNewContainerFormat:ContainerFormatAsice];
                                                  [self.tableView reloadData];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:Localizations.ActionCancel
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
  
  [actionSheet.popoverPresentationController setPermittedArrowDirections:0]; // Remove actionSheet arrow on iPad.
  actionSheet.popoverPresentationController.sourceView = self.view;
  CGRect sourceRect = CGRectMake(self.view.frame.size.width / 2, (self.view.frame.size.height / 2) + 100.0, 0.0, 0.0); // Change actionSheet offset from center 100.0pts lower.
  actionSheet.popoverPresentationController.sourceRect = sourceRect;
  [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)showFileImportActionSheet {
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Initiate file import"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"image.jpg"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"jpg"];
                                                  NSURL *fileUrl = [NSURL URLWithString:filePath];
                                                  [appDelegate application:[UIApplication sharedApplication] openURL:fileUrl sourceApplication:nil annotation:nil];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"presentation.pdf"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"presentation" ofType:@"pdf"];
                                                  NSURL *fileUrl = [NSURL URLWithString:filePath];
                                                  [appDelegate application:[UIApplication sharedApplication] openURL:fileUrl sourceApplication:nil annotation:nil];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"datafile.txt"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"datafile" ofType:@"txt"];
                                                  NSURL *fileUrl = [NSURL URLWithString:filePath];
                                                  [appDelegate application:[UIApplication sharedApplication] openURL:fileUrl sourceApplication:nil annotation:nil];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"test1.bdoc"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"bdoc"];
                                                  NSURL *fileUrl = [NSURL URLWithString:filePath];
                                                  [appDelegate application:[UIApplication sharedApplication] openURL:fileUrl sourceApplication:nil annotation:nil];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"asiceTest.asice"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"asiceTest" ofType:@"asice"];
                                                  NSURL *fileUrl = [NSURL URLWithString:filePath];
                                                  [appDelegate application:[UIApplication sharedApplication] openURL:fileUrl sourceApplication:nil annotation:nil];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"ddocTest.ddoc"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ddocTest" ofType:@"ddoc"];
                                                  NSURL *fileUrl = [NSURL URLWithString:filePath];
                                                  [appDelegate application:[UIApplication sharedApplication] openURL:fileUrl sourceApplication:nil annotation:nil];
                                                }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:Localizations.ActionCancel
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
  
  [actionSheet.popoverPresentationController setPermittedArrowDirections:0]; // Remove actionSheet arrow on iPad.
  actionSheet.popoverPresentationController.sourceView = self.view;
  CGRect sourceRect = CGRectMake(self.view.frame.size.width / 2, (self.view.frame.size.height / 2) + 100.0, 0.0, 0.0); // Change actionSheet offset from center 100.0pts lower.
  actionSheet.popoverPresentationController.sourceRect = sourceRect;
  [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.settingsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSArray *sectionArray = [self.settingsArray objectAtIndex:section];
  return sectionArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case 3:
      return Localizations.SettingsMobileIdHeader;
      break;
    case 4:
      return @"DEV";
      break;
      
    default:
      return nil;
      break;
  }
  
  return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
  }
  
  NSArray *sectionArray = [self.settingsArray objectAtIndex:indexPath.section];
  NSNumber *cellType = [sectionArray objectAtIndex:indexPath.row];
  
  NSString *titleLabelText;
  NSString *detailLabelText;
  switch (cellType.integerValue) {
    case SettingsCellTypeNewContainerFormat:
      titleLabelText = Localizations.SettingsNewContainerFormat;
      detailLabelText = [DefaultsHelper getNewContainerFormat];
      break;
      
    case SettingsCellTypeImportFile:
      titleLabelText = @"Initiate file import";
      break;
      
    case SettingsCellTypeAbout:
      titleLabelText = Localizations.SettingsAbout;
      detailLabelText = @">";
      break;
    case SettingsCellTypeIDCode:
      titleLabelText = Localizations.SettingsIdCodeTitle;
      detailLabelText = [DefaultsHelper getIDCode];
      break;
    case SettingsCellTypePhoneNumber:
      titleLabelText = Localizations.SettingsPhoneNumberTitle;
      detailLabelText = [DefaultsHelper getPhoneNumber];
      break;
    case SettingsCellTypeDuplicateContainer:
      titleLabelText = @"Create duplicate container";
      break;
    case SettingsCellTypeApplicationVersion:
      titleLabelText = Localizations.SettingsApplicationVersion;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      NSBundle *bundle = [NSBundle mainBundle];
      NSMutableString *versionString = [[NSMutableString alloc] initWithString:[[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
      [versionString appendString:[NSString stringWithFormat:@".%@", [[bundle infoDictionary] objectForKey:@"CFBundleVersion"]]];
      detailLabelText = versionString;
      break;
    
      
      
  }
  [cell.textLabel setText:titleLabelText];
  [cell.detailTextLabel setText:detailLabelText];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSArray *sectionArray = [self.settingsArray objectAtIndex:indexPath.section];
  NSNumber *cellType = [sectionArray objectAtIndex:indexPath.row];
  
  switch (cellType.integerValue) {
    case SettingsCellTypeNewContainerFormat:
      [self showNewContainerFormatActionSheet];
      break;
      
    case SettingsCellTypeImportFile: {
      [self showFileImportActionSheet];
      break;
    }
      
    case SettingsCellTypeDuplicateContainer: {
      NSString *containerName = [[FileManager sharedInstance] createTestContainer];
      
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:[NSString stringWithFormat:@"TEST container named \"%@\" has been created. It's now visible under \"%@\" tab.", containerName, Localizations.TabContainers] preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
      
      break;
    }
    case SettingsCellTypeAbout: {
      AboutViewController *controller = [[AboutViewController alloc] init];
      [self.navigationController pushViewController:controller animated:YES];
      break;
    }
    case SettingsCellTypeIDCode: {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.SettingsIdCodeTitle message:Localizations.SettingsIdCodeAlertMessage preferredStyle:UIAlertControllerStyleAlert];
      [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = Localizations.SettingsIdCodeTitle;
        textField.keyboardType = UIKeyboardTypeNumberPad;
      }];
      [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *idCodeTextField = [alert.textFields firstObject];
        [DefaultsHelper setIDCode:idCodeTextField.text];
        [self.tableView reloadData];
      }]];
      [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionCancel style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
      break;
    }
    case SettingsCellTypePhoneNumber: {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.SettingsPhoneNumberTitle message:Localizations.SettingsPhoneNumberAlertMessage preferredStyle:UIAlertControllerStyleAlert];
      [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = Localizations.SettingsPhoneNumberTitle;
        textField.keyboardType = UIKeyboardTypeNumberPad;
      }];
      [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *phoneNumberTextField = [alert.textFields firstObject];
        [DefaultsHelper setPhoneNumber:phoneNumberTextField.text];
        [self.tableView reloadData];
      }]];
      [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionCancel style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
      break;
    }
    default:
      break;
  }
}

- (void)receiveSettingsChangedNotification:(NSNotification *)notification {
  [self.tableView reloadData];
}

@end
