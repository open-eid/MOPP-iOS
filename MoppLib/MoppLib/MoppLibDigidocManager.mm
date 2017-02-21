//
//  MoppLibDigidocManager.m
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/X509Cert.h>
#include <digidocpp/XmlConf.h>
#include <digidocpp/crypto/Signer.h>

#import "MoppLibDigidocManager.h"
#import "MoppLibDataFile.h"
#import "MLDateFormatter.h"
#import "MLFileManager.h"
#import "MoppLibError.h"
#import "CardActionsManager.h"

#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

@interface NSString (Digidoc)
+ (NSString*)stdstring:(const std::string&)str;
@end

@implementation NSString (Digidoc)
+ (NSString*)stdstring:(const std::string&)str {
    return str.empty() ? [NSString string] : [NSString stringWithUTF8String:str.c_str()];
}
@end

class DigiDocConf: public digidoc::ConfCurrent {
public:
  std::string TSLCache() const
  {
    NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
    //    NSLog(@"tslCachePath: %@", tslCachePath);
    return tslCachePath.UTF8String;
  }
  
  std::string xsdPath() const
  {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:@"schema" ofType:@""];
    return path.UTF8String;
  }
  
  virtual std::string PKCS12Cert() const {
    NSBundle *bundle = [NSBundle bundleForClass:[MoppLibDigidocManager class]];
    NSString *path = [bundle pathForResource:@"878252.p12" ofType:@""];
    return path.UTF8String;
  }
  
  // Comment in to see libdigidocpp logs
  /*virtual int logLevel() const {
   return 3;
   }*/
  
};


class WebSigner: public digidoc::Signer
{
public:
  WebSigner(const digidoc::X509Cert &cert): _cert(cert) {}
  
private:
  digidoc::X509Cert cert() const override { return _cert; }
  std::vector<unsigned char> sign(const std::string &, const std::vector<unsigned char> &) const override
  {
    // THROW("Not implemented");
    return std::vector<unsigned char>();
  }
  
  digidoc::X509Cert _cert;
};

