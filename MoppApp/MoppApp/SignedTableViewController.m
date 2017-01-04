//
//  SignedTableViewController.m
//  MoppApp
//
//  Created by Ants Käär on 29.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "SignedTableViewController.h"
#import "SignedContainerCell.h"
#import "SignedDetailViewController.h"

@interface SignedTableViewController ()

@property (strong, nonatomic) NSArray *containers;
@property (strong, nonatomic) NSArray *filteredContainers;
@property (strong, nonatomic) NSString *selectedContainer;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation SignedTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabSigned];
  
  self.containers = [NSArray array];
  self.filteredContainers = [NSArray array];
  
//  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//  self.containers = @[[bundle pathForResource:@"test1" ofType:@"bdoc"],
//                      [bundle pathForResource:@"test2" ofType:@"bdoc"]];
  
  
  [self.tableView setEstimatedRowHeight:UITableViewAutomaticDimension];
  [self.tableView setRowHeight:UITableViewAutomaticDimension];
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  
  // UISearchController
  self.navigationController.extendedLayoutIncludesOpaqueBars = YES; // Don't hide searchBar when activating.
  
  self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
  self.searchController.searchResultsUpdater = self;
  self.searchController.dimsBackgroundDuringPresentation = NO;
  [self.searchController.searchBar sizeToFit]; // Fix searchBar size on iOS 8.
  self.tableView.tableHeaderView = self.searchController.searchBar;
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self reloadData];
}

- (void)reloadData {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSFileManager *manager = [NSFileManager defaultManager];
  self.containers = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
  self.filteredContainers = self.containers;
  
  for (NSString *filePath in self.containers) {
    MSLog(@"%@", filePath);
  }
  
  [self filterContainers:nil];
}

- (void)filterContainers:(NSString *)searchString {
  MSLog(@"searchString: %@", searchString);
  if (searchString.length == 0) {
    self.filteredContainers = self.containers;
  } else {
    self.filteredContainers = [self.containers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchString]];
  }
  [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.filteredContainers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SignedContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SignedContainerCell" forIndexPath:indexPath];
  
  NSString *fileName = [self.filteredContainers objectAtIndex:indexPath.row];
  [cell.titleLabel setText:fileName];
  
  return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  self.selectedContainer = [self.filteredContainers objectAtIndex:indexPath.row];
  
  [self filterContainers:nil];
  [self.searchController setActive:NO];
}


//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  SignedDetailViewController *detailsViewController = [segue destinationViewController];
  detailsViewController.containerPath = self.selectedContainer;
}


#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
  MSLog(@"updateSearchResultsForSearchController");
  [self filterContainers:searchController.searchBar.text];
}
@end
