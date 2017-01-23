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
#import <MoppLib/MoppLib.h>
#import "NoContainersCell.h"

typedef enum : NSUInteger {
  ContainersListSectionUnsigned,
  ContainersListSectionSigned
} ContainersListSection;

@interface ContainersListViewController ()

@property (strong, nonatomic) NSArray *unsignedContainers;
@property (strong, nonatomic) NSArray *signedContainers;
@property (strong, nonatomic) NSArray *filteredUnsignedContainers;
@property (strong, nonatomic) NSArray *filteredSignedContainers;
@property (strong, nonatomic) MoppLibContainer *selectedContainer;

@end

@implementation ContainersListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabContainers];
  
  self.unsignedContainers = [NSArray array];
  self.signedContainers = [NSArray array];
  
  //  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  //  self.containers = @[[bundle pathForResource:@"test1" ofType:@"bdoc"],
  //                      [bundle pathForResource:@"test2" ofType:@"bdoc"]];
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  [self setEditing:NO]; // Update edit button title.
}

- (void)reloadData {
  self.unsignedContainers = [[MoppLibManager sharedInstance] getContainersIsSigned:NO];
  self.signedContainers = [[MoppLibManager sharedInstance] getContainersIsSigned:YES];
  
  self.filteredUnsignedContainers = self.unsignedContainers;
  self.filteredSignedContainers = self.signedContainers;
  
  [super reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  
  if (editing) {
    self.editButtonItem.title = Localizations.ActionCancel;
  } else {
    self.editButtonItem.title = Localizations.ActionEdit;
  }
}

- (void)filterContainers:(NSString *)searchString {
  if (searchString.length == 0) {
    self.filteredUnsignedContainers = self.unsignedContainers;
    self.filteredSignedContainers = self.signedContainers;
  } else {
    self.filteredUnsignedContainers = [self.unsignedContainers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.fileName contains[c] %@", searchString]];
    self.filteredSignedContainers = [self.signedContainers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.fileName contains[c] %@", searchString]];
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
      if (self.filteredUnsignedContainers.count > 0) {
        count = self.filteredUnsignedContainers.count;
      } else {
        count = 1;
      }
      break;
    }
    case ContainersListSectionSigned: {
      if (self.filteredSignedContainers.count > 0) {
        count = self.filteredSignedContainers.count;
      } else {
        count = 1;
      }
      break;
    }
      
    default:
      break;
  }
  return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  MoppLibContainer *container;
  switch (indexPath.section) {
    case ContainersListSectionUnsigned: {
      if (self.filteredUnsignedContainers.count > 0) {
        MoppLibContainer *container = [self.filteredUnsignedContainers objectAtIndex:indexPath.row];
        ContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerCell class]) forIndexPath:indexPath];
        [cell.titleLabel setText:container.fileName];
        [cell.dateLabel setText:[[DateFormatter sharedInstance] dateToRelativeString:[container.fileAttributes fileCreationDate]]];
        return cell;
      } else {
        NoContainersCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoContainersCell class]) forIndexPath:indexPath];
        return cell;
      }
      break;
    }
    case ContainersListSectionSigned: {
      if (self.filteredSignedContainers.count > 0) {
        MoppLibContainer *container = [self.filteredSignedContainers objectAtIndex:indexPath.row];
        ContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerCell class]) forIndexPath:indexPath];
        [cell.titleLabel setText:container.fileName];
        [cell.dateLabel setText:[[DateFormatter sharedInstance] dateToRelativeString:[container.fileAttributes fileCreationDate]]];
        return cell;
      } else {
        NoContainersCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoContainersCell class]) forIndexPath:indexPath];
        return cell;
      }
      break;
    }
    default:
      break;
  }
  
  
  return nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  switch (indexPath.section) {
    case ContainersListSectionUnsigned: {
      if (self.filteredUnsignedContainers.count == 0) {
        return;
      }
      self.selectedContainer = [self.filteredUnsignedContainers objectAtIndex:indexPath.row];
      break;
    }
    case ContainersListSectionSigned: {
      if (self.filteredSignedContainers.count == 0) {
        return;
      }
      self.selectedContainer = [self.filteredSignedContainers objectAtIndex:indexPath.row];
      break;
    }
    default:
      break;
  }
  
  [self performSegueWithIdentifier:@"ContainerDetailsSegue" sender:self];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case ContainersListSectionUnsigned: {
      if (self.filteredUnsignedContainers.count == 0) {
        return NO;
      } else {
        return YES;
      }
      break;
    }
    case ContainersListSectionSigned: {
      if (self.filteredSignedContainers.count == 0) {
        return NO;
      } else {
        return YES;
      }
      break;
    }
    default:
      return NO;
      break;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  return Localizations.ActionDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    
    switch (indexPath.section) {
      case ContainersListSectionUnsigned: {
        MoppLibContainer *container = [self.unsignedContainers objectAtIndex:indexPath.row];
        [[FileManager sharedInstance] removeFileWithName:container.fileName];
        break;
      }
      case ContainersListSectionSigned: {
        MoppLibContainer *container = [self.signedContainers objectAtIndex:indexPath.row];
        [[FileManager sharedInstance] removeFileWithName:container.fileName];
        break;
      }
        
      default:
        break;
    }
    
//    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self reloadData];
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
    detailsViewController.container = self.selectedContainer;
    
  } else if ([segue.identifier isEqualToString:@"FileImportSegue"]) {
    UINavigationController *navController = [segue destinationViewController];
    FileImportViewController *fileImportViewController = (FileImportViewController *)navController.viewControllers[0];
    fileImportViewController.delegate = self;
    fileImportViewController.dataFilePath = self.dataFilePath;
  }
}


#pragma mark - FileImportViewControllerDelegate
- (void)openContainerDetails:(MoppLibContainer *)container {
  self.selectedContainer = container;
  [self performSegueWithIdentifier:@"ContainerDetailsSegue" sender:self];
}

@end
