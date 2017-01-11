//
//  ErrorCell.h
//  MoppApp
//
//  Created by Katrin Annuk on 30/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+Additions.h"

typedef NS_ENUM(NSUInteger, ErrorCellType) {
  ErrorCellTypeError,
  ErrorCellTypeWarning
};

@interface ErrorCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *errorTextView;
@property (assign, nonatomic) ErrorCellType type;
@end
