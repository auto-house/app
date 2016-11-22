//
//  DevicePickerViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "DevicePickerViewController.h"

#define CURTAIN_SERVICE_UUID_CONNECTION                      @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_BLINK @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF1"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_SETUP @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF2"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_DAUTH @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF3"


@interface DevicePickerViewController ()

@property (nonatomic) BOOL peripheralReady;
@property (nonatomic, retain) CBPeripheral *selectedPeripheral;

@property (nonatomic, retain) NSMutableArray *peripherals;

@end


@implementation DevicePickerViewController

@synthesize peripheralReady = _peripheralReady;
@synthesize selectedPeripheral = _selectedPeripheral;
@synthesize peripherals = _peripherals;

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
        
        //NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES};
        
        CBUUID *primary = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_CONNECTION];
        NSArray *known = [self.centralManager retrieveConnectedPeripheralsWithServices:@[primary]];
        
        for (CBPeripheral *peripheral in known) {
            NSLog(@"Previously connected to %@.", peripheral);
        }
        
        //[self.centralManager scanForPeripheralsWithServices:@[primary] options:nil];
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        
    }
    
}

#pragma mark - Private

- (NSString *)generateAuthKey {
    
    return @"acbd18db4cc2f85cedef654fccc4a4d8";
    
}

- (NSString *)generateEncryptionKey {
    
    return @"1dd318f884fa0cc1a8abbeebb7fe7914";
    
}

