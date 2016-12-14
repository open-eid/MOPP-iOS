//
//  PIN1ViewController.m
//  iEstEidUtil
//

#import "PINViewController.h"

#import <openssl/x509.h>

@interface PINViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *ibusage;
@property (weak, nonatomic) IBOutlet UITableViewCell *ibleft;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *ibcert;
@property (weak, nonatomic) IBOutlet UITextField *ibold;
@property (weak, nonatomic) IBOutlet UITextField *ibnew;
@property (weak, nonatomic) IBOutlet UITextField *ibrepeat;

@end

@implementation PINViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    const unsigned char *p = [_cert bytes];
    X509 *c = d2i_X509(0, &p, [_cert length]);
    if (c) {
        for (UITableViewCell *cell in _ibcert) {
            switch (cell.tag) {
                case 0:
                    cell.detailTextLabel.text = [self commonName:c->cert_info->subject];
                    break;
                case 1:
                    cell.detailTextLabel.text = [self commonName:c->cert_info->issuer];
                    break;
                case 2:
                    cell.detailTextLabel.text = [self date:c->cert_info->validity->notBefore];
                    break;
                case 3:
                    cell.detailTextLabel.text = [self date:c->cert_info->validity->notAfter];
                    break;
                default:
                    break;
            }
        }
        X509_free(c);
    }

    _ibusage.detailTextLabel.text = [NSString stringWithFormat:@"%u", _usage];
    _ibleft.detailTextLabel.text = [NSString stringWithFormat:@"%u", _left];
    [self pinCancel];
}

- (NSString*)commonName:(X509_NAME*)name {
    NSString *result;
    for(int i = 0; i < X509_NAME_entry_count(name); ++i) {
        X509_NAME_ENTRY *e = X509_NAME_get_entry(name, i);
        const char *obj = OBJ_nid2sn(OBJ_obj2nid(X509_NAME_ENTRY_get_object(e)));
        if (strcmp(obj, "CN") == 0) {
            unsigned char *data = 0;
            /*int size =*/ ASN1_STRING_to_UTF8(&data, X509_NAME_ENTRY_get_data(e));
            result = [NSString stringWithUTF8String:(char*)data];
            OPENSSL_free(data);
        }
    }
    return result;
}

- (NSString*)date:(ASN1_TIME*)date {
    ASN1_GENERALIZEDTIME *generalized = ASN1_TIME_to_generalizedtime(date, NULL);
    if (!generalized) {
        return nil;
    }
    // ASN1 generalized times look like this: "20131114230046Z"
    //                                format:  YYYYMMDDHHMMSS
    //                               indices:  01234567890123
    //                                                   1111
    // There are other formats (e.g. specifying partial seconds or 
    // time zones) but this is good enough for our purposes since
    // we only use the date and not the time.
    //
    // (Source: http://www.obj-sys.com/asn1tutorial/node14.html)
    NSString *str = [NSString stringWithUTF8String:(char *)ASN1_STRING_data(generalized)];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year   = [str substringWithRange:NSMakeRange(0, 4)].intValue;
    components.month  = [str substringWithRange:NSMakeRange(4, 2)].intValue;
    components.day    = [str substringWithRange:NSMakeRange(6, 2)].intValue;
    components.hour   = [str substringWithRange:NSMakeRange(8, 2)].intValue;
    components.minute = [str substringWithRange:NSMakeRange(10, 2)].intValue;
    components.second = [str substringWithRange:NSMakeRange(12, 2)].intValue;

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeZone: [NSTimeZone  defaultTimeZone]];
    [df setDateFormat:@"YYYY-MM-dd HH:mm:ss z"];
    return [df stringFromDate:[NSCalendar.currentCalendar dateFromComponents:components]];
}

- (IBAction)pinCancel {
    _ibold.text = nil;
    _ibnew.text = nil;
    _ibrepeat.text = nil;
}

- (IBAction)pinChange {
    if ([_ibold.text isEqualToString:_ibnew.text]) {
        [[[UIAlertView alloc] initWithTitle:self.title message:@"PINs should be different" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
        return;
    }
    if (![_ibnew.text isEqualToString:_ibrepeat.text]) {
        [[[UIAlertView alloc] initWithTitle:self.title message:@"PINs are different" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
        return;
    }
    if ([_delegate changePin:self.title old:_ibold.text newpin:_ibnew.text]) {
        [[[UIAlertView alloc] initWithTitle:self.title message:@"PIN changed successfully" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
        [self pinCancel];
    } else {
        [[[UIAlertView alloc] initWithTitle:self.title message:@"PIN change failed" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: [self.ibold becomeFirstResponder]; break;
            case 1: [self.ibnew becomeFirstResponder]; break;
            case 2: [self.ibrepeat becomeFirstResponder]; break;
            default: break;
        }
    }
}

@end
