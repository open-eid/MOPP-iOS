//
//  MyEIDViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 30/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "MyEIDViewController.h"
#import <MoppLib/MoppLib.h>
#import "NameAndPhotoCell.h"
#import "PersonalDataCell.h"
#import "ErrorCell.h"
#import "InfoCell.h"
#import "SimpleHeaderView.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "UIColor+Additions.h"
#import "DateFormatter.h"
#import <MBProgressHUD/MBProgressHUD.h>

typedef enum : NSUInteger {
  PersonalDataSectionErrors,
  PersonalDataSectionData,
  PersonalDataSectionEid,
  PersonalDataSectionSigningCert,
  PersonalDataSectionAuthenticationCert,
  PersonalDataSectionInfo
} PersonalDataSection;

typedef enum : NSUInteger {
  PersonalDataCellTypeErrorNoReader,
  PersonalDataCellTypeErrorNoCard,
  PersonalDataCellTypeErrorPin1Blocked,
  PersonalDataCellTypeErrorPin2Blocked,
  PersonalDataCellTypeInfo,
  PersonalDataCellTypeName,
  PersonalDataCellTypeSurname,
  PersonalDataCellTypeBirthDate,
  PersonalDataCellTypeCitizenship,
  PersonalDataCellTypeEmail,
  PersonalDataCellTypeId,
  PersonalDataCellTypeDocument,
  PersonalDataCellTypeDocumentValidity,
  PersonalDataCellTypeDocumentExpiration,
  PersonalDataCellTypeCertExpiration,
  PersonalDataCellTypeCertValidity,
  PersonalDataCellTypeCertUsed
} PersonalDataCellType;

@interface MyEIDViewController () <UITextViewDelegate>
@property (nonatomic, strong) MoppLibPersonalData *personalData;
@property (nonatomic, strong) MoppLibCertData *signingCertData;
@property (nonatomic, strong) MoppLibCertData *authenticationCertData;
@property (nonatomic, strong) NSArray *sectionData;
@property (nonatomic, assign) BOOL isReaderConnected;
@property (nonatomic, assign) BOOL isCardInserted;
@property (strong, nonatomic) IBOutlet UIView *sectionHeaderLine;
@property (nonatomic, strong) NSNumber *pin1RetryCount;
@property (nonatomic, strong) NSNumber *pin2RetryCount;
@end

@implementation MyEIDViewController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.title = Localizations.MyEidMyEid;
  
  self.pin1RetryCount = [NSNumber numberWithInt:-1];
  self.pin2RetryCount = [NSNumber numberWithInt:-1];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardStatusChanged) name:kMoppLibNotificationReaderStatusChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retryCounterChanged) name:kMoppLibNotificationRetryCounterChanged object:nil];

  UINib *nib = [UINib nibWithNibName:@"ErrorCell" bundle:nil];
  [self.tableView registerNib:nib forCellReuseIdentifier:@"ErrorCell"];
  
  nib = [UINib nibWithNibName:@"InfoCell" bundle:nil];
  [self.tableView registerNib:nib forCellReuseIdentifier:@"InfoCell"];
  
  [self setupSections];
  
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    [self updateData];
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)updateCardData {
  [MoppLibCardActions minimalCardPersonalDataWithViewController:self success:^(MoppLibPersonalData *personalData) {
    self.personalData = personalData;

  } failure:^(NSError *error) {
    self.personalData = nil;
  }];
}

- (void)updateCertData {
  
  [MoppLibCardActions signingCertWithViewController:self success:^(MoppLibCertData *data) {
    self.signingCertData = data;
    
  } failure:^(NSError *error) {
    self.signingCertData = nil;
  }];
  
  [MoppLibCardActions authenticationCertWithViewController:self success:^(MoppLibCertData *data) {
    self.authenticationCertData = data;
    
  } failure:^(NSError *error) {
    self.authenticationCertData = nil;
  }];
}

- (void)updateRetryCounters {
  [MoppLibCardActions pin1RetryCountWithViewController:self success:^(NSNumber *count) {
    if (self.pin1RetryCount != count) {
      self.pin1RetryCount = count;
      [self reloadData];
    }
  } failure:^(NSError *error) {
    MSLog(@"Error %@", error);
  }];
  
  [MoppLibCardActions pin2RetryCountWithViewController:self success:^(NSNumber *count) {
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    if (self.pin2RetryCount != count) {
      self.pin2RetryCount = count;
      [self reloadData];
    }
  } failure:^(NSError *error) {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    MSLog(@"Error %@", error);
  }];
}

- (void)setSigningCertData:(MoppLibCertData *)signingCertData {
  _signingCertData = signingCertData;
  [self reloadData];
}

