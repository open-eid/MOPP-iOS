//
//  ContainerDetailsHeaderCell.h
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContainerDetailsHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *containerImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@end