class SmartID: public digidoc::Signer
{
    const NSString *m_url = @"https://rp-api.smart-id.com/v1";
    const NSData *UUID_ENCRYPTED = [[NSData alloc] initWithBase64EncodedString:@"k3S0bg/YQhrBPgWhLW6G6TbA6h3vdU8765lNFR3Fnu3isF/7/r0d+8z0ED85fXSVIzQLGTCR+coiy9vYhvcgmVLUmEMXtJDXNrFoI8qKxYmPH+t0dtao3PyDwGKez06pCfPCV1Vur6/NnTj6aJGeK3qMy8CEFWHF95trARNGaac=" options:0];
    NSString *m_UUID;
    mutable digidoc::X509Cert m_cert;
    mutable NSString *documentNR;
    UIAlertController *m_alert;
    mutable bool running = true;

public:
    SmartID(NSString *account, UIAlertController *alert): documentNR(account), m_alert(alert)
    {
        NSData *PKCS12Data = [NSData dataWithContentsOfFile:[NSString stdstring:digidoc::Conf::instance()->PKCS12Cert()]];
        NSDictionary *options = @{(__bridge NSString *)kSecImportExportPassphrase: [NSString stdstring:digidoc::Conf::instance()->PKCS12Pass()]};
        CFArrayRef items = nullptr;
        SecKeyRef privateKey = nullptr;
        if (SecPKCS12Import((__bridge CFDataRef)PKCS12Data, (__bridge CFDictionaryRef)options, &items) == errSecSuccess) {
            SecIdentityRef identity = SecIdentityRef(CFDictionaryGetValue(CFDictionaryRef(CFArrayGetValueAtIndex(items, 0)), kSecImportItemIdentity));
            SecIdentityCopyPrivateKey(identity, &privateKey);
        } else {
            NSLog(@"Failed to import PKCS12 certificate");
        }
        CFRelease(items);

        if (!privateKey) {
            NSLog(@"Failed to import PKCS12 certificate");
        }

        NSMutableData *UUID = [[NSMutableData alloc] initWithLength:SecKeyGetBlockSize(privateKey)];
        size_t size = UUID.length;
        SecKeyDecrypt(privateKey, kSecPaddingPKCS1, (const uint8_t*)UUID_ENCRYPTED.bytes, UUID_ENCRYPTED.length, (uint8_t*)UUID.mutableBytes, &size);
        UUID.length = size;
        m_UUID = [[NSString alloc] initWithData:UUID encoding:NSUTF8StringEncoding];
        if (privateKey) {
            CFRelease(privateKey);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [m_alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { running = false; }]];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * 60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            running = false;
            [m_alert dismissViewControllerAnimated:YES completion:nil];
        });

        m_cert = digidoc::X509Cert(sendRequest(
                                               [NSString stringWithFormat:@"%@/certificatechoice/document/%@", m_url, documentNR],
                                               @{
                                                 @"relyingPartyUUID": m_UUID,
                                                 @"relyingPartyName": @"DigiDoc3",
                                                 @"certificateLevel": @"ADVANCED",
                                                 }), digidoc::X509Cert::Der);
    }
    digidoc::X509Cert cert() const override
    {
        return m_cert;
    }

    std::vector<unsigned char> sign(const std::string &method, const std::vector<unsigned char> &digest) const override
    {
        NSString *digestMethod;
        if(method == "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")
            digestMethod = @"SHA256";
        else if(method == "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384")
            digestMethod = @"SHA384";
        else if(method == "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512")
            digestMethod = @"SHA512";
        else
            throw digidoc::Exception(__FILE__, __LINE__, "Unsupported digest method");

        std::vector<unsigned char> codeDigest(CC_SHA256_DIGEST_LENGTH);
        CC_SHA256(digest.data(), CC_LONG(digest.size()), codeDigest.data());
        int code = codeDigest[CC_SHA256_DIGEST_LENGTH - 2] << 8 | codeDigest[CC_SHA256_DIGEST_LENGTH - 1];
        dispatch_async(dispatch_get_main_queue(), ^{
            m_alert.message = [NSString stringWithFormat:@"Make sure verification code matches with one in phone screen\nVerification code: %04d", (code % 10000)];
        });

        return sendRequest(
                           [NSString stringWithFormat:@"%@/signature/document/%@", m_url, documentNR],
                           @{
                             @"relyingPartyUUID": m_UUID,
                             @"relyingPartyName": @"DigiDoc3",
                             @"certificateLevel": @"ADVANCED",
                             @"hash": [[NSData dataWithBytesNoCopy:(void*)digest.data() length:digest.size() freeWhenDone:NO] base64EncodedStringWithOptions:0],
                             @"hashType": digestMethod,
                             @"displayText": @"Sign document"
                             });
    }

    std::vector<unsigned char> sendRequest(NSString *url, NSDictionary *req) const
    {
        static const NSArray *contentType = @[@"application/json", @"application/json-rpc", @"application/json;charset=UTF-8"];
        NSDictionary *json;
        NSString *sessionID;
        NSError *error;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        while (true) {
            [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            if (req) {
                request.HTTPMethod = @"POST";
                request.HTTPBody = [NSJSONSerialization dataWithJSONObject:req options:NSJSONWritingPrettyPrinted error:&error];
                [request addValue:[NSString stringWithFormat:@"%d", int(request.HTTPBody.length)] forHTTPHeaderField:@"Content-Length"];
            }

            NSHTTPURLResponse *urlResponse;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];

            if (error) {
                throw digidoc::Exception(__FILE__, __LINE__, error.localizedDescription.UTF8String);
            }
            else if (urlResponse.statusCode == 404 && sessionID == nil) {
                throw digidoc::Exception(__FILE__, __LINE__, "Account not found");
            }
            else if (urlResponse.statusCode == 404 && sessionID != nil) {
                throw digidoc::Exception(__FILE__, __LINE__, "Request not found");
            }
            else if (urlResponse.statusCode != 200) {
                throw digidoc::Exception(__FILE__, __LINE__, (const char*)data.bytes);
            }
            else if (![contentType containsObject:urlResponse.allHeaderFields[@"Content-Type"]]) {
                throw digidoc::Exception(__FILE__, __LINE__, "Invalid Content-Type header");
            }
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if(!running) {
                digidoc::Exception e(__FILE__, __LINE__, "Signing canceled");
                e.setCode(digidoc::Exception::PINCanceled);
                throw e;
            }
            else if (error) {
                throw digidoc::Exception(__FILE__, __LINE__, error.localizedDescription.UTF8String);
            }
            else if (sessionID == nil) {
                sessionID = json[@"sessionID"];
                request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/session/%@?timeoutMs=10000", m_url, sessionID]]];
                req = nil;
            }
            else if ([json[@"state"] isEqualToString:@"RUNNING"]) {
                continue;
            }
            else if ([json objectForKey:@"signature"] != nil && json[@"signature"] != (id)[NSNull null]) {
                NSData *b64 = [[NSData alloc] initWithBase64EncodedString:json[@"signature"][@"value"] options:0];
                return std::vector<unsigned char>((const unsigned char*)b64.bytes, (const unsigned char*)b64.bytes + b64.length);
            }
            else if ([json objectForKey:@"cert"] != nil && json[@"cert"] != (id)[NSNull null]) {
                documentNR = json[@"result"][@"documentNumber"];
                NSData *b64 = [[NSData alloc] initWithBase64EncodedString:json[@"cert"][@"value"] options:0];
                return std::vector<unsigned char>((const unsigned char*)b64.bytes, (const unsigned char*)b64.bytes + b64.length);
            }
            else if([json[@"result"][@"endResult"] isEqualToString:@"USER_REFUSED"]) {
                digidoc::Exception e(__FILE__, __LINE__, "Signing canceled");
                e.setCode(digidoc::Exception::PINCanceled);
                throw e;
            }
            else {
                NSLog(@"Service result: %@", json[@"result"][@"endResult"]);
                throw digidoc::Exception(__FILE__, __LINE__, "Failed to sign container");
            }
        }
    }
};