- (void)setAuthenticationCertData:(MoppLibCertData *)authenticationCertData {
  _authenticationCertData = authenticationCertData;
  [self reloadData];
}

- (void)setPersonalData:(MoppLibPersonalData *)personalData {
  _personalData = personalData;
  [self reloadData];
}

- (void)setIsCardInserted:(BOOL)isCardInserted {
  if (_isCardInserted != isCardInserted) {
    _isCardInserted = isCardInserted;
    if (!isCardInserted) {
      self.personalData = nil;
      self.signingCertData = nil;
      self.authenticationCertData = nil;
    }
    [self reloadData];
  }
}

- (void)setIsReaderConnected:(BOOL)isReaderConnected {
  if (_isReaderConnected != isReaderConnected) {
    _isReaderConnected = isReaderConnected;
    if (!isReaderConnected) {
      self.personalData = nil;
      self.signingCertData = nil;
      self.authenticationCertData = nil;
    }
    [self reloadData];
  }
}

- (void)reloadData {
  [self setupSections];
  [self.tableView reloadData];
}

- (void)setupSections {
  NSMutableArray *array = [NSMutableArray new];
  
    NSMutableArray *errors = [NSMutableArray new];
    
    if (self.isReaderConnected == NO) {
      [errors addObject:[NSNumber numberWithInt:PersonalDataCellTypeErrorNoReader]];
      
    } else if (self.isCardInserted == NO) {
      [errors addObject:[NSNumber numberWithInt:PersonalDataCellTypeErrorNoCard]];
      
    } else {
      if (self.pin1RetryCount.integerValue == 0) {
        [errors addObject:[NSNumber numberWithInt:PersonalDataCellTypeErrorPin1Blocked]];
      }
      
      if (self.pin2RetryCount.integerValue == 0) {
        [errors addObject:[NSNumber numberWithInt:PersonalDataCellTypeErrorPin2Blocked]];
      }
    }
  
  if (errors.count > 0) {
    [array addObject:@[[NSNumber numberWithInt:PersonalDataSectionErrors], errors]];
  }
  
  if (self.personalData) {
    NSArray *personalData = @[[NSNumber numberWithInt:PersonalDataCellTypeName],
                              [NSNumber numberWithInt:PersonalDataCellTypeSurname],
                              [NSNumber numberWithInt:PersonalDataCellTypeId],
                              [NSNumber numberWithInt:PersonalDataCellTypeBirthDate],
                              [NSNumber numberWithInt:PersonalDataCellTypeCitizenship],
                              [NSNumber numberWithInt:PersonalDataCellTypeEmail]];
    [array addObject:@[[NSNumber numberWithInt:PersonalDataSectionData], personalData]];
    
    NSArray *eid = @[[NSNumber numberWithInt:PersonalDataCellTypeDocument],
                              [NSNumber numberWithInt:PersonalDataCellTypeDocumentValidity],
                              [NSNumber numberWithInt:PersonalDataCellTypeDocumentExpiration]];
    [array addObject:@[[NSNumber numberWithInt:PersonalDataSectionEid], eid]];
    
    NSArray *cert = @[[NSNumber numberWithInt:PersonalDataCellTypeCertValidity],
                     [NSNumber numberWithInt:PersonalDataCellTypeCertExpiration],
                     [NSNumber numberWithInt:PersonalDataCellTypeCertUsed]];
    [array addObject:@[[NSNumber numberWithInt:PersonalDataSectionSigningCert], cert]];
    [array addObject:@[[NSNumber numberWithInt:PersonalDataSectionAuthenticationCert], cert]];

  }
  
  if (!self.personalData) {
    [array addObject:@[[NSNumber numberWithInt:PersonalDataSectionInfo], @[[NSNumber numberWithInt:PersonalDataCellTypeInfo]]]];
  }
  
  self.sectionData = array;
}

- (void)cardStatusChanged {
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    [self updateData];
  }];
}

- (void)updateData {
  if (self.isReaderConnected && self.isCardInserted) {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self updateCardData];
    [self updateCertData];
    [self updateRetryCounters];
  }
}

- (void)retryCounterChanged {
  [self updateRetryCounters];
}

NSString *pinBlockedPath = @"myeid://pinBlocked";

- (void)setupPinBlockedMessage:(UITextView *)textView withPinString:(NSString *)pin {
  NSString *tapHere = Localizations.MyEidPinActionsView;
  [textView setLinkedText:Localizations.MyEidPinBlocked(pin, pin, tapHere) withLinks:@{pinBlockedPath:tapHere}];
}

NSString *readerNotFoundPath = @"myeid://readerNotConnected";

