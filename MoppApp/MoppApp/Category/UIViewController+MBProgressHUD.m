//
//  UIViewController+MBProgressHUD.m
//  MoppApp
//
//  Created by Ants Käär on 09.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "UIViewController+MBProgressHUD.h"

@implementation UIViewController (MBProgressHUD)

- (MBProgressHUD *)showHUD {
  UIView *view;
  if (self.tabBarController.view != nil) {
    view = self.tabBarController.view;
  } else if (self.navigationController.view != nil) {
    view = self.navigationController.view;
  } else {
    view = self.view;
  }
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:NO];
  [hud setDimBackground:YES];
  return hud;
}

- (void)hideHUD {
  [MBProgressHUD hideAllHUDsForView:self.tabBarController.view animated:NO];
  [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:NO];
  [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
}

@end
