//
//  ReaderSelectionViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 21/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ReaderSelectionViewController.h"
#import "MBProgressHUD.h"

@interface ReaderSelectionViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *cbCentralManager;
@property (nonatomic, strong) NSMutableArray *foundPeripherals;
@end

@implementation ReaderSelectionViewController

- (void)dealloc {
  [self.cbCentralManager stopScan];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  self.title = @"Vali kaardilugeja";
  self.foundPeripherals = [NSMutableArray new];
  
  self.cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: [NSNumber numberWithBool:YES]}];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - CBCentralManager

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  
  switch (central.state) {
    case CBManagerStatePoweredOff:
      NSLog(@"Central manager state powered off");
      
      [self.foundPeripherals removeAllObjects];
      break;
      
    case CBManagerStateUnknown:
      NSLog(@"Central manager state unknown");
      break;
      
    case CBManagerStatePoweredOn:
      NSLog(@"Central manager state powered on");
      
      // TODO can we scan for card readers only?
      [self.cbCentralManager scanForPeripheralsWithServices:nil options:nil];
      
      break;
      
    case CBManagerStateResetting:
      NSLog(@"Central manager state resetting");
      break;
      
    case CBManagerStateUnsupported:
      NSLog(@"Central manager state unsupported");
      break;
      
    case CBManagerStateUnauthorized:
      NSLog(@"Central manager state unauthorized");
      break;
      
    default:
      break;
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
  [self performSegueWithIdentifier:@"unwindReaderSelection" sender:self];
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
  
  if ([self.foundPeripherals indexOfObject:peripheral] == NSNotFound) {
    [self.foundPeripherals addObject:peripheral];
    [self.tableView reloadData];
  }
}

#pragma mark - Tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.foundPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PeripheralCell" forIndexPath:indexPath];
  
  if (indexPath.row < self.foundPeripherals.count) {
    CBPeripheral *peripheral = self.foundPeripherals[indexPath.row];
    
    if (peripheral.name.length > 0) {
      cell.textLabel.text = peripheral.name;
      
    } else {
      cell.textLabel.text = peripheral.identifier.UUIDString;
    }
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < self.foundPeripherals.count) {
    
    // Make sure previous connection is cancelled
    if (self.selectedPeripheral) {
      [self.cbCentralManager cancelPeripheralConnection:self.selectedPeripheral];
    }

    self.selectedPeripheral = self.foundPeripherals[indexPath.row];
    
    if (![MBProgressHUD HUDForView:self.view]) {
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    // TODO may need cancel option or timeout in case user incorrect peripheral. Connection attempts do not time out by default.
    [self.cbCentralManager connectPeripheral:self.selectedPeripheral options:nil];
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