- (void)alertViewWithTitle:(NSString *)title forMessage:(NSString *)message {
    
    UIAlertController *alertController;
    UIAlertAction *dismissalAction;
    
    alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    dismissalAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:dismissalAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)askVisualConfirmation:(CBPeripheral *)peripheral service:(CBService *)service {
    
    NSLog(@"askVisualConfirmation: service:");
    
    NSString *title = @"Is it?";
    NSString *msg = @"Is the connection LED blinking?";
    
    UIAlertController *alert;
    UIAlertAction *connectAction, *dismissAction;
    
    alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    connectAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSError *error;
        NSDictionary *message;
        NSData *data;
        CBCharacteristic *characteristic;
        
        NSString *authKey = [self generateAuthKey];
        NSString *encryptionKey = [self generateEncryptionKey];
        
        message = @{
                    @"action": @"setup",
                    @"authKey": authKey,
                    @"encryptionKey": encryptionKey
                    };
        
        data = [NSJSONSerialization dataWithJSONObject:message options:NSJSONWritingPrettyPrinted error:&error];
        
        if (service.characteristics.count > 0) {
            
            for (CBCharacteristic *ch in service.characteristics) {
                NSLog(@"Characteristic: %@", ch);
                if ([ch.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_SETUP]) {
                    characteristic = ch;
                }
            }
            
            NSLog(@"Characteristic Selected: %@", characteristic);
            
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
        }else{
            
            NSLog(@"No characteristics found.");
            
        }
        
    }];
    
    [alert addAction:connectAction];
    
    dismissAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:dismissAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
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
    
    NSIndexPath *indexPath;
    
    if ([self.peripherals containsObject:peripheral] == YES){
        
        // Update RSSI.
        // Decrease the miss advertising count.
        
    }else{
        
        // Peripheral discovered and not yet on the available devices list.
        
        indexPath = [NSIndexPath indexPathForRow:self.peripherals.count inSection:0];
        
        [self.peripherals addObject:peripheral];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
    }
    
    // Check for devices on the list that went off or out of range.
    // Do this by counting every time a device miss advertises.
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"centralManager: didConnectPeripheral:");
    
    CBUUID *uuid;
    
    if (peripheral == self.selectedPeripheral) {
        
        // The selected peripheral was successfully connected.
        // Discover its services. If they are known, call the peripheral delegate method to continue setting it up.
        
        peripheral.delegate = self;
        
        if (peripheral.services) {
            
            [self peripheral:peripheral didDiscoverServices:nil];
        
        }else{
            
            // Look for the connection service, its the primary one.
            uuid = [CBUUID UUIDWithString:CURTAIN_SERVICE_UUID_CONNECTION];
            [peripheral discoverServices:@[uuid]];
            
        }
        
    }
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    NSLog(@"peripheral: didDiscoverServices:");
    
    NSString *title, *message;
    
    CBService *connectionService;
    CBUUID *blinkCharacteristic, *setupCharacteristic, *dauthCharacteristic;
    NSArray *characteristics;
    
    if (peripheral == self.selectedPeripheral) {
        
        if (error) {
            
            NSLog(@"Unable to discover requested services with error: %@.", error);
            
            title = @"Error";
            message = [NSString stringWithFormat:@"Failed to discover the services offered by \"%@\".", peripheral.name];
            
            [self alertViewWithTitle:title forMessage:message];
            
        }else{
            
            if (peripheral.services.count == 0) {
                
                title = @"Error";
                message = [NSString stringWithFormat:@"No services offered by \"%@\" were found.", peripheral.name];
                
                [self alertViewWithTitle:title forMessage:message];
                
            }else{
                
                for (CBService *service in peripheral.services) {
                    if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_CONNECTION]) {
                        connectionService = service;
                    }
                }
                
                if (connectionService == nil) {
                    
                    title = @"Error";
                    message = [NSString stringWithFormat:@"The connection service was not found in \"%@\".", peripheral.name];
                    
                    [self alertViewWithTitle:title forMessage:message];
                    
                }else{
                    
                    // Look for the characteristics used while setting up the device.
                    
                    blinkCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_BLINK];
                    setupCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_SETUP];
                    dauthCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_DAUTH];
                    
                    characteristics = @[blinkCharacteristic, setupCharacteristic, dauthCharacteristic];
                    
                    [peripheral discoverCharacteristics:characteristics forService:connectionService];
                    
                }
                
            }
            
        }
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didDiscoverCharacteristicsForService:(nonnull CBService *)service
                error:(nullable NSError *)error {
    
    NSLog(@"peripheral: didDiscoverCharacteristicsForService: error:");
    
    NSError *err;
    NSDictionary *json;
    NSData *data;
    CBCharacteristic *characteristic;
    
    NSString *title, *message;
    
    if (peripheral == self.selectedPeripheral) {
        
        if (error) {
            
            NSLog(@"Unable to discover requested characteristics with error: %@.", error);
            
            title = @"Error";
            message = [NSString stringWithFormat:@"Failed to discover the characteristics offered by \"%@\".", peripheral.name];
            
            [self alertViewWithTitle:title forMessage:message];
            
        }else{
            
            if (service.characteristics.count < 3) {
                
                title = @"Error";
                message = [NSString stringWithFormat:@"Unable to obtain the required characteristics from \"%@\".", peripheral.name];
                
                [self alertViewWithTitle:title forMessage:message];
                
            }else{
                
                json = @{@"action": @"blink-led"};
                data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&err];
                
                for (CBCharacteristic *ch in service.characteristics) {
                    if ([ch.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_BLINK]) {
                        characteristic = ch;
                    }
                    NSLog(@"Discovered characteristic: %@.", ch);
                }
                
                [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                
            }
            
        }
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"peripheral: didWriteValueForCharacteristic: error:");
    
    NSInteger index;
    NSIndexPath *indexPath;
    
    NSString *uuid, *title, *message;
    
    CBService *service;
    
    if (peripheral == self.selectedPeripheral) {
        
        uuid = characteristic.UUID.UUIDString;
        
        if ([uuid isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_BLINK]) {
            
            // Wrote value for the blink characteristic.
            
            if (error) {
                
                // Something went wrong while asking the LED to blink.
                // Deselect the peripheral, update the table row and report to the user.
                
                title = @"Error";
                message = @"Failed to write value for the Blink Characteristic.";
                
                index = [self.peripherals indexOfObject:self.selectedPeripheral];
                indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                self.selectedPeripheral = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                [self alertViewWithTitle:title forMessage:message];
                
            }else{
                
                // The peripheral acknowledged the request to blink the connection LED.
                // Ask the user for a visual confirmation.
                
                for (CBService *s in peripheral.services) {
                    if ([s.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_UUID_CONNECTION]) {
                        service = s;
                    }
                }
                
                [self askVisualConfirmation:peripheral service:service];
                
            }
            
        }else if ([uuid isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_UUID_SETUP]) {
            
            // Wrote value for the setup characteristic.
            
            if (error) {
                
                // Something went wrong while while setting up the peripheral.
                // Deselect the peripheral, update the table row and report to the user.
                
                title = @"Error";
                message = @"Failed to write value for the Setup Characteristic.";
                
                index = [self.peripherals indexOfObject:self.selectedPeripheral];
                indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                self.selectedPeripheral = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                [self alertViewWithTitle:title forMessage:message];
                
            }else{
                
                NSLog(@"All finished, save things and get the hell out of here.");
                
                self.peripheralReady = YES;
                
                // Reload row.
                
                NSInteger index = [self.peripherals indexOfObject:self.selectedPeripheral];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                // Inform the delegate.
                
                NSDictionary *infos = @{
                                        @"authKey": [self generateAuthKey],
                                        @"encryptionKey": [self generateEncryptionKey],
                                        @"peripheral": self.selectedPeripheral
                                        };
                
                if ([self.delegate respondsToSelector:@selector(pickedDevice:)]) {
                    [self.delegate pickedDevice:infos];
                }
                
            }
            
        }
        
    }
    
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
        
        cell.textLabel.text = peripheral.name;
        
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
        }
        
        cell.imageView.image = [UIImage imageNamed:@"three-bars.png"];
        cell.textLabel.text = (peripheral.name.length ? peripheral.name : @"Unknow Device");
        cell.accessoryType = (peripheral == self.selectedPeripheral ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    
    CBPeripheral *peripheral;
    
    NSIndexPath *oldIndexPath;
    NSArray *indexesToReload;
    
    peripheral = [self.peripherals objectAtIndex:indexPath.row];
    
    if (peripheral != self.selectedPeripheral) {
        
        // Update the selected row to start spinning the activity indicator.
        // If a device was previously configured, update its row too, removing the chechmark.
        
        if (self.selectedPeripheral) {
            index = [self.peripherals indexOfObject:self.selectedPeripheral];
            oldIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
            indexesToReload = @[oldIndexPath, indexPath];
        }else{
            indexesToReload = @[indexPath];
        }
        
        self.peripheralReady = NO;
        self.selectedPeripheral = peripheral;
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // Connect to the peripheral.
        // If it is already connected, just call the central manager method to start setting it up.
        
        if (peripheral.state == CBPeripheralStateConnected) {
            [self centralManager:self.centralManager didConnectPeripheral:peripheral];
        }else{
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
