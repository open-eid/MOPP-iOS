//
//  ViewController.m
//  MoppApp
//
//  Created by Ants Käär on 20.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ViewController.h"
#import <MoppLib/MoppLib.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *openContainerButton;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabSigning];
  
  [self.openContainerButton setTitle:@"Open container test.bdoc" forState:UIControlStateNormal];
  [self.label setText:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}
- (IBAction)readCardActionPressed:(id)sender {
  [MoppLibCardActions cardPersonalDataWithViewController:self success:^(NSData *data) {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil) message:@"Successfully read some data from card" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
      
    }];
    
  } failure:^(NSError *error) {
    NSString *message;
    if (error.code == moppLibCardNotFoundError) {
      message = NSLocalizedString(@"Card not found", nil);
      
    } else if (error.code == moppLibReaderNotFoundError) {
      message = NSLocalizedString(@"Reader not attached", nil);
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
      
    }];
    
  }];
}

- (IBAction)openContainerButtonPressed:(id)sender {
  
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:@"test" ofType:@"bdoc"];
  
  NSArray *signatures = [ObjCPP getSignaturesWithContainerPath:path];
  
  
  NSMutableString *signaturesString = [[NSMutableString alloc] initWithString:@""];
  [signaturesString appendString:@"Container:\n\n"];
  [signaturesString appendString:@"test.bdoc\n\n\n"];
  [signaturesString appendString:@"Signatures:\n\n"];
  
  for (int i = 0; i < signatures.count; i++) {
    NSString *signature = [signatures objectAtIndex:i];
    
    [signaturesString appendString:[NSString stringWithFormat:@"%d) ", i + 1]];
    [signaturesString appendString:signature];
    [signaturesString appendString:@"\n"];
  }
  [self.label setText:[signaturesString copy]];
}

@end
