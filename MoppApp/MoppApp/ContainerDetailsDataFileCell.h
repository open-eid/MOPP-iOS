//
//  ContainerDetailsDataFileCell.h
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContainerDetailsDataFileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *dataFileImageView;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;

@end
