//
//  DateFormatter.h
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateFormatter : NSObject

+ (DateFormatter *)sharedInstance;

// 02.03.2015
- (NSString *)ddMMYYYYToString:(NSDate *)date;

// 02.03.2015
- (NSDate *)ddMMYYYYToDate:(NSString *)string;

// 17:32:06 02.03.2015
- (NSString *)HHmmssddMMYYYYToString:(NSDate *)date;

// 21. Nov OR relative string "Today" etc.
- (NSString *)dateToRelativeString:(NSDate *)date;

- (NSString *)UTCTimestampStringToLocalTime:(NSDate *)date;
@end
