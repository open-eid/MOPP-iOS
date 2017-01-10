//
//  ErrorCell.m
//  MoppApp
//
//  Created by Katrin Annuk on 30/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

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
