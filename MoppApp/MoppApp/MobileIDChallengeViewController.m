//
//  MobileIDChallengeViewController.m
//  MoppApp
//
//  Created by Olev Abel on 2/6/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MobileIDChallengeViewController.h"

@interface MobileIDChallengeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *mobileIDChallengeCodeLabel;

@end

@implementation MobileIDChallengeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.mobileIDChallengeCodeLabel.text = Localizations.ChallengeCodeLabel(self.challengeID);
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


@end
