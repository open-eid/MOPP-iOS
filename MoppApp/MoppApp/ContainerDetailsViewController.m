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

typedef enum : NSUInteger {
  ContainerDetailsSectionHeader,
  ContainerDetailsSectionDataFile,
  ContainerDetailsSectionSignature
} ContainerDetailsSection;

@interface ContainerDetailsViewController ()

@end

@implementation ContainerDetailsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.ContainerDetailsTitle];
  
  [self.view setBackgroundColor:[UIColor whiteColor]];
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  [self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self.tableView reloadData];
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
      
    case ContainerDetailsSectionSignature:
      return self.container.signatures.count;
      break;
      
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
      return YES;
      break;
  
    default:
      return NO;
      break;
  }
  return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    
    switch (indexPath.section) {
      case ContainerDetailsSectionDataFile: {
//        MoppLibDataFile *dataFile = [self.container.dataFiles objectAtIndex:indexPath.row];
        self.container = [[MoppLibManager sharedInstance] removeDataFileFromContainerWithPath:self.container.filePath atIndex:indexPath.row];
        break;
      }
      case ContainerDetailsSectionSignature: {
        MoppLibSignature *signature = [self.container.signatures objectAtIndex:indexPath.row];
        break;
      }
        
      default:
        break;
    }
    
    [self.tableView reloadData];
  }
}


@end
