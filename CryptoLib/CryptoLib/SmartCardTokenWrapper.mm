
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
#import "Extensions.h"

#import <CryptoLib/CryptoLib-Swift.h>

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

libcdoc::result_t SmartCardTokenWrapper::deriveECDH1(std::vector<uint8_t>& dst, const std::vector<uint8_t> &public_key, unsigned int idx)
{
    NSError *error = nil;
    dst = [[token->smartTokenClass derive:[NSData dataFromVectorNoCopy:public_key] error:&error] toVector];
    token->error = error;
    return dst.empty() ? libcdoc::CRYPTO_ERROR : libcdoc::OK;
}

libcdoc::result_t SmartCardTokenWrapper::decryptRSA(std::vector<uint8_t>& dst, const std::vector<uint8_t>& data, bool oaep, unsigned int idx)
{
    NSError *error = nil;
    dst = [[token->smartTokenClass decrypt:[NSData dataFromVectorNoCopy:data] error:&error] toVector];
    token->error = error;
    return dst.empty() ? libcdoc::CRYPTO_ERROR : libcdoc::OK;
}

libcdoc::result_t SmartCardTokenWrapper::sign(std::vector<uint8_t> &dst, HashAlgorithm algorithm, const std::vector<uint8_t> &digest, unsigned int idx)
{
    NSError *error = nil;
    dst = [[token->smartTokenClass authenticate:[NSData dataFromVectorNoCopy:digest] error:&error] toVector];
    token->error = error;
    return dst.empty() ? libcdoc::CRYPTO_ERROR : libcdoc::OK;
}
