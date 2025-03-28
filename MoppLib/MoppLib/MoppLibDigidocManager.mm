//
//  MoppLibDigidocManager.m
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

#import "MoppLibDigidocManager.h"
#import "MoppLibConfiguration.h"
#import "MoppLibContainer.h"
#import "MoppLibDataFile.h"
#import "MoppLibProxyConfiguration.h"
#import "MoppLibRoleAddressData.h"
#import "MoppLibSignature.h"
#import <CryptoLib/CryptoLib-Swift.h>
#import <MoppLib/MoppLib-Swift.h>

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/XmlConf.h>
#include <digidocpp/crypto/Signer.h>
#include <digidocpp/crypto/X509Cert.h>


class DigiDocConf: public digidoc::ConfCurrent {

private:
  MoppLibConfiguration *moppLibConfiguration;
  MoppLibProxyConfiguration *proxyConfiguration;

public:

    DigiDocConf(MoppLibConfiguration* moppConfiguration, MoppLibProxyConfiguration* proxyConfiguration)
        : moppLibConfiguration(moppConfiguration)
        , proxyConfiguration(proxyConfiguration)
    {}

    std::string TSLCache() const override {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *tslCachePath = [paths objectAtIndex:0];
        return tslCachePath.UTF8String;
    }

  std::string TSUrl() const override {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *tsaUrl = [defaults stringForKey:@"kTimestampUrlKey"];
      return [tsaUrl length] != 0 ? tsaUrl.UTF8String : moppLibConfiguration.TSAURL.UTF8String;
  }

  std::string verifyServiceUri() const override {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *sivaUrl = [defaults stringForKey:@"kSivaUrl"];
      NSString *usingSivaUrl = [sivaUrl length] != 0 ? sivaUrl : moppLibConfiguration.SIVAURL;
      printLog(@"Using SiVa URL: %@", usingSivaUrl);
      NSLog(@"Using SiVa URL: %@", usingSivaUrl);
      return [sivaUrl length] != 0 ? sivaUrl.UTF8String : moppLibConfiguration.SIVAURL.UTF8String;
  }

  std::vector<digidoc::X509Cert> TSLCerts() const override {
      return stringsToX509Certs(moppLibConfiguration.TSLCERTS);
  }

  std::string TSLUrl() const override {
      return moppLibConfiguration.TSLURL.UTF8String;
  }
    
  std::vector<digidoc::X509Cert> TSCerts() const override {
      NSMutableArray<NSString *> *certBundle = [NSMutableArray arrayWithArray:moppLibConfiguration.CERTBUNDLE];
      if (moppLibConfiguration.TSACERT != NULL) {
          [certBundle addObject:moppLibConfiguration.TSACERT];
      }
      return stringsToX509Certs(certBundle);
  }

    virtual std::vector<digidoc::X509Cert> verifyServiceCerts() const override {
        NSMutableArray<NSString*> *certs = [NSMutableArray arrayWithArray:moppLibConfiguration.CERTBUNDLE];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *sivaFileName = [defaults stringForKey:@"kSivaFileCertName"];
        if (!(sivaFileName == nil || [sivaFileName isEqualToString:@""])) {
            NSString *sivaCert = getSivaCert(sivaFileName);
            
            if (!(sivaCert == nil || [sivaCert isEqualToString:@""])) {
                // Remove certificate header, footer, whitespaces and newlines
                NSCharacterSet *characterSetToRemove = [NSCharacterSet characterSetWithCharactersInString:@" \n\r\t"];
                
                NSString * formattedSivaCert = [sivaCert stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
                formattedSivaCert = [formattedSivaCert stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
                formattedSivaCert = [[formattedSivaCert componentsSeparatedByCharactersInSet:characterSetToRemove] componentsJoinedByString:@""];
                
                [certs addObject:formattedSivaCert];
            }
        }
        
        return stringsToX509Certs(certs);
    }

  std::string ocsp(const std::string &issuer) const override {
    NSString *ocspIssuer = [NSString stringWithCString:issuer.c_str() encoding:[NSString defaultCStringEncoding]];
    if ([moppLibConfiguration.OCSPISSUERS objectForKey:ocspIssuer]) {
        printLog(@"Using issuer: '%@' with OCSP url from central configuration: %@", ocspIssuer, moppLibConfiguration.OCSPISSUERS[ocspIssuer]);
        return std::string([moppLibConfiguration.OCSPISSUERS[ocspIssuer] UTF8String]);
    }
    printLog(@"Did not find url for issuer: %@.", ocspIssuer);
    return digidoc::ConfCurrent::ocsp(issuer);
  }
    
    virtual std::string proxyHost() const override {
        NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"kProxyHost"];
        if (host == nil) {
            return std::string("");
        }
        return std::string([host UTF8String]);
    }
    
    virtual std::string proxyPort() const override {
        NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:@"kProxyPort"];
        return std::to_string(port);
    }
    
