//
//  MOPPSOAPManager.m
//  MoppLib
//
//  Created by Olev Abel on 1/27/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//
#import "MoppSOAPManager.h"
#import <SOAPEngine64/SOAPEngine.h>
#import "MoppLibManager.h"
#import "MoppLibDataFile.h"
#import <MoppLib/MoppLib-Swift.h>




static NSString *kDigestMethodSHA256 = @"http://www.w3.org/2001/04/xmlenc#sha256";
static NSString *kServiceName = @"DigiDoc3";
static NSString *kFormat = @"BDOC";
static NSString *kVersion = @"2.1";
static NSString *kMessagingMode = @"asynchClientServer";
static NSString *kDigestType = @"sha256";
static NSInteger kAsyncConfiguration = 0;

@implementation MoppSOAPManager

- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container persionalData:(MoppLibPersonalData *)personalData {
  AEXMLDocument *document = [AEXMLDocument new];
  NSMutableDictionary *envelopeAttributes = [[NSMutableDictionary alloc] init];
  [envelopeAttributes setObject:@"http://www.w3.org/2001/XMLSchema-instance" forKey:@"xmlns:xsi"];
  [envelopeAttributes setObject:@"http://www.w3.org/2001/XMLSchema" forKey:@"xmlns:xsd"];
  [envelopeAttributes setObject:@"http://schemas.xmlsoap.org/soap/envelope/" forKey:@"xmlns:soapenv"];
  [envelopeAttributes setObject:@"http://www.sk.ee/DigiDocService/DigiDocService_2_3.wsdl" forKey:@"xmlns:dig"];
  AEXMLElement *envelope = [[AEXMLElement alloc] initWithName:@"soap:Envelope" value:nil attributes:envelopeAttributes];
  [envelope addChildWithName:@"soap:Header" value:nil attributes:nil];
  AEXMLElement *body = [[AEXMLElement alloc] initWithName:@"soap:Body" value:nil attributes:nil];
  [envelope addChild:body];
  AEXMLElement *mobileCreateSignature = [[AEXMLElement alloc] initWithName:@"dig:MobileCreateSignature" value:nil attributes:@{@"soapenv:encodingStyle" : @"http://schemas.xmlsoap.org/soap/encoding/"}];
  [body addChild:mobileCreateSignature];
  [mobileCreateSignature addChildWithName:@"IDCode" value:personalData.personalIdentificationCode attributes:@{@"xsi:type" : @"xsd:string"}];
  [mobileCreateSignature addChildWithName:@"PhoneNo" value:@"+37253308299" attributes:@{@"xsi:type" : @"xsd:string"}];
  [mobileCreateSignature addChildWithName:@"Language" value:personalData.nationality attributes:@{@"xsi:type" : @"xsd:string"}];
  [mobileCreateSignature addChildWithName:@"ServiceName" value:kServiceName attributes:@{@"xsi:type" : @"xsd:string"}];
  AEXMLElement *dataFiles = [[AEXMLElement alloc] initWithName:@"DataFiles" value:nil attributes:@{@"xsi:type" : @"dig:DataFileDigestList"}];
  [mobileCreateSignature addChild:dataFiles];
  for (MoppLibDataFile *file in container.dataFiles) {
    AEXMLElement *dataFileDigest = [[AEXMLElement alloc] initWithName:@"DataFileDigest" value:nil attributes:@{@"xsi:type" : @"dig:DataFileDigest"}];
    [dataFileDigest addChildWithName:@"Id" value:file.fileId attributes:@{@"xsi:type" : @"xsd:string"}];
    [dataFileDigest addChildWithName:@"DigestType" value:kDigestType attributes:@{@"xsi:type" : @"xsd:string"}];
    [dataFileDigest addChildWithName:@"DigestValue" value:[[MoppLibManager sharedInstance] dataFileCalculateHashWithDigestMethod:kDigestMethodSHA256 container:container dataFileId:file.fileId] attributes:@{@"xsi:type" : @"xsd:string"}];
    [dataFiles addChild:dataFileDigest];
  }
  [mobileCreateSignature addChildWithName:@"Format" value:kFormat attributes:@{@"xsi:type" : @"xsd:string"}];
  [mobileCreateSignature addChildWithName:@"Version" value:kVersion attributes:@{@"xsi:type" : @"xsd:string"}];
  [mobileCreateSignature addChildWithName:@"SignatureID" value:container.getNextSignatureId attributes:@{@"xsi:type" : @"xsd:string"}];
  [mobileCreateSignature addChildWithName:@"MessagingMode" value:kMessagingMode attributes:@{@"xsi:type" : @"xsd:string"}];
  [document addChild:envelope];
  NSLog(@"SOAP REQUEST %@", document.xml);

}

@end
