//
//  InitializationViewController.m
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

#import "InitializationViewController.h"
#import "UIViewController+MBProgressHUD.h"
#import <MoppLib/MoppLib.h>
#import "AppDelegate.h"

@interface InitializationViewController ()

@end

@implementation InitializationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
 
  UIView *launchImageView = [[[NSBundle mainBundle] loadNibNamed:@"LaunchScreen" owner:self options:nil] lastObject];
  [self.view addSubview:launchImageView];
  [launchImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  __weak typeof(self) weakSelf = self;
  __weak AppDelegate *weakAppDelegate = appDelegate;
  
  // Initialize MoppLib.
  [self showHUD];
  [[MoppLibManager sharedInstance] setupWithSuccess:^{
    [weakSelf hideHUD];
    [weakAppDelegate setupTabController];
  } andFailure:^(NSError *error) {
    [weakSelf hideHUD];
    [weakAppDelegate setupTabController];
  }];
}

@end
