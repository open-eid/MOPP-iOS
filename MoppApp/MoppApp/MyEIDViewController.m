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

typedef enum : NSUInteger {
  PersonalDataSectionErrors,
  PersonalDataSectionData,
  PersonalDataSectionInfo
} PersonalDataSection;

@interface MyEIDViewController ()
@property (nonatomic, strong) MoppLibPersonalData *personalData;
@property (nonatomic, strong) NSArray *sectionData;
@property (nonatomic, assign) BOOL isReaderConnected;
@property (nonatomic, assign) BOOL isCardInserted;
@end

@implementation MyEIDViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardStatusChanged) name:kMoppLibNotificationReaderStatusChanged object:nil];
  
  [self setupSections];
  
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
  }];
  
  
  [MoppLibCardActions cardPersonalDataWithViewController:self success:^(MoppLibPersonalData *data) {
    self.personalData = data;
    
  } failure:^(NSError *error) {
    self.personalData = nil;
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setPersonalData:(MoppLibPersonalData *)personalData {
  _personalData = personalData;
  [self setupSections];
  [self.tableView reloadData];
}

- (void)setIsCardInserted:(BOOL)isCardInserted {
  if (_isCardInserted != isCardInserted) {
    _isCardInserted = isCardInserted;
    [self setupSections];
    [self.tableView reloadData];
  }
}

- (void)setIsReaderConnected:(BOOL)isReaderConnected {
  if (_isReaderConnected != isReaderConnected) {
    _isReaderConnected = isReaderConnected;
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
  }
  
  [array addObject:[NSNumber numberWithInt:PersonalDataSectionInfo]];
  
  self.sectionData = array;
}

- (void)cardStatusChanged {
  self.isReaderConnected = [MoppLibCardActions isReaderConnected];
  
  [MoppLibCardActions isCardInserted:^(BOOL isInserted) {
    self.isCardInserted = isInserted;
    
    if (!self.isReaderConnected || !isInserted) {
      self.personalData = nil;
    } else {
      [MoppLibCardActions cardPersonalDataWithViewController:self success:^(MoppLibPersonalData *data) {
        self.personalData = data;
        
      } failure:^(NSError *error) {
        self.personalData = nil;
      }];
    }
  }];
}

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
  
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSNumber *sectionData = self.sectionData[indexPath.section];
  if (sectionData.intValue == PersonalDataSectionErrors) {
    ErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WarningCell" forIndexPath:indexPath];
    if (!self.isReaderConnected) {
      cell.errorLabel.text = Localizations.MyEidWarningReaderNotFound;
    } else if (!self.isCardInserted){
      cell.errorLabel.text = Localizations.MyEidWarningCardNotFound;
    }
    return cell;
  }
  
  if (sectionData.intValue == PersonalDataSectionInfo) {
    InfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
    cell.infoLabel.text = Localizations.MyEidIdCardInfo;
    return cell;
  }
  
  if (sectionData.intValue == PersonalDataSectionData) {
    if (indexPath.row == 0) {
      NameAndPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NameAndPhotoCell" forIndexPath:indexPath];
      cell.nameLabel.text = [self.personalData fullName];
      return cell;
    }
    
    PersonalDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonalDataCell" forIndexPath:indexPath];
    
    NSString *titleString;
    NSString *dataString;
    
    switch (indexPath.row) {
      case 1:
        titleString = Localizations.MyEidPersonalCode;
        dataString = self.personalData.personalIdentificationCode;
        break;
      case 2:
        titleString = Localizations.MyEidBirth;
        dataString = self.personalData.birthDate;
        break;
      case 3:
        titleString = Localizations.MyEidCitizenship;
        dataString = self.personalData.nationality;
        break;
      case 4:
        titleString = Localizations.MyEidEmail;
        dataString = @"";
        break;
        
        
      default:
        break;
    }
    
    cell.titleLabel.text = titleString;
    cell.dataLabel.text = dataString;
    
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
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
