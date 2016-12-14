//
//  PINViewController.h
//  iEstEidUtil
//

#import <UIKit/UIKit.h>

@protocol PINViewDelegate

- (bool)changePin:(NSString*)type old:(NSString*)old newpin:(NSString*)pin;

@end

@interface PINViewController : UITableViewController

@property (nonatomic,assign) NSData *cert;
@property (nonatomic,assign) NSUInteger left, usage;
@property(nonatomic,assign) id<PINViewDelegate> delegate;

@end
