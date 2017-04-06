//
//  MobileIDChallengeViewController.m
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import "MobileIDChallengeViewController.h"
#import "Constants.h"

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
    double step = 1.0 / kRequestTimeout;
    self.currentProgress = self.currentProgress + step;
    [self.mobileIDSessionCounter setProgress:self.currentProgress];
  } else {
    [timer invalidate];
    [[MoppLibService sharedInstance] cancelMobileSignatureStatusPolling];
    [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorMessage : Localizations.MobileIdTimeoutMessage}];
  }
}

@end
