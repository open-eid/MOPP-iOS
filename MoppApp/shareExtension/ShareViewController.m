//
//  ShareViewController.m
//  shareExtension
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"share-extension-import-title", nil) message:NSLocalizedString(@"share-extension-import-message", nil)  preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
      [[NSFileManager defaultManager] createDirectoryAtURL:groupFolderUrl
        withIntermediateDirectories:NO
        attributes:@{NSFileProtectionKey: NSFileProtectionComplete} error:&err];
      
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