    virtual std::string proxyUser() const override {
        return std::string([proxyConfiguration.USERNAME UTF8String]);
    }
    
    virtual std::string proxyPass() const override {
        return std::string([proxyConfiguration.PASSWORD UTF8String]);
    }

    std::vector<digidoc::X509Cert> stringsToX509Certs(NSArray<NSString*> *certBundle) const {
        __block std::vector<digidoc::X509Cert> x509Certs;

        [certBundle enumerateObjectsUsingBlock:^(NSString* object, NSUInteger idx, BOOL *stop) {
            try {
                NSData *data = [[NSData alloc] initWithBase64EncodedString:object options:NSDataBase64DecodingIgnoreUnknownCharacters];
                auto bytes = reinterpret_cast<const unsigned char*>(data.bytes);
                x509Certs.emplace_back(bytes, data.length);
            } catch (const digidoc::Exception &e) {
                printLog(@"Unable to generate a X509 certificate object. Code: %u, message: %s", e.code(), e.msg().c_str());
            } catch(...) {
                printLog(@"Generating a X509 certificate object raised an exception!\n");
            }
        }];

        return x509Certs;
    }

    bool isDebugMode() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"isDebugMode"];
    }

    bool isLoggingEnabled() const {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"kIsFileLoggingEnabled"];
    }

    // Comment in / out to see / hide libdigidocpp logs
    // Currently enabled on DEBUG mode

    int logLevel() const override {
        if (isDebugMode() || isLoggingEnabled()) {
            return 4;
        } else {
            return 0;
        }
    }

    std::string logFile() const override {
        if (!isDebugMode() && !isLoggingEnabled()) {
            return std::string();
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

    NSString* getSivaCert(NSString *fileName) const {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths objectAtIndex:0];
        NSString *subfolderName = @"siva-cert";
        
        NSString *subfolderPath = [cachesDirectory stringByAppendingPathComponent:subfolderName];
        
        NSString *filePath = [subfolderPath stringByAppendingPathComponent:fileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *error = nil;
            NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            
            if (fileContents) {
                return fileContents;
            } else {
                NSLog(@"Error reading file '%@': %@", fileName, [error localizedDescription]);
                return nil;
            }
        } else {
            NSLog(@"File '%@' not found at path: %@", fileName, filePath);
            return nil;
        }
        return nil;
    }
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
    return {};
  }

  digidoc::X509Cert _cert;
};

struct MoppLibDigidocContainerOpenCB: public digidoc::ContainerOpenCB {
    bool validateOnline() const final {
        return MoppLibManager.shared.validateOnline;
    }
};


@interface MoppLibDigidocManager ()
    - (MoppLibSignatureStatus)determineSignatureStatus:(int) status;
@end

@implementation MoppLibDigidocManager

static std::unique_ptr<digidoc::Container> docContainer = nil;
static digidoc::Signature *signature = nil;
static std::unique_ptr<digidoc::Signer> signer{};

+ (MoppLibDigidocManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibDigidocManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure withMoppConfiguration:(MoppLibConfiguration*)moppConfiguration andProxyConfiguration:(MoppLibProxyConfiguration*)proxyConfiguration {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Initialize libdigidocpp.
        try {
            digidoc::Conf::init(new DigiDocConf(moppConfiguration, proxyConfiguration));
            std::string appInfo = MoppLibManager.userAgent.UTF8String;
            digidoc::initialize(appInfo, appInfo);
            dispatch_async(dispatch_get_main_queue(), success);
        } catch(const digidoc::Exception &e) {
            parseException(e);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = [NSError errorWithDomain:@"MoppLib" code:e.code() userInfo:@{@"message":[NSString stringWithUTF8String:e.msg().c_str()]}];
                failure(error);
            });
        }
    });
}

