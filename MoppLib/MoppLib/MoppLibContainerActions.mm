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

#import <MoppLib/MoppLibContainerActions.h>
#import <MoppLib/MoppLib-Swift.h>

#include <digidocpp/Conf.h>
#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/Signer.h>
#include <digidocpp/crypto/X509Cert.h>

#if DEBUG
#define printLog(...) NSLog(__VA_ARGS__)
#else
#define printLog(...)
#endif

digidoc::Exception::ExceptionCode parseException(const digidoc::Exception &e) {
    printLog(@"%u, %s", e.code(), e.msg().c_str());
    digidoc::Exception::ExceptionCode code = e.code();
    for (const digidoc::Exception &ex : e.causes()) {
        code = std::max(code, parseException(ex));
    }
    return code;
}

@implementation MoppLibError (digidocpp)

+ (void)setException:(const digidoc::Exception &)exception toError:(NSError**)error {
    if (error) { *error = [MoppLibError errorWithException:exception]; }
}

+ (NSError*)errorWithException:(const digidoc::Exception &)exception {
    switch (parseException(exception)) {
            using enum digidoc::Exception::ExceptionCode;
        case CertificateRevoked:
        case CertificateUnknown:
            return [MoppLibError error:MoppLibErrorCodeCertRevoked];
        case TSTooManyRequests:
            return [MoppLibError error:MoppLibErrorCodeTooManyRequests];
        case OCSPTimeSlot:
            return [MoppLibError error:MoppLibErrorCodeOCSPTimeSlot];
        case NetworkError:
            if (exception.msg().starts_with("Failed to create ssl connection with host")) {
                return [MoppLibError error:MoppLibErrorCodeSslHandshakeFailed];
            }
            if (exception.msg().starts_with("Failed to create proxy connection with host") ||
                exception.msg().starts_with("Failed to connect to host")) {
                return [MoppLibError error:MoppLibErrorCodeInvalidProxySettings];
            }
            return [MoppLibError error:MoppLibErrorCodeNoInternetConnection];
        case 63:
            return [MoppLibError error:MoppLibErrorCodeFileNameTooLong];
        default:
            return [MoppLibError errorWithMessage:[NSString stringWithUTF8String:exception.msg().c_str()]];
    }
}

@end


