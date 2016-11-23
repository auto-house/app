//
//  DeviceViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "DeviceViewController.h"
#import "CCDevice.h"
#import "CCGroup.h"

#define CURTAIN_SERVICE_UUID_CONNECTION                      @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_BLINK @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF1"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_SETUP @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF2"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_DAUTH @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF3"

#define CURTAIN_SERVICE_UUID_DEMO                           @"FFFFFFFF-FFFF-FFFF-FFF1-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_DEMO_CHARACTERISTIC_UUID_DEMO       @"FFFFFFFF-FFFF-FFFF-FFF1-FFFFFFFFFFF1"


@interface DeviceViewController ()

@property (nonatomic, retain) NSMutableArray *discoveredPeripherals;
@property (nonatomic, retain) NSMutableArray *ignoredPeripherals;
@property (nonatomic, retain) CBPeripheral *peripheral;

@end


@implementation DeviceViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Device";
    
    self.centralManager.delegate = self;
    
    self.discoveredPeripherals = [[NSMutableArray alloc] init];
    self.ignoredPeripherals = [[NSMutableArray alloc] init];
    
    [self checkPeripheral];
    
}

#pragma mark - Private

- (void)alertViewWithTitle:(NSString *)title forMessage:(NSString *)message {
    
    UIAlertController *alertController;
    UIAlertAction *dismissalAction;
    
    alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    dismissalAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:dismissalAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)checkPeripheral {
    
    CBPeripheral *peripheral = self.device.peripheral;
    
    if (peripheral == nil) {
        
        CBUUID *connectionService = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_CONNECTION];
        [self.centralManager scanForPeripheralsWithServices:@[connectionService] options:nil];
        
    }else{
        
        peripheral.delegate = self;
        
        if (peripheral.state == CBPeripheralStateConnected) {
            
            CBService *connectionService, *demoService;
            
            for (CBService *service in peripheral.services) {
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_CONNECTION]) {
                    connectionService = service;
                }
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_DEMO]) {
                    demoService = service;
                }
            }
            
            if (connectionService == nil || demoService == nil) {
                
                CBUUID *connectionServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_CONNECTION];
                CBUUID *demoServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_DEMO];
                
                [peripheral discoverServices:@[connectionServiceUUID, demoServiceUUID]];
                
            }else{
                
                //
                
            }
            
        }else{
            
            [self.centralManager connectPeripheral:peripheral options:nil];
            
        }
        
    }
    
}

- (void)blinkLED {
    
    CBPeripheral *peripheral = self.peripheral;
    
    if (peripheral == nil) {
        
        [self checkPeripheral];
        
    }else{
        
        CBService *blinkService;
        CBCharacteristic *demoCharacteristic;
        
        for (CBService *service in peripheral.services) {
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_DEMO]) {
                blinkService = service;
            }
        }
        
        for (CBCharacteristic *characteristic in blinkService.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_DEMO_CHARACTERISTIC_UUID_DEMO]) {
                demoCharacteristic = characteristic;
            }
        }
        
        NSError *error;
        NSDictionary *json = @{@"action": @"blink-led"};
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
        
        NSLog(@"go go go");
        
        [peripheral writeValue:data forCharacteristic:demoCharacteristic type:CBCharacteristicWriteWithResponse];
        
        
    }
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"centralManagerDidUpdateState:");
    
    switch (central.state) {
        case CBManagerStatePoweredOn: NSLog(@"centralManagerDidUpdate: CBManagerStatePoweredOn"); break;
        case CBManagerStatePoweredOff: NSLog(@"centralManagerDidUpdate: CBManagerStatePoweredOff"); break;
        case CBManagerStateUnsupported: NSLog(@"centralManagerDidUpdate: CBManagerStateUnsupported"); break;
        case CBManagerStateUnauthorized: NSLog(@"centralManagerDidUpdate: CBManagerStateUnauthorized"); break;
        case CBManagerStateResetting: NSLog(@"centralManagerDidUpdate: CBManagerStateResetting"); break;
        case CBManagerStateUnknown: NSLog(@"centralManagerDidUpdate: CBManagerStateUnknown"); break;
    }
    
}

