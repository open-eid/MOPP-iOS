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

typedef NS_ENUM(NSUInteger, SettingsCellType) {
  SettingsCellTypeNewContainerFormat,
  SettingsCellTypeImportFile,
  SettingsCellTypeDuplicateContainer
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
                         @[
//                           @(SettingsCellTypeImportFile),
                           @(SettingsCellTypeDuplicateContainer)]];
  
  [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
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
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"datafile.jpg"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"datafile" ofType:@"jpg"];
                                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:filePath]];
//                                                  [appDelegate application:nil openURL:nil sourceApplication:nil annotation:nil];
//                                                  [appDelegate application:[UIApplication sharedApplication] openURL:[NSURL URLWithString:filePath] options:nil];
                                                }]];
//  [actionSheet addAction:[UIAlertAction actionWithTitle:ContainerFormatAsice
//                                                  style:UIAlertActionStyleDefault
//                                                handler:^(UIAlertAction * _Nonnull action) {
//                                                  [DefaultsHelper setNewContainerFormat:ContainerFormatAsice];
//                                                }]];
  
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
    case 0:
      return nil;
      break;
      
    case 1:
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
      
    case SettingsCellTypeDuplicateContainer:
      titleLabelText = @"Create duplicate container";
      break;
      
    default:
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
      [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];

      break;
    }
      
    default:
      break;
  }
}

@end
