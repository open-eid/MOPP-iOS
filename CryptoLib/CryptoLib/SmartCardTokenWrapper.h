//
//  SmartCardTokenWrapper.hpp
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

#if __cplusplus

#import <cdoc/CryptoBackend.h>
#import <Foundation/Foundation.h>
#include <memory>

@protocol AbstractSmartToken;

class SmartCardTokenWrapper: public libcdoc::CryptoBackend
{
public:
    SmartCardTokenWrapper(const std::string &password, id<AbstractSmartToken> smartToken);
    ~SmartCardTokenWrapper() noexcept;

    std::vector<uint8_t> cert() const;
    libcdoc::result_t deriveECDH1(std::vector<uint8_t> &dst, const std::vector<uint8_t> &public_key, unsigned int idx) final;
    libcdoc::result_t decryptRSA(std::vector<uint8_t> &dst, const std::vector<uint8_t> &data, bool oaep, unsigned int idx) final;
    libcdoc::result_t sign(std::vector<uint8_t> &dst, HashAlgorithm algorithm, const std::vector<uint8_t> &digest, unsigned int idx) final;
    NSError* lastError() const;

private:
    class Private;
    std::unique_ptr<Private> token;
};

#endif
