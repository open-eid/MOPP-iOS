//
//  MoppLibPrivateConstants.m
//  MoppLib
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

#import "MoppLibPrivateConstants.h"

NSString *const kRIADigiDocId = @"ee.ria.digidoc";
NSString *const kTestServiceNames = @"Testimine";
NSString *const kMessagingModes = @"asynchClientServer";

@implementation PrivateConstants

+ (NSDictionary *)getCentralConfigurationFromCache {
    NSString *stringg = [[NSString alloc] initWithString: [[NSUserDefaults standardUserDefaults] stringForKey:@"config"]];
    NSData *jsonData = [stringg dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    return [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error: &error];
}

+ (void)setIDCardRestartedValue:(BOOL)isIDCardRestarted {
    [[NSUserDefaults standardUserDefaults] setBool:isIDCardRestarted forKey:@"isIdCardRestarted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getIDCardRestartedValue {
    if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"isIdCardRestarted"]) {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"isIdCardRestarted"];
    } else {
        return FALSE;
    }
}

@end

