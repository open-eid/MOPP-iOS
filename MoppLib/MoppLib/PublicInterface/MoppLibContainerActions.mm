//
//  MoppLibContainerActions.m
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

#import "MoppLibContainerActions.h"
#import "MoppLibDigidocManager.h"
#import <CryptoLib/CryptoLib-Swift.h>
#import <MoppLib/MoppLib-Swift.h>

#include <digidocpp/Conf.h>
#include <digidocpp/Container.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/X509Cert.h>

@interface MoppLibError (digidocpp)
+ (void)setException:(const digidoc::Exception &)exception toError:(NSError**)error;
@end

struct DigiDocConf final: public digidoc::ConfCurrent {
    std::string TSLCache() const final {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *tslCachePath = [paths objectAtIndex:0];
        return tslCachePath.UTF8String;
    }

    std::string TSLUrl() const final {
        if (MoppLibConfiguration.tslURL) {
            return MoppLibConfiguration.tslURL.UTF8String;
        }
        return digidoc::ConfCurrent::TSLUrl();
    }

    std::vector<digidoc::X509Cert> TSLCerts() const final {
        if (MoppLibConfiguration.tslCerts) {
            return toX509Certs(MoppLibConfiguration.tslCerts);
        }
        return digidoc::ConfCurrent::TSLCerts();
    }

    std::string TSUrl() const final {
        if (NSString *tsaUrl = [NSUserDefaults.standardUserDefaults stringForKey:@"kTimestampUrlKey"]; tsaUrl.length != 0) {
            return tsaUrl.UTF8String;
        }
        if (MoppLibConfiguration.tsaURL.UTF8String) {
            return MoppLibConfiguration.tsaURL.UTF8String;
        }
        return digidoc::ConfCurrent::TSUrl();
    }

    std::vector<digidoc::X509Cert> TSCerts() const final {
        if (MoppLibConfiguration.certBundle || MoppLibConfiguration.tsaCert) {
            return toX509Certs(MoppLibConfiguration.certBundle, MoppLibConfiguration.tsaCert);
        }
        return digidoc::ConfCurrent::TSCerts();
    }

    std::string verifyServiceUri() const final {
        if (NSString *sivaUrl = [NSUserDefaults.standardUserDefaults stringForKey:@"kSivaUrl"]; sivaUrl.length != 0) {
            return sivaUrl.UTF8String;
        }
        if (MoppLibConfiguration.sivaURL) {
            return MoppLibConfiguration.sivaURL.UTF8String;
        }
        return digidoc::ConfCurrent::verifyServiceUri();
    }

    std::vector<digidoc::X509Cert> verifyServiceCerts() const final {
        if (MoppLibConfiguration.certBundle || MoppLibConfiguration.sivaCert) {
            return toX509Certs(MoppLibConfiguration.certBundle, MoppLibConfiguration.sivaCert);
        }
        return digidoc::ConfCurrent::verifyServiceCerts();
    }

    std::string ocsp(const std::string &issuer) const final {
        NSString *ocspIssuer = [NSString stringWithUTF8String:issuer.c_str()];
        if (NSString *url = MoppLibConfiguration.ocspIssuers[ocspIssuer]) {
            printLog(@"Using issuer: '%@' with OCSP url from central configuration: %@", ocspIssuer, url);
            return url.UTF8String;
        }
        printLog(@"Did not find url for issuer: %@.", ocspIssuer);
        return digidoc::ConfCurrent::ocsp(issuer);
    }

    std::string proxyHost() const final {
        if (NSString *host = [NSUserDefaults.standardUserDefaults stringForKey:@"kProxyHost"]) {
            return host.UTF8String;
        }
        return {};
    }

    std::string proxyPort() const final {
        NSInteger port = [NSUserDefaults.standardUserDefaults integerForKey:@"kProxyPort"];
        return std::to_string(port);
    }

    std::string proxyUser() const final {
        if (NSString *user = [NSUserDefaults.standardUserDefaults stringForKey:@"kProxyUsername"]) {
            return user.UTF8String;
        }
        return {};
    }

