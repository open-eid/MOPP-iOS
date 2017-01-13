//
//  ButtonWithRoundedCorners.h
//  CoveredVenue
//
//  Created by Katrin Annuk on 03/05/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface ButtonWithRoundedCorners : UIButton
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end
