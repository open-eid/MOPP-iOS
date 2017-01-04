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

typedef enum : NSUInteger {
  PersonalDataSectionErrors,
  PersonalDataSectionData,
  PersonalDataSectionEid,
  PersonalDataSectionSigningCert,
  PersonalDataSectionInfo
} PersonalDataSection;

@interface MyEIDViewController () <UITextViewDelegate>
@property (nonatomic, strong) MoppLibPersonalData *personalData;
@property (nonatomic, strong) MoppLibCertData *signingCertData;
@property (nonatomic, strong) NSArray *sectionData;
@property (nonatomic, assign) BOOL isReaderConnected;
@property (nonatomic, assign) BOOL isCardInserted;
@property (strong, nonatomic) IBOutlet UIView *sectionHeaderLine;
@end

@implementation MyEIDViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.title = Localizations.MyEidMyEid;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardStatusChanged) name:kMoppLibNotificationReaderStatusChanged object:nil];
  
  [self setupSections];
  
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    
    if (self.isReaderConnected && self.isCardInserted) {
      [self updateCardData];
      [self updateCertData];
    }
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)updateCardData {
  [MoppLibCardActions cardPersonalDataWithViewController:self success:^(MoppLibPersonalData *data) {
    self.personalData = data;
    
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
}

- (void)setSigningCertData:(MoppLibCertData *)signingCertData {
  _signingCertData = signingCertData;
  [self.tableView reloadData];
}

- (void)setPersonalData:(MoppLibPersonalData *)personalData {
  _personalData = personalData;
  [self setupSections];
  [self.tableView reloadData];
}

- (void)setIsCardInserted:(BOOL)isCardInserted {
  if (_isCardInserted != isCardInserted) {
    _isCardInserted = isCardInserted;
    if (!isCardInserted) {
      self.personalData = nil;
      self.signingCertData = nil;
    }
    [self setupSections];
    [self.tableView reloadData];
  }
}

- (void)setIsReaderConnected:(BOOL)isReaderConnected {
  if (_isReaderConnected != isReaderConnected) {
    _isReaderConnected = isReaderConnected;
    if (!isReaderConnected) {
      self.personalData = nil;
      self.signingCertData = nil;
    }
    [self setupSections];
    [self.tableView reloadData];
  }
}

- (void)setupSections {
  NSMutableArray *array = [NSMutableArray new];
  
  if (self.isCardInserted == NO || self.isReaderConnected == NO) {
    [array addObject:[NSNumber numberWithInt:PersonalDataSectionErrors]];
    
  } else if (self.personalData) {
    [array addObject:[NSNumber numberWithInt:PersonalDataSectionData]];
    [array addObject:[NSNumber numberWithInt:PersonalDataSectionEid]];
    [array addObject:[NSNumber numberWithInt:PersonalDataSectionSigningCert]];
  }
  
  if (!self.personalData) {
    [array addObject:[NSNumber numberWithInt:PersonalDataSectionInfo]];
  }
  
  self.sectionData = array;
}

- (void)cardStatusChanged {
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    
    if (self.isReaderConnected && isInserted) {
      [self updateCardData];
      [self updateCertData];
    }
  }];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSNumber *sectionData = self.sectionData[section];
  if (sectionData.intValue == PersonalDataSectionErrors) {
    return 1;
  }
  
  if (sectionData.intValue == PersonalDataSectionInfo) {
    return 1;
  }
  
  if (sectionData.intValue == PersonalDataSectionData) {
    return 5;
  }
  
  if (sectionData.intValue == PersonalDataSectionEid) {
    return 3;
  }
  
  if (sectionData.intValue == PersonalDataSectionSigningCert) {
    return 3;
  }
  
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSNumber *sectionData = self.sectionData[indexPath.section];
  if (sectionData.intValue == PersonalDataSectionErrors) {
    ErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WarningCell" forIndexPath:indexPath];
    if (!self.isReaderConnected) {
      [self setupReaderNotFoundMessage:cell.errorTextView];
    } else if (!self.isCardInserted) {
      cell.errorTextView.text = Localizations.MyEidWarningCardNotFound;
    }
    return cell;
  }
  
  if (sectionData.intValue == PersonalDataSectionInfo) {
    InfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
    [self setupIDCardIntroMessage:cell.infoTextView];
    return cell;
  }
  
  NSString *titleString;
  NSString *dataString;
  UIColor *labelColor = [UIColor blackColor];
  
  if (sectionData.intValue == PersonalDataSectionData) {
    switch (indexPath.row) {
      case 0:
        titleString = Localizations.MyEidGivenNames;
        dataString = [self.personalData givenNames];
        break;
        
      case 1:
        titleString = Localizations.MyEidSurname;
        dataString = self.personalData.surname;
        break;
        
      case 2:
        titleString = Localizations.MyEidPersonalCode;
        dataString = self.personalData.personalIdentificationCode;
        break;
        
      case 3:
        titleString = Localizations.MyEidBirth;
        dataString = self.personalData.birthDate;
        break;
        
      case 4:
        titleString = Localizations.MyEidCitizenship;
        dataString = self.personalData.nationality;
        break;
        
      /*case 5:
        titleString = Localizations.MyEidEmail;
        dataString = @"";
        break;
        */
        
      default:
        break;
    }
  }
  
  if (sectionData.intValue == PersonalDataSectionEid) {
    switch (indexPath.row) {
      case 0:
        titleString = Localizations.MyEidCardInReader;
        dataString = self.personalData.documentNumber;
        break;
      case 1: {
        BOOL isCardValid = [[NSDate date] compare:[self.personalData.expiryDate expiryDateStringToDate]] == NSOrderedAscending;
        titleString = Localizations.MyEidValidity;
        dataString = isCardValid ? Localizations.MyEidValid : Localizations.MyEidNotValid;
        labelColor = isCardValid ? [UIColor darkGreen] : [UIColor red];
        break;
      }
      case 2:
        titleString = Localizations.MyEidValidUntil;
        dataString = self.personalData.expiryDate;
        break;
        
      default:
        break;
    }
  }
  
  if (sectionData.intValue == PersonalDataSectionSigningCert) {
    switch (indexPath.row) {
      case 0: {
        titleString = Localizations.MyEidValidity;
        if (self.signingCertData) {
          BOOL isValid = self.signingCertData.isValid && [[NSDate date] compare:self.signingCertData.expiryDate] == NSOrderedAscending;
          dataString = isValid ? Localizations.MyEidValid : Localizations.MyEidNotValid;
          labelColor = isValid ? [UIColor darkGreen] : [UIColor red];

        } else {
          dataString = @"-";
        }
        break;
      }
      case 1:
        titleString = Localizations.MyEidValidUntil;
        if (self.signingCertData) {
          dataString = [self.signingCertData.expiryDate expiryDateString];
          
        } else {
          dataString = @"-";
        }
        break;
      case 2:
        titleString = Localizations.MyEidUseCount;
        
        if (self.signingCertData) {
          dataString = self.signingCertData.usageCount == 1 ? Localizations.MyEidUsedOnce : Localizations.MyEidTimesUsed(self.signingCertData.usageCount);
          
        } else {
          dataString = @"-";
        }
        break;
        
      default:
        break;
    }
  }
  
  if (titleString.length > 0 || dataString.length > 0) {
    PersonalDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonalDataCell" forIndexPath:indexPath];
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
  NSNumber *sectionData = self.sectionData[section];
  
  if (sectionData.intValue == PersonalDataSectionErrors) {
    return CGFLOAT_MIN;
  }
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSNumber *sectionData = self.sectionData[section];
  
  if (sectionData.intValue == PersonalDataSectionInfo) {
    return self.sectionHeaderLine;
    
  } else {
    NSString *title;
    
    
    if (sectionData.intValue == PersonalDataSectionData) {
      title = Localizations.MyEidPersonalData;
    } else if (sectionData.intValue == PersonalDataSectionEid) {
      title = Localizations.MyEidEid;
    } else if (sectionData.intValue == PersonalDataSectionSigningCert) {
      title = Localizations.MyEidSignatureCertificate;
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
    [self updateCertData];
    return NO;
    
  } else if ([[URL absoluteString] isEqualToString:idCardIntroPath]) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:Localizations.MyEidIdCardInfoLink]];
  }
  
  return YES; // let the system open this URL
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
