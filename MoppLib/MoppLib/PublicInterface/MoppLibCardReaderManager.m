//
//  MoppLibCardReaderManager.m
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

#import "MoppLibCardReaderManager.h"
#import "CardActionsManager.h"
#import "CardReaderiR301.h"
#import "ReaderInterface.h"

@interface MoppLibCardReaderManagerContext : NSObject
@property (nonatomic) SCARDCONTEXT handle;
@end

@implementation MoppLibCardReaderManagerContext

-(instancetype)init {
    if (self = [super init]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &self->_handle);
            printLog(@"ID-CARD: Started reader discovery: %x", self.handle);
        });
    }
    return self;
}

-(void)dealloc {
    SCARDCONTEXT copy = self.handle;
    dispatch_async(dispatch_get_main_queue(), ^{
        FtDidEnterBackground(1);
        SCardCancel(copy);
        SCardReleaseContext(copy);
        printLog(@"ID-CARD: Stopped reader discovery with status: %x", copy);
    });
}

@end

@interface MoppLibCardReaderManager()<ReaderInterfaceDelegate>
@property (nonatomic, strong) MoppLibCardReaderManagerContext *context;
@property (nonatomic, strong) ReaderInterface *readerInterface;
@property (nonatomic) MoppLibCardReaderStatus status;
@end

@implementation MoppLibCardReaderManager

+ (MoppLibCardReaderManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibCardReaderManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    sharedInstance.status = Initial;
    sharedInstance.readerInterface = [ReaderInterface new];
    [sharedInstance.readerInterface setDelegate:sharedInstance];
  });
  return sharedInstance;
}

- (void)startDiscoveringReaders {
    printLog(@"ID-CARD: Starting reader discovery");
    [self updateStatus:_status == Initial ? Initial : ReaderRestarted];
    self.context = [MoppLibCardReaderManagerContext new];
}

- (void)stopDiscoveringReaders {
    [self stopDiscoveringReadersWithStatus:Initial];
}

- (void)stopDiscoveringReadersWithStatus:(MoppLibCardReaderStatus)status {
    printLog(@"ID-CARD: Stopping reader discovery with status %lu", (unsigned long)status);
    CardActionsManager.sharedInstance.reader = nil;
    _status = status;
    self.context = nil;
}

- (void)updateStatus:(MoppLibCardReaderStatus)status {
    if (_status == status) {
        return;
    }

    _status = status;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate)
            [self.delegate moppLibCardReaderStatusDidChange:status];
    });
}

#pragma mark - ReaderInterfaceDelegate

- (void)readerInterfaceDidChange:(BOOL)attached bluetoothID:(NSString *)bluetoothID {
    printLog(@"ID-CARD attached: %d", attached);
    if (!attached) {
        CardActionsManager.sharedInstance.reader = nil;
        return [self updateStatus:Initial];
    }
    CardActionsManager.sharedInstance.reader = [[CardReaderiR301 alloc] initWithContextHandle:self.context.handle];
    if (CardActionsManager.sharedInstance.reader != nil) {
        [self updateStatus:ReaderConnected];
    }
}

- (void)cardInterfaceDidDetach:(BOOL)attached {
    printLog(@"ID-CARD: Card (interface) attached: %d", attached);
    [self updateStatus:attached ? CardConnected : ReaderConnected];
}

- (void)didGetBattery:(NSInteger)battery {
}

- (void)findPeripheralReader:(NSString *)readerName {
    printLog(@"ID-CARD: Reader name: %@", readerName);
}

@end
