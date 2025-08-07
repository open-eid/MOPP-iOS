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
#import <MoppLib/MoppLib-Swift.h>

#include <digidocpp/Container.h>
#include <digidocpp/DataFile.h>
#include <digidocpp/Signature.h>
#include <digidocpp/Exception.h>
#include <digidocpp/crypto/Signer.h>
#include <digidocpp/crypto/X509Cert.h>

#include <set>

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

@implementation MoppLibDigidocManager

static std::unique_ptr<digidoc::Container> docContainer = nil;
static digidoc::Signature *signature = nil;
static std::unique_ptr<digidoc::Signer> signer{};

+ (BOOL)isSignatureValid:(NSData *)data error:(NSError**)error {
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
        auto *bytes = reinterpret_cast<const unsigned char*>(data.bytes);
        signature->setSignatureValue({bytes, bytes + data.length});
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
        for (NSString *role in roleData.roles) {
            if (role.length > 0) {
                roles.push_back(role.UTF8String);
            }
        }
        signer->setSignerRoles(roles);
        printLog(@"\nProfile info set successfully\n");

        printLog(@"\nSetting signature...\n");
        signature = docContainer->prepareSignature(signer.get());
        printLog(@"\nSignature ID set to %s...\n", signature->id().c_str());
        return [MoppLibDigidocManager getNSDataFromVector:signature->dataToSign()];
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
        return nil;
    }
}

+ (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error {

  // Having two container instances of the same file is causing crashes. Should synchronize all container operations?
  @synchronized (self) {

    std::unique_ptr<digidoc::Container> doc;
    try {
      MoppLibDigidocContainerOpenCB cb;
      doc = digidoc::Container::openPtr(containerPath.UTF8String, &cb);
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
      return nil;
    }
    try {
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
          [signatures addObject:[MoppLibDigidocManager getSignature:signature pos:pos++ mediaType:doc->mediaType() dataFileCount:doc->dataFiles().size()]];
      }

      return [[MoppLibContainer alloc]
              initWithFileName:containerPath.lastPathComponent
              filePath:containerPath
              dataFiles:dataFiles
              signatures:signatures];
    } catch(const digidoc::Exception &e) {
        [MoppLibError setException:e toError:error];
      return nil;
    }
  }
}

+ (MoppLibSignature *)getSignature:(digidoc::Signature *)signature pos:(int)pos mediaType:(const std::string&)mediaType dataFileCount:(NSInteger)dataFileCount {

    static const NSISO8601DateFormatter *dateFrom = [[NSISO8601DateFormatter alloc] init];

    digidoc::X509Cert signingCert = signature->signingCertificate();
    digidoc::X509Cert ocspCert = signature->OCSPCertificate();
    digidoc::X509Cert timestampCert = signature->TimeStampCertificate();

    std::string givename = signingCert.subjectName("GN");
    std::string surname = signingCert.subjectName("SN");
    std::string serialNR = [MoppLibDigidocManager getSerialNumber:signingCert.subjectName("serialNumber")];

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
    moppLibSignature.signingCertificate = [MoppLibDigidocManager getNSDataFromVector:signingCert];
    moppLibSignature.signatureMethod = [NSString stringWithUTF8String:signature->signatureMethod().c_str()];
    moppLibSignature.containerFormat = [NSString stringWithUTF8String:mediaType.c_str()];
    moppLibSignature.signatureFormat = [NSString stringWithUTF8String:signature->profile().c_str()];
    moppLibSignature.signedFileCount = dataFileCount;
    moppLibSignature.signatureTimestampUTC = [dateFrom dateFromString:[NSString stringWithUTF8String:signature->TimeStampTime().c_str()]];
    moppLibSignature.hashValueOfSignature = [MoppLibDigidocManager getNSDataFromVector:signature->messageImprint()];
    moppLibSignature.tsCertificateIssuer = [NSString stringWithUTF8String:timestampCert.issuerName("CN").c_str()];
    moppLibSignature.tsCertificate = [MoppLibDigidocManager getNSDataFromVector:timestampCert];
    moppLibSignature.ocspCertificateIssuer = [NSString stringWithUTF8String:ocspCert.issuerName("CN").c_str()];
    moppLibSignature.ocspCertificate = [MoppLibDigidocManager getNSDataFromVector:ocspCert];
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

+ (NSData *)getNSDataFromVector:(const std::vector<unsigned char>&)vectorData {
    return [NSData dataWithBytes:vectorData.data() length:vectorData.size()];
}

@end
