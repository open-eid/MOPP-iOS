//
//  ViewController.m
//  MoppApp
//
//  Created by Ants Käär on 20.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ViewController.h"
#import "MoppLib/ObjCPP.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *openContainerButton;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TestString];
  
  [self.openContainerButton setTitle:@"Open container test.bdoc" forState:UIControlStateNormal];
  [self.label setText:nil];
  
  MSLog(@"test MSLog");
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