struct WebSigner: public digidoc::Signer
{
    WebSigner(const digidoc::X509Cert &cert): _cert(cert) {}
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
            return url.UTF8String;
        }
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

    int logLevel() const final {
        if (MoppLibConfiguration.isDebugMode || MoppLibConfiguration.isLoggingEnabled) {
            return 4;
        } else {
            return 0;
        }
    }

    std::string logFile() const final {
        if (!MoppLibConfiguration.isDebugMode && !MoppLibConfiguration.isLoggingEnabled) {
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

static std::unique_ptr<digidoc::Container> docContainer = nil;
static digidoc::Signature *signature = nil;
static std::unique_ptr<digidoc::Signer> signer{};

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

+ (NSData *)getNSDataFromVector:(const std::vector<unsigned char>&)vectorData {
    return [NSData dataWithBytes:vectorData.data() length:vectorData.size()];
}

+ (void)dispatch:(void (^)(void))command completion:(void (^)(NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        try {
            command();
        } catch(const digidoc::Exception &e) {
            [MoppLibError setException:e toError:&error];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
    });
}

+ (MoppLibSignature *)getSignature:(digidoc::Signature *)signature pos:(int)pos mediaType:(const std::string&)mediaType dataFileCount:(NSInteger)dataFileCount {

    static const NSISO8601DateFormatter *dateFrom = [[NSISO8601DateFormatter alloc] init];

    digidoc::X509Cert signingCert = signature->signingCertificate();
    digidoc::X509Cert ocspCert = signature->OCSPCertificate();
    digidoc::X509Cert timestampCert = signature->TimeStampCertificate();

    std::string givename = signingCert.subjectName("GN");
    std::string surname = signingCert.subjectName("SN");
    std::string serialNR = [MoppLibContainerActions getSerialNumber:signingCert.subjectName("serialNumber")];

    std::string name = givename.empty() || surname.empty() ? signingCert.subjectName("CN") :
        surname + ", " + givename + ", " + serialNR;
    if (name.empty()) {
        name = signature->signedBy();
    }

    MoppLibSignature *moppLibSignature = [MoppLibSignature new];
    moppLibSignature.pos = pos;
    moppLibSignature.subjectName = [NSString stringWithUTF8String:name.c_str()];
    moppLibSignature.signersCertificateIssuer = [NSString stringWithUTF8String:signingCert.issuerName("CN").c_str()];
    moppLibSignature.issuerName = [NSString stringWithUTF8String:signingCert.issuerName().c_str()];
    moppLibSignature.signingCertificate = [MoppLibContainerActions getNSDataFromVector:signingCert];
    moppLibSignature.signatureMethod = [NSString stringWithUTF8String:signature->signatureMethod().c_str()];
    moppLibSignature.containerFormat = [NSString stringWithUTF8String:mediaType.c_str()];
    moppLibSignature.signatureFormat = [NSString stringWithUTF8String:signature->profile().c_str()];
    moppLibSignature.signedFileCount = dataFileCount;
    moppLibSignature.signatureTimestampUTC = [dateFrom dateFromString:[NSString stringWithUTF8String:signature->TimeStampTime().c_str()]];
    moppLibSignature.hashValueOfSignature = [MoppLibContainerActions getNSDataFromVector:signature->messageImprint()];
    moppLibSignature.tsCertificateIssuer = [NSString stringWithUTF8String:timestampCert.issuerName("CN").c_str()];
    moppLibSignature.tsCertificate = [MoppLibContainerActions getNSDataFromVector:timestampCert];
    moppLibSignature.ocspCertificateIssuer = [NSString stringWithUTF8String:ocspCert.issuerName("CN").c_str()];
    moppLibSignature.ocspCertificate = [MoppLibContainerActions getNSDataFromVector:ocspCert];
    moppLibSignature.ocspTimeUTC = [dateFrom dateFromString:[NSString stringWithUTF8String:signature->OCSPProducedAt().c_str()]];
    moppLibSignature.signersMobileTimeUTC = [dateFrom dateFromString:[NSString stringWithUTF8String:signature->claimedSigningTime().c_str()]];
    moppLibSignature.timestamp = [dateFrom dateFromString:[NSString stringWithUTF8String:signature->trustedSigningTime().c_str()]];

    // Role and address data
    std::vector<std::string> signatureRoles = signature->signerRoles();
    NSMutableArray* signatureRolesList = [NSMutableArray arrayWithCapacity: signatureRoles.size()];
    for (auto const& signatureRole: signatureRoles) {
        [signatureRolesList addObject: [NSString stringWithUTF8String:signatureRole.c_str()]];
    }

    moppLibSignature.roleAndAddressData =
        [[MoppLibRoleAddressData alloc]
         initWithRoles:signatureRolesList
         city:[NSString stringWithUTF8String:signature->city().c_str()]
         state:[NSString stringWithUTF8String:signature->stateOrProvince().c_str()]
         country:[NSString stringWithUTF8String:signature->countryName().c_str()]
         zip:[NSString stringWithUTF8String:signature->postalCode().c_str()]];

    digidoc::Signature::Validator validator(signature);
    switch (validator.status()) {
            using enum digidoc::Signature::Validator::Status;
        case Valid: moppLibSignature.status = MoppLibSignatureStatusValid; break;
        case Warning: moppLibSignature.status = MoppLibSignatureStatusWarning; break;
        case NonQSCD: moppLibSignature.status = MoppLibSignatureStatusNonQSCD; break;
        case Test:
        case Unknown: moppLibSignature.status = MoppLibSignatureStatusUnknownStatus; break;
        case Invalid: moppLibSignature.status = MoppLibSignatureStatusInvalid; break;
    }
    moppLibSignature.diagnosticsInfo = [NSString stringWithUTF8String:validator.diagnostics().c_str()];

    return moppLibSignature;
}

+ (std::string)getSerialNumber:(std::string)serialNumber {
    static const std::set<std::string> types {"PAS", "IDC", "PNO", "TAX", "TIN"};
    if (serialNumber.length() > 6 && (types.find(serialNumber.substr(0, 3)) != types.cend() || serialNumber[2] == ':') && serialNumber[5] == '-') {
        return serialNumber.substr(6);
    }
    return serialNumber;
}

+ (void)openContainerWithPath:(NSString *)containerPath completion:(void (^)(MoppLibContainer *container, NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MoppLibContainer *container = nil;
        NSError *error = nil;
        try {
            MoppLibDigidocContainerOpenCB cb;
            auto doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

            // DataFiles
            NSMutableArray *dataFiles = [NSMutableArray array];
            for (digidoc::DataFile *dataFile: doc->dataFiles()) {
                [dataFiles addObject:[[MoppLibDataFile alloc]
                                      initWithFileName:[NSString stringWithUTF8String:dataFile->fileName().c_str()]
                                      mediaType:[NSString stringWithUTF8String:dataFile->mediaType().c_str()]
                                      fileId:[NSString stringWithUTF8String:dataFile->id().c_str()]
                                      fileSize:dataFile->fileSize()]];
            }

            // Signatures
            NSMutableArray *signatures = [NSMutableArray array];
            int pos = 0;
            for (digidoc::Signature *signature: doc->signatures()) {
                [signatures addObject:[MoppLibContainerActions getSignature:signature pos:pos++ mediaType:doc->mediaType() dataFileCount:doc->dataFiles().size()]];
            }

            container = [[MoppLibContainer alloc]
                         initWithFileName:containerPath.lastPathComponent
                         filePath:containerPath
                         dataFiles:dataFiles
                         signatures:signatures];
        } catch(const digidoc::Exception &e) {
            [MoppLibError setException:e toError:&error];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(container, error); });
    });
}

