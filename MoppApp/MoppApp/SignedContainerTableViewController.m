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
  
  [self setTitle:@"Konteiner"];
  
  [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  NSString *filePath = [[FileManager sharedInstance] filePathWithFileName:self.containerFileName];
  self.container = [[MoppLibManager sharedInstance] getContainerWithPath:filePath];
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
      [cell.titleLabel setText:self.containerFileName];
      return cell;
      
      break;
    }
      
    case SignedContainerSectionDataFile: {
      SignedContainerDataFileCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SignedContainerDataFileCell class]) forIndexPath:indexPath];
      
      MoppLibDataFile *dataFile = [self.container.dataFiles objectAtIndex:indexPath.row];
      [cell.fileNameLabel setText:dataFile.fileName];
      [cell.detailsLabel setText:[NSString stringWithFormat:@"Suurus: %f", dataFile.fileSize]];
      
      return cell;
      
      break;
    }
      
    case SignedContainerSectionSignature: {
      SignedContainerSignatureCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SignedContainerSignatureCell class]) forIndexPath:indexPath];
      
      MoppLibSignature *signature = [self.container.signatures objectAtIndex:indexPath.row];
      [cell.signatureNameLabel setText:signature.subjectName];
      [cell.detailsLabel setText:signature.timestamp];
      if (signature.isValid) {
        [cell.signatureValidityLabel setText:@"Allkiri on kehtiv"];
      } else {
        [cell.signatureValidityLabel setText:@"Allkiri ei ole kehtiv"];
      }
      
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

@end
