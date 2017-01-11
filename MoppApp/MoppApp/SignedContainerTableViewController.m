//
//  SignedContainerTableViewController.m
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "SignedContainerTableViewController.h"
#import "SignedContainerDetailsCell.h"
#import "SignedContainerDataFileCell.h"
#import "SignedContainerSignatureCell.h"
#import "DateFormatter.h"
#import <MoppLib/MoppLib.h>
#import "FileManager.h"
#import "SimpleHeaderView.h"
#import "UIColor+Additions.h"
#import "UIViewController+MBProgressHUD.h"

typedef enum : NSUInteger {
  SignedContainerSectionDetails,
  SignedContainerSectionDataFile,
  SignedContainerSectionSignature
} SignedContainerSection;

@interface SignedContainerTableViewController ()

@property (strong, nonatomic) MoppLibContainer *container;

@end

@implementation SignedContainerTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.SignedContainerDetailsTitle];
  
  [self.view setBackgroundColor:[UIColor whiteColor]];
  
  [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  NSString *filePath = [[FileManager sharedInstance] filePathWithFileName:self.containerFileName];

  self.container = [[MoppLibManager sharedInstance] getContainerWithPath:filePath];
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
    case SignedContainerSectionDetails:
      return 1;
      break;
      
    case SignedContainerSectionDataFile:
      return self.container.dataFiles.count;
      break;
      
    case SignedContainerSectionSignature:
      return self.container.signatures.count;
      break;
      
    default:
      break;
  }
  return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  switch (indexPath.section) {
      
    case SignedContainerSectionDetails: {
      SignedContainerDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SignedContainerDetailsCell class]) forIndexPath:indexPath];
      
      NSDictionary *fileAttributes = [[FileManager sharedInstance] fileAttributes:self.containerFileName];
      [cell.titleLabel setText:self.containerFileName];
      [cell.detailsLabel setText:Localizations.SignedContainerDetailsHeaderDetails([self.containerFileName pathExtension], [fileAttributes fileSize] / 1024)];
      return cell;
      
      break;
    }
      
    case SignedContainerSectionDataFile: {
      SignedContainerDataFileCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SignedContainerDataFileCell class]) forIndexPath:indexPath];
      
      MoppLibDataFile *dataFile = [self.container.dataFiles objectAtIndex:indexPath.row];
      [cell.fileNameLabel setText:dataFile.fileName];
      [cell.detailsLabel setText:Localizations.SignedContainerDetailsDatafileDetails(dataFile.fileSize / 1024)];
      
      return cell;
      
      break;
    }
      
    case SignedContainerSectionSignature: {
      SignedContainerSignatureCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SignedContainerSignatureCell class]) forIndexPath:indexPath];
      
      MoppLibSignature *signature = [self.container.signatures objectAtIndex:indexPath.row];
      [cell.signatureNameLabel setText:signature.subjectName];
      [cell.detailsLabel setText:[[DateFormatter sharedInstance] HHmmssddMMYYYYToString:signature.timestamp]];
      
      NSString *postfix;
      UIColor *postfixColor;
      if (signature.isValid) {
        postfix = Localizations.SignedContainerDetailsSignatureValid;
        postfixColor = [UIColor darkGreen];
      } else {
        postfix = Localizations.SignedContainerDetailsSignatureInvalid;
        postfixColor = [UIColor red];
      }
      NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:Localizations.SignedContainerDetailsSignaturePrefix(postfix)];
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
    case SignedContainerSectionDataFile:
    case SignedContainerSectionSignature:
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
    case SignedContainerSectionDataFile: {
      [header.titleLabel setText:Localizations.SignedContainerDetailsDatafileSectionHeader];
      break;
    }
    case SignedContainerSectionSignature: {
      [header.titleLabel setText:Localizations.SignedContainerDetailsSignatureSectionHeader];
      break;
    }
      
    default:
      header = nil;
      break;
  }
  
  return header;
}

@end
