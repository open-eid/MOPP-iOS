//
//  BaseContainersListViewController.h
//  MoppApp
//
//  Created by Ants Käär on 16.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseContainersListViewController : UITableViewController <UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;

- (void)reloadData;
- (void)filterContainers:(NSString *)searchString;

@end
