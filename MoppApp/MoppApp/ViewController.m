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
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [ObjCPP testMethod];
  
}

- (IBAction)unwindFromReaderSelection:(UIStoryboardSegue *)segue {
  if ([segue.sourceViewController isKindOfClass:[ReaderSelectionViewController class]]) {
    ReaderSelectionViewController *controller = segue.sourceViewController;
    self.peripheral = controller.selectedPeripheral;
    NSLog(@"Selected peripheral %@", self.peripheral);

  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"selectReader"]) {
    ReaderSelectionViewController *controller = segue.destinationViewController;
    controller.selectedPeripheral = self.peripheral;
  }
}

@end
