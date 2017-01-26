//
//  DependencyTableViewCell.h
//  MoppApp
//
//  Created by Olev Abel on 1/26/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DependencyTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dependencyNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *licenseNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *licenseLinkLabel;


@end
