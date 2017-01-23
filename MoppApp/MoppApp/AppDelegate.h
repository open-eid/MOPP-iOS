//
//  AppDelegate.h
//  MoppApp
//
//  Created by Ants Käär on 20.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)setupTabController;

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end