@interface MoppLibDigidocManager ()
@end

@implementation MoppLibDigidocManager

+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure {
  
  // Copy initial TSL cache for libdigidocpp if needed.
  NSString *tslCachePath = [[MLFileManager sharedInstance] tslCachePath];
  NSString *eeTslCachePath = [NSString stringWithFormat:@"%@/EE.xml", tslCachePath];
  if (![[MLFileManager sharedInstance] fileExistsAtPath:eeTslCachePath]) {
    MLLog(@"Copy TSL cache: true");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *tslCache = @[[bundle pathForResource:@"EE" ofType:@"xml"],
                          [bundle pathForResource:@"FI" ofType:@"xml"],
                          [bundle pathForResource:@"tl-mp" ofType:@"xml"]];
    
    for (NSString *sourcePath in tslCache) {
      NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", tslCachePath, [sourcePath lastPathComponent]];
      [[MLFileManager sharedInstance] copyFileWithPath:sourcePath toPath:destinationPath];
    }
  } else {
    MLLog(@"Copy TSL cache: false");
  }
  
  
  // Initialize libdigidocpp.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    try {
      digidoc::Conf::init(new DigiDocConf);
      digidoc::initialize();
      
      dispatch_async(dispatch_get_main_queue(), ^{
        success();
      });
    } catch(const digidoc::Exception &e) {
      parseException(e);
      
      dispatch_async(dispatch_get_main_queue(), ^{
        failure(nil);
      });
    }
  });
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath {
  
  // Having two container instances of the same file is causing crashes. Should synchronize all container operations?
  @synchronized (self) {
    
    MoppLibContainer *moppLibContainer = [MoppLibContainer new];
    
    [moppLibContainer setFileName:[containerPath lastPathComponent]];
    [moppLibContainer setFilePath:containerPath];
    [moppLibContainer setFileAttributes:[[MLFileManager sharedInstance] fileAttributes:containerPath]];
    
    digidoc::Container *doc;
    try {
      
      doc = digidoc::Container::open(containerPath.UTF8String);
      
      // DataFiles
      NSMutableArray *dataFiles = [NSMutableArray array];
      
      for (int i = 0; i < doc->dataFiles().size(); i++) {
        digidoc::DataFile *dataFile = doc->dataFiles().at(i);
        
        MoppLibDataFile *moppLibDataFile = [MoppLibDataFile new];
        moppLibDataFile.fileId = [NSString stringWithUTF8String:dataFile->id().c_str()];
        moppLibDataFile.mediaType = [NSString stringWithUTF8String:dataFile->mediaType().c_str()];
        moppLibDataFile.fileName = [NSString stringWithUTF8String:dataFile->fileName().c_str()];
        moppLibDataFile.fileSize = dataFile->fileSize();
        
        [dataFiles addObject:moppLibDataFile];
      }
      moppLibContainer.dataFiles = [dataFiles copy];
      
      
      // Signatures
      NSMutableArray *signatures = [NSMutableArray array];
      for (int i = 0; i < doc->signatures().size(); i++) {
        digidoc::Signature *signature = doc->signatures().at(i);
        digidoc::X509Cert cert = signature->signingCertificate();
        //      NSLog(@"Signature: %@", [NSString stringWithUTF8String:cert.subjectName("CN").c_str()]);
        
        MoppLibSignature *moppLibSignature = [MoppLibSignature new];
        
        std::string name  = cert.subjectName("CN");
        if (name.length() <= 0) {
          name = signature->signedBy();
        }
        moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];
        
        std::string timestamp = signature->OCSPProducedAt();
        if (timestamp.length() <= 0) {
          timestamp = signature->trustedSigningTime();
        }
        
        moppLibSignature.timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:timestamp.c_str()]];
        
        try {
          signature->validate();
          moppLibSignature.isValid = YES;
        } catch(const digidoc::Exception &e) {
          parseException(e);
          moppLibSignature.isValid = NO;
        }
        
        [signatures addObject:moppLibSignature];
      }
      moppLibContainer.signatures = [signatures copy];
      delete doc;
      return moppLibContainer;
      
    } catch(const digidoc::Exception &e) {
      parseException(e);
      delete doc;
      return nil;
    }
    
  }
}
- (NSString *)dataFileCalculateHashWithDigestMethod:(NSString *)method container:(MoppLibContainer *)moppContainer dataFileId:(NSString *)dataFileId {
  MLLog(@"dataFileCalculateHashWithDigestMehtod %@", method);
  digidoc::Container *container;
  try {
    container = digidoc::Container::open(moppContainer.filePath.UTF8String);
    for (int i = 0; i < container->dataFiles().size(); i ++) {
      digidoc::DataFile *dataFile = container->dataFiles().at(i);
      NSString *currentId = [NSString stringWithUTF8String:dataFile->id().c_str()];
      if ([currentId isEqualToString:dataFileId]) {
        NSData * data = [NSData dataWithBytes:dataFile->calcDigest([method UTF8String]).data() length:dataFile->calcDigest([method UTF8String]).size()];
        delete container;
        return [data base64EncodedStringWithOptions:0];
      }
    }
  } catch (const digidoc::Exception &e) {
    parseException(e);
  }
  delete container;
  return nil;
}
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  MLLog(@"createContainerWithPath: %@, dataFilePath: %@", containerPath, dataFilePath);
  
  digidoc::Container *container;
  try {
    
    container = digidoc::Container::create(containerPath.UTF8String);
    container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  delete container;
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  digidoc::Container *container;
  try {
    
    container = digidoc::Container::open(containerPath.UTF8String);
    container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  delete container;
  return moppLibContainer;
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex {
  digidoc::Container *container;
  try {
    
    container = digidoc::Container::open(containerPath.UTF8String);
    container->removeDataFile(dataFileIndex);
    
    try {
      container->save(containerPath.UTF8String);
    } catch(const digidoc::Exception &e) {
      parseException(e);
    }
    
  } catch(const digidoc::Exception &e) {
    parseException(e);
  }
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  delete container;
  return moppLibContainer;
}

- (NSArray *)getContainersIsSigned:(BOOL)isSigned {
  
  NSMutableArray *containers = [NSMutableArray array];
  NSArray *containerPaths = [[MLFileManager sharedInstance] getContainers];
  for (NSString *containerPath in containerPaths) {
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
    
    if (isSigned && [moppLibContainer isSigned]) {
      [containers addObject:moppLibContainer];
    } else if (!isSigned && ![moppLibContainer isSigned]){
      [containers addObject:moppLibContainer];
    }
  }
  return containers;
}

void parseException(const digidoc::Exception &e) {
  NSLog(@"%s", e.msg().c_str());
  for (const digidoc::Exception &ex : e.causes()) {
    parseException(ex);
  }
}

- (void)addSignature:(MoppLibContainer *)moppContainer pin2:(NSString *)pin2 cert:(NSData *)cert success:(ContainerBlock)success andFailure:(FailureBlock)failure {
  digidoc::Container *doc;
  
  try {
    const unsigned char *bytes = (const unsigned  char *)[cert bytes];
    digidoc::X509Cert x509Cert = digidoc::X509Cert(bytes, cert.length, digidoc::X509Cert::Format::Der);
    
    doc = digidoc::Container::open(moppContainer.filePath.UTF8String);
    
    // Checking if signature with same certificate already exists
    for (int i = 0; i < doc->signatures().size(); i++) {
      digidoc::Signature *signature = doc->signatures().at(i);
      
      digidoc::X509Cert signatureCert = signature->signingCertificate();
      
      if (x509Cert == signatureCert) {
        delete doc;
        failure([MoppLibError signatureAlreadyExistsError]);
        return;
      }
    }
    
    WebSigner *signer = new WebSigner(x509Cert);
    
    std::string profile;
    if (doc->signatures().size() > 0) {
      std::string containerProfile = doc->signatures().at(0)->profile();
      
      if (containerProfile.find("time-stamp") != std::string::npos) {
        profile = "time-stamp";
      } else if (containerProfile.find("time-mark") != std::string::npos) {
        profile = "time-mark";
      }
    } else {
      // No signatures. bdoc should use time-mark
      if ([[moppContainer.filePath pathExtension] isEqualToString:@"bdoc"]) {
        profile = "time-mark";
      }
    }
    
    if (profile.length() <= 0) {
      profile = "time-stamp";
    }
    
    signer->setProfile(profile);
    signer->setSignatureProductionPlace("", "", "", "");
    signer->setSignerRoles(std::vector<std::string>());
    
    digidoc::Signature *signature = doc->prepareSignature(signer);
    std::vector<unsigned char> dataToSign = signature->dataToSign();
    
    [[CardActionsManager sharedInstance] calculateSignatureFor:[NSData dataWithBytes:dataToSign.data() length:dataToSign.size()] pin2:pin2 controller:nil success:^(NSData *calculatedSignature) {
      try {
        unsigned char *buffer = (unsigned char *)[calculatedSignature bytes];
        std::vector<unsigned char>::size_type size = calculatedSignature.length;
        std::vector<unsigned char> vec(buffer, buffer + size);
        
        signature->setSignatureValue(vec);
        signature->extendSignatureProfile(profile);
        signature->validate();
        doc->save();
        MoppLibContainer *moppLibContainer = [self getContainerWithPath:moppContainer.filePath];
        success(moppLibContainer);
        delete doc;
      } catch(const digidoc::Exception &e) {
        parseException(e);
        delete doc;
        failure([MoppLibError generalError]); // TODO try to find more specific error codes
      }
    } failure:^(NSError *error) {
      delete doc;
      failure(error);
    }];
    
    
  } catch(const digidoc::Exception &e) {
    delete doc;
    parseException(e);
    failure([MoppLibError generalError]);  // TODO try to find more specific error codes
  }
}

- (void)addSignature:(MoppLibContainer *)moppContainer controller:(UIAlertController*)alert smartID:(NSString *)account success:(ContainerBlock)success andFailure:(FailureBlock)failure {

    try {
        std::unique_ptr<digidoc::Container> doc(digidoc::Container::open(moppContainer.filePath.UTF8String));
        SmartID *signer = new SmartID(account, alert);
        doc->sign(signer)->validate();
        doc->save();
        success([self getContainerWithPath:moppContainer.filePath]);
    } catch(const digidoc::Exception &e) {
        parseException(e);
        failure([MoppLibError generalError]);  // TODO try to find more specific error codes
    }
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath {
  digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);
  for (int i = 0; i < doc->signatures().size(); i++) {
    digidoc::Signature *signature = doc->signatures().at(i);
    digidoc::X509Cert cert = signature->signingCertificate();
    NSString *name = [NSString stringWithUTF8String:cert.subjectName("CN").c_str()];
    if ([name isEqualToString:[moppSignature subjectName]]) {
      NSDate *timestamp = [[MLDateFormatter sharedInstance] YYYYMMddTHHmmssZToDate:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
      if ([[moppSignature timestamp] compare:timestamp] == NSOrderedSame) {
        try {
          doc->removeSignature(i);
          doc->save(containerPath.UTF8String);
        } catch(const digidoc::Exception &e) {
          parseException(e);
        }
        break;
      }
    }
  }
  delete doc;
  
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath];
  return moppLibContainer;
}

- (NSString *)getMoppLibVersion {
  NSMutableString *resultString = [[NSMutableString alloc] initWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
  [resultString appendString:[NSString stringWithFormat:@".%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
  return resultString;
}


- (void)addMobileIDSignatureToContainer:(MoppLibContainer *)moppContainer
                              signature:(NSString *)signature
                                success:(ContainerBlock)success
                             andFailure:(FailureBlock)failure {
  digidoc::Container *container;
  try {
    container = digidoc::Container::open(moppContainer.filePath.UTF8String);
    NSData *data = [signature dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char bytes[[data length]];
    [data getBytes:bytes length:data.length];
    std::vector<unsigned char> signatureVector(bytes, bytes + data.length);
    container->addAdESSignature(signatureVector);
    container->save();
    MLLog(@"Mobile ID signature added");
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:moppContainer.filePath];
    success(moppLibContainer);
  } catch(const digidoc::Exception &e) {
    parseException(e);
    failure([MoppLibError generalError]);
  }
  delete container;
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path {
  digidoc::Container *doc = digidoc::Container::open(containerPath.UTF8String);
  
  for (int i = 0; i < doc->dataFiles().size(); i++) {
    digidoc::DataFile *dataFile = doc->dataFiles().at(i);
    
    if([fileName isEqualToString:[NSString stringWithUTF8String:dataFile->fileName().c_str()]]) {
      dataFile->saveAs(path.UTF8String);
      break;
    }
  }
  delete doc;
  
}

@end