- (void)centralManager:(CBCentralManager *)central
            didDiscoverPeripheral:(CBPeripheral *)peripheral
                advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                    RSSI:(NSNumber *)RSSI {
    
    NSLog(@"centralManager: didDiscoverPeripheral: advertisementData: RSSI:");
    
    if ([self.discoveredPeripherals containsObject:peripheral] == NO || [self.ignoredPeripherals containsObject:peripheral] == NO) {
        
        [self.discoveredPeripherals addObject:peripheral];
        [central connectPeripheral:peripheral options:nil];
        
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"centralManager: didConnectPeripheral:");
    
    if ([self.discoveredPeripherals containsObject:peripheral] == YES) {
        
        CBUUID *connectionService = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_CONNECTION];
        CBUUID *demoService = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_DEMO];
        
        [self. discoveredPeripherals addObject:peripheral];
        
        [peripheral setDelegate:self];
        [peripheral discoverServices:@[connectionService, demoService]];
        
    }
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    NSLog(@"peripheral: didDiscoverServices:");
    
    if ([self.discoveredPeripherals containsObject:peripheral]) {
        
        for (CBService *service in peripheral.services) {
            
            NSLog(@"service %@", service);
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_CONNECTION]) {
                
                CBUUID *blinkCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_BLINK];
                CBUUID *setupCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_SETUP];
                CBUUID *dauthCharacteristics = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_DAUTH];
                NSArray *characteristics = @[blinkCharacteristic, setupCharacteristic, dauthCharacteristics];
                [peripheral discoverCharacteristics:characteristics forService:service];
                
            }
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_DEMO]) {
                
                CBUUID *demoCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_DEMO_CHARACTERISTIC_UUID_DEMO];
                NSArray *characteristics = @[demoCharacteristic];
                [peripheral discoverCharacteristics:characteristics forService:service];
                
                
            }
            
        }
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didDiscoverCharacteristicsForService:(nonnull CBService *)service
                error:(nullable NSError *)error {
    
    NSLog(@"peripheral: didDiscoverCharacteristicsForService: error:");
    
    if ([self.discoveredPeripherals containsObject:peripheral]) {
        
        CBCharacteristic *dauthCharacteristic;
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_DAUTH]) {
                dauthCharacteristic = characteristic;
            }
        }
        
        if (dauthCharacteristic == nil) {
            
            NSLog(@"Error, auth characteristic not found.");
            
        }else{
            
            [peripheral readValueForCharacteristic:dauthCharacteristic];
            
        }
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    NSLog(@"peripheral: didUpdateValueForDescriptor: error:");
    
    if ([self.discoveredPeripherals containsObject:peripheral]) {
        
        if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_DAUTH]) {
            
            NSString *authKey = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            
            if ([authKey isEqualToString:self.device.authKey]) {
                
                self.peripheral = peripheral;
                [self.discoveredPeripherals removeObject:peripheral];
                
                NSLog(@"Fucking equal!!!");
                
            }else{
                
                NSLog(@"Authentication keys doesn't match.");
                
                [self.discoveredPeripherals removeObject:peripheral];
                [self.ignoredPeripherals addObject:peripheral];
                
            }
            
        }
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"peripheral: didWriteValueForCharacteristic: error:");
    
    NSLog(@"error %@", error);
    
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0 && indexPath.row == 0 ? 70 : 44);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0 ? 3 : 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    static NSString * const cellIdentifierAccessoryLabel = @"cell-identifier-accessory-label";
    static NSString * const cellIdentifierDevice = @"cell-identifier-device";
    
    UITableViewCell *cell;
    UILabel *accessoryLabel;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDevice];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifierDevice];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.imageView.image = self.image;
        cell.textLabel.text = self.device.name;
        cell.detailTextLabel.text = self.device.group.name;
        
    }else if (indexPath.section == 0) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierAccessoryLabel];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierAccessoryLabel];
            
            accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
            accessoryLabel.textAlignment = NSTextAlignmentRight;
            accessoryLabel.textColor = [UIColor colorWithRed:109/255.f green:109/255.f blue:114/255.f alpha:1];
            cell.accessoryView = accessoryLabel;
            
        }
        
        if (indexPath.row == 1) {
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Status";
            accessoryLabel.text = @"Connected";
            
        }else if (indexPath.row == 2) {
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"RSSI";
            accessoryLabel.text = @"187 dB";
            
        }
        
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
        }
        
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = self.view.tintColor;
        cell.textLabel.text = @"Blink LED";
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        
        [self blinkLED];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
