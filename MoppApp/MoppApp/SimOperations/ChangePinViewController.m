//
//  ChangePinViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 10/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ChangePinViewController.h"

@interface ChangePinViewController ()
@property (weak, nonatomic) IBOutlet UITextField *currentPinField;
@property (weak, nonatomic) IBOutlet UITextField *pinField;
@property (weak, nonatomic) IBOutlet UITextField *pinRepeatedField;

@end

@implementation ChangePinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)infoTapped:(id)sender {
  NSString *message = @"* Uus PIN1 peab olema erinev eelmisest.\n\n* Uus PIN1 peab olema 4-12 - numbriline ega tohi sisaldada tähti.\n\n* Uus PIN1 ei saa olla 0000, 1234, ega tohi osaliselt ega täielikult kattuda sinu isikukoodiga.";
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reeglid" message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:^{
    
  }];
}

- (IBAction)okTapped:(id)sender {
  NSString *message = @"See osa ei tööta veel";
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vabandan" message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:^{
    
  }];
}

- (IBAction)backgroundTapped:(id)sender {
  [self.pinField resignFirstResponder];
  [self.currentPinField resignFirstResponder];
  [self.pinRepeatedField resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
