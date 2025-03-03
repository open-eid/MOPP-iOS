
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

#include "SmartCardTokenWrapper.h"

#import <CryptoLib/AbstractSmartToken.h>

class SmartCardTokenWrapper::Private{
public:
    id<AbstractSmartToken> smartTokenClass;
    NSString *pin1;
};


SmartCardTokenWrapper::SmartCardTokenWrapper(const std::string &password, id<AbstractSmartToken> smartToken)
: token(new Private) {
    token->pin1 = [NSString stringWithUTF8String:password.c_str()];
    token->smartTokenClass = smartToken;
}

SmartCardTokenWrapper::~SmartCardTokenWrapper() noexcept = default;

std::vector<uchar> SmartCardTokenWrapper::cert() const {
    return encodeData([token->smartTokenClass getCertificate]);
}

std::vector<uchar> SmartCardTokenWrapper::decrypt(const std::vector<uchar> &data) const {
    NSMutableData *nsdata = [NSMutableData dataWithBytesNoCopy:(void *)data.data() length:data.size() freeWhenDone:0];
    return encodeData([token->smartTokenClass decrypt:nsdata pin1:token->pin1]);
}

std::vector<uchar> SmartCardTokenWrapper::derive(const std::vector<uchar> &publicKey) const {
    NSMutableData *nsdata = [NSMutableData dataWithBytesNoCopy:(void *)publicKey.data() length:publicKey.size() freeWhenDone:0];
    return encodeData([token->smartTokenClass derive:nsdata pin1:token->pin1]);
}

std::vector<uchar> SmartCardTokenWrapper::encodeData(const NSData *dataBlock) {
    const unsigned char *buffer = reinterpret_cast<const unsigned char*>(dataBlock.bytes);
    return {buffer, std::next(buffer, dataBlock.length)};
}
