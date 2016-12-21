//
//  ReaderSelectionViewController.m
//  MoppApp
//
//  Created by Katrin Annuk on 21/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "ReaderSelectionViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

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
    
    self.cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: [NSNumber numberWithBool:YES]}];
    
    // TODO can we scan for card readers only?
    [self.cbCentralManager scanForPeripheralsWithServices:nil options:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"Central manager did update state %ld", (long)central.state);
    
    switch (central.state) {
        case CBManagerStatePoweredOff:
            
            break;
            
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"******* discovered peripheral %@", peripheral);
    NSLog(@"******* services %@", peripheral.services);
    
    for (CBService *service in peripheral.services) {
        NSLog(@"***** service uuid %@", service.UUID);
    }

    [self.foundPeripherals addObject:peripheral];
}

/*- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"******* discovered service %@", peripheral);

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
