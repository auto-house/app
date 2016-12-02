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
#import "CCSchedule.h"

#import "ScheduleViewController.h"

#define CURTAIN_SERVICE_CONNECTION_UUID                             @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_BLINK_UUID        @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF1"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_SETUP_UUID        @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF2"
#define CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_DAUTH_UUID        @"FFFFFFFF-FFFF-FFFF-FFF0-FFFFFFFFFFF3"

#define CURTAIN_SERVICE_DEMO_UUID                                   @"FFFFFFFF-FFFF-FFFF-FFF1-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_DEMO_CHARACTERISTIC_DEMO_UUID               @"FFFFFFFF-FFFF-FFFF-FFF1-FFFFFFFFFFF1"

#define CURTAIN_SERVICE_LIGHTS_UUID                                 @"FFFFFFFF-FFFF-FFFF-FFF2-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_LIGHTS_CHARACTERISTIC_INTERNAL_UUID         @"FFFFFFFF-FFFF-FFFF-FFF2-FFFFFFFFFFF1"
#define CURTAIN_SERVICE_LIGHTS_CHARACTERISTIC_EXTERNAL_UUID         @"FFFFFFFF-FFFF-FFFF-FFF2-FFFFFFFFFFF2"

#define CURTAIN_SERVICE_MOVE_UUID                                   @"FFFFFFFF-FFFF-FFFF-FFF3-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_MOVE_CHARACTERISTIC_OPEN_UUID               @"FFFFFFFF-FFFF-FFFF-FFF3-FFFFFFFFFFF1"
#define CURTAIN_SERVICE_MOVE_CHARACTERISTIC_CLOSE_UUID              @"FFFFFFFF-FFFF-FFFF-FFF3-FFFFFFFFFFF2"


@interface DeviceViewController ()

@property (nonatomic, retain) NSMutableArray *discoveredPeripherals;
@property (nonatomic, retain) NSMutableArray *ignoredPeripherals;
@property (nonatomic, retain) CBPeripheral *peripheral;

@property (nonatomic, retain) NSMutableArray *schedule;

@end


@implementation DeviceViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Device";
    
    self.centralManager.delegate = self;
    
    self.discoveredPeripherals = [[NSMutableArray alloc] init];
    self.ignoredPeripherals = [[NSMutableArray alloc] init];
    
    [self checkPeripheral];
    
    // Fetch device schedule.
    
    NSError *error;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"device == %@", self.device];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
    [request setPredicate:predicate];
    
    NSArray *schedule = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    for (CCSchedule *item in schedule) {
        NSLog(@"Schedule created on %@", item.creationDate);
    }
    
    self.schedule = [NSMutableArray arrayWithArray:schedule];
    
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
        
        CBUUID *connectionService = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_UUID];
        [self.centralManager scanForPeripheralsWithServices:@[connectionService] options:nil];
        
    }else{
        
        peripheral.delegate = self;
        
        if (peripheral.state == CBPeripheralStateConnected) {
            
            CBService *connectionService, *demoService, *lightsService, *moveService;
            
            for (CBService *service in peripheral.services) {
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_UUID]) {
                    connectionService = service;
                }
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_DEMO_UUID]) {
                    demoService = service;
                }
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_LIGHTS_UUID]) {
                    lightsService = service;
                }
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_MOVE_UUID]) {
                    moveService = service;
                }
            }
            
            if (connectionService == nil || demoService == nil || lightsService == nil || moveService == nil) {
                
                CBUUID *connectionServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_UUID];
                CBUUID *demoServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_DEMO_UUID];
                CBUUID *lightsServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_LIGHTS_UUID];
                CBUUID *moveServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_MOVE_UUID];
                
                [peripheral discoverServices:@[connectionServiceUUID, demoServiceUUID, lightsServiceUUID, moveServiceUUID]];
                
            }
            
        }else{
            
            [self.centralManager connectPeripheral:peripheral options:nil];
            
        }
        
    }
    
}

