//
//  ReaderSelectionViewController.h
//  MoppApp
//
//  Created by Katrin Annuk on 21/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol ReaderSelectionViewControllerDelegate <NSObject>

- (void)peripheralSelected:(CBPeripheral *)peripheral;
- (void)cancelledReaderSelection;
@end

@interface ReaderSelectionViewController : UITableViewController
@property (nonatomic, strong) CBPeripheral *selectedPeripheral;
@property (nonatomic, strong) id<ReaderSelectionViewControllerDelegate> delegate;
@end
