//
//  ContainerDetailsHeaderCell.m
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "ContainerDetailsHeaderCell.h"

@implementation ContainerDetailsHeaderCell

- (void)awakeFromNib {
  [super awakeFromNib];
  
  [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
