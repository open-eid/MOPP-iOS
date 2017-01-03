//
//  ViewWithRoundedCorners.m
//  CoveredStaff
//
//  Created by Katrin Annuk on 20/10/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ViewWithRoundedCorners.h"

@implementation ViewWithRoundedCorners

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)initialize {
    self.layer.borderWidth = _borderWidth ? _borderWidth : 1;
    self.layer.borderColor = _borderColor ? _borderColor.CGColor : [UIColor clearColor].CGColor;
    self.layer.cornerRadius = _cornerRadius ? _cornerRadius : 6;
    self.clipsToBounds = YES;
}

@end
