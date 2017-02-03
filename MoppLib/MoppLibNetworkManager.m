//
//  MoppLibNetworkManager.m
//  MoppLib
//
//  Created by Olev Abel on 2/2/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibNetworkManager.h"
#import "MoppLibError.h"

typedef NS_ENUM(NSInteger, MoppLibNetworkRequestMethod) {
  MoppLibNetworkRequestMethodMobileCreateSignature,
  MoppLibNetworkRequestMethodMobileGetMobileCreateSignatureStatus
};
@interface MoppLibNetworkManager ()

@end
@implementation MoppLibNetworkManager

+ (MoppLibNetworkManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibNetworkManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (NSMutableURLRequest *)requestWithXMLBody:(NSString *)xmlBody {
  NSError *error;
  NSURL *url = [NSURL URLWithString:kDDSServerUrl];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  NSData *requestBodyData = [xmlBody dataUsingEncoding:NSUTF8StringEncoding];
  [request setURL:url];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"gzip,deflate" forHTTPHeaderField:@"Accept-Encoding"];
  [request setHTTPBody:requestBodyData];
  return [request copy];
}

- (void)postDataToPathWithXml:(NSString *)xmlBody method:(MoppLibNetworkRequestMethod)method success:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure {
  
  NSURLRequest *request = [self requestWithXMLBody:xmlBody];
  NSLog(@"Request : %@", request);
  NSURLSessionTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (!error) {
      NSInteger statusCode = [(NSHTTPURLResponse *) response statusCode];
      if (statusCode != 401) {
        NSError *resultError;
        switch (method) {
          case MoppLibNetworkRequestMethodMobileCreateSignature:{
            [[MoppLibSOAPManager sharedInstance] parseMobileCreateSignatureResultWithResponseData:data withSuccess:^(NSObject *responseObject) {
              success(responseObject);
            } andFailure:^(NSError *error) {
              failure(error);
            }];
            break;
          }
          case MoppLibNetworkRequestMethodMobileGetMobileCreateSignatureStatus:
            NSLog(@"NOT IMPLEMENTED");
            break;
        }
    
      } else {
        NSString *errorDescription = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
        failure([NSError errorWithDomain:@"MoppLib" code:statusCode userInfo:@{NSLocalizedDescriptionKey : errorDescription}]);
      }
    }else {
      if (error.code == NSURLErrorCancelled) {
        failure([MoppLibError urlSessionCanceledError]);
      } else {
        failure(error);
      }
    }
  }];
  [dataTask resume];
}

/*- (id)processResultWithData:(NSData *)data
 resultModelClass:(Class)resultModelClass
 withError:(NSError * *)resultError {
 
 }*/
- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container
                               nationality:(NSString *)nationality
                                    idCode:(NSString *)idCode
                                   phoneNo:(NSString *)phoneNo
                               withSuccess:(ObjectSuccessBlock)success
                                andFailure:(FailureBlock)failure {
  NSString *xmlRequest = [[MoppLibSOAPManager sharedInstance] mobileCreateSignatureWithContainer:container nationality:nationality idCode:idCode phoneNo:phoneNo];
  [self postDataToPathWithXml:xmlRequest method:MoppLibNetworkRequestMethodMobileCreateSignature success:^(NSObject *responseObject) {
    success(responseObject);
  } andFailure:^(NSError *error) {
    failure(error);
  }];
}
@end
