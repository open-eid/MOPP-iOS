//
//  BaseContainersListViewController.m
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import "BaseContainersListViewController.h"
#import "ContainerCell.h"
#import "NoContainersCell.h"

@interface BaseContainersListViewController ()



@end

@implementation BaseContainersListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.definesPresentationContext = YES;
  
  UINib *containerCellNib = [UINib nibWithNibName:NSStringFromClass([ContainerCell class]) bundle:nil];
  [self.tableView registerNib:containerCellNib forCellReuseIdentifier:NSStringFromClass([ContainerCell class])];
  
  UINib *noContainersCellNib = [UINib nibWithNibName:NSStringFromClass([NoContainersCell class]) bundle:nil];
  [self.tableView registerNib:noContainersCellNib forCellReuseIdentifier:NSStringFromClass([NoContainersCell class])];
  
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
  
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)reloadData {
  
  [self filterContainers:nil];
}

- (void)filterContainers:(NSString *)searchString {
//  MSLog(@"searchString: %@", searchString);
  [self.tableView reloadData];
}


#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
//  MSLog(@"updateSearchResultsForSearchController");
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
