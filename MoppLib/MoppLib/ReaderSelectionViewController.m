//
//  ReaderSelectionViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 21/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ReaderSelectionViewController.h"
#import "MBProgressHUD.h"
#import "CBManagerHelper.h"

@interface ReaderSelectionViewController () <CBManagerHelperDelegate>

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
  
  [[CBManagerHelper sharedInstance] addDelegate:self];
  
  self.title = NSLocalizedString(@"Select reader", nil);
  self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Cancel", nil);
  self.infoLabel.text = NSLocalizedString(@"Card reader is not connected. Please make sure your reader is active and select reader.", nil);
  
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
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
  
  [self dismissViewControllerAnimated:YES completion:^{
    if (self.delegate) {
      [self.delegate peripheralSelected:peripheral];
    }
  }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Viga" message:[NSString stringWithFormat:@"Seadme ühendamisel tekkis probleem: %@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
  }]];
  
  [self presentViewController:alert animated:YES completion:^{
    
  }];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
  [self.tableView reloadData];
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
      [[CBManagerHelper sharedInstance] startScan];
      
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
  
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PeripheralCell" forIndexPath:indexPath];
  
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
    
    if (![MBProgressHUD HUDForView:self.view]) {
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    // TODO may need cancel option or timeout in case user selects incorrect peripheral. Connection attempts do not time out by default.
    [[CBManagerHelper sharedInstance] connectPeripheral:self.selectedPeripheral];
  }
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
