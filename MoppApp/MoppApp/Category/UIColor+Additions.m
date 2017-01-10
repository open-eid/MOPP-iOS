//
//  UIColor+Additions.m
//  MoppApp
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "UIColor+Additions.h"

NSString *const kThemeDarkGreen = @"5DA54B";
NSString *const kThemeRed = @"d52d37";
NSString *const kThemeDarkBlue = @"00365C";
NSString *const kThemeWarningIconTint = @"FF9033";
NSString *const kThemeWarningBackgroundColor = @"FFF4E1";
NSString *const kThemeWarningBorderColor = @"FBE3BC";
NSString *const kThemeErrorIconTint = @"F3B12E";
NSString *const kThemeErrorBackgroundColor = @"FFE6E6";
NSString *const kThemeErrorBorderColor = @"FFCED0";

@implementation UIColor (Additions)

+ (UIColor *)colorFromHexString:(NSString *)hexString {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString alpha:(CGFloat)alpha {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

+ (UIColor *)darkGreen {
  return [self colorFromHexString:kThemeDarkGreen];
}

+ (UIColor *)darkBlue {
  return [self colorFromHexString:kThemeDarkBlue];
}

+ (UIColor *)red {
  return [self colorFromHexString:kThemeRed];
}

+ (UIColor *)warningIconTint {
  return [self colorFromHexString:kThemeWarningIconTint];
}

+ (UIColor *)warningBackgroundColor {
  return [self colorFromHexString:kThemeWarningBackgroundColor];
}

+ (UIColor *)warningBorderColor {
  return [self colorFromHexString:kThemeWarningBorderColor];
}

+ (UIColor *)errorIconTint {
  return [self colorFromHexString:kThemeErrorIconTint];
}

+ (UIColor *)errorBackgroundColor {
  return [self colorFromHexString:kThemeErrorBackgroundColor];
}

+ (UIColor *)errorBorderColor {
  return [self colorFromHexString:kThemeErrorBorderColor];
}

@end
