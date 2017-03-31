//
//  ErrorCell.m
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

#import "ErrorCell.h"
#import "ViewWithRoundedCorners.h"
#import "UIColor+Additions.h"

@interface ErrorCell()
@property (weak, nonatomic) IBOutlet ViewWithRoundedCorners *containerView;
@property (weak, nonatomic) IBOutlet UIButton *dummyButton;

@end

@implementation ErrorCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
  [self updateTheme];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setType:(ErrorCellType)type {
  _type = type;
  [self updateTheme];
}

- (void)prepareForReuse {
  [self.errorTextView setLinkedText:@"" withLinks:nil];

}

- (void)updateTheme {
  if (self.type == ErrorCellTypeError) {
    self.containerView.borderColor = [UIColor errorBorderColor];
    self.containerView.backgroundColor = [UIColor errorBackgroundColor];
    self.dummyButton.tintColor = [UIColor errorIconTint];
    
  } else {
    self.containerView.borderColor = [UIColor warningBorderColor];
    self.containerView.backgroundColor = [UIColor warningBackgroundColor];
    self.dummyButton.tintColor = [UIColor warningIconTint];
  }
}

@end
