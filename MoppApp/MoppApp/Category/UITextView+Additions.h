//
//  UITextView+Additions.h
//  MoppApp
//
//  Created by Katrin Annuk on 02/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (Additions)
- (void)setLinkedText:(NSString *)text withLinks:(NSDictionary *)linkStrings;
@end
