//
//  SignedViewController.m
//  MoppApp
//
//  Created by Ants Käär on 29.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "SignedDetailViewController.h"

@interface SignedDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *testLabel;

@end

@implementation SignedDetailViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:self.containerPath];
  
  [self.testLabel setText:self.containerPath];
  
}

@end
