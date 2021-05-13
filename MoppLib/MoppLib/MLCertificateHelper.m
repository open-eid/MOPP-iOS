//
//  MLCertificateHelper.m
//  MoppLib
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

#import "MLCertificateHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import "MoppLibDigidocManager.h"

@implementation MLCertificateHelper

+ (NSURLCredential *)getCredentialsFormCert {
  NSString *cert = [[MoppLibDigidocManager sharedInstance ] pkcs12Cert];
  NSString *certPath = [[NSBundle bundleForClass:self] pathForResource:[cert lastPathComponent] ofType:@""];
  NSData *p12Data = [NSData dataWithContentsOfFile:certPath];
  CFDataRef certDataRef = (__bridge_retained CFDataRef)p12Data;
  CFStringRef password = (__bridge CFStringRef)@"aPQ11ti4";
  SecIdentityRef identity = nil;
  SecCertificateRef certificate = nil;
  OSStatus status = extractIdentityAndTrust(certDataRef, password, &identity, nil);
  if (status != errSecSuccess || identity == nil) {
    NSLog(@"Failed to extract identity and trust: %d", (int)status);
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
