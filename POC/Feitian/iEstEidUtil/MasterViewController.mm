//
//  MasterViewController.m
//  iEstEidUtil
//

#import "MasterViewController.h"

#import "CardInfoViewController.h"
#import "PINViewController.h"
#import "winscard.h"

#import <vector>

@interface MasterViewController() <PINViewDelegate> {
    SCARDCONTEXT context;
    SCARDHANDLE card;
    DWORD proto;
    NSArray *personalfile;
    NSData *authCert, *signCert;
    NSUInteger authUsage, authLeft, signUsage, signLeft;
    DWORD ret, sw1, sw2;
}

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    ret = SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &context);
    if (ret != SCARD_S_SUCCESS) {
        return;
    }

    DWORD size = 0;
    ret = SCardListReaders(context, NULL, NULL, &size);
    if (ret != SCARD_S_SUCCESS) {
        return;
    }

    std::vector<char> reader(size, 0);
    ret = SCardListReaders(context, NULL, reader.data(), &size);
    if (ret != SCARD_S_SUCCESS) {
        return;
    }

    ret = SCardConnect(context, reader.data(), SCARD_SHARE_SHARED, SCARD_PROTOCOL_T0|SCARD_PROTOCOL_T1, &card, &proto);
    if (ret != SCARD_S_SUCCESS) {
        return;
    }

    [self sendCommand:{ 0x00, 0xA4, 0x00, 0x0C, 0x00 }];
    if (ret != SCARD_S_SUCCESS) {
        return;
    }

    [self sendCommand:{ 0x00, 0xA4, 0x02, 0x0C, 0x02, 0x00, 0x16 }];
    for(BYTE i = 1; i <= 3; ++i) {
        std::vector<BYTE> data = [self sendCommand:{ 0x00, 0xB2, i, 0x04, 0x00 }];
        if(ret != SCARD_S_SUCCESS) {
            continue;
        }
        switch (i) {
            case 1: authLeft = data[5]; break;
            case 2: signLeft = data[5]; break;
            default: break;
        }
    }

    [self sendCommand:{ 0x00, 0xA4, 0x01, 0x0C, 0x02, 0xEE, 0xEE }];
    if(ret != SCARD_S_SUCCESS) {
        return;
    }

    [self sendCommand:{ 0x00, 0xA4, 0x02, 0x0C, 0x02, 0x00, 0x13 }];
    for(BYTE i = 1; i <= 4; ++i) {
        std::vector<BYTE> data = [self sendCommand:{ 0x00, 0xB2, i, 0x04, 0x00 }];
        if(ret != SCARD_S_SUCCESS) {
            continue;
        }
        DWORD count = 0xFFFFFF - ((BYTE(data[12]) << 16) + (BYTE(data[13]) << 8) + BYTE(data[14]));
        switch (i) {
            case 1: authUsage = count; break;
            case 2: signUsage = count; break;
            case 3: authUsage = count ? count : authUsage; break;
            case 4: signUsage = count ? count : signUsage; break;
            default: break;
        }
    }

    [self sendCommand:{ 0x00, 0xA4, 0x02, 0x04, 0x02, 0x50, 0x44 }];
    NSMutableArray *data = [NSMutableArray array];
    for(BYTE i = 1; i <= 16; ++i) {
        std::vector<BYTE> result = [self sendCommand:{ 0x00, 0xB2, i, 0x04, 0x00 }];
        data[i - 1] = [NSString stringWithCString:(const char*)result.data() encoding:NSWindowsCP1252StringEncoding];
    }
    personalfile = data;

    [self sendCommand:{ 0x00, 0xA4, 0x02, 0x04, 0x02, 0xAA, 0xCE }];
    std::vector<BYTE> cert = [self readBinary];
    if(ret == SCARD_S_SUCCESS) {
        cert.resize(BYTE(cert[2]) * 256 + BYTE(cert[3]) + 4);
        authCert = [NSData dataWithBytes:cert.data() length:cert.size()];
    }

    [self sendCommand:{ 0x00, 0xA4, 0x02, 0x04, 0x02, 0xDD, 0xCE }];
    cert = [self readBinary];
    if(ret == SCARD_S_SUCCESS) {
        cert.resize(BYTE(cert[2]) * 256 + BYTE(cert[3]) + 4);
        signCert = [NSData dataWithBytes:cert.data() length:cert.size()];
    }
}

- (std::vector<BYTE>)sendCommand:(const std::vector<BYTE> &)cmd {
    sw1 = sw2 = 0;
    SCARD_IO_REQUEST pioSendPci;
    std::vector<BYTE> data(255 + 3, 0);
    DWORD size(data.size());

    ret = SCardTransmit(card, &pioSendPci, cmd.data(), DWORD(cmd.size()), NULL, data.data(), &size);
    if(ret != SCARD_S_SUCCESS) {
        return std::vector<BYTE>();
    }

    sw1 = data[size-2];
    sw2 = data[size-1];
    data.resize(size - 2);
    if(sw1 == 0x61) {
        std::vector<BYTE> result = [self sendCommand:{ 0x00, 0xC0, 0x00, 0x00, BYTE(sw2) }];
        data.insert(data.end(), result.begin(), result.end());
    }
    return data;
}

- (std::vector<BYTE>)readBinary {
    std::vector<BYTE> data;
    while(data.size() < 0x0600) {
        std::vector<BYTE> result = [self sendCommand:{ 0x00, 0xB0, BYTE(data.size() >> 8), BYTE(data.size()), 0x00 }];
        if(ret != SCARD_S_SUCCESS)
            return std::vector<BYTE>();
        data.insert(data.end(), result.begin(), result.end());
    }
    return data;
}

- (bool)changePin:(NSString*)type old:(NSString *)old newpin:(NSString *)pin {
    BYTE t = 0;
    if ([type isEqualToString:@"PIN1"]) {
        t = 1;
    } else if ([type isEqualToString:@"PIN2"]) {
        t = 2;
    } else if ([type isEqualToString:@"PUK"]) {
        t = 0;
    } else {
        return false;
    }

    std::vector<BYTE> cmd{ 0x00, 0x24, 0x00, t, BYTE(old.length + pin.length) };
    cmd.insert(cmd.end(), old.UTF8String, old.UTF8String + old.length);
    cmd.insert(cmd.end(), pin.UTF8String, pin.UTF8String + pin.length);
    [self sendCommand:cmd];
    return sw1 == 0x90 && sw2 == 0x00;

}

#pragma mark - Table View

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController *view;
    if ([segue.identifier isEqualToString:@"showCardInfo"]) {
        CardInfoViewController *info = (CardInfoViewController*)[segue.destinationViewController topViewController];
        info.personalfile = personalfile;
        view = info;
    } else if ([segue.identifier isEqualToString:@"showPin1"]) {
        PINViewController *pin = (PINViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"PINViewController"];
        pin.delegate = self;
        pin.title = @"PIN1";
        pin.cert = authCert;
        pin.left = authLeft;
        pin.usage = authUsage;
        view = pin;
    } else if ([segue.identifier isEqualToString:@"showPin2"]) {
        PINViewController *pin = (PINViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"PINViewController"];
        pin.delegate = self;
        pin.title = @"PIN2";
        pin.cert = signCert;
        pin.left = signLeft;
        pin.usage = signUsage;
        view = pin;
    }
    if (view != nil) {
        view.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        view.navigationItem.leftItemsSupplementBackButton = YES;
        [segue.destinationViewController setViewControllers:@[view]];
    }
}

@end
