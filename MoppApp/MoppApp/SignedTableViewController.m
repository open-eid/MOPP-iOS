//
//  SignedTableViewController.m
//  MoppApp
//
//  Created by Ants Käär on 29.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "SignedTableViewController.h"
#import "SignedContainerCell.h"
#import "SignedContainerDetailsCell.h"
#import "FileManager.h"
#import "DateFormatter.h"
#import "SignedContainerTableViewController.h"

@interface SignedTableViewController ()

@property (strong, nonatomic) NSArray *containers;
@property (strong, nonatomic) NSArray *filteredContainers;
@property (strong, nonatomic) NSString *containerFileName;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation SignedTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabSigned];
  
  self.definesPresentationContext = YES;
  
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
  self.extendedLayoutIncludesOpaqueBars = YES; // Remove empty tableHeaderView when activating search bar.
  
  self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
  self.searchController.searchResultsUpdater = self;
  self.searchController.dimsBackgroundDuringPresentation = NO;
  [self.searchController.searchBar sizeToFit]; // Fix searchBar size on iOS 8.
  self.tableView.tableHeaderView = self.searchController.searchBar;
//  [self.searchController.searchBar setPlaceholder:@"asdf"];
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)reloadData {
  self.containers = [[FileManager sharedInstance] getBDocFiles];
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
  SignedContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SignedContainerCell class]) forIndexPath:indexPath];
  
  NSString *fileName = [self.filteredContainers objectAtIndex:indexPath.row];
  [cell.titleLabel setText:fileName];
  [cell.dateLabel setText:[[DateFormatter sharedInstance] ddMMMToString:[[FileManager sharedInstance] fileCreationDate:fileName]]];
  
  return cell;
}

#pragma mark - UITableViewDelegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.containerFileName = [self.filteredContainers objectAtIndex:indexPath.row];
  
  return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  [self.searchController setActive:NO];
  [self filterContainers:nil];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    
    NSString *fileName = [self.filteredContainers objectAtIndex:indexPath.row];
    [[FileManager sharedInstance] removeFileWithName:fileName];
    
    [self reloadData];
//    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  SignedContainerTableViewController *detailsViewController = [segue destinationViewController];
  detailsViewController.containerFileName = self.containerFileName;
}


#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
  MSLog(@"updateSearchResultsForSearchController");
  [self filterContainers:searchController.searchBar.text];
}
@end
