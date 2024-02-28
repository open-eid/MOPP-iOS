//
//  DdocParserDelegate.m
//  CryptoLib
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

#if DEBUG
#define printLog(...) NSLog(__VA_ARGS__)
#else
#define printLog(...)
#endif

#import "DdocParserDelegate.h"
@interface DdocParserDelegate ()  <NSXMLParserDelegate>
@end

@implementation DdocParserDelegate {
    
}

- (void) parserDidStartDocument:(NSXMLParser *)parser {
    printLog(@"parserDidStartDocument");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    printLog(@"didStartElement --> %@", elementName);
    
    if ([elementName isEqualToString:@"DataFile"]) {
        if (_dictionary == nil){
            _dictionary  = [NSMutableDictionary new];
        }
        NSString *attribute = attributeDict[@"Filename"];
        [_dictionary setObject:@"" forKey:attribute];
        _lastKey = attribute;
        printLog(@"didStartElement --> %@", attributeDict[@"Filename"]);
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    // If parsing ddoc original filenames, sometimes filename may contain new line symbols
    if (string != nil && [string length] != 0 && ![string isEqualToString:@"\n    "] && ![string isEqualToString:@"\n"]){ 
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        if (_currentElement == nil ) {
            _currentElement = [NSString new];
        }
        _currentElement = [NSString stringWithFormat:@"%@%@", _currentElement, string];
    }
    printLog(@"foundCharacters --> %@", string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([_currentElement length] != 0) {
        [_dictionary setValue:_currentElement forKey:_lastKey];
        _currentElement = @"";
    }
    printLog(@"didEndElement   --> %@", elementName);
}

- (void) parserDidEndDocument:(NSXMLParser *)parser {
    printLog(@"parserDidEndDocument");
}
@end
