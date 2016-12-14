//
//  CardInfoViewController.m
//  iEstEidUtil
//
//  Created by Raul Metsma on 24.05.12.
//  Copyright (c) 2012 SK. All rights reserved.
//

#import "CardInfoViewController.h"

@interface CardInfoViewController ()
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *data;

@end

@implementation CardInfoViewController

@synthesize data, personalfile;

- (void)viewDidLoad
{
    [super viewDidLoad];
    for (UITableViewCell *cell in data) {
        if (cell.tag == 1) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",
                                         [personalfile objectAtIndex:cell.tag],
                                         [personalfile objectAtIndex:cell.tag+1]];
        } else {
            cell.detailTextLabel.text = [personalfile objectAtIndex:cell.tag];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
