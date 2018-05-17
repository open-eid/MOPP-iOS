//
//  ApduToken.hpp
//  CryptoLib
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

#ifndef ApduToken_hpp
#define ApduToken_hpp

#include <stdio.h>
#import "cdoc/Token.h"
#import <UIKit/UIKit.h>
#endif /* ApduToken_hpp */


class CDOC_EXPORT ApduToken: public Token
{
public:
    ApduToken(const std::string &password,  UIViewController *controller);
    ApduToken();
    virtual std::vector<uchar> cert() const override;
    virtual std::vector<uchar> decrypt(const std::vector<uchar> &data) const override;
    virtual std::vector<uchar> derive(const std::vector<uchar> &publicKey) const override;
private:
    DISABLE_COPY(ApduToken);
    class Private;
    Private *d;
};
