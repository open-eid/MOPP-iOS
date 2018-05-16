//
//  XmlParserDelegate.m
//  CryptoLib
//
//  Created by Siim Suu on 20/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

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
        if(_dictionary == nil){
            _dictionary  = [[NSMutableDictionary alloc] init];
        }
        NSString *attribute = attributeDict[@"Filename"];
        [_dictionary setObject:@"" forKey:attribute];
        _lastKey = attribute;
        NSLog(@"didStartElement --> %@", attributeDict[@"Filename"]);
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if(string != nil && [string length] != 0 && ![string isEqualToString:@"\n    "] && ![string isEqualToString:@"\n"]){
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
