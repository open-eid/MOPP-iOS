//
//  CardReaderIR301.m
//  MoppLib
//
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

#import "CardReaderiR301.h"
#import "NSString+Additions.h"
#import "NSData+Additions.h"
#import "MoppLibCardReaderManager.h"
#import "MoppLibError.h"
#import "ReaderInterface.h"

@implementation NSMutableData (CardReaderiR301)

- (UInt16)takeSW {
    UInt16 value = 0;
    if (self.length < 2)
        return value;
    [self getBytes:&value range:NSMakeRange(self.length - 2, 2)];
    [self setLength:self.length - 2];
    return CFSwapInt16BigToHost(value);
}

@end


@implementation CardReaderiR301 {
    SCARDCONTEXT contextHandle;
    SCARDHANDLE cardHandle;
    SCARD_IO_REQUEST pioSendPci;
}

-(void)dealloc {
    if (cardHandle) {
        SCardDisconnect(cardHandle, SCARD_LEAVE_CARD);
    }
}

-(id)initWithContextHandle:(SCARDCONTEXT)_contextHandle {
    //assert(_contextHandle);
    if (!_contextHandle) {
        printLog(@"ID-CARD: Invalid context handle: %x", _contextHandle);
        return nil;
    }

    char modelNameBuf[100];
    unsigned int modelNameLength = sizeof(modelNameBuf);
    if (FtGetAccessoryModelName(_contextHandle, &modelNameLength, modelNameBuf) != 0) {
        printLog(@"ID-CARD: Failed to identify reader");
        return nil;
    }
    modelNameBuf[modelNameLength] = '\0';
    NSString *modelName = [NSString stringWithUTF8String:modelNameBuf];

    printLog(@"ID-CARD: Checking if card reader is supported: %s", modelNameBuf);
    if (![modelName hasPrefix:@"iR301"]) {
        printLog(@"ID-CARD: Unsupported reader: %@", modelName);
        return nil;
    }

    if (self = [super init]) {
        contextHandle = _contextHandle;
        pioSendPci.dwProtocol = SCARD_PROTOCOL_UNDEFINED;
        pioSendPci.cbPciLength = sizeof(SCARD_IO_REQUEST);
    }
    return self;
}

- (NSMutableData*)transmitCommand:(const NSData *)apdu {
    printLog(@"ID-CARD: Transmitting APDU data %@", [apdu hexString]);
    NSMutableData *response = [NSMutableData dataWithLength:512];
    NSUInteger responseSize = response.length;
    if (SCARD_S_SUCCESS != SCardTransmit(cardHandle, &pioSendPci, apdu.bytes, (DWORD)apdu.length,
                                         NULL, response.mutableBytes, (LPDWORD)&responseSize)) {
        printLog(@"ID-CARD: Failed to send APDU data");
        return nil;
    }
    if (responseSize < 2) {
        printLog(@"ID-CARD: Response size must be atleast 2. Response size: %lu", (unsigned long)responseSize);
        return nil;
    }
    [response setLength:responseSize];
    printLog(@"IR301 Response: %@", [response hexString]);
    return response;
}

#pragma mark - CardReaderWrapper

- (void)transmitCommand:(const NSString *)commandHex success:(SCDataSuccessBlock)success failure:(FailureBlock)failure {
    printLog(@"ID-CARD: CardReaderiR301. transmitCommand.");

    NSData *apdu = [commandHex toHexData];
    NSMutableData *response = [self transmitCommand:apdu];
    if (response == nil) {
        return failure([MoppLibError readerProcessFailedError]);
    }

    UInt16 sw = [response takeSW];
    if ((sw & 0xFF00) == 0x6C00) {
        NSMutableData *mutableApdu = [apdu mutableCopy];
        ((UInt8*)mutableApdu.mutableBytes)[apdu.length - 1] = (UInt8)sw; // set new Le byte
        response = [self transmitCommand:mutableApdu];
        if(response == nil) {
            return failure([MoppLibError readerProcessFailedError]);
        }
        sw = [response takeSW];
    }

    // While there is additional response data in the chip card: 61 XX
    // where XX defines the size of additional data in bytes)
    unsigned char getResponseApdu[5] = { 0x00, 0xC0, 0x00, 0x00, 0x00 };
    while ((sw & 0xFF00) == 0x6100) {
        getResponseApdu[4] = (UInt8)sw;
        // Set the size of additional data to get from the chip
        NSMutableData *data = [self transmitCommand:[NSData dataWithBytesNoCopy:getResponseApdu length:sizeof(getResponseApdu) freeWhenDone:NO]];
        if(data == nil) {
            return failure([MoppLibError readerProcessFailedError]);
        }
        sw = [data takeSW];
        [response appendData:data];
    }

    success(response, sw);
}

- (void)transmitCommandChecked:(const NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self transmitCommand:commandHex success:^(NSData *responseData, UInt16 sw) {
        if (sw == 0x9000) {
            success(responseData);
        } else {
            failure([MoppLibError generalError]);
        }
    } failure:failure];
}

- (void)powerOnCard:(DataSuccessBlock)success failure:(FailureBlock)failure {
    if (cardHandle) {
        SCardDisconnect(cardHandle, SCARD_LEAVE_CARD);
        cardHandle = 0;
    }

    char mszReaders[128];
    DWORD dwReaders = sizeof(mszReaders);
    LONG iRet = SCardListReaders(contextHandle, NULL, mszReaders, &dwReaders);
    if(iRet != SCARD_S_SUCCESS) {
        printLog(@"SCardListReaders error %08x",iRet);
        return failure([MoppLibError readerProcessFailedError]);
    }

    iRet = SCardConnect(contextHandle, mszReaders, SCARD_SHARE_SHARED,
                        SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &cardHandle, &pioSendPci.dwProtocol);
    if (iRet != SCARD_S_SUCCESS) {
        return failure([MoppLibError readerProcessFailedError]);
    }

    NSMutableData *atr = [NSMutableData dataWithLength:32];
    NSUInteger atrSize = atr.length;
    DWORD dwStatus = 0;
    iRet = SCardStatus(cardHandle, NULL, NULL, &dwStatus, NULL, (LPBYTE)atr.mutableBytes, (LPDWORD)&atrSize);
    [atr setLength:atrSize];
    printLog(@"SCardStatus status: %d ATR: %@", dwStatus, [atr hexString]);

    if (dwStatus == SCARD_PRESENT) {
        success(atr);
    } else {
        printLog(@"ID-CARD: Did not successfully power on card");
        failure([MoppLibError readerProcessFailedError]);
    }
}

- (BOOL)isCardInserted {
    DWORD status = [self cardStatus];
    return status == SCARD_PRESENT || status == SCARD_POWERED || status == SCARD_SWALLOWED;
}

- (BOOL)isConnected {
    DWORD dwStatus;
    SCARDHANDLE fakeHandle = 1;
    return SCardStatus(fakeHandle, NULL, NULL, &dwStatus, NULL, NULL, NULL) == SCARD_S_SUCCESS;
}

- (DWORD)cardStatus {
    DWORD status;
    SCARDHANDLE fakeHandle = 1;
    if (SCardStatus(fakeHandle, NULL, NULL, &status, NULL, NULL, NULL) != SCARD_S_SUCCESS) {
        return SCARD_ABSENT;
    }
    return status;
}

- (BOOL)isCardPoweredOn {
    return [self cardStatus] == SCARD_PRESENT;
}

@end