- (void)operateCurtain:(CurtainAction)action {
    
    CBPeripheral *peripheral = self.peripheral;
    
    if (peripheral == nil) {
        
        [self checkPeripheral];
        
    }else{
        
        CBService *moveService;
        CBCharacteristic *moveCharacteristic;
        
        for (CBService *service in peripheral.services) {
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_MOVE_UUID]) {
                moveService = service;
            }
        }
        
        for (CBCharacteristic *characteristic in moveService.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_MOVE_CHARACTERISTIC_OPEN_UUID]) {
                moveCharacteristic = characteristic;
            }
        }
        
        NSError *error;
        NSDictionary *json = @{@"action": @"open"};
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
        
        [peripheral writeValue:data forCharacteristic:moveCharacteristic type:CBCharacteristicWriteWithResponse];
        
        
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
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_DEMO_UUID]) {
                blinkService = service;
            }
        }
        
        for (CBCharacteristic *characteristic in blinkService.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_DEMO_CHARACTERISTIC_DEMO_UUID]) {
                demoCharacteristic = characteristic;
            }
        }
        
        NSError *error;
        NSDictionary *json = @{@"action": @"blink-led"};
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
        
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
        
        CBUUID *connectionService = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_UUID];
        CBUUID *demoService = [CBUUID UUIDWithString:CURTAIN_SERVICE_DEMO_UUID];
        CBUUID *lightsService = [CBUUID UUIDWithString:CURTAIN_SERVICE_LIGHTS_UUID];
        CBUUID *moveService = [CBUUID UUIDWithString:CURTAIN_SERVICE_MOVE_UUID];
        
        
        [self. discoveredPeripherals addObject:peripheral];
        
        [peripheral setDelegate:self];
        [peripheral discoverServices:@[connectionService, demoService, lightsService, moveService]];
        
    }
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    NSLog(@"peripheral: didDiscoverServices:");
    
    if ([self.discoveredPeripherals containsObject:peripheral]) {
        
        for (CBService *service in peripheral.services) {
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_UUID]) {
                
                CBUUID *blinkCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_BLINK_UUID];
                CBUUID *setupCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_SETUP_UUID];
                CBUUID *dauthCharacteristics = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_DAUTH_UUID];
                
                NSArray *characteristics = @[blinkCharacteristic, setupCharacteristic, dauthCharacteristics];
                [peripheral discoverCharacteristics:characteristics forService:service];
                
            }
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_DEMO_UUID]) {
                
                CBUUID *demoCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_DEMO_CHARACTERISTIC_DEMO_UUID];
                
                NSArray *characteristics = @[demoCharacteristic];
                [peripheral discoverCharacteristics:characteristics forService:service];
                
            }
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_LIGHTS_UUID]) {
                
                CBUUID *internalLightsCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_LIGHTS_CHARACTERISTIC_INTERNAL_UUID];
                CBUUID *externalLightsCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_LIGHTS_CHARACTERISTIC_EXTERNAL_UUID];
                
                NSArray *characteristics = @[internalLightsCharacteristic, externalLightsCharacteristic];
                [peripheral discoverCharacteristics:characteristics forService:service];
                
            }
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_MOVE_UUID]) {
                
                CBUUID *openCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_MOVE_CHARACTERISTIC_OPEN_UUID];
                CBUUID *closeCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_MOVE_CHARACTERISTIC_CLOSE_UUID];
                
                NSArray *characteristics = @[openCharacteristic, closeCharacteristic];
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
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_DAUTH_UUID]) {
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
        
        if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_CONNECTION_CHARACTERISTIC_DAUTH_UUID]) {
            
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger number;
    
    switch (section) {
        case 0:
            number = 1;
            break;
        case 1:
            number = 3;
            break;
        case 2:
            number = self.schedule.count + 1;
            break;
        default:
            number = 0;
            break;
    }
    
    return number;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *title;
    
    switch (section) {
        case 1:
            title = @"Quick Actions";
            break;
        case 2:
            title = @"Scheduled Actions";
            break;
        default:
            title = nil;
            break;
    }
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0 && indexPath.row == 0 ? 100 : 44);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    static NSString * const cellIdentifierDevice = @"cell-identifier-device";
    static NSString * const cellIdentifierAccessorySwitch = @"cell-identifier-accessory-switch";
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat sidesPadding = 15;
    
    UITableViewCell *cell;
    
    UIImageView *imageView;
    UILabel *groupLabel;
    UILabel *titleLabel;
    
    UISwitch *accessorySwitch;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDevice];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifierDevice];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(sidesPadding, 10, 80, 80)];
            [cell.contentView addSubview:imageView];
            
            groupLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidesPadding+80+10, 10, screenSize.width-(2*sidesPadding)-80-10, 20)];
            groupLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            [cell.contentView addSubview:groupLabel];
            
            titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidesPadding+80+10, 30, screenSize.width-(2*sidesPadding)-80-10, 20)];
            titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            [cell.contentView addSubview:titleLabel];
            
            imageView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
            //groupLabel.backgroundColor = [UIColor greenColor];
            //titleLabel.backgroundColor = [UIColor orangeColor];
            
        }
        
        imageView.image = self.image;
        groupLabel.text = self.device.group.name;
        titleLabel.text = self.device.name;
        
    }else if (indexPath.section == 2 && indexPath.row < self.schedule.count) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierAccessorySwitch];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifierAccessorySwitch];
            
            accessorySwitch = [[UISwitch alloc] init];
            cell.accessoryView = accessorySwitch;
            
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.timeStyle = NSDateFormatterShortStyle;
        
        CCSchedule *schedule = [self.schedule objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [formatter stringFromDate:schedule.time];
        cell.detailTextLabel.text = schedule.repeat;
        
        accessorySwitch.on = [schedule.active boolValue];
        
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
        }
        
        if (indexPath.section == 1) {
            
            cell.textLabel.textColor = self.view.tintColor;
            
            if (indexPath.row == 0) {
                
                cell.textLabel.text = @"Open";
                
            }else if (indexPath.row == 1) {
                
                cell.textLabel.text = @"Close";
                
            }else if (indexPath.row == 2){
                
                cell.textLabel.text = @"Blink LED";
                
            }
            
        }else if (indexPath.section == 2) {
            
            cell.textLabel.textColor = self.view.tintColor;
            cell.textLabel.text = @"New Scheduled Action";
            
        }
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            
            [self operateCurtain:CurtainActionOpen];
            
        }else if (indexPath.row == 1) {
            
            [self operateCurtain:CurtainActionClose];
            
        }else{
            
            [self blinkLED];
            
        }
        
    }else if (indexPath.section == 2 && indexPath.row == self.schedule.count) {
        
        // Schedule a new action.
        
        ScheduleViewController *view = [[ScheduleViewController alloc] initWithStyle:UITableViewStyleGrouped];
        view.managedObjectContext = self.managedObjectContext;
        view.device = self.device;
        
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:view];
        [self presentViewController:navCon animated:YES completion:nil];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
