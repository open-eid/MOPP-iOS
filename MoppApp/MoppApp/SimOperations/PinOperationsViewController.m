//
//  PinOperationsViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 06/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "PinOperationsViewController.h"
#import "ChangePinViewController.h"
#import "ErrorCell.h"
#import "InfoCell.h"
#import <MoppLib/MoppLib.h>

typedef enum : NSUInteger {
  PinOperationsCellReaderNotConnected,
  PinOperationsCellNoCard,
  PinOperationsCellInfo,
  PinOperationsCellChangePin1,
  PinOperationsCellChangePin2,
  PinOperationsCellUnblockPin1,
  PinOperationsCellUnblockPin2
  
} PinOperationsCell;

@interface PinOperationsViewController ()<UITextViewDelegate>

@property (nonatomic, assign) BOOL isReaderConnected;
@property (nonatomic, assign) BOOL isCardInserted;
@property (nonatomic, strong) NSArray *cellData;
@property (strong, nonatomic) IBOutlet UIView *sectionHeaderLine;
@property (nonatomic, strong) NSNumber *pin1RetryCount;
@property (nonatomic, strong) NSNumber *pin2RetryCount;

@end

@implementation PinOperationsViewController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

  self.title = Localizations.TabSimSettings;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardStatusChanged) name:kMoppLibNotificationReaderStatusChanged object:nil];
  
  UINib *nib = [UINib nibWithNibName:@"ErrorCell" bundle:nil];
  [self.tableView registerNib:nib forCellReuseIdentifier:@"ErrorCell"];
  
  nib = [UINib nibWithNibName:@"InfoCell" bundle:nil];
  [self.tableView registerNib:nib forCellReuseIdentifier:@"InfoCell"];
  
  [self setupCells];

  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    
    if (self.isReaderConnected && self.isCardInserted) {
      [self updateRetryCounters];
    }
  }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (self.isReaderConnected && self.isCardInserted) {
    [self updateRetryCounters];
  }
}
- (void)setIsCardInserted:(BOOL)isCardInserted {
  if (_isCardInserted != isCardInserted) {
    _isCardInserted = isCardInserted;
    [self setupCells];
    [self.tableView reloadData];
  }
}

- (void)setIsReaderConnected:(BOOL)isReaderConnected {
  if (_isReaderConnected != isReaderConnected) {
    _isReaderConnected = isReaderConnected;
    [self setupCells];
    [self.tableView reloadData];
  }
}

- (void)setupCells {
  NSMutableArray *cellData = [NSMutableArray new];
  
  if (!self.isReaderConnected) {
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellReaderNotConnected]];
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellInfo]];
    
  } else if (!self.isCardInserted) {
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellNoCard]];
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellInfo]];
    
  } else {
    if (self.pin1RetryCount) {
      if (self.pin1RetryCount.intValue > 0) {
        [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePin1]];
        
      } else if(self.pin1RetryCount.intValue == 0) {
        [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellUnblockPin1]];
      }
    }
    
    if (self.pin2RetryCount) {
      if (self.pin2RetryCount.intValue > 0) {
        [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePin2]];
        
      } else if(self.pin2RetryCount.intValue == 0) {
        [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellUnblockPin2]];
      }
    }
  }
  
  self.cellData = cellData;
}

- (void)updateRetryCounters {
  [MoppLibCardActions pin1RetryCountWithViewController:self success:^(NSNumber *count) {
    if (self.pin1RetryCount != count) {
      self.pin1RetryCount = count;
      [self setupCells];
      [self.tableView reloadData];
    }

  } failure:^(NSError *error) {
    NSLog(@"Error %@", error);
  }];
  
  [MoppLibCardActions pin2RetryCountWithViewController:self success:^(NSNumber *count) {
    if (self.pin2RetryCount != count) {
      self.pin2RetryCount = count;
      [self setupCells];
      [self.tableView reloadData];
    }

    
  } failure:^(NSError *error) {
    NSLog(@"Error %@", error);
  }];
}

- (void)cardStatusChanged {
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
  }];
}

NSString *readerNotFoundPath2 = @"myeid://readerNotConnected";

- (void)setupReaderNotFoundMessage:(UITextView *)textView {
  NSString *tapHere = Localizations.MyEidTapHere;
  [textView setLinkedText:Localizations.MyEidWarningReaderNotFound(tapHere) withLinks:@{readerNotFoundPath2:tapHere}];
}

#pragma mark - Tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.cellData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSNumber *cellType = self.cellData[indexPath.row];
  
  switch (cellType.unsignedIntegerValue) {
    case PinOperationsCellNoCard: {
      ErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ErrorCell" forIndexPath:indexPath];
      cell.type = ErrorCellTypeWarning;
      cell.errorTextView.text = Localizations.MyEidWarningCardNotFound;
      return cell;
    }
      
    case PinOperationsCellReaderNotConnected: {
      ErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ErrorCell" forIndexPath:indexPath];
      cell.errorTextView.delegate = self;
      cell.type = ErrorCellTypeWarning;
      [self setupReaderNotFoundMessage:cell.errorTextView];
      return cell;
    }
      
    case PinOperationsCellUnblockPin2:
    case PinOperationsCellUnblockPin1:
    case PinOperationsCellChangePin2:
    case PinOperationsCellChangePin1: {

      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PinActionCell" forIndexPath:indexPath];
      
      if (cellType.unsignedIntegerValue == PinOperationsCellChangePin1) {
        cell.textLabel.text = Localizations.PinActionsChangePin(Localizations.PinActionsPin1);
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellChangePin2) {
        cell.textLabel.text = Localizations.PinActionsChangePin(Localizations.PinActionsPin2);
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellUnblockPin1) {
        cell.textLabel.text = Localizations.PinActionsUnblockPin(Localizations.PinActionsPin1);
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellUnblockPin2) {
        cell.textLabel.text = Localizations.PinActionsUnblockPin(Localizations.PinActionsPin2);
      }
      return cell;
    }
      
    case PinOperationsCellInfo: {
        InfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
      cell.infoTextView.text = Localizations.PinActionsInfo;
      
      return cell;
    }
      
    default:
      break;
  }
  
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([sender isKindOfClass:[UITableViewCell class]]) {
    NSIndexPath *path = [self.tableView indexPathForCell:sender];
    ChangePinViewController *controller = segue.destinationViewController;
    
    NSNumber *cellType = self.cellData[path.row];
    if (cellType.unsignedIntegerValue == PinOperationsCellChangePin1) {
      controller.type = PinOperationTypeChangePin1;
      
    } else if (cellType.unsignedIntegerValue == PinOperationsCellChangePin2) {
      controller.type = PinOperationTypeChangePin2;

    } else if (cellType.unsignedIntegerValue == PinOperationsCellUnblockPin1) {
      controller.type = PinOperationTypeUnblockPin1;

    } else if (cellType.unsignedIntegerValue == PinOperationsCellUnblockPin2) {
      controller.type = PinOperationTypeUnblockPin2;
    }
  }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
  if ([[URL absoluteString] isEqualToString:readerNotFoundPath2]) {
    [self updateRetryCounters];
    return NO;
    
  }
  
  return YES; // let the system open this URL
}

@end
