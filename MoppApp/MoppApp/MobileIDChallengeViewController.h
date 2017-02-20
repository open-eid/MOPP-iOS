//
//  MobileIDChallengeViewController.h
//  MoppApp
//
//  Created by Olev Abel on 2/6/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MoppLib/MoppLib.h>

@interface MobileIDChallengeViewController : UIViewController

@property (nonatomic, strong) NSString *challengeID;
@property (nonatomic, strong) NSString *sessCode;
@end
