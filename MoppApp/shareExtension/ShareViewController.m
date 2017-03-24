//
//  ShareViewController.m
//  shareExtension
//
//  Created by Katrin Annuk on 23/03/2017.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSArray *array = self.extensionContext.inputItems;
  
  for (NSExtensionItem *item in array) {
    for (NSItemProvider *provider in item.attachments) {
      [self cacheFileForProvider:provider];
    }
  }
  
  // TODO some files might not be importable
  
  // TODO can there be other formats than public.data
  
  // TODO add download for items on web
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Importing file" message:@"File is now cached for you. Go to RIA DigiDoc application to finish import"  preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)cacheFileForProvider:(NSItemProvider *)provider {
  if ([provider hasItemConformingToTypeIdentifier:@"public.data"]) {
    
    [provider loadItemForTypeIdentifier:@"public.data" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
      if ([((NSObject*)item) isKindOfClass: [NSURL class]]) {
        NSURL *itemUrl = (NSURL *)item;
        [self cacheFileOnUrl:itemUrl];
      }
    }];
    
  } /*else if ([provider hasItemConformingToTypeIdentifier:@"public.content"]) {

  }*/
}

- (void)cacheFileOnUrl:(NSURL *)itemUrl {
  NSData *data = [NSData dataWithContentsOfURL:itemUrl];
  if (data) {
    
    NSURL *groupFolderUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.ee.ria.digidoc.ios"];
    groupFolderUrl = [groupFolderUrl URLByAppendingPathComponent:@"Temp"];
    NSError *err;
    [[NSFileManager defaultManager] createDirectoryAtURL:groupFolderUrl withIntermediateDirectories:NO attributes:nil error:&err];
    
    NSURL  *filePath = [groupFolderUrl URLByAppendingPathComponent:itemUrl.lastPathComponent] ;
    
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtURL:itemUrl toURL:filePath error:&error];
    // [data writeToFile:[filePath absoluteString] atomically:YES];
  }
  
}

- (BOOL)isContentValid {
  // Do validation of contentText and/or NSExtensionContext attachments here
  return YES;
}

- (void)didSelectPost {
  // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
  
  // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
  [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
  // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
  return @[];
}

@end
