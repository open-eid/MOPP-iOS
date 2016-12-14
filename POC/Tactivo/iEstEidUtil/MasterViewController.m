//
//  MasterViewController.m
//  iEstEidUtil
//
//  Created by Raul Metsma on 22.04.12.
//  Copyright (c) 2012 SK. All rights reserved.
//

#import "MasterViewController.h"

#import "CardInfoViewController.h"
#import "PINViewController.h"

@interface MasterViewController() {
    CardLib *lib;
}

@end
@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    lib = [[CardLib alloc] initWithDelegate:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Table View

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showCardInfo"]) {
        CardInfoViewController *view = [segue destinationViewController];
        view.personalfile = lib.personalfile;
    } else if ([[segue identifier] isEqualToString:@"showPin1"]) {
        PINViewController *view = [segue destinationViewController];
        view.delegate = self;
        view.title = @"PIN1";
        view.cert = lib.authCert;
        view.left = lib.authLeft;
        view.usage = lib.authUsage;
    } else if ([[segue identifier] isEqualToString:@"showPin2"]) {
        PINViewController *view = [segue destinationViewController];
        view.delegate = self;
        view.title = @"PIN2";
        view.cert = lib.signCert;
        view.left = lib.signLeft;
        view.usage = lib.signUsage;
    }
}

#pragma mark - CardLib

- (void)message:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:@"Reader" message:msg delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
}

#pragma mark - PINViewDelegate

- (bool)changePin:(NSString*)type old:(NSString *)old newpin:(NSString *)pin
{
    if ([type isEqualToString:@"PIN1"]) {
        return [lib changePin1:old newpin:pin];
    } else if ([type isEqualToString:@"PIN2"]) {
        return [lib changePin2:old newpin:pin];
    } else if ([type isEqualToString:@"PUK"]) {
        return [lib changePuk:old newpin:pin];
    } else {
        return false;
    }
}

@end