    std::string proxyPass() const final {
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: NSBundle.mainBundle.bundleIdentifier,
            (__bridge id)kSecAttrAccount: [NSString stringWithFormat:@"%@.proxyPasswordKey", NSBundle.mainBundle.bundleIdentifier],
            (__bridge id)kSecReturnData: @YES,
            (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
        };

        CFTypeRef infoData = nullptr;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &infoData);
        if (status == errSecSuccess && infoData != nullptr) {
            if (NSData *password = CFBridgingRelease(infoData)) {
                return {(const char*)password.bytes, password.length};
            }
        }
        return {};
    }

    std::vector<digidoc::X509Cert> toX509Certs(NSArray<NSData*> *certBundle, NSURL *cert = nil) const {
        std::vector<digidoc::X509Cert> x509Certs;
        auto add = [&x509Certs](NSData *data) {
            try {
                bool isPEM = std::string_view(reinterpret_cast<const char*>(data.bytes), data.length)
                    .starts_with("-----BEGIN CERTIFICATE-----");
                auto bytes = reinterpret_cast<const unsigned char*>(data.bytes);
                x509Certs.emplace_back(bytes, data.length, isPEM ? digidoc::X509Cert::Pem : digidoc::X509Cert::Der);
            } catch (const digidoc::Exception &e) {
                printLog(@"Unable to generate a X509 certificate object. Code: %u, message: %s", e.code(), e.msg().c_str());
            }
        };
        for (NSData *data in certBundle) {
            add(data);
        }
        if (cert) {
            add([NSData dataWithContentsOfURL:cert]);
        }
        return x509Certs;
    }

    bool isDebugMode() const {
        return [NSUserDefaults.standardUserDefaults boolForKey:@"isDebugMode"];
    }

    bool isLoggingEnabled() const {
        return [NSUserDefaults.standardUserDefaults boolForKey:@"kIsFileLoggingEnabled"];
    }

    // Comment in / out to see / hide libdigidocpp logs
    // Currently enabled on DEBUG mode

    int logLevel() const final {
        if (isDebugMode() || isLoggingEnabled()) {
            return 4;
        } else {
            return 0;
        }
    }

    std::string logFile() const final {
        if (!isDebugMode() && !isLoggingEnabled()) {
            return {};
        }
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheDirectory = [paths objectAtIndex:0];
        NSString *logsPath = [cacheDirectory stringByAppendingPathComponent:@"logs"];
        BOOL isDirectory = NO;
        if ([NSFileManager.defaultManager fileExistsAtPath:logsPath isDirectory:&isDirectory] && isDirectory) {
            return logFileLocation(logsPath);
        }
        // Create folder 'logs' in Library/Cache directory
        NSError* error;
        if ([NSFileManager.defaultManager createDirectoryAtPath:logsPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            return logFileLocation(logsPath);
        }
        printLog(@"createFolder error: %@", error);
        // Save log files to 'Library/Cache' directory if creating 'logs' folder was unsuccessful
        return logFileLocation(cacheDirectory);
    }

    std::string logFileLocation(NSString *logsFolderPath) const {
        return [logsFolderPath stringByAppendingPathComponent:@"libdigidocpp.log"].UTF8String;
    }
};

@implementation MoppLibContainerActions

+ (BOOL)setup:(NSError **)error; {
    // Initialize libdigidocpp.
    try {
        digidoc::Conf::init(new DigiDocConf);
        std::string appInfo = MoppLibManager.userAgent.UTF8String;
        digidoc::initialize(appInfo, appInfo);
        return YES;
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
        return NO;
    }
}

+ (NSString *)libdigidocppVersion {
    return [NSString stringWithUTF8String:digidoc::version().c_str()];
}

+ (MoppLibContainerActions *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibContainerActions *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)openContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure {

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] getContainerWithPath:containerPath error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
        error == nil ? success(container) : failure(error);
    });
  });
}

- (MoppLibContainer *)openContainerWithPath:(NSString *)containerPath error:(NSError **)error {
    return [[MoppLibDigidocManager sharedInstance] getContainerWithPath:containerPath error:error];
}

- (void)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] createContainerWithPath:containerPath withDataFilePaths:dataFilePaths error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      error == nil ? success(container) : failure(error);
    });
  });
  
}

- (void)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] addDataFilesToContainerWithPath:containerPath withDataFilePaths:dataFilePaths error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      error == nil ? success(container) : failure(error);
    });
  });
  
}

- (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] removeDataFileFromContainerWithPath:containerPath atIndex:dataFileIndex error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
        error == nil ? success(container) : failure(error);
    });
  });
  
}

- (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] removeSignature:moppSignature fromContainerWithPath:containerPath error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      error == nil ? success(container) : failure(error);
    });
  });
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [[MoppLibDigidocManager sharedInstance] container:containerPath saveDataFile:fileName to:path success:^{
          dispatch_async(dispatch_get_main_queue(), ^{
            success();
          });
      } failure:^(NSError *error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
          });
      }];
    
  });
}

+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData error:(NSError **)error {
    return [MoppLibDigidocManager prepareSignature:cert containerPath:containerPath roleData:roleData error:error];
}

+ (BOOL)isSignatureValid:(NSData *)signatureValue error:(NSError**)error {
    return [MoppLibDigidocManager isSignatureValid:signatureValue error:error];
}

@end
