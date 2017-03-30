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
  PinOperationsCellChangePuk,
  PinOperationsCellUnblockPin1,
  PinOperationsCellUnblockPin2,
  PinOperationsCellErrorPin1Blocked,
  PinOperationsCellErrorPin2Blocked,
  PinOperationsCellErrorPukBlocked,
  PinOperationsCellSeparator
  
} PinOperationsCell;

@interface PinOperationsViewController ()<UITextViewDelegate>

@property (nonatomic, assign) BOOL isReaderConnected;
@property (nonatomic, assign) BOOL isCardInserted;
@property (nonatomic, strong) NSArray *cellData;
@property (nonatomic, strong) NSNumber *pin1RetryCount;
@property (nonatomic, strong) NSNumber *pin2RetryCount;
@property (nonatomic, strong) NSNumber *pukRetryCount;
@end

@implementation PinOperationsViewController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
  self.pin2RetryCount = [NSNumber numberWithInt:-1];
  self.pin1RetryCount = [NSNumber numberWithInt:-1];
  self.pukRetryCount = [NSNumber numberWithInt:-1];

  self.title = Localizations.TabSimSettings;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardStatusChanged) name:kMoppLibNotificationReaderStatusChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retryCounterChanged) name:kMoppLibNotificationRetryCounterChanged object:nil];

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
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellSeparator]];
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellInfo]];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
  } else if (!self.isCardInserted) {
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellNoCard]];
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellSeparator]];
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellInfo]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    
  } else {
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];

    if (self.pin1RetryCount.integerValue == 0) {
      [cellData addObject:[NSNumber numberWithInt:PinOperationsCellErrorPin1Blocked]];
    }
    
    if (self.pin2RetryCount.integerValue == 0) {
      [cellData addObject:[NSNumber numberWithInt:PinOperationsCellErrorPin2Blocked]];
    }
    
    if (self.pukRetryCount.integerValue == 0) {
      [cellData addObject:[NSNumber numberWithInt:PinOperationsCellErrorPukBlocked]];
    }
    
    if (self.pin1RetryCount.intValue > 0) {
      [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePin1]];
      
    } else if(self.pin1RetryCount.intValue == 0) {
      [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellUnblockPin1]];
    }
    
    if (self.pin2RetryCount.intValue > 0) {
      [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePin2]];
      
    } else if(self.pin2RetryCount.intValue == 0) {
      [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellUnblockPin2]];
    }
    
    if (self.pukRetryCount.intValue > 0) {
      [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePuk]];
    }
  }
  
  self.cellData = cellData;
}

- (void)updateRetryCounters {
  [MoppLibCardActions pin1RetryCountWithViewController:self success:^(NSNumber *count) {
    if (self.pin1RetryCount != count) {
      self.pin1RetryCount = count;
      [self updateBlockingIndicators];
    }

  } failure:^(NSError *error) {
    MSLog(@"Error %@", error);
  }];
  
  [MoppLibCardActions pin2RetryCountWithViewController:self success:^(NSNumber *count) {
    if (self.pin2RetryCount != count) {
      self.pin2RetryCount = count;
      [self updateBlockingIndicators];
    }

  } failure:^(NSError *error) {
    MSLog(@"Error %@", error);
  }];
  
  [MoppLibCardActions pukRetryCountWithViewController:self success:^(NSNumber *count) {
    if (self.pukRetryCount != count) {
      self.pukRetryCount = count;
      [self updateBlockingIndicators];
    }
    
    
  } failure:^(NSError *error) {
    MSLog(@"Error %@", error);
  }];
}

- (void)updateBlockingIndicators {
  int badgeValue = 0;
  if (self.pin1RetryCount && self.pin1RetryCount.intValue == 0) {
    badgeValue++;
  }
  
  if (self.pin2RetryCount && self.pin2RetryCount.intValue == 0) {
    badgeValue++;
  }
  
  if (self.pukRetryCount && self.pukRetryCount.intValue == 0) {
    badgeValue++;
  }
  
  if (badgeValue > 0) {
    self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%i", badgeValue];
  } else {
    self.navigationController.tabBarItem.badgeValue = nil;
  }
  [self setupCells];
  [self.tableView reloadData];
}

