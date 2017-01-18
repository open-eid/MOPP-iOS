//
//  InitializationViewController.m
//  MoppApp
//
//  Created by Ants Käär on 18.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

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
