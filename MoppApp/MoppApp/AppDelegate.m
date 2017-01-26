//
//  AppDelegate.m
//  MoppApp
//
//  Created by Ants Käär on 20.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "AppDelegate.h"
#import "MPNavigationController.h"
#import "UIColor+Additions.h"
#import "LandingTabBarController.h"
#import "ContainersListViewController.h"
#import "FileManager.h"
#import "InitializationViewController.h"
#import "Session.h"
#import <MoppLib/MoppLib.h>
#import "DefaultsHelper.h"

@interface AppDelegate ()

@property (strong, nonatomic) LandingTabBarController *tabBarController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  [[Session sharedInstance] setup];
  
  [[UINavigationBar appearance] setTranslucent:NO]; // Set navBar not translucent by default.
  
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self.window setBackgroundColor:[UIColor whiteColor]];
  
  [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
  [[UINavigationBar appearance] setBarTintColor:[UIColor darkBlue]];
  [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
  [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];

  InitializationViewController *initializationViewController = [[InitializationViewController alloc] init];
  self.window.rootViewController = initializationViewController;
  
  [self.window makeKeyAndVisible];
  
  return YES;
}

- (void)setupTabController {
  self.tabBarController = [[UIStoryboard storyboardWithName:@"Landing" bundle:nil] instantiateInitialViewController];
  self.window.rootViewController = self.tabBarController;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  if (url) {
//    NSString *dataFileName = [url.absoluteString lastPathComponent];
//    NSString *dataFilePath = [[FileManager sharedInstance] filePathWithFileName:[NSString stringWithFormat:@"Inbox/%@", dataFileName]];

    NSString *filePath = url.relativePath;
    NSString *fileName = [filePath lastPathComponent];
    NSString *fileExtension = [filePath pathExtension];
    MSLog(@"Imported file: %@", filePath);
    
    [self.tabBarController setSelectedIndex:0];
    UINavigationController *navController = (UINavigationController *)[self.tabBarController.viewControllers objectAtIndex:0];
    [navController popViewControllerAnimated:NO];
    ContainersListViewController *containersListViewController = (ContainersListViewController *)navController.viewControllers[0];
    
    if ([fileExtension isEqualToString:ContainerFormatDdoc] ||
        [fileExtension isEqualToString:ContainerFormatAsice] ||
        [fileExtension isEqualToString:ContainerFormatBdoc]) {
      
      // Move container from inbox folder to documents folder and cleanup.
      NSString *newFilePath = [[FileManager sharedInstance] filePathWithFileName:fileName];
      [[FileManager sharedInstance] copyFileWithPath:filePath toPath:newFilePath];
      [[FileManager sharedInstance] removeFileWithPath:filePath];
      
      MoppLibContainer *moppLibContainer = [[MoppLibManager sharedInstance] getContainerWithPath:newFilePath];
      
      if (moppLibContainer) {
        [containersListViewController setSelectedContainer:moppLibContainer];
        
      } else {
        
        // Remove invalid container. Probably ddoc.
        [[FileManager sharedInstance] removeFileWithName:fileName];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.FileImportImportFailedAlertTitle message:Localizations.FileImportImportFailedAlertMessage(fileName) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
        [containersListViewController presentViewController:alert animated:YES completion:nil];
      }
      
    } else {
      
      [containersListViewController setDataFilePath:filePath];
    }
    
  }
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
