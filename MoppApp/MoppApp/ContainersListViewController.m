//
//  ContainersListViewController.m
//  MoppApp
//
//  Created by Ants Käär on 16.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ContainersListViewController.h"
#import "FileManager.h"
#import "DateFormatter.h"
#import "ContainerCell.h"
#import "ContainerDetailsViewController.h"
#import "SimpleHeaderView.h"


typedef enum : NSUInteger {
  ContainersListSectionUnsigned,
  ContainersListSectionSigned
} ContainersListSection;

@interface ContainersListViewController ()

@property (strong, nonatomic) NSArray *unsignedContainers;
@property (strong, nonatomic) NSArray *signedContainers;
@property (strong, nonatomic) NSArray *filteredUnsignedContainers;
@property (strong, nonatomic) NSArray *filteredSignedContainers;
@property (strong, nonatomic) NSString *containerFileName;

@end

@implementation ContainersListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabContainers];
  
  self.unsignedContainers = [NSArray array];
  self.signedContainers = [NSArray array];
//  self.filteredContainers = [NSArray array];
  
  //  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  //  self.containers = @[[bundle pathForResource:@"test1" ofType:@"bdoc"],
  //                      [bundle pathForResource:@"test2" ofType:@"bdoc"]];
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  self.navigationItem.rightBarButtonItem = self.editButtonItem;  
}

- (void)reloadData {
  self.unsignedContainers = [[FileManager sharedInstance] getContainers];
  self.signedContainers = [[FileManager sharedInstance] getContainers];
  self.filteredUnsignedContainers = self.unsignedContainers;
  self.filteredSignedContainers = self.signedContainers;
  
  [super reloadData];
}

- (void)filterContainers:(NSString *)searchString {
  if (searchString.length == 0) {
    self.filteredUnsignedContainers = self.unsignedContainers;
    self.filteredSignedContainers = self.signedContainers;
  } else {
    self.filteredUnsignedContainers = [self.unsignedContainers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchString]];
    self.filteredSignedContainers = [self.signedContainers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchString]];
  }
  [super filterContainers:searchString];
}


#pragma mark - File importing
- (void)setDataFilePath:(NSString *)dataFilePath {
  _dataFilePath = dataFilePath;

  [self performSegueWithIdentifier:@"FileImportSegue" sender:self];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger count = 0;
  switch (section) {
    case ContainersListSectionUnsigned: {
      count = self.filteredUnsignedContainers.count;
      break;
    }
    case ContainersListSectionSigned: {
      count = self.filteredSignedContainers.count;
      break;
    }
      
    default:
      break;
  }
  return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerCell class]) forIndexPath:indexPath];
  
  NSString *fileName;
  switch (indexPath.section) {
    case ContainersListSectionUnsigned: {
      fileName = [self.filteredUnsignedContainers objectAtIndex:indexPath.row];
      break;
    }
    case ContainersListSectionSigned: {
      fileName = [self.filteredSignedContainers objectAtIndex:indexPath.row];
      break;
    }
    default:
      break;
  }
  
  NSDictionary *fileAttributes = [[FileManager sharedInstance] fileAttributes:fileName];
  [cell.titleLabel setText:fileName];
  [cell.dateLabel setText:[[DateFormatter sharedInstance] dateToRelativeString:[fileAttributes fileCreationDate]]];
  
  return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  switch (indexPath.section) {
    case ContainersListSectionUnsigned: {
      self.containerFileName = [self.filteredUnsignedContainers objectAtIndex:indexPath.row];
      break;
    }
    case ContainersListSectionSigned: {
      self.containerFileName = [self.filteredSignedContainers objectAtIndex:indexPath.row];
      break;
    }
    default:
      break;
  }
  
  [self performSegueWithIdentifier:@"ContainerDetailsSegue" sender:self];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    
    switch (indexPath.section) {
      case ContainersListSectionUnsigned: {
        NSString *fileName = [self.unsignedContainers objectAtIndex:indexPath.row];
        [[FileManager sharedInstance] removeFileWithName:fileName];
        break;
      }
      case ContainersListSectionSigned: {
        NSString *fileName = [self.signedContainers objectAtIndex:indexPath.row];
        [[FileManager sharedInstance] removeFileWithName:fileName];
        break;
      }
        
      default:
        break;
    }
    
    [self reloadData];
    //    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  
  SimpleHeaderView *header = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SimpleHeaderView class]) owner:self options:nil] objectAtIndex:0];
  
  switch (section) {
    case ContainersListSectionUnsigned: {
      [header.titleLabel setText:Localizations.ContainersListSectionHeaderUnsigned];
      break;
    }
    case ContainersListSectionSigned: {
      [header.titleLabel setText:Localizations.ContainersListSectionHeaderSigned];
      break;
    }
      
    default:
      header = nil;
      break;
  }
  
  return header;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"ContainerDetailsSegue"]) {
    ContainerDetailsViewController *detailsViewController = [segue destinationViewController];
    detailsViewController.containerFileName = self.containerFileName;
    
  } else if ([segue.identifier isEqualToString:@"FileImportSegue"]) {
    UINavigationController *navController = [segue destinationViewController];
    FileImportViewController *fileImportViewController = (FileImportViewController *)navController.viewControllers[0];
    fileImportViewController.delegate = self;
    fileImportViewController.dataFilePath = self.dataFilePath;
  }
}


#pragma mark - FileImportViewControllerDelegate
- (void)openContainerDetailsWithName:(NSString *)containerFileName {
  self.containerFileName = containerFileName;
  [self performSegueWithIdentifier:@"ContainerDetailsSegue" sender:self];
}

@end
