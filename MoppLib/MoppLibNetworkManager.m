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
#import "MoppLibPrivateConstants.h"
#import "MOPPLibConfiguration.h"

@interface MoppLibNetworkManager ()

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSMutableData *receivedData;

@property (nonatomic, retain) NSMutableArray<NSString *> *testData;

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
 // NSError *error;
  
  BOOL useTestDDS = MoppLibSOAPManager.sharedInstance.useTestDigiDocService;
  NSURL *url = [NSURL URLWithString:(useTestDDS ? PrivateConstants.getCentralConfigurationFromCache[@"MID-SIGN-TEST-URL"] : PrivateConstants.getCentralConfigurationFromCache[@"MID-SIGN-URL"])];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  NSData *requestBodyData = [xmlBody dataUsingEncoding:NSUTF8StringEncoding];
  [request setURL:url];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"gzip,deflate" forHTTPHeaderField:@"Accept-Encoding"];
  [request setHTTPBody:requestBodyData];
  return [request copy];
}

/**
* Method used when using test ID-cards with test configuration.
*
* @param userData - Must include Mobile-ID user's "idCode", "phoneNo" and "language".
*
*/
- (void)postDataToTestPathWithXml:(NSString *)xmlBody userData:(NSDictionary *)userData method:(MoppLibNetworkRequestMethod)method success:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure {
    
    NSData *requestBodyData = [xmlBody dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *headers = @{ @"Content-Type": @"text/xml",
                               @"Accept-Encoding": @"gzip,deflate" };
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?IDCode=%@&PhoneNo=%@&Language=%@&ServiceName=%@&MessagingMode=%@", PrivateConstants.getCentralConfigurationFromCache[@"MID-SIGN-TEST-URL"], userData[@"idCode"], userData[@"phoneNo"], userData[@"language"], kTestServiceNames, kMessagingModes]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:requestBodyData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        MLLog(@"Request : %@", request);
        [self postDataRequest:data method:method response:response error:error success:^(NSObject *responseObject) {
            success(responseObject);
        } andFailure:^(NSError *error) {
            failure(error);
        }];
    }];
    [dataTask resume];
}

- (void)postDataToPathWithXml:(NSString *)xmlBody method:(MoppLibNetworkRequestMethod)method success:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure {
    
    NSURLRequest *request = [self requestWithXMLBody:xmlBody];
    
    NSURLSessionTask *dataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        MLLog(@"Request : %@", request);
        [self postDataRequest:data method:method response:response error:error success:^(NSObject *responseObject) {
            success(responseObject);
        } andFailure:^(NSError *error) {
            failure(error);
        }];
    }];
    [dataTask resume];
}

- (void)postDataRequest:(NSData * _Nullable)data method:(MoppLibNetworkRequestMethod)method response:(NSURLResponse * _Nullable)response error:(NSError * _Nullable)error success:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure {
    if (!error) {
        NSInteger statusCode = [(NSHTTPURLResponse *) response statusCode];
        if (statusCode != 401) {
            //  NSError *resultError;
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
}

- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container
                                  language:(NSString *)language
                                    idCode:(NSString *)idCode
                                   phoneNo:(NSString *)phoneNo
                               withSuccess:(ObjectSuccessBlock)success
                                andFailure:(FailureBlock)failure {
    NSString *xmlRequest = [[MoppLibSOAPManager sharedInstance] mobileCreateSignatureWithContainer:container language:language idCode:idCode phoneNo:phoneNo];
    if (MoppLibSOAPManager.sharedInstance.useTestDigiDocService) {
        self.testData = [[NSMutableArray alloc] init];
        [self.testData addObject:idCode];
        [self.testData addObject:phoneNo];
        [self.testData addObject:language];
        NSDictionary *testUserData = @{ @"idCode": self.testData[0], @"phoneNo": self.testData[1], @"language": self.testData[2] };
        [self postDataToTestPathWithXml:xmlRequest userData:testUserData method:MoppLibNetworkRequestMethodMobileCreateSignature success:^(NSObject *responseObject) {
            success(responseObject);
        } andFailure:^(NSError *error) {
            failure(error);
        }];
    } else {
        [self postDataToPathWithXml:xmlRequest method:MoppLibNetworkRequestMethodMobileCreateSignature success:^(NSObject *responseObject) {
            success(responseObject);
        } andFailure:^(NSError *error) {
            failure(error);
        }];
    }
}

- (void)getMobileCreateSignatureStatusWithSesscode:(NSString *)sessCode
                                       withSuccess:(ObjectSuccessBlock)success
                                        andFailure:(FailureBlock)failure {
    NSString *xmlRequest = [[MoppLibSOAPManager sharedInstance] getMobileCreateSignatureStatusWithSessCode:sessCode];
    if (MoppLibSOAPManager.sharedInstance.useTestDigiDocService) {
        NSDictionary *testUserData = @{ @"idCode": self.testData[0], @"phoneNo": self.testData[1], @"language": self.testData[2] };
        [self postDataToTestPathWithXml:xmlRequest userData: testUserData method:MoppLibNetworkRequestMethodMobileGetMobileCreateSignatureStatus success:^(NSObject *responseObject) {
            success(responseObject);
        } andFailure:^(NSError *error) {
            failure(error);
        }];
    } else {
        [self postDataToPathWithXml:xmlRequest method:MoppLibNetworkRequestMethodMobileGetMobileCreateSignatureStatus success:^(NSObject *responseObject) {
            success(responseObject);
        } andFailure:^(NSError *error) {
            failure(error);
        }];
    }
}

- (BOOL)certificatePinningCheckedWith:(NSURLAuthenticationChallenge *)challenge {
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    if (SecTrustGetCertificateCount(serverTrust) == 0)
        return YES;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    NSMutableArray *policies = [NSMutableArray array];
    [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)challenge.protectionSpace.host)];
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);

    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    BOOL certificateIsValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
    
    NSString *certificateName = challenge.protectionSpace.host;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    NSString *pathToOldCert = [bundle pathForResource:certificateName ofType:@"cer"];
    NSData *oldLocalCertificate = [NSData dataWithContentsOfFile:pathToOldCert];
    
    NSString *pathToNewCert = [bundle pathForResource:[certificateName stringByAppendingString:@".new"] ofType:@"cer"];
    NSData *newLocalCertificate = [NSData dataWithContentsOfFile:pathToNewCert];
    
    return certificateIsValid && ([remoteCertificateData isEqualToData:oldLocalCertificate] || [remoteCertificateData isEqualToData:newLocalCertificate]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
  
    if ([self certificatePinningCheckedWith:challenge]) {
        NSURLCredential *credential = [MLCertificateHelper getCredentialsFormCert];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    }
}

@end
