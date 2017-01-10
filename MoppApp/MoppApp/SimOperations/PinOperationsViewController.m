//
//  PinOperationsViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 06/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "PinOperationsViewController.h"
#import "ErrorCell.h"
#import <MoppLib/MoppLib.h>

typedef enum : NSUInteger {
  PinOperationsCellReaderNotConnected,
  PinOperationsCellNoCard,
  PinOperationsCellChangePin1,
  PinOperationsCellChangePin2
} PinOperationsCell;

@interface PinOperationsViewController ()<UITextViewDelegate>

@property (nonatomic, assign) BOOL isReaderConnected;
@property (nonatomic, assign) BOOL isCardInserted;
@property (nonatomic, strong) NSArray *cellData;
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
    
  } else if (!self.isCardInserted) {
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellNoCard]];
    
  } else {
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePin1]];
    [cellData addObject:[NSNumber numberWithUnsignedInteger:PinOperationsCellChangePin2]];
  }
  
  self.cellData = cellData;
}

- (void)updateRetryCounters {
  [MoppLibCardActions pin1RetryCountWithViewController:self success:^(NSNumber *count) {
    NSLog(@"Pin 1 retry counter: %@", count);
    
  } failure:^(NSError *error) {
    NSLog(@"Error %@", error);
  }];
  
  [MoppLibCardActions pin2RetryCountWithViewController:self success:^(NSNumber *count) {
    NSLog(@"Pin 2 retry counter: %@", count);
    
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
      
    case PinOperationsCellChangePin1: {
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PinActionCell" forIndexPath:indexPath];
      cell.textLabel.text = Localizations.PinActionsChangePin1;
      return cell;
    }
      
    case PinOperationsCellChangePin2: {
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PinActionCell" forIndexPath:indexPath];
      cell.textLabel.text = Localizations.PinActionsChangePin2;
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
