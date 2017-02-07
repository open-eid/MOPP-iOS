//
//  MoppLibNetworkManager.m
//  MoppLib
//
//  Created by Olev Abel on 2/2/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibNetworkManager.h"
#import "MoppLibError.h"
#import "MoppLibSOAPManager.h"


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
        [[MoppLibSOAPManager sharedInstance] processResultWithData:data method:method withSuccess:^(NSObject *responseObject) {
          success(responseObject);
        } andFailure:^(NSError *error) {
          failure(error);
        }];
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

- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container
                                  language:(NSString *)language
                                    idCode:(NSString *)idCode
                                   phoneNo:(NSString *)phoneNo
                               withSuccess:(ObjectSuccessBlock)success
                                andFailure:(FailureBlock)failure {
  NSString *xmlRequest = [[MoppLibSOAPManager sharedInstance] mobileCreateSignatureWithContainer:container language:language idCode:idCode phoneNo:phoneNo];
  [self postDataToPathWithXml:xmlRequest method:MoppLibNetworkRequestMethodMobileCreateSignature success:^(NSObject *responseObject) {
    success(responseObject);
  } andFailure:^(NSError *error) {
    failure(error);
  }];
}

- (void)getMobileCreateSignatureStatusWithSesscode:(NSString *)sessCode
                                       withSuccess:(ObjectSuccessBlock)success
                                        andFailure:(FailureBlock)failure {
  NSString *xmlRequest = [[MoppLibSOAPManager sharedInstance] getMobileCreateSignatureStatusWithSessCode:sessCode];
  [self postDataToPathWithXml:xmlRequest method:MoppLibNetworkRequestMethodMobileGetMobileCreateSignatureStatus success:^(NSObject *responseObject) {
    success(responseObject);
  } andFailure:^(NSError *error) {
    failure(error);
  }];
}
@end
