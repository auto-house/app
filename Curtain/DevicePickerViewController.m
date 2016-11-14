//
//  DevicePickerViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "DevicePickerViewController.h"

#define CURTAIN_SERVICE_CONNECTION_UUID @"ff51b30e-d7e2-4d93-8842-a7c4a57dfb07"

@interface DevicePickerViewController ()

@property (nonatomic) BOOL peripheralReady;

@property (nonatomic, retain) NSMutableArray *peripherals;
@property (nonatomic, retain) CBPeripheral *selectedPeripheral;

@end


@implementation DevicePickerViewController

@synthesize peripheralReady = _peripheralReady;
@synthesize peripherals = _peripherals;
@synthesize selectedPeripheral = _selectedPeripheral;

@synthesize centralManager = _centralManager;

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Device";
    
    self.peripheralReady = NO;
    self.peripherals = [[NSMutableArray alloc] init];
    self.selectedPeripheral = nil;
    
    self.centralManager.delegate = self;
    
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
            
        case CBManagerStatePoweredOn:
            NSLog(@"centralManagerDidUpdate: CBManagerStatePoweredOn");
            break;
            
        case CBManagerStatePoweredOff:
            NSLog(@"centralManagerDidUpdate: CBManagerStatePoweredOff");
            break;
            
        case CBManagerStateUnsupported:
            NSLog(@"centralManagerDidUpdate: CBManagerStateUnsupported");
            break;
            
        case CBManagerStateUnauthorized:
            NSLog(@"centralManagerDidUpdate: CBManagerStateUnauthorized");
            break;
            
        case CBManagerStateResetting:
            NSLog(@"centralManagerDidUpdate: CBManagerStateResetting");
            break;
            
        case CBManagerStateUnknown:
            NSLog(@"centralManagerDidUpdate: CBManagerStateUnknown");
            break;
            
    }
    
}

- (void)centralManager:(CBCentralManager *)central
            didDiscoverPeripheral:(CBPeripheral *)peripheral
                advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                    RSSI:(NSNumber *)RSSI {
    
    if ([self.peripherals containsObject:peripheral] == NO) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.peripherals.count inSection:0];
        
        [self.peripherals addObject:peripheral];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    if (peripheral == self.selectedPeripheral) {
        
        peripheral.delegate = self;
        
        CBUUID *connectionService = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_UUID];
        [peripheral discoverServices:@[connectionService]];
        
    }
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (peripheral == self.selectedPeripheral) {
        
        CBService *connectionService = [peripheral.services firstObject];
        [peripheral discoverCharacteristics:nil forService:connectionService];
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didDiscoverCharacteristicsForService:(nonnull CBService *)service
                error:(nullable NSError *)error {
    
    if (peripheral == self.selectedPeripheral) {
        
        // Tell the RPi to blink the connection LED.
        // Display an alert view asking if it is blinking. If it is, connect. Else, ignore.
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            NSLog(@"Peripheral: %@ Characteristic: %@", peripheral.name, characteristic.description);
            
            //NSData *data = [@"connect" dataUsingEncoding:NSUTF8StringEncoding];
            //[peripheral readValueForCharacteristic:characteristic];
            //[peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            
        }
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                error:(NSError *)error {
    
    NSData *data = characteristic.value;
    NSString *json = [NSString stringWithUTF8String:data.bytes];
    
    NSLog(@"Value of characteristic %@", json);
    
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Select the device you wish to configure";
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    static UIView *view;
    
    if (view == nil) {
        
        view = [[UIView alloc] init];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(tableView.separatorInset.left, 0, 80, 30)];
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor colorWithRed:109/255.f green:109/255.f blue:114/255.f alpha:1];
        label.text = @"SEARCHING";
        [view addSubview:label];
        
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.center = CGPointMake(110, 15);
        [indicator startAnimating];
        [view addSubview:indicator];
        
    }
    
    return view;
    
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 30;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    static NSString * const cellIdentifierSpinner = @"cell-identifier-spinner";
    
    UITableViewCell *cell;
    UIActivityIndicatorView *indicator;
    
    CBPeripheral *peripheral = [self.peripherals objectAtIndex:indexPath.row];
    
    if (peripheral == self.selectedPeripheral && self.peripheralReady == NO) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierSpinner];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierSpinner];
            
            indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            cell.accessoryView = indicator;
            [indicator startAnimating];
            
        }
        
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
        }
        
        cell.accessoryType = (peripheral == self.selectedPeripheral ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        
    }
    
    cell.textLabel.text = peripheral.name;
    
    return cell;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBPeripheral *peripheral = [self.peripherals objectAtIndex:indexPath.row];
    self.selectedPeripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral options:nil];
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