- (void)setupReaderNotFoundMessage:(UITextView *)textView {
  NSString *tapHere = Localizations.MyEidTapHere;
  [textView setLinkedText:Localizations.MyEidWarningReaderNotFound(tapHere) withLinks:@{readerNotFoundPath:tapHere}];
}

NSString *idCardIntroPath = @"myeid://readIDCardInfo";

- (void)setupIDCardIntroMessage:(UITextView *)textView {
  NSString *tapHere = Localizations.MyEidFindMoreInfo;
  [textView setLinkedText:Localizations.MyEidIdCardInfo(tapHere) withLinks:@{idCardIntroPath:tapHere}];
}

#pragma mark - TableView

- (NSInteger)sectionTypeForSection:(int)section {
  NSArray *sectionData = self.sectionData[section];
  NSNumber *type = sectionData[0];
  return type.integerValue;
}

- (NSInteger)cellTypeForRow:(int)row inSection:(int)section {
  NSArray *sectionData = self.sectionData[section];
  NSArray *cellData = sectionData[1];
  NSNumber *type = cellData[row];
  return type.integerValue;
}

- (NSInteger)sectionTypInSection:(int)section {
  NSArray *sectionData = self.sectionData[section];
  NSNumber *type =  sectionData[0];
  return type.integerValue;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (self.sectionData.count > section) {
    NSArray *sectionData = self.sectionData[section];
    NSArray *cellData = sectionData[1];

    return cellData.count;
  }
  
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PersonalDataCellType cellType = [self cellTypeForRow:indexPath.row inSection:indexPath.section];
  PersonalDataSection sectionType = [self sectionTypInSection:indexPath.section];

  switch (cellType) {
    case PersonalDataCellTypeErrorPin1Blocked:
    case PersonalDataCellTypeErrorPin2Blocked:
    case PersonalDataCellTypeErrorNoCard:
    case PersonalDataCellTypeErrorNoReader: {
      ErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ErrorCell" forIndexPath:indexPath];
      cell.errorTextView.delegate = self;
      cell.type = cellType == PersonalDataCellTypeErrorPin1Blocked || cellType == PersonalDataCellTypeErrorPin2Blocked ? ErrorCellTypeError : ErrorCellTypeWarning;
      if (cellType == PersonalDataCellTypeErrorNoReader) {
        [self setupReaderNotFoundMessage:cell.errorTextView];
      } else if (cellType == PersonalDataCellTypeErrorNoCard) {
        cell.errorTextView.text = Localizations.MyEidWarningCardNotFound;
      } else {
        [self setupPinBlockedMessage:cell.errorTextView withPinString:cellType == PersonalDataCellTypeErrorPin1Blocked ? Localizations.PinActionsPin1 : Localizations.PinActionsPin2];
      }
      return cell;
    }
      
    case PersonalDataCellTypeInfo: {
      InfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
      cell.infoTextView.delegate = self;
      [self setupIDCardIntroMessage:cell.infoTextView];
      return cell;
    }

    case PersonalDataCellTypeCertUsed:
    case PersonalDataCellTypeCertExpiration:
    case PersonalDataCellTypeCertValidity:
    case PersonalDataCellTypeDocumentExpiration:
    case PersonalDataCellTypeDocumentValidity:
    case PersonalDataCellTypeDocument:
    case PersonalDataCellTypeEmail:
    case PersonalDataCellTypeCitizenship:
    case PersonalDataCellTypeBirthDate:
    case PersonalDataCellTypeId:
    case PersonalDataCellTypeSurname:
    case PersonalDataCellTypeName: {
      return [self personalDataCellForType:cellType section:sectionType];
    }
      
      break;
      
    default:
      break;
  }

  return nil;
}

