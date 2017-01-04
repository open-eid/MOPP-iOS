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
  [MoppLibCardActions cardPersonalDataWithViewController:self success:^(MoppLibPersonalData *data) {
    
    NSMutableString *name = [NSMutableString new];
    if (data.firstNameLine1.length > 0) {
      [name appendString:data.firstNameLine1];
    }
    if (data.firstNameLine2.length > 0) {
      if (name.length > 0) {
        [name appendString:@" "];
      }
      [name appendString:data.firstNameLine2];
    }
    
    if (data.surname.length > 0) {
      if (name.length > 0) {
        [name appendString:@" "];
      }
      [name appendString:data.surname];
    }
    NSString *message = [NSString stringWithFormat:@"Successfully read some data from card: \nName:%@\nDocument number:%@", name, data.documentNumber];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
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

- (IBAction)createContainer:(id)sender {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"HH:mm:ss yyyy-MM-dd"];
  NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
  NSString *fileName = [NSString stringWithFormat:@"%@.bdoc", stringFromDate];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
  
  NSFileManager *manager = [NSFileManager defaultManager];
  
  NSString *bdocPath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"bdoc"];
  NSData *bdocData = [NSData dataWithContentsOfFile:bdocPath];
  if ([manager createFileAtPath:filePath contents:bdocData attributes:nil]) {
    MSLog(@"Created file: %@", filePath);
  } else {
    MSLog(@"Failed to create file");
  }
}

@end
