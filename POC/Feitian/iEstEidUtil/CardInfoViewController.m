//
//  CardInfoViewController.m
//  iEstEidUtil
//

#import "CardInfoViewController.h"

@interface CardInfoViewController ()
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *data;

@end

@implementation CardInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    for (UITableViewCell *cell in _data) {
        if (cell.tag == 1) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",
                                         [_personalfile objectAtIndex:cell.tag],
                                         [_personalfile objectAtIndex:cell.tag+1]];
        } else {
            cell.detailTextLabel.text = [_personalfile objectAtIndex:cell.tag];
        }
    }
}

@end