+ (digidoc::X509Cert)getCertFromData:(NSData *)data {
    return digidoc::X509Cert(reinterpret_cast<const unsigned char *>(data.bytes), data.length);
}

+ (void)isSignatureValid:(NSData *)cert signatureValue:(NSData *)data success:(VoidBlock)success failure:(FailureBlock)failure {
    auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
    std::vector<unsigned char> calculatedSignatureBase64(bytes, bytes + data.length);

    if (!signature) {
        std::string signatureId = signature->id();
        printLog(@"\nError: Did not find signature with an ID of %s\n", signatureId.c_str());
        NSError *signatureError;
        signatureError = [NSError errorWithDomain:[NSString stringWithFormat:@"Did not find signature with an ID of %s\n", signature->id().c_str()] code:-1 userInfo:nil];
        return failure(signatureError);
    }

    if (auto timeStampTime = signature->TimeStampTime(); !timeStampTime.empty()) {
        printLog(@"\nSignature already validated at %s\n", timeStampTime.c_str());
        return success();
    }

    try {
        printLog(@"\nStarting signature validation...\n");
        printLog(@"\nSetting signature value...\n");
        signature->setSignatureValue(calculatedSignatureBase64);
        printLog(@"\nExtending signature profile...\n");
        signature->extendSignatureProfile(signer.get());
        printLog(@"\nValidating signature...\n");
        digidoc::Signature::Validator validator(signature);
        printLog(@"\nValidator status: %u\n", validator.status());
        printLog(@"\nSaving container...\n");
        docContainer->save();
        printLog(@"\nSignature validated at %s!\n", signature->TimeStampTime().c_str());
        success();
    } catch(const digidoc::Exception &e) {
        parseException(e);
        NSError *error;
        NSString *signatureId = [NSString stringWithCString:signature->id().c_str() encoding:[NSString defaultCStringEncoding]];
        [self removeSignature:docContainer.get() signatureId:signatureId error:&error];
        printLog(@"\nError validating signature: %s\n", e.msg().c_str());
        NSError *validationError;
        validationError = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
        failure(validationError);
    }
}

+ (void)removeSignature:(digidoc::Container *)container signatureId:(NSString *)signatureId error:(NSError **)error {

    const char *signatureIdUTF8 = signatureId.UTF8String;
    for (int i = 0; i < container->signatures().size(); i++) {
        digidoc::Signature *signature = container->signatures().at(i);
        try {
            if (signature->id() == signatureIdUTF8) {
                container->removeSignature(i);
                container->save();
                break;
            }
        } catch(const digidoc::Exception &e) {
            parseException(e);
            *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
            break;
        }
    }
}