- (void)retryCounterChanged {
  [self updateRetryCounters];
}

- (void)cardStatusChanged {
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    [self updateRetryCounters];
  }];
}

NSString *readerNotFoundPath2 = @"myeid://readerNotConnected";
NSString *supportedReaderPath2 = @"myeid://supportedReader";

- (void)setupReaderNotFoundMessage:(UITextView *)textView {
  NSString *tapHere = Localizations.MyEidTapHere;
  NSString *supportedReader = Localizations.MyEidSupportedReader;
  
  [textView setLinkedText:Localizations.MyEidWarningReaderNotFound(tapHere, supportedReader) withLinks:@{readerNotFoundPath2:tapHere, supportedReaderPath2:supportedReader}];
}

#pragma mark - Tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.cellData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSNumber *cellType = self.cellData[indexPath.row];
  
  switch (cellType.unsignedIntegerValue) {
      
    case PinOperationsCellErrorPin1Blocked:
    case PinOperationsCellErrorPin2Blocked:
    case PinOperationsCellErrorPukBlocked: {
      ErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ErrorCell" forIndexPath:indexPath];
      cell.errorTextView.delegate = self;
      cell.type = ErrorCellTypeError;
      NSString *pinType;
      
      if (cellType.unsignedIntegerValue == PinOperationsCellErrorPin1Blocked) {
        pinType = Localizations.PinActionsPin1;
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellErrorPin2Blocked) {
        pinType = Localizations.PinActionsPin2;
      
      } else {
        pinType = Localizations.PinActionsPuk;
      }
      
      cell.errorTextView.text = Localizations.PinActionsPinBlocked(pinType);
      return cell;
    }

    case PinOperationsCellSeparator: {
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SeparatorCell"];
      return cell;
    }
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
    case PinOperationsCellChangePin1:
    case PinOperationsCellChangePuk: {

      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PinActionCell" forIndexPath:indexPath];
      
      if (cellType.unsignedIntegerValue == PinOperationsCellChangePin1) {
        cell.textLabel.text = Localizations.PinActionsChangePin(Localizations.PinActionsPin1);
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellChangePin2) {
        cell.textLabel.text = Localizations.PinActionsChangePin(Localizations.PinActionsPin2);
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellUnblockPin1) {
        cell.textLabel.text = Localizations.PinActionsUnblockPin(Localizations.PinActionsPin1);
        
      } else if (cellType.unsignedIntegerValue == PinOperationsCellUnblockPin2) {
        cell.textLabel.text = Localizations.PinActionsUnblockPin(Localizations.PinActionsPin2);
      
      } else if (cellType.unsignedIntegerValue == PinOperationsCellChangePuk) {
        cell.textLabel.text = Localizations.PinActionsChangePin(Localizations.PinActionsPuk);
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  NSNumber *cellType = self.cellData[indexPath.row];
  
  if (cellType.unsignedIntegerValue == PinOperationsCellChangePuk) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.ContainerDetailsAttention message:Localizations.PinActionsPukChangeWarning preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      [self performPinChangeSegue:indexPath];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionCancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    
  } else {
    [self performPinChangeSegue:indexPath];
  }
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
    
    } else if (cellType.unsignedIntegerValue == PinOperationsCellChangePuk) {
      controller.type = PinOperationTypeChangePuk;
    }
  }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)performPinChangeSegue:(NSIndexPath *)indexPath {
  [self performSegueWithIdentifier:@"ChangePin" sender:[self tableView:self.tableView cellForRowAtIndexPath:indexPath]];
}
#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
  if ([[URL absoluteString] isEqualToString:readerNotFoundPath2]) {
    [self updateRetryCounters];
    return NO;
    
  } else if ([[URL absoluteString] isEqualToString:supportedReaderPath2]) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.acs.com.hk/en/products/392/acr3901u-s1-secure-bluetooth%C2%AE-contact-card-reader/"]];
  }
  
  return YES; // let the system open this URL
}

@end
