
//
//  SmartCardTokenWrapper.mm
//  CryptoLib
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

#import "SmartCardTokenWrapper.h"

#import <CryptoLib/CryptoLib-Swift.h>

@implementation NSData (std_vector)
+ (instancetype)dataFromVectorNoCopy:(const std::vector<unsigned char>&)data {
    return data.empty() ? nil : [NSData dataWithBytesNoCopy:(void *)data.data() length:data.size() freeWhenDone:NO];
}

- (std::vector<unsigned char>)toVector {
    if (self == nil) {
        return {};
    }
    const auto *p = reinterpret_cast<const uint8_t*>(self.bytes);
    return {p, std::next(p, self.length)};
}
@end

struct SmartCardTokenWrapper::Private {
    id<AbstractSmartToken> smartTokenClass;
    NSError *error;
};


SmartCardTokenWrapper::SmartCardTokenWrapper(id<AbstractSmartToken> smartToken)
    : token(std::make_unique<Private>())
{
    *token = {smartToken, nullptr};
}

SmartCardTokenWrapper::~SmartCardTokenWrapper() noexcept = default;

NSError* SmartCardTokenWrapper::lastError() const
{
    return token->error;
}

std::vector<uchar> SmartCardTokenWrapper::cert() const
{
    NSError *error = nil;
    auto result = [[token->smartTokenClass getCertificateAndReturnError:&error] toVector];
    token->error = error;
    return result;
}

std::vector<uchar> SmartCardTokenWrapper::decrypt(const std::vector<uchar> &data) const
{
    NSError *error = nil;
    auto result = [[token->smartTokenClass derive:[NSData dataFromVectorNoCopy:data] error:&error] toVector];
    token->error = error;
    return result;
}

std::vector<uchar> SmartCardTokenWrapper::derive(const std::vector<uchar> &publicKey) const
{
    NSError *error = nil;
    auto result = [[token->smartTokenClass derive:[NSData dataFromVectorNoCopy:publicKey] error:&error] toVector];
    token->error = error;
    return result;
}
