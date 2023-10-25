//
//  MOPPLibConfiguration.m
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

#import "MOPPLibConfiguration.h"

@implementation MoppLibConfiguration

- (id) initWithConfiguration:(NSString *)SIVAURL TSLURL:(NSString *)TSLURL TSLCERTS:(NSArray<NSString*> *)TSLCERTS LDAPCERTS:(NSArray<NSString*> *)LDAPCERTS TSAURL:(NSString *)TSAURL OCSPISSUERS:(NSDictionary *)OCSPISSUERS CERTBUNDLE:(NSArray<NSString*> *)CERTBUNDLE TSACERT:(NSString *)TSACERT {
    self = [super init];
    if (self) {
        self.SIVAURL = SIVAURL;
        self.TSLURL = TSLURL;
        self.TSLCERTS = TSLCERTS;
        self.LDAPCERTS = LDAPCERTS;
        self.TSAURL = TSAURL;
        self.OCSPISSUERS = OCSPISSUERS;
        self.CERTBUNDLE = CERTBUNDLE;
        self.TSACERT = TSACERT;
    }
    
    return self;
}

@end