+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData {
    digidoc::X509Cert x509Cert;

    try {
        x509Cert = [self getCertFromData:cert];
    } catch (const digidoc::Exception &e) {
        parseException(e);
        return nil;
    }

    docContainer.reset();
    signature = NULL;
    signer = std::make_unique<WebSigner>(x509Cert);

    try {
        MoppLibDigidocContainerOpenCB cb;
        docContainer = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    } catch(const digidoc::Exception &e) {
        parseException(e);
        return nil;
    }

    NSLog(@"\nSetting profile info...\n");
    NSLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
    signer->setProfile("time-stamp");
    signer->setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
    signer->setUserAgent(MoppLibManager.userAgent.UTF8String);

    std::vector<std::string> roles;
    for (NSString *role in roleData.ROLES) {
        if (role != (id)[NSNull null] && [role length] != 0) {
            roles.push_back(std::string([role UTF8String] ?: ""));
        }
    }
    
    signer->setSignerRoles(roles);
    NSLog(@"\nProfile info set successfully\n");
    
    NSLog(@"\nSetting signature...\n");
    signature = docContainer->prepareSignature(signer.get());
    printLog(@"\nSignature ID set to %s...\n", signature->id().c_str());

    std::vector<unsigned char> dataToSign = signature->dataToSign();
    return [NSData dataWithBytes:dataToSign.data() length:dataToSign.size()];
}

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error {

  // Having two container instances of the same file is causing crashes. Should synchronize all container operations?
  @synchronized (self) {

    MoppLibContainer *moppLibContainer = [MoppLibContainer new];

    [moppLibContainer setFileName:[containerPath lastPathComponent]];
    [moppLibContainer setFilePath:containerPath];

    std::unique_ptr<digidoc::Container> doc;
    try {
      MoppLibDigidocContainerOpenCB cb;
      doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    } catch(const digidoc::Exception &e) {
      parseException(e);

      if (e.code() == 63) {
          *error = [MoppLibError fileNameTooLongError];
      } else if (e.code() == digidoc::Exception::NetworkError) {
          if (e.msg().starts_with("Failed to create ssl connection with host")) {
              *error = [MoppLibError sslHandshakeError];
          } else {
              *error = [MoppLibError noInternetConnectionError];
          }
      } else {
          *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
      }
      return nil;
    }
    try {
      // DataFiles
      NSMutableArray *dataFiles = [NSMutableArray array];

      for (digidoc::DataFile *dataFile: doc->dataFiles()) {
        MoppLibDataFile *moppLibDataFile = [MoppLibDataFile new];
        moppLibDataFile.fileId = [NSString stringWithUTF8String:dataFile->id().c_str()];
        moppLibDataFile.mediaType = [NSString stringWithUTF8String:dataFile->mediaType().c_str()];
        moppLibDataFile.fileName = [NSString stringWithUTF8String:dataFile->fileName().c_str()];
        moppLibDataFile.fileSize = dataFile->fileSize();
        [dataFiles addObject:moppLibDataFile];
      }
      moppLibContainer.dataFiles = dataFiles;


      // Signatures
      NSMutableArray *signatures = [NSMutableArray array];
      // Timestamp tokens
      NSMutableArray *timeStampTokens = [NSMutableArray array];
      for (digidoc::Signature *signature: doc->signatures()) {
        [signatures addObject:[self getSignatureData:signature->signingCertificate() signature:signature mediaType:doc->mediaType() dataFileCount:doc->dataFiles().size()]];
          [timeStampTokens addObject:[self getSignatureData:signature->TimeStampCertificate() signature:signature mediaType:doc->mediaType() dataFileCount:doc->dataFiles().size()]];
      }

      moppLibContainer.signatures = [signatures copy];
      moppLibContainer.timestampTokens = [timeStampTokens copy];
      return moppLibContainer;

    } catch(const digidoc::Exception &e) {
      parseException(e);
      *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
      return nil;
    }
  }
}

