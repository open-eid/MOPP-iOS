//
//  BaseContainersListViewController.m
//  MoppApp
//
//  Created by Ants Käär on 16.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "BaseContainersListViewController.h"
#import "ContainerCell.h"

@interface BaseContainersListViewController ()



@end

@implementation BaseContainersListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.definesPresentationContext = YES;
  
  UINib *nib = [UINib nibWithNibName:NSStringFromClass([ContainerCell class]) bundle:nil];
  [self.tableView registerNib:nib forCellReuseIdentifier:NSStringFromClass([ContainerCell class])];
  
  // UISearchController
  self.extendedLayoutIncludesOpaqueBars = YES; // Remove empty tableHeaderView when activating search bar.
  
  self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
  self.searchController.searchResultsUpdater = self;
  self.searchController.dimsBackgroundDuringPresentation = NO;
  [self.searchController.searchBar sizeToFit]; // Fix searchBar size on iOS 8.
  self.tableView.tableHeaderView = self.searchController.searchBar;
  [self.searchController.searchBar setPlaceholder:Localizations.ContainersListSearchPlaceholder];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)reloadData {
  
  [self filterContainers:nil];
}

- (void)filterContainers:(NSString *)searchString {
  MSLog(@"searchString: %@", searchString);
  [self.tableView reloadData];
}


#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
  MSLog(@"updateSearchResultsForSearchController");
  [self filterContainers:searchController.searchBar.text];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

@end
