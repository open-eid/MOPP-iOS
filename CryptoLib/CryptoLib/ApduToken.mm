//
//  ApduToken.cpp
//  CryptoLib
//
//  Created by Siim Suu on 04/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#include "ApduToken.h"

#import "cdoc/Token.h"
#import <UIKit/UIKit.h>
#include <iostream>
#include "base64.h"

class ApduToken::Private{
public:
    
    std::vector<uchar> certResponse;
    std::vector<uchar> decryptResponse;
};
    UIViewController *uiViewController;

std::vector<uchar>  cert;
std::string pin1;

ApduToken::ApduToken(const std::string &password, UIViewController *controller)
: d(new Private){
    uiViewController = controller;
    pin1 = password;
}

std::vector<uchar> ApduToken::cert() const{
    return d->certResponse;
}

std::vector<uchar> ApduToken::decrypt(const std::vector<uchar> &data) const{
    return d->decryptResponse;
}

std::vector<uchar> ApduToken::derive(const std::vector<uchar> &publicKey) const{
    return d->decryptResponse;
}

ApduToken::ApduToken()
{
    
}
