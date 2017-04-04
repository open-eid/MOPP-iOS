//
//  ReaderSelectionViewController.m
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

#import "ReaderSelectionViewController.h"
#import "CBManagerHelper.h"

@interface ReaderSelectionViewController () <CBManagerHelperDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property (weak, nonatomic) IBOutlet UIView *spinnerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@end

@implementation ReaderSelectionViewController

- (void)dealloc {
  [[CBManagerHelper sharedInstance] stopScan];
  [[CBManagerHelper sharedInstance] removeDelegate:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.spinnerView.layer.borderWidth = 0;
  self.spinnerView.layer.cornerRadius = 10;
  self.spinnerView.clipsToBounds = YES;
  
  [self stopSpinner];
  
  [[CBManagerHelper sharedInstance] startScan];
  [[CBManagerHelper sharedInstance] addDelegate:self];
  
  self.title = MLLocalizedString(@"Select reader", nil);
  self.navigationItem.leftBarButtonItem.title = MLLocalizedString(@"Cancel", nil);
  self.infoLabel.text = MLLocalizedString(@"Connect reader message", nil);
  
  [self.navigationController.navigationBar setHidden:NO];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (IBAction)cancelTapped:(id)sender {
  [self dismissViewControllerAnimated:YES completion:^{
    if (self.delegate) {
      [self.delegate cancelledReaderSelection];
    }
  }];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  [self stopSpinner];
  
  [self dismissViewControllerAnimated:YES completion:^{
    if (self.delegate) {
      [self.delegate peripheralSelected:peripheral];
    }
  }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  [self stopSpinner];
  
  NSString *title = MLLocalizedString(@"Error", nil);
  NSString *message = MLLocalizedString(@"Problem connecting %@", nil);
  NSString *ok = MLLocalizedString(@"Ok", nil);
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:message, [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:ok style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
  }]];
  
  [self presentViewController:alert animated:YES completion:^{
    
  }];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {

  [self.myTableView reloadData];

}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  
}

#pragma mark - CBCentralManager

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  
  switch (central.state) {
    case CBManagerStatePoweredOff:
      break;
      
    case CBManagerStateUnknown:
      break;
      
    case CBManagerStatePoweredOn:
     // [[CBManagerHelper sharedInstance] startScan];
      
      break;
      
    case CBManagerStateResetting:
      break;
      
    case CBManagerStateUnsupported:
      break;
      
    case CBManagerStateUnauthorized:
      break;
      
    default:
      break;
  }
}

#pragma mark - Tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [CBManagerHelper sharedInstance].foundPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = [self.myTableView dequeueReusableCellWithIdentifier:@"PeripheralCell" forIndexPath:indexPath];
  
  if (indexPath.row < [CBManagerHelper sharedInstance].foundPeripherals.count) {
    CBPeripheral *peripheral = [CBManagerHelper sharedInstance].foundPeripherals[indexPath.row];
    
    if (peripheral.name.length > 0) {
      cell.textLabel.text = peripheral.name;
      
    } else {
      cell.textLabel.text = peripheral.identifier.UUIDString;
    }
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < [CBManagerHelper sharedInstance].foundPeripherals.count) {
    
    self.selectedPeripheral = [CBManagerHelper sharedInstance].foundPeripherals[indexPath.row];
    
    [self startSpinner];
    
    // TODO may need cancel option or timeout in case user selects incorrect peripheral. Connection attempts do not time out by default.
    [[CBManagerHelper sharedInstance] connectPeripheral:self.selectedPeripheral];
  }
}

- (void)startSpinner {
  self.spinnerView.hidden = NO;
  [self.spinner startAnimating];
}

- (void)stopSpinner {
  self.spinnerView.hidden = YES;
  [self.spinner stopAnimating];
}

/*- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
 return UITableViewAutomaticDimension;
 }
 
 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
 return UITableViewAutomaticDimension;
 }*/

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
