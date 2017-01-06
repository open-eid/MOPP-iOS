//
//  SignedContainerSignatureCell.h
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignedContainerSignatureCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *signatureImageView;
@property (weak, nonatomic) IBOutlet UILabel *signatureNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;
@property (weak, nonatomic) IBOutlet UILabel *signatureValidityLabel;

@end
