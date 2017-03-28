//
//  ShareViewController.m
//  shareExtension
//
//  Created by Katrin Annuk on 23/03/2017.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController () <NSURLSessionDelegate>

@end

@implementation ShareViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self performSelectorInBackground:@selector(cacheFilesWithCompletion:) withObject: ^(BOOL imported) {
    if (imported) {
      [self performSelectorOnMainThread:@selector(displayFilesImportedMessage) withObject:nil waitUntilDone:NO];
    }
  }];
}

- (void)displayFilesImportedMessage {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Importing file" message:@"File is now cached for you. Go to RIA DigiDoc application to finish import"  preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)cacheFilesWithCompletion:(void (^)(BOOL))completion {
  NSArray *array = self.extensionContext.inputItems;

  [self cacheItem:0 withProvider:0 inArray:array completion:completion];
}

- (void)cacheItem:(int)itemIndex withProvider:(int)providerIndex inArray:(NSArray *)items completion:(void (^)(BOOL))completion {
    
  if (items.count > itemIndex) {
    NSExtensionItem *item = items[itemIndex];
    
    if (item.attachments.count > providerIndex) {
      [self cacheFileForProvider:item.attachments[providerIndex] completion:^(BOOL imported) {
        [self cacheItem:itemIndex withProvider:providerIndex + 1 inArray:items completion:completion];

      }];
    } else {
      [self cacheItem:itemIndex + 1 withProvider:0 inArray:items completion:completion];
    }
    
  } else {
    completion(YES);
  }
}

- (void)cacheFileForProvider:(NSItemProvider *)provider completion:(void (^)(BOOL))completion {
  if ([provider hasItemConformingToTypeIdentifier:@"public.data"]) {

    [provider loadItemForTypeIdentifier:@"public.data" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
      if ([((NSObject*)item) isKindOfClass: [NSURL class]]) {
        NSURL *itemUrl = (NSURL *)item;
        completion([self cacheFileOnUrl:itemUrl]);
      }
    }];
    
  }
  
}

- (BOOL)cacheFileOnUrl:(NSURL *)itemUrl {

  if ([[itemUrl scheme] isEqualToString:@"file"]) {
    
    
    NSData *data = [NSData dataWithContentsOfURL:itemUrl];
    if (data) {
      
      NSURL *groupFolderUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.ee.ria.digidoc.ios"];
      groupFolderUrl = [groupFolderUrl URLByAppendingPathComponent:@"Temp"];
      NSError *err;
      [[NSFileManager defaultManager] createDirectoryAtURL:groupFolderUrl withIntermediateDirectories:NO attributes:nil error:&err];
      
      NSURL  *filePath = [groupFolderUrl URLByAppendingPathComponent:itemUrl.lastPathComponent] ;
      
      NSError *error;
      [[NSFileManager defaultManager] copyItemAtURL:itemUrl toURL:filePath error:&error];
      
      if (!error) {
        return YES;
      }
    }
    
  } else {
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"digidoc.share.background.task"];
    conf.sharedContainerIdentifier = @"group.ee.ria.digidoc.ios";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:nil];

    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:itemUrl];
    
    [task resume];
    return YES;
  }
  return NO;
}

@end
