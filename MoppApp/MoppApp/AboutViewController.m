//
//  AboutViewController.m
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import "AboutViewController.h"
#import "DependencyTableViewCell.h"
#import "DependencyWrapper.h"




@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *developmentLabel;
@property (weak, nonatomic) IBOutlet UITableView *dependencyTableView;
@property (weak, nonatomic) IBOutlet UILabel *addtionalDepsLabel;
@property (strong, nonatomic) IBOutlet UIView *tableviewHeader;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerWidthConstraint;

@property (strong, nonatomic) NSArray<DependencyWrapper *> *dependenciesArray;
@end

@implementation AboutViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  DependencyWrapper *MBProgressHUD = [[DependencyWrapper alloc] initWithDependencyName:@"MBProgressHUD" licenseName:@"MIT License" licenseLink:@"https://github.com/jdg/MBProgressHUD/blob/master/LICENSE"];
  DependencyWrapper *OCMock = [[DependencyWrapper alloc] initWithDependencyName:@"OCMock" licenseName:@"Apache 2 License" licenseLink:@"https://github.com/erikdoe/ocmock/blob/master/License.txt"];
  DependencyWrapper *PureLayout = [[DependencyWrapper alloc] initWithDependencyName:@"PureLayout" licenseName:@"MIT License" licenseLink:@"https://github.com/PureLayout/PureLayout/blob/master/LICENSE"];
  DependencyWrapper *Libdigidocpp = [[DependencyWrapper alloc] initWithDependencyName:@"libdigidocpp" licenseName:@"GNU Lesser General Public License (LGPL) version 2.1" licenseLink:@"https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html"];
  self.dependenciesArray = @[MBProgressHUD, OCMock, PureLayout, Libdigidocpp];
  NSBundle *bundle = [NSBundle mainBundle];
  NSMutableString *versionString = [[NSMutableString alloc] initWithString:Localizations.SettingsApplicationVersion];
  [versionString appendString:@" "];
  [versionString appendString:[[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
  [versionString appendString:[NSString stringWithFormat:@".%@", [[bundle infoDictionary] objectForKey:@"CFBundleVersion"]]];
  [self.versionLabel setText:versionString];
  [self.developmentLabel setText:Localizations.AboutDevelopment];
  self.developmentLabel.numberOfLines = 4;
  [self.addtionalDepsLabel setText:Localizations.AboutDependencies];
  [self.dependencyTableView setDelegate:self];
  [self.dependencyTableView setDataSource:self];
  
  
  UINib *dependecyCellNib = [UINib nibWithNibName:NSStringFromClass([DependencyTableViewCell class]) bundle:nil];
  [self.dependencyTableView registerNib:dependecyCellNib forCellReuseIdentifier:NSStringFromClass([DependencyTableViewCell class])];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (self.headerWidthConstraint.constant != self.dependencyTableView.frame.size.width) {
    self.headerWidthConstraint.constant = self.dependencyTableView.frame.size.width;
  }
  
  if (self.dependencyTableView.tableHeaderView) {
    CGSize size = [self.dependencyTableView.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGRect frame = self.dependencyTableView.tableHeaderView.frame;
    if (frame.size.height != size.height) {
      frame.size.height = size.height;
      [self.tableviewHeader setFrame:frame];
    }
  }
}

- (void)licenseLinkClicked:(UITapGestureRecognizer *)recognizer{
  UILabel *linkLabel = (UILabel *) recognizer.view;
  DependencyWrapper *deps = [self.dependenciesArray objectAtIndex:linkLabel.tag];
  [[UIApplication sharedApplication]openURL:[NSURL URLWithString:deps.licenseLink]];
}
#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  DependencyWrapper *deps = [self.dependenciesArray objectAtIndex:indexPath.row];
  DependencyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DependencyTableViewCell class]) forIndexPath:indexPath];
  [cell.dependencyNameLabel setText:deps.dependencyName];
  [cell.licenseNameLabel setText:deps.licenseName];
  [cell.licenseLinkLabel setText:deps.licenseLink];
  cell.licenseLinkLabel.tag = indexPath.row;
  cell.licenseLinkLabel.userInteractionEnabled = YES;
  [cell.licenseLinkLabel addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(licenseLinkClicked:)]];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.dependenciesArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

@end