- (PersonalDataCell *)personalDataCellForType:(PersonalDataCellType)type section:(PersonalDataSection)section {
  NSString *titleString;
  NSString *dataString;
  UIColor *labelColor = [UIColor blackColor];
  
  MoppLibCertData *cert = section == PersonalDataSectionAuthenticationCert ? self.authenticationCertData : self.signingCertData;

  switch (type) {
      
    case PersonalDataCellTypeCertUsed: {
      titleString = Localizations.MyEidUseCount;
      
      if (cert) {
        dataString = cert.usageCount == 1 ? Localizations.MyEidUsedOnce : Localizations.MyEidTimesUsed(cert.usageCount);
        
      } else {
        dataString = @"-";
      }
      break;
    }
      
    case PersonalDataCellTypeCertExpiration: {
      titleString = Localizations.MyEidValidUntil;
      if (cert) {
        dataString = [[DateFormatter sharedInstance] ddMMYYYYToString:cert.expiryDate];
        
      } else {
        dataString = @"-";
      }
      break;
    }
      
    case PersonalDataCellTypeCertValidity: {
      titleString = Localizations.MyEidValidity;
      if (cert) {
        BOOL isValid = cert.isValid && [[NSDate date] compare:cert.expiryDate] == NSOrderedAscending;
        dataString = isValid ? Localizations.MyEidValid : Localizations.MyEidNotValid;
        labelColor = isValid ? [UIColor darkGreen] : [UIColor red];
        
      } else {
        dataString = @"-";
      }
      break;
    }
      
    case PersonalDataCellTypeDocumentExpiration: {
      titleString = Localizations.MyEidValidUntil;
      dataString = self.personalData.expiryDate;
      break;
    }
      
    case PersonalDataCellTypeDocumentValidity: {
      BOOL isCardValid = [[NSDate date] compare:[[DateFormatter sharedInstance] ddMMYYYYToDate:self.personalData.expiryDate]] == NSOrderedAscending;
      titleString = Localizations.MyEidValidity;
      dataString = isCardValid ? Localizations.MyEidValid : Localizations.MyEidNotValid;
      labelColor = isCardValid ? [UIColor darkGreen] : [UIColor red];
      break;
    }
      
    case PersonalDataCellTypeDocument: {
      titleString = Localizations.MyEidCardInReader;
      dataString = self.personalData.documentNumber;
      break;
    }
      
    case PersonalDataCellTypeEmail: {
      titleString = Localizations.MyEidEmail;
      NSString *email = @"-";
      if (self.authenticationCertData && self.authenticationCertData.email.length > 0) {
        email = self.authenticationCertData.email;
      }
      dataString = email;
      break;
    }
      
    case PersonalDataCellTypeCitizenship: {
      titleString = Localizations.MyEidCitizenship;
      dataString = self.personalData.nationality;
      break;
    }
      
    case PersonalDataCellTypeBirthDate: {
      titleString = Localizations.MyEidBirth;
      dataString = self.personalData.birthDate;
      break;
    }
      
    case PersonalDataCellTypeId: {
      titleString = Localizations.MyEidPersonalCode;
      dataString = self.personalData.personalIdentificationCode;
      break;
    }
      
    case PersonalDataCellTypeSurname: {
      titleString = Localizations.MyEidSurname;
      dataString = self.personalData.surname;
      break;
    }
      
    case PersonalDataCellTypeName: {
      titleString = Localizations.MyEidGivenNames;
      dataString = [self.personalData givenNames];
      break;
    }
      
      break;
      
    default:
      break;
  }
  
  if (titleString.length > 0 || dataString.length > 0) {
    PersonalDataCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PersonalDataCell"];
    cell.titleLabel.text = titleString;
    cell.dataLabel.text = dataString;
    cell.dataLabel.textColor = labelColor;
    
    return cell;
  }
  
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  NSInteger sectionType = [self sectionTypeForSection:section];
  
  if (sectionType == PersonalDataSectionErrors) {
    return CGFLOAT_MIN;
  }
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSInteger sectionType = [self sectionTypeForSection:section];
  
  if (sectionType == PersonalDataSectionInfo) {
    return self.sectionHeaderLine;
    
  } else {
    NSString *title;
    
    
    if (sectionType == PersonalDataSectionData) {
      title = Localizations.MyEidPersonalData;
    
    } else if (sectionType == PersonalDataSectionEid) {
      title = Localizations.MyEidEid;
    
    } else if (sectionType == PersonalDataSectionSigningCert) {
      title = Localizations.MyEidSignatureCertificate;
      
    } else if (sectionType == PersonalDataSectionAuthenticationCert) {
      title = Localizations.MyEidAuthenticationCertificate;
    }
    
    if (title.length > 0) {
      SimpleHeaderView *header =  [[[NSBundle mainBundle] loadNibNamed:@"SimpleHeaderView" owner:self options:nil] objectAtIndex:0];
      header.titleLabel.text= title;
      return header;
    }
  }
  
  return nil;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
  if ([[URL absoluteString] isEqualToString:readerNotFoundPath]) {
    [self updateCardData];
    return NO;
    
  } else if ([[URL absoluteString] isEqualToString:idCardIntroPath]) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:Localizations.MyEidIdCardInfoLink]];
  } else if ([[URL absoluteString] isEqualToString:pinBlockedPath]) {
    // Navigate to PIN actions view
    if ([self.navigationController.parentViewController isKindOfClass:[UITabBarController class]]) {
      ((UITabBarController *)self.navigationController.parentViewController).selectedIndex = 2;
    }
  }

  return YES; // let the system open this URL
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  textView.selectedRange = NSMakeRange(0, 0);
}


@end
