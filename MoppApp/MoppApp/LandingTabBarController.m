//
//  LandingTabBarController.m
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

#import "LandingTabBarController.h"
#import "UIViewController+MBProgressHUD.h"
#import "MobileIDChallengeViewController.h"
#import "Constants.h"
#import <MoppLib/MoppLibMobileCreateSignatureResponse.h>
#import "UIColor+Additions.h"

@interface LandingTabBarController ()
@property (nonatomic, strong) MobileIDChallengeViewController *currentMobileIDChallengeView;
@end

@implementation LandingTabBarController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.tabBar setTintColor:[UIColor darkBlue]];
  
  [self setupTabFor:[self.viewControllers objectAtIndex:0] title:Localizations.TabContainers image:@"documentsNormal_2" selectedImage:@"documentsNormal"];
  [self setupTabFor:[self.viewControllers objectAtIndex:1] title:Localizations.TabMyEid image:@"eIDNormal" selectedImage:@"eIDNormal_2"];
  [self setupTabFor:[self.viewControllers objectAtIndex:2] title:Localizations.TabSimSettings image:@"pinNormal" selectedImage:@"pinNormal_2"];
  [self setupTabFor:[self.viewControllers objectAtIndex:3] title:Localizations.TabSettings image:@"settingsNormal" selectedImage:@"settingsNormal_2"];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMobileCreateSignatureNotification:) name:kCreateSignatureNotificationName object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveErrorNotification:) name:kErrorNotificationName object:nil];
}

- (void)setupTabFor:(UIViewController *)controller title:(NSString *)title image:(NSString *)image selectedImage:(NSString *)selectedImage {
  [controller setTitle:title];
  [[controller tabBarItem] setImage:[UIImage imageNamed:image]];
  [[controller tabBarItem] setSelectedImage:[UIImage imageNamed:selectedImage]];
}

- (void)receiveMobileCreateSignatureNotification:(NSNotification *)notification {
  MoppLibMobileCreateSignatureResponse *response = [notification.userInfo objectForKey:kCreateSignatureResponseKey];
  MobileIDChallengeViewController *mobileIDChallengeview = [self.storyboard instantiateViewControllerWithIdentifier:@"MobileIDChallengeView"];
  self.currentMobileIDChallengeView = mobileIDChallengeview;
  self.currentMobileIDChallengeView.challengeID = response.challengeId;
  self.currentMobileIDChallengeView.sessCode = [NSString stringWithFormat:@"%ld", (long)response.sessCode];
  self.currentMobileIDChallengeView.modalPresentationStyle = UIModalPresentationOverCurrentContext;
  self.currentMobileIDChallengeView.view.alpha = 0.75f;
  [self presentViewController:self.currentMobileIDChallengeView animated:YES completion:nil];
}

- (void)receiveErrorNotification:(NSNotification *)notification {
  NSError *error = [[notification userInfo] objectForKey:kErrorKey];
  [self.currentMobileIDChallengeView dismissViewControllerAnimated:YES completion:nil];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ErrorAlertTitleGeneral
                                                                 message:[[error userInfo]
                                                                          objectForKey:NSLocalizedDescriptionKey]
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
