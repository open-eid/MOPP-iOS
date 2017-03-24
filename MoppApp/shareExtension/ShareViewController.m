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
  
#warning TODO - some files might not be importable
#warning TODO - can there be other formats than public.data
#warning TODO - add download for items on web
  
  
  [self performSelectorInBackground:@selector(cacheFilesWithCompletion:) withObject:  ^(BOOL imported) {
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
    
  } /*else if ([provider hasItemConformingToTypeIdentifier:@"public.content"]) {

  }*/
  
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
    // [data writeToFile:[filePath absoluteString] atomically:YES];

    if (!error) {
      return YES;
    }
  }
    
  } else {
  //  NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"digidoc.share.background.task"]];
   // NSURLSessionDownloadTask *task = [session downloadTaskWithURL:itemUrl];
    
   // [task resume];
  }
  return NO;
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
