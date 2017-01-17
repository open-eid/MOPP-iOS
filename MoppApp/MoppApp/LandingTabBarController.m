//
//  LandingTabBarController.m
//  MoppApp
//
//  Created by Ants Käär on 29.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "LandingTabBarController.h"
#import <MoppLib/MoppLib.h>
#import "UIViewController+MBProgressHUD.h"

@interface LandingTabBarController ()

@end

@implementation LandingTabBarController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[self.viewControllers objectAtIndex:0] setTitle:Localizations.TabContainers];
  [[self.viewControllers objectAtIndex:1] setTitle:Localizations.TabMyEid];
  [[self.viewControllers objectAtIndex:2] setTitle:Localizations.TabSimSettings];
  [[self.viewControllers objectAtIndex:3] setTitle:Localizations.TabSettings];
  
  // Initialize MoppLib.
  [self showHUD];
  __weak typeof(self) weakSelf = self;
  [[MoppLibManager sharedInstance] setupWithSuccess:^{
    [weakSelf hideHUD];
  } andFailure:^(NSError *error) {
    [weakSelf hideHUD];
  }];
}


@end
