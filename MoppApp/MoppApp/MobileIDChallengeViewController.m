//
//  MobileIDChallengeViewController.m
//  MoppApp
//
//  Created by Olev Abel on 2/6/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MobileIDChallengeViewController.h"
#import <MoppLib/MoppLibConstants.h>


static double kRequestTimeout = 60.0;

@interface MobileIDChallengeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *mobileIDChallengeCodeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *mobileIDSessionCounter;

@property (nonatomic) double currentProgress;
@property (nonatomic, strong) NSTimer *sessionTimer;
@end

@implementation MobileIDChallengeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.mobileIDChallengeCodeLabel.text = Localizations.ChallengeCodeLabel(self.challengeID);
  self.currentProgress = 0.0;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveCreateSignatureStatus:) name:kSignatureAddedToContainerNotificationName object:nil];
  self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSessionProgress:) userInfo:nil repeats:YES];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)receiveCreateSignatureStatus:(NSNotification *)notification {
  [self.sessionTimer invalidate];
  [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewWillDisAppear:(BOOL)animated {
  [self.sessionTimer invalidate];
}

- (void)updateSessionProgress:(NSTimer *)timer {
  if (self.currentProgress < 1.0) {
    double step = 1.0/kRequestTimeout;
    self.currentProgress = self.currentProgress + step;
    [self.mobileIDSessionCounter setProgress:self.currentProgress];
  } else {
    [timer invalidate];
    [[MoppLibService sharedInstance] cancelMobileSignatureStatusPolling];
    [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorMessage : Localizations.MobileIdTimeoutMessage}];
  }
}

@end