- (MoppLibSignature *)getSignatureData:(const digidoc::X509Cert&)cert signature:(digidoc::Signature *)signature mediaType:(const std::string&)mediaType dataFileCount:(NSInteger)dataFileCount {

    digidoc::X509Cert signingCert = signature->signingCertificate();
    digidoc::X509Cert ocspCert = signature->OCSPCertificate();
    digidoc::X509Cert timestampCert = signature->TimeStampCertificate();

    std::string givename = cert.subjectName("GN");
    std::string surname = cert.subjectName("SN");
    std::string serialNR = [self getSerialNumber:cert.subjectName("serialNumber")];

    std::string name = givename.empty() || surname.empty() ? cert.subjectName("CN") :
        surname + ", " + givename + ", " + serialNR;
    if (name.empty()) {
        name = signature->signedBy();
    }

    MoppLibSignature *moppLibSignature = [MoppLibSignature new];
    moppLibSignature.trustedSigningTime = [NSString stringWithUTF8String:signature->trustedSigningTime().c_str()];
    moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];

    moppLibSignature.signersCertificateIssuer = [NSString stringWithUTF8String:signingCert.issuerName("CN").c_str()];
    moppLibSignature.issuerName = [NSString stringWithCString:signingCert.issuerName().c_str() encoding:[NSString defaultCStringEncoding]];
    moppLibSignature.signingCertificate = [self getCertDataFromX509:signingCert];
    moppLibSignature.signatureMethod = [NSString stringWithUTF8String:signature->signatureMethod().c_str()];
    moppLibSignature.containerFormat = [NSString stringWithUTF8String:mediaType.c_str()];
    moppLibSignature.signatureFormat = [NSString stringWithUTF8String:signature->profile().c_str()];
    moppLibSignature.signedFileCount = dataFileCount;
    moppLibSignature.signatureTimestamp = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->TimeStampTime().c_str()]];
    moppLibSignature.signatureTimestampUTC = [NSString stringWithUTF8String:signature->TimeStampTime().c_str()];
    moppLibSignature.hashValueOfSignature = [self getNSDataFromVector:signature->messageImprint()];
    moppLibSignature.tsCertificateIssuer = [NSString stringWithUTF8String:timestampCert.issuerName("CN").c_str()];
    moppLibSignature.tsCertificate = [self getCertDataFromX509:timestampCert];
    moppLibSignature.ocspCertificateIssuer = [NSString stringWithUTF8String:ocspCert.issuerName("CN").c_str()];
    moppLibSignature.ocspCertificate = [self getCertDataFromX509:ocspCert];
    moppLibSignature.ocspTime = [self getDateTimeInCurrentTimeZoneFromDateString:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
    moppLibSignature.ocspTimeUTC = [NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()];
    moppLibSignature.signersMobileTimeUTC = [NSString stringWithUTF8String:signature->claimedSigningTime().c_str()];
    moppLibSignature.timestamp = [NSString stringWithUTF8String:signature->trustedSigningTime().c_str()];

    // Role and address data
    std::vector<std::string> signatureRoles = signature->signerRoles();
    NSMutableArray* signatureRolesList = [NSMutableArray arrayWithCapacity: signatureRoles.size()];
    for (auto const& signatureRole: signatureRoles) {
        [signatureRolesList addObject: [NSString stringWithUTF8String:signatureRole.c_str()]];
    }

    MoppLibRoleAddressData *moppLibRoleAddressData = [MoppLibRoleAddressData new];
    moppLibRoleAddressData.ROLES = signatureRolesList;
    moppLibRoleAddressData.CITY = [NSString stringWithUTF8String:signature->city().c_str()];
    moppLibRoleAddressData.STATE = [NSString stringWithUTF8String:signature->stateOrProvince().c_str()];
    moppLibRoleAddressData.COUNTRY = [NSString stringWithUTF8String:signature->countryName().c_str()];
    moppLibRoleAddressData.ZIP = [NSString stringWithUTF8String:signature->postalCode().c_str()];
    moppLibSignature.roleAndAddressData = moppLibRoleAddressData;

    try {
      digidoc::Signature::Validator validator(signature);
      digidoc::Signature::Validator::Status status = validator.status();
      moppLibSignature.diagnosticsInfo = [NSString stringWithUTF8String:validator.diagnostics().c_str()];
      moppLibSignature.status = [self determineSignatureStatus:status];
    } catch(const digidoc::Exception &e) {
      moppLibSignature.status = Invalid;
    }

    return moppLibSignature;
}

- (std::string)getSerialNumber:(std::string)serialNumber {
    static const std::set<std::string> types {"PAS", "IDC", "PNO", "TAX", "TIN"};
    if (serialNumber.length() > 6 && (types.find(serialNumber.substr(0, 3)) != types.cend() || serialNumber[2] == ':') && serialNumber[5] == '-') {
        return serialNumber.substr(6);
    }
    return serialNumber;
}

- (NSData *)getCertDataFromX509:(const digidoc::X509Cert&)cert {
    std::vector<unsigned char> data = cert;
    return [NSData dataWithBytes:data.data() length:data.size()];
}

- (NSString *)getDateTimeInCurrentTimeZoneFromDateString:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *systemTimeZone = [NSTimeZone systemTimeZone];
    [dateFormatter setTimeZone:systemTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    NSString *dateStringSystemTimeZone = [dateFormatter stringFromDate:date];

    return dateStringSystemTimeZone;
}

- (NSData *)getNSDataFromVector:(std::vector<unsigned char>)vectorData {
    return [NSData dataWithBytes:vectorData.data() length:vectorData.size()];
}

