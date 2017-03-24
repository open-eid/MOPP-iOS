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
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "Constants.h"

@interface AppDelegate () <CrashlyticsDelegate>

@property (strong, nonatomic) LandingTabBarController *tabBarController;
@property (strong, nonatomic) NSURL *tempUrl;
@property (strong, nonatomic) NSString *sourceApplication;
@property (strong, nonatomic) id annotation;
@property (nonatomic, copy) void (^crashReportCompletion)(BOOL);
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[Session sharedInstance] setup];
  
  [[UINavigationBar appearance] setTranslucent:NO]; // Set navBar not translucent by default.
  
  [CrashlyticsKit setDelegate:self];
  [Fabric with:@[[Crashlytics class]]];

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

- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report completionHandler:(void (^)(BOOL))completionHandler {
  if ([[DefaultsHelper crashReportSetting] isEqualToString:CrashlyticsAlwaysSend]) {
    completionHandler(YES);
  } else {
    self.crashReportCompletion = completionHandler;
  }
}

- (void)setupTabController {
  self.tabBarController = [[UIStoryboard storyboardWithName:@"Landing" bundle:nil] instantiateInitialViewController];
  self.window.rootViewController = self.tabBarController;
  
  if (self.tempUrl) {
    [self application:[UIApplication sharedApplication] openURL:self.tempUrl sourceApplication:self.sourceApplication annotation:self.annotation];
    self.tempUrl = nil;
    self.sourceApplication = nil;
    self.annotation = nil;
  }
  
  if (self.crashReportCompletion) {
    [self displayCrashReportDialog];
  }
}

- (void)displayCrashReportDialog {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.CrashlyticsTitle message:Localizations.CrashlyticsMessage preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.CrashlyticsActionSend style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    self.crashReportCompletion(YES);
    self.crashReportCompletion = nil;
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.CrashlyticsActionAlwaysSend style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [DefaultsHelper setCrashReportSetting:CrashlyticsAlwaysSend];
    self.crashReportCompletion(YES);
    self.crashReportCompletion = nil;
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.CrashlyticsActionDoNotSend style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    self.crashReportCompletion(NO);
    self.crashReportCompletion = nil;
  }]];
  [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  if (url) {

    // When app has just been launched, it may not be ready to deal with containers yet. We need to wait until libdigidocpp setup is complete.
    if (!self.tabBarController) {
      self.annotation = annotation;
      self.sourceApplication = sourceApplication;
      self.tempUrl = url;
      return YES;
    }

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
      newFilePath = [[FileManager sharedInstance] copyFileWithPath:filePath toPath:newFilePath];
      [[FileManager sharedInstance] removeFileWithPath:filePath];
      
      void (^failure)(void) = ^void (void) {
        // Remove invalid container. Probably ddoc.
        [[FileManager sharedInstance] removeFileWithName:fileName];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.FileImportImportFailedAlertTitle message:Localizations.FileImportImportFailedAlertMessage(fileName) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
        [containersListViewController presentViewController:alert animated:YES completion:nil];
      };
      
      [[MoppLibContainerActions sharedInstance] getContainerWithPath:newFilePath success:^(MoppLibContainer *container) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContainerChanged object:nil userInfo:@{kKeyContainer:container}];

        MoppLibContainer *moppLibContainer = container;
        if (moppLibContainer) {
          [containersListViewController setSelectedContainer:moppLibContainer];
          
        } else {
          failure();
        }
      } failure:^(NSError *error) {
        failure();
      }];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillEnterForeground object:nil userInfo:nil];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
