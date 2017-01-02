//
//  NameAndPhotoCell.h
//  MoppApp
//
//  Created by Katrin Annuk on 30/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NameAndPhotoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
