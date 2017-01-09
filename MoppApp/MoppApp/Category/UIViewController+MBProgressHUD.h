//
//  UIViewController+MBProgressHUD.h
//  MoppApp
//
//  Created by Ants Käär on 09.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface UIViewController (MBProgressHUD)

- (MBProgressHUD *)showHUD;
- (void)hideHUD;

@end
