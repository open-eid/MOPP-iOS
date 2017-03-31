//
//  UIViewController+MBProgressHUD.m
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
