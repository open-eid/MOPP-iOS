//
//  CdocParserDelegate.m
//  CryptoLib
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

#import "CdocParserDelegate.h"
@interface CdocParserDelegate ()  <NSXMLParserDelegate>
@end

@implementation CdocParserDelegate {
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"denc:EncryptedKey"]) {
        if (_addressees == nil){
            _addressees  = [NSMutableArray new];
        }
        if (_lastAddressee == nil){
            _lastAddressee  = [Addressee new];
        }
        NSString *attribute = attributeDict[@"Recipient"];
        NSArray *cn = [attribute componentsSeparatedByString:@","];
        Addressee *addressee = [Addressee new];
        if (cn.count > 1) {
            addressee.surname = cn[0];
            addressee.givenName = cn[1];
            addressee.identifier = cn[2];
        } else {
            addressee.identifier = cn[0];
        }
        [_addressees addObject:addressee];
        _lastAddressee = addressee;
    }
    if ([elementName isEqualToString:@"ds:X509Certificate"]) {
        _isNextCharactersCertificate = YES;
    }
    if ([elementName isEqualToString:@"denc:EncryptionProperty"] && [[attributeDict valueForKey: @"Name"]  isEqual: @"orig_file"]) {
        _isNextCharactersFilename = YES;
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_isNextCharactersFilename) {
        if (_currentFilenameNode) {
            _currentFilenameNode = [_currentFilenameNode stringByAppendingString:string];
        } else {
            _currentFilenameNode = string;
        }
    }
        
    if (_isNextCharactersCertificate) {
        NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString *pemCertificate = [NSString stringWithFormat:@"-----BEGIN CERTIFICATE-----\n%@\n-----END CERTIFICATE------", trimmedString];
        
        NSData *pemFormattedCertificate = [pemCertificate dataUsingEncoding:NSUTF8StringEncoding];
        _lastAddressee.cert = [pemFormattedCertificate subdataWithRange:NSMakeRange(0, [pemFormattedCertificate length] - 1)];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName {
    if (_isNextCharactersFilename) {
        if (_dataFiles == nil){
            _dataFiles  = [NSMutableArray new];
        }
        NSArray *filenameWithBytesLength = [_currentFilenameNode componentsSeparatedByString:@"|"];
        NSString *filename = filenameWithBytesLength[0];
        CryptoDataFile *dataFile = [CryptoDataFile new];
        dataFile.filename = filename;
        [_dataFiles addObject:dataFile];
    }
    _currentFilenameNode = nil;
    _isNextCharactersFilename = NO;
    _isNextCharactersCertificate = NO;
}

@end
