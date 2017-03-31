//
//  MoppLibNetworkManager.m
//  MoppLib
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

#import "MoppLibNetworkManager.h"
#import "MoppLibError.h"
#import "MoppLibSOAPManager.h"
#import "MLCertificateHelper.h"
#import "NSString+Additions.h"

@interface MoppLibNetworkManager ()

@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) NSMutableData *receivedData;

@end

@implementation MoppLibNetworkManager

+ (MoppLibNetworkManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibNetworkManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    [sharedInstance setUrlSession:[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:sharedInstance delegateQueue:nil]];
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
  
  NSURLSessionTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    MLLog(@"Request : %@", request);
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
  NSURLCredential *creds = [MLCertificateHelper getCredentialsFormCert];
  completionHandler(NSURLSessionAuthChallengeUseCredential, creds);
}

@end
