//
//  ApduToken.hpp
//  CryptoLib
//
//  Created by Siim Suu on 04/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

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
