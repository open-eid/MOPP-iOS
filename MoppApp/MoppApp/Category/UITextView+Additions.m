//
//  UITextView+Additions.m
//  MoppApp
//
//  Created by Katrin Annuk on 02/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "UITextView+Additions.h"

@implementation UITextView (Additions)

- (void)setLinkedText:(NSString *)text withLinks:(NSDictionary *)linkStrings {
  [self setLinkedText:text withLinks:linkStrings font:nil];
}

- (void)setLinkedText:(NSString *)text withLinks:(NSDictionary *)linkStrings font:(UIFont *)font {
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
  
  NSArray *paths = linkStrings.allKeys;
  for (int i = 0; i < paths.count; i++) {
    NSString *path = paths[i];
    NSString *link = [linkStrings objectForKey:path];
    [attributedString addAttribute:NSLinkAttributeName
                             value:path
                             range:[text rangeOfString:link]];
  }
  
  UIFont *defaultFont = [UIFont systemFontOfSize:14];
  [attributedString addAttribute:NSFontAttributeName value:font ? font : defaultFont range:NSMakeRange(0,text.length)];

  self.attributedText = attributedString;
  
  self.selectable = YES;
  self.editable = NO;
}

@end
