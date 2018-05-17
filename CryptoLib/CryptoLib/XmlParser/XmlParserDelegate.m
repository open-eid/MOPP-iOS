//
//  XmlParserDelegate.m
//  CryptoLib
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

#import "XmlParserDelegate.h"
@interface XmlParserDelegate ()  <NSXMLParserDelegate>
@end

@implementation XmlParserDelegate {
    
}

- (void) parserDidStartDocument:(NSXMLParser *)parser {
    NSLog(@"parserDidStartDocument");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSLog(@"didStartElement --> %@", elementName);
    
    if ([elementName isEqualToString:@"DataFile"]) {
        if (_dictionary == nil){
            _dictionary  = [[NSMutableDictionary alloc] init];
        }
        NSString *attribute = attributeDict[@"Filename"];
        [_dictionary setObject:@"" forKey:attribute];
        _lastKey = attribute;
        NSLog(@"didStartElement --> %@", attributeDict[@"Filename"]);
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (string != nil && [string length] != 0 && ![string isEqualToString:@"\n    "] && ![string isEqualToString:@"\n"]){
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        [_dictionary setValue:string forKey:_lastKey];
    }
    NSLog(@"foundCharacters --> %@", string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSLog(@"didEndElement   --> %@", elementName);
}

- (void) parserDidEndDocument:(NSXMLParser *)parser {
    NSLog(@"parserDidEndDocument");
}
@end
