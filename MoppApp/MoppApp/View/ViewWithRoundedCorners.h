//
//  ViewWithRoundedCorners.h
//  CoveredStaff
//
//  Created by Katrin Annuk on 20/10/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface ViewWithRoundedCorners : UIView
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end