+ (void)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray<NSString*> *)dataFilePaths completion:(CompletionBlock)completion {
    [self dispatch:^{
        if (auto container = digidoc::Container::createPtr(containerPath.UTF8String)) {
            for (NSString *dataFilePath in dataFilePaths) {
                container->addDataFile(dataFilePath.UTF8String, @"application/octet-stream".UTF8String);
            }
            container->save(containerPath.UTF8String);
        }
    } completion:completion];
}

+ (void)openContainer:(NSString *)containerPath command:(void (^)(digidoc::Container &container))command completion:(void (^)(NSError *error))completion {
    [self dispatch:^{
        if (MoppLibDigidocContainerOpenCB cb;
            auto container = digidoc::Container::openPtr(containerPath.UTF8String, &cb)) {
            command(*container);
        }
    } completion:completion];
}

+ (void)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray<NSString*> *)dataFilePaths completion:(CompletionBlock)completion {
    [self openContainer:containerPath command:^(digidoc::Container &container) {
        for (NSString *dataFilePath in dataFilePaths) {
            container.addDataFile(dataFilePath.UTF8String, "application/octet-stream");
        }
        container.save(containerPath.UTF8String);
    } completion:completion];
}

+ (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex completion:(CompletionBlock)completion {
    [self openContainer:containerPath command:^(digidoc::Container &container) {
        container.removeDataFile((int)dataFileIndex);
        container.save(containerPath.UTF8String);
    } completion:completion];
}

+ (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath completion:(CompletionBlock)completion {
    [self openContainer:containerPath command:^(digidoc::Container &container) {
        container.removeSignature(moppSignature.pos);
        container.save(containerPath.UTF8String);
    } completion:completion];
}

+ (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path completion:(CompletionBlock)completion  {
    [self openContainer:containerPath command:^(digidoc::Container &container) {
        const char *fileNameUTF8 = fileName.UTF8String;
        for (digidoc::DataFile *dataFile: container.dataFiles()) {
            if (dataFile->fileName() == fileNameUTF8) {
                dataFile->saveAs(path.UTF8String);
                break;
            }
        }
    } completion:completion];
}

+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData sendDiagnostics:(SendDiagnostics)sendDiagnostics error:(NSError **)error {
    try {
        signer = std::make_unique<WebSigner>(digidoc::X509Cert(reinterpret_cast<const unsigned char *>(cert.bytes), cert.length));
        signature = NULL;
        MoppLibDigidocContainerOpenCB cb;
        docContainer = digidoc::Container::openPtr(containerPath.UTF8String, &cb);

        printLog(@"\nSetting profile info...\n");
        printLog(@"Role data - roles: %@, city: %@, state: %@, zip: %@, country: %@", roleData.roles, roleData.city, roleData.state, roleData.zip, roleData.country);
        signer->setProfile("time-stamp");
        signer->setSignatureProductionPlace(roleData.city.UTF8String ?: "", roleData.state.UTF8String ?: "", roleData.zip.UTF8String ?: "", roleData.country.UTF8String ?: "");
        signer->setUserAgent([MoppLibManager userAgentWithSendDiagnostics:sendDiagnostics].UTF8String);

        std::vector<std::string> roles;
        roles.reserve(roleData.roles.count);
        for (NSString *role in roleData.roles) {
            if (role.length > 0) {
                roles.emplace_back(role.UTF8String);
            }
        }
        signer->setSignerRoles(roles);
        printLog(@"\nProfile info set successfully\n");

        printLog(@"\nSetting signature...\n");
        signature = docContainer->prepareSignature(signer.get());
        printLog(@"\nSignature ID set to %s...\n", signature->id().c_str());
        return [MoppLibContainerActions getNSDataFromVector:signature->dataToSign()];
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
        return nil;
    }
}

+ (BOOL)isSignatureValid:(NSData *)signatureValue error:(NSError**)error {
    if (!signature) {
        printLog(@"\nError: Did not find signature\n");
        if (error) {
            *error = [MoppLibError errorWithMessage:@"Did not find signature"];
        }
        return NO;
    }

    if (auto timeStampTime = signature->TimeStampTime(); !timeStampTime.empty()) {
        printLog(@"\nSignature already validated at %s\n", timeStampTime.c_str());
        return YES;
    }

    try {
        printLog(@"\nStarting signature validation...\n");
        printLog(@"\nSetting signature value...\n");
        auto *bytes = reinterpret_cast<const unsigned char*>(signatureValue.bytes);
        signature->setSignatureValue({bytes, bytes + signatureValue.length});
        printLog(@"\nExtending signature profile...\n");
        signature->extendSignatureProfile(signer.get());
        printLog(@"\nValidating signature...\n");
        signature->validate();
        printLog(@"\nSaving container...\n");
        docContainer->save();
        printLog(@"\nSignature validated at %s!\n", signature->TimeStampTime().c_str());
        return YES;
    } catch(const digidoc::Exception &e) {
        printLog(@"\nError validating signature: %s\n", e.msg().c_str());
        [MoppLibError setException:e toError:error];
        return NO;
    }
}

@end
