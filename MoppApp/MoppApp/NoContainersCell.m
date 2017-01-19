//
//  NoContainersCell.m
//  MoppApp
//
//  Created by Ants Käär on 19.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "NoContainersCell.h"

@implementation NoContainersCell

- (void)awakeFromNib {
  [super awakeFromNib];
 
  [self setSelectionStyle:UITableViewCellSelectionStyleNone];
  
  [self.noContainersLabel setText:Localizations.NoContainersCellTitle];
}

@end
