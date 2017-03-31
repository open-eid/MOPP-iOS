//
//  UITextView+Additions.m
//  MoppApp
//
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
