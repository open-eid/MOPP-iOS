//
//  MLCertificateHelper.m
//  MoppLib
//
//  Created by Olev Abel on 2/13/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MLCertificateHelper.h"
#import <CommonCrypto/CommonDigest.h>


@implementation MLCertificateHelper

+ (NSURLCredential *)getCredentialsFormCert {
  NSString *certPath = [[NSBundle bundleForClass:self] pathForResource:@"sk878252" ofType:@"p12"];
  NSData *p12Data = [NSData dataWithContentsOfFile:certPath];
  CFDataRef certDataRef = (__bridge_retained CFDataRef)p12Data;
  CFStringRef password = (__bridge CFStringRef)@"aPQ11ti4";
  SecIdentityRef identity = nil;
  SecCertificateRef certificate = nil;
  OSStatus status = extractIdentityAndTrust(certDataRef, password, &identity, nil);
  if (status != errSecSuccess || identity == nil) {
    NSLog(@"Failed to exrtact identity and trust: %ld", status);
  } else {
    SecIdentityCopyCertificate(identity, &certificate);
  }
  const void *certs[] = {certificate};
  CFArrayRef certsArray = CFArrayCreate(NULL, certs, 1, NULL);
  NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray *)certsArray persistence:NSURLCredentialPersistenceForSession];
  if (identity) CFRelease(identity);
  if (certsArray) CFRelease(certsArray);
  if (certificate) CFRelease(certificate);
  return credential;
}
OSStatus extractIdentityAndTrust(CFDataRef inP12data, CFStringRef password, SecIdentityRef *identity, SecTrustRef *trust){
  OSStatus securityError = errSecSuccess;
  const void *keys[] = { kSecImportExportPassphrase };
  const void *values[] = { password };
  CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
  CFArrayRef items = nil;
  securityError = SecPKCS12Import(inP12data, options, &items);
  if (securityError == errSecSuccess) {
    CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
    if (identity && CFDictionaryGetValueIfPresent(myIdentityAndTrust, kSecImportItemIdentity, (const void **)identity)) {
      CFRetain(*identity);
    }
    if (trust && CFDictionaryGetValueIfPresent(myIdentityAndTrust, kSecImportItemTrust, (const void **)trust)) {
      CFRetain(*trust);
    }
  }
  if (options) {CFRelease(options);}
  if (items) {CFRelease(items);}
  return securityError;
}
@end