- (MoppLibSignatureStatus)determineSignatureStatus:(int) status{

    if(digidoc::Signature::Validator::Status::Valid==status){
        return Valid;
    }
    else if(digidoc::Signature::Validator::Status::NonQSCD==status){
        return NonQSCD;
    }
    else if(digidoc::Signature::Validator::Status::Warning==status){
        return Warning;
    }
    else if(digidoc::Signature::Validator::Status::Unknown==status){
        return UnknownStatus;
    }
    return Invalid;
}

- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  MLLog(@"createContainerWithPath: %@, dataFilePaths: %@", containerPath, dataFilePaths);

  try {
    auto container = digidoc::Container::createPtr(containerPath.UTF8String);
    for (NSString *dataFilePath in dataFilePaths) {
      container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
    }
    container->save(containerPath.UTF8String);
  } catch(const digidoc::Exception &e) {
    parseException(e);
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error {
  try {
    MoppLibDigidocContainerOpenCB cb;
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

    for (NSString *dataFilePath in dataFilePaths) {
      [self addDataFileToContainer:container.get() withDataFilePath:dataFilePath error: error];
    }

    container->save(containerPath.UTF8String);

  } catch(const digidoc::Exception &e) {
    parseException(e);
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
  }

  NSError *error2;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&error2];

  return moppLibContainer;
}

