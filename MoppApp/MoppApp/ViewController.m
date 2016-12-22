//
//  ViewController.m
//  MoppApp
//
//  Created by Ants Käär on 20.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ViewController.h"
#import "MoppLib/ObjCPP.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ReaderSelectionViewController.h"

@interface ViewController ()
@property (nonatomic, strong) CBPeripheral *peripheral;
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

- (IBAction)unwindFromReaderSelection:(UIStoryboardSegue *)segue {
  if ([segue.sourceViewController isKindOfClass:[ReaderSelectionViewController class]]) {
    ReaderSelectionViewController *controller = segue.sourceViewController;
    self.peripheral = controller.selectedPeripheral;
    NSLog(@"Selected peripheral %@", self.peripheral);

  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"ReaderSelection"]) {
    ReaderSelectionViewController *controller = segue.destinationViewController;
    controller.selectedPeripheral = self.peripheral;
  }
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
