//
//  ViewController.m
//  MOPP
//
//  Created by Raul Metsma on 03/06/16.
//  Copyright © 2016 RIA. All rights reserved.
//

#import "ViewController.h"

#import "AudioJack/ACRAudioJackReader.h"

#include <vector>

@interface ViewController () <ACRAudioJackReaderDelegate> {
    ACRAudioJackReader *_reader;
}

@property (weak, nonatomic) IBOutlet UILabel *atr;
@property (weak, nonatomic) IBOutlet UITextField *pin;
@property (weak, nonatomic) IBOutlet UILabel *signature;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _reader = [[ACRAudioJackReader alloc] init];
    [_reader setDelegate:self];
}

- (IBAction)connect:(id)sender {
    [_reader resetWithCompletion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            NSData *atr = [_reader powerCardWithAction:ACRCardWarmReset slotNum:0 timeout:10 error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.atr.text = [ViewController toHex:atr];
            });
            if (atr != nil) {
                ACRCardProtocol protocols = ACRProtocolT0 | ACRProtocolT1;
                ACRCardProtocol activeProtocol = [_reader setProtocol:protocols slotNum:0 timeout:10 error:&error];
            }
        });
    }];
}

- (IBAction)login:(id)sender {
    std::vector<uint8_t> resp = [self transmit:{ 0x00, 0x20, 0x02, 0x00, 0x05, 0x35, 0x31, 0x31, 0x31, 0x31 }];
    [[[UIAlertView alloc] initWithTitle:@"Login"
                                message:[self checkOK:resp] ? @"Login OK" : @"Login failed"
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (IBAction)sign:(id)sender {
    if (![self checkOK:[self transmit:{ 0x00, 0xA4, 0x00, 0x00, 0x0C }]] ||
        ![self checkOK:[self transmit:{ 0x00, 0xA4, 0x01, 0x0C, 0x02, 0xEE, 0xEE }]] ||
        ![self checkOK:[self transmit:{ 0x00, 0x22, 0xF3, 0x01 }]] ||
        ![self checkOK:[self transmit:{ 0x00, 0x22, 0x41, 0xB8, 0x02, 0x83, 0x00 }]]) {
        [[[UIAlertView alloc] initWithTitle:@"Sign"
                                    message:@"Failed to sign"
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (std::vector<uint8_t>)transmit:(const std::vector<uint8_t>&)apdu {
    NSError *error = nil;
    NSData *resp = [_reader transmitApdu:apdu.data() length:apdu.size() slotNum:0 timeout:10 error:&error];
    return std::vector<uint8_t>((uint8_t*)resp.bytes, (uint8_t*)resp.bytes + resp.length);
}

- (bool)checkOK:(const std::vector<uint8_t>&)apdu {
    return apdu.size() != 2 && apdu[apdu.size()-2] == 0x90 && apdu[apdu.size()-1] == 0x00;
}

+ (NSString*)toHex:(NSData*)data {
    const unsigned char *dataBuffer = (const unsigned char *)data.bytes;
    if (!dataBuffer)
        return [NSString string];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:data.length * 2];
    for (int i = 0; i < data.length; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    return hexString;
}

@end