- (void)addDataFileToContainer:(digidoc::Container *)container withDataFilePath:(NSString *)dataFilePath error:(NSError **)error  {

  try {
    container->addDataFile(dataFilePath.UTF8String, "application/octet-stream");
  } catch(const digidoc::Exception &e) {
    NSString *message = [NSString stringWithCString:e.msg().c_str() encoding:NSUTF8StringEncoding];

    // libdigidoc doesn't send specific error code when file with same name already exists.
    if (e.code() == 0 && [message hasPrefix:@"Document with same file name"]) {
        *error = [MoppLibError duplicatedFilenameError];
    } else {
      parseException(e);
      *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
    }
  }
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex error:(NSError **)error {
  try {
    MoppLibDigidocContainerOpenCB cb;
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    container->removeDataFile((int)dataFileIndex);
    container->save(containerPath.UTF8String);
  } catch(const digidoc::Exception &e) {
    *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
    parseException(e);
  }

  NSError *err;
  MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
  return moppLibContainer;
}

void parseException(const digidoc::Exception &e) {
  printLog(@"%u, %s", e.code(), e.msg().c_str());
  for (const digidoc::Exception &ex : e.causes()) {
    parseException(ex);
  }
}

- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert roleData:(MoppLibRoleAddressData *)roleData success:(VoidBlock)success andFailure:(FailureBlock)failure {

  try {
    // Load the container
    MoppLibDigidocContainerOpenCB cb;
    // Create unique_ptr that manages a container in this scope
    auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    WebSigner signer([MoppLibDigidocManager getCertFromData:cert]);

    NSLog(@"\nSetting profile info...\n");
    NSLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.ROLES, roleData.CITY, roleData.STATE, roleData.ZIP, roleData.COUNTRY);
    signer.setProfile("time-stamp");
    signer.setSignatureProductionPlace(std::string([roleData.CITY UTF8String] ?: ""), std::string([roleData.STATE UTF8String] ?: ""), std::string([roleData.ZIP UTF8String] ?: ""), std::string([roleData.COUNTRY UTF8String] ?: ""));
    signer.setUserAgent([MoppLibManager userAgent:true].UTF8String);

    std::vector<std::string> roles;
    for (NSString *role in roleData.ROLES) {
        if (role != (id)[NSNull null] && [role length] != 0) {
            roles.push_back(std::string([role UTF8String] ?: ""));
        }
    }
    signer.setSignerRoles(roles);

    digidoc::Signature *signature;
    try {
        signature = container->prepareSignature(&signer);
    } catch (const digidoc::Exception &e) {
        parseException(e);
        return failure([MoppLibError generalError]);
    }

    NSError *error = nil;
    std::vector<unsigned char> dataToSign = signature->dataToSign();
    NSData *calculatedSignature = [MoppLibCardActions calculateSignatureForData:[NSData dataWithBytesNoCopy:dataToSign.data() length:dataToSign.size() freeWhenDone:NO] pin2:pin2 error:&error];
    if (error != nil) {
      return failure(error);
    }

    unsigned char *buffer = (unsigned char *)[calculatedSignature bytes];
    std::vector<unsigned char> vec(buffer, buffer + calculatedSignature.length);

    signature->setSignatureValue(vec);
    signature->extendSignatureProfile(&signer);
    signature->validate();
    container->save();
    success();
  } catch(const digidoc::Exception &e) {
    parseException(e);
    if (e.code() == 18) {
        failure([MoppLibError tooManyRequests]);
    } else if (e.code() == digidoc::Exception::ExceptionCode::OCSPTimeSlot) {
        failure([MoppLibError ocspTimeSlotError]);
    } else if (e.code() == digidoc::Exception::ExceptionCode::NetworkError && (e.msg().starts_with("Failed to create proxy connection with host") || e.msg().starts_with("Failed to connect to host"))) {
        failure([MoppLibError invalidProxySettingsError]);
    } else {
        NSError *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:@{}];
        failure(error);
    }
  }
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error {
  MoppLibDigidocContainerOpenCB cb;
  auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
  for (int i = 0; i < doc->signatures().size(); i++) {
    digidoc::Signature *signature = doc->signatures().at(i);
    digidoc::X509Cert cert = signature->signingCertificate();

    // Estonian signatures
    NSString *name = [self trimWhitespace:[NSString stringWithUTF8String:cert.subjectName("CN").c_str()]];
    NSString *trustedTimeStamp = [self trimWhitespace:[NSString stringWithUTF8String:signature->trustedSigningTime().c_str()]];

    NSString *givenName = [self trimWhitespace:[NSString stringWithUTF8String:cert.subjectName("GN").c_str()]];
    NSString *surname = [self trimWhitespace:[NSString stringWithUTF8String:cert.subjectName("SN").c_str()]];
    NSString *serialNR = [self trimWhitespace:[NSString stringWithUTF8String:[self getSerialNumber:cert.subjectName("serialNumber")].c_str()]];

    NSString* subjectName = [self trimWhitespace:[moppSignature subjectName]];
    NSString* trustedSigningTime = [self trimWhitespace:[moppSignature trustedSigningTime]];

    // Foreign signatures
    NSString *foreignName = [NSString stringWithFormat:@"%@, %@, %@", surname, givenName, serialNR];

    if (([name isEqualToString:subjectName] || [foreignName isEqualToString:subjectName]) && [trustedTimeStamp isEqualToString:trustedSigningTime]) {
        try {
            doc->removeSignature(i);
            doc->save(containerPath.UTF8String);
        } catch(const digidoc::Exception &e) {
            parseException(e);
            *error = [NSError errorWithDomain:[NSString stringWithUTF8String:e.msg().c_str()] code:e.code() userInfo:nil];
        }
        break;
    }
}

    NSError *err;
    MoppLibContainer *moppLibContainer = [self getContainerWithPath:containerPath error:&err];
    return moppLibContainer;
}

- (NSString *)trimWhitespace:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
}

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure {
    try {
        MoppLibDigidocContainerOpenCB cb;
        if (auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb)) {
            const char *fileNameUTF8 = fileName.UTF8String;
            for (digidoc::DataFile *dataFile: doc->dataFiles()) {
                if (dataFile->fileName() == fileNameUTF8) {
                    dataFile->saveAs(path.UTF8String);
                    success();
                    return;
                }
            }
            failure([MoppLibError generalError]);
        } else {
            failure([MoppLibError generalError]);
        }
    } catch(const digidoc::Exception &e) {
        parseException(e);
    }

    failure([MoppLibError generalError]);
}

- (BOOL)isContainerFileSaveable:(NSString *)containerPath saveDataFile:(NSString *)fileName {
    try {
        MoppLibDigidocContainerOpenCB cb;
        if (auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb)) {
            const char *fileNameUTF8 = fileName.UTF8String;
            for (digidoc::DataFile *dataFile: doc->dataFiles()) {
                if(dataFile->fileName() == fileNameUTF8) {
                    return TRUE;
                }
            }
        }
    } catch(const digidoc::Exception &e) {
        parseException(e);
    }
    return FALSE;
}

@end
