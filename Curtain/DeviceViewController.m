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

#define CELL_DEVICE_IMAGE_VIEW_TAG  90001
#define CELL_DEVICE_LABEL_GROUP_TAG 90002
#define CELL_DEVICE_LABEL_TITLE_TAG 90003
#define CELL_DEVICE_LABEL_STATE_TAG 90004

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
#define CURTAIN_SERVICE_MOVE_CHARACTERISTIC_FULL_UUID               @"FFFFFFFF-FFFF-FFFF-FFF3-FFFFFFFFFFF1"

#define CURTAIN_SERVICE_SYNC_UUID                                   @"FFFFFFFF-FFFF-FFFF-FFF4-FFFFFFFFFFFF"
#define CURTAIN_SERVICE_SYNC_CHARACTERISTIC_INCLUDE_UUID            @"FFFFFFFF-FFFF-FFFF-FFF4-FFFFFFFFFFF1"
#define CURTAIN_SERVICE_SYNC_CHARACTERISTIC_ABANDON_UUID            @"FFFFFFFF-FFFF-FFFF-FFF4-FFFFFFFFFFF2"


@interface DeviceViewController ()

@property (nonatomic, retain) NSIndexPath *indexPathToInsert;

@property (nonatomic, retain) NSMutableArray *discoveredPeripherals;
@property (nonatomic, retain) NSMutableArray *ignoredPeripherals;
@property (nonatomic, retain) CBPeripheral *peripheral;

@property (nonatomic, retain) NSMutableArray *schedule;

@end


@implementation DeviceViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Device";
    
    self.centralManager.delegate = self;
    
    self.discoveredPeripherals = [[NSMutableArray alloc] init];
    self.ignoredPeripherals = [[NSMutableArray alloc] init];
    
    [self checkPeripheral];
    
    CBUUID *primary = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_UUID];
    NSArray *known = [self.centralManager retrieveConnectedPeripheralsWithServices:@[primary]];
    
    for (CBPeripheral *peripheral in known) {
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    
    // Fetch device schedule.
    
    NSError *error;
    
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"device == %@", self.device];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
    [request setPredicate:predicate];
    NSArray *schedule = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    // Sort scheduled actions by time.
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm";
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES comparator:^NSComparisonResult(NSDate *obj1, NSDate *obj2) {
        return [[formatter stringFromDate:obj1] compare:[formatter stringFromDate:obj2]];
    }];
    
    self.schedule = [NSMutableArray arrayWithArray:[schedule sortedArrayUsingDescriptors:@[sortDescriptor]]];
    
    // Request permission to trigger notifications.
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!error) {
                                  NSLog(@"request authorization succeeded!");
                              }
                          }];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self.indexPathToInsert) {
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[self.indexPathToInsert] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        self.indexPathToInsert = nil;
        
    }
    
}

#pragma mark - NSObjects

- (NSString *)prettyPeripheralState:(CBPeripheralState)state {
    
    NSString *pretty;
    
    switch (state) {
            
        case CBPeripheralStateConnected:
            pretty = @"Connected";
            break;
            
        case CBPeripheralStateConnecting:
            pretty = @"Connecting";
            break;
            
        case CBPeripheralStateDisconnected:
            pretty = @"Disconnected";
            break;
            
        case CBPeripheralStateDisconnecting:
            pretty = @"Disconnecting";
            break;
            
    }
    
    return pretty;
    
}

- (NSString *)prettyStringForAction:(NSInteger)action {
    
    NSString *string;
    
    switch (action) {
        case SchedulableActionOpen:
            string = @"Open";
            break;
        case SchedulableActionClose:
            string = @"Close";
            break;
        case SchedulableActionBlink:
            string = @"Blink";
            break;
    }
    
    return string;
}

- (NSString *)prettyStringForRepeat:(NSString *)repeat {
    
    NSString *string = @"";
    NSArray *days = [repeat componentsSeparatedByString:@","];
    
    if (days.count == 7) {
        
        string = @"Everyday";
        
    }else{
        
        for (NSString *day in days) {
            
            NSString *append = @"";
            NSInteger d = [day integerValue];
            
            switch (d) {
                case WeekdaySunday:
                    append = @"Sun ";
                    break;
                case WeekdayMonday:
                    append = @"Mon ";
                    break;
                case WeekdayTuesday:
                    append = @"Tue ";
                    break;
                case WeekdayWednesday:
                    append = @"Wed ";
                    break;
                case WeekdayThursday:
                    append = @"Thr ";
                    break;
                case WeekdayFriday:
                    append = @"Fri ";
                    break;
                case WeekdaySaturday:
                    append = @"Sat ";
                    break;
                    
            }
            
            string = [string stringByAppendingString:append];
            
        }
        
    }
    
    return string;
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
            
            CBService *connectionService, *demoService, *lightsService, *moveService, *syncService;
            
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
                if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_SYNC_UUID]) {
                    syncService = service;
                }
            }
            
            if (connectionService == nil || demoService == nil || lightsService == nil || moveService == nil || syncService == nil) {
                
                CBUUID *connectionServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_CONNECTION_UUID];
                CBUUID *demoServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_DEMO_UUID];
                CBUUID *lightsServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_LIGHTS_UUID];
                CBUUID *moveServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_MOVE_UUID];
                CBUUID *syncServiceUUID = [CBUUID UUIDWithString:CURTAIN_SERVICE_SYNC_UUID];
                
                [peripheral discoverServices:@[connectionServiceUUID, demoServiceUUID, lightsServiceUUID, moveServiceUUID, syncServiceUUID]];
                
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
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_MOVE_CHARACTERISTIC_FULL_UUID]) {
                moveCharacteristic = characteristic;
            }
        }
        
        NSError *error;
        NSDictionary *json = @{@"action": (action == CurtainActionOpen ? @"open" : @"close")};
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

- (void)syncScheduledAction:(CCSchedule *)schedule {
    
    CBPeripheral *peripheral = self.peripheral;
    
    if (peripheral == nil) {
        
        [self checkPeripheral];
        
    }else{
        
        CBService *syncService;
        CBCharacteristic *includeCharacteristic;
        
        for (CBService *service in peripheral.services) {
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_SYNC_UUID]) {
                syncService = service;
            }
        }
        
        for (CBCharacteristic *characteristic in syncService.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_SYNC_CHARACTERISTIC_INCLUDE_UUID]) {
                includeCharacteristic = characteristic;
            }
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm";
        
        NSString *identifier = [NSString stringWithFormat:@"%f", [schedule.creationDate timeIntervalSince1970]];
        identifier = [identifier stringByReplacingOccurrencesOfString:@"." withString:@""];
        
        NSDictionary *json = @{
                               @"id": identifier,
                               @"action": schedule.action,
                               @"repeat": schedule.repeat,
                               @"scheduledTime": [formatter stringFromDate:schedule.time],
                               @"currentTime": [formatter stringFromDate:[NSDate date]]
                               };
        
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
        
        [peripheral writeValue:data forCharacteristic:includeCharacteristic type:CBCharacteristicWriteWithResponse];
        
        
    }
    
}

#pragma mark - Schedule view controller delegate

- (void)scheduledActionCreated:(CCSchedule *)schedule {
    
    self.indexPathToInsert = [NSIndexPath indexPathForRow:self.schedule.count inSection:2];
    
    [self.schedule addObject:schedule];
    
    if ([schedule.active boolValue] == YES && [schedule.isSynchronized boolValue] == NO) {
        [self syncScheduledAction:schedule];
    }
    
    // Schedule local notification.
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    
    content.title = @"Scheduled Action";
    content.body = [NSString stringWithFormat:@"%@ - %@",
                    self.device.name,
                    [self prettyStringForAction:[schedule.action integerValue]]
                    ];
    
    content.sound = [UNNotificationSound defaultSound];
    
    NSInteger interval = [schedule.time timeIntervalSinceDate:[NSDate date]] - 30;
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:interval repeats:NO];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond" content:content trigger:trigger];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"add NotificationRequest succeeded!");
        }
    }];
    
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
        CBUUID *syncService = [CBUUID UUIDWithString:CURTAIN_SERVICE_SYNC_UUID];
        
        [self. discoveredPeripherals addObject:peripheral];
        
        [peripheral setDelegate:self];
        [peripheral discoverServices:@[connectionService, demoService, lightsService, moveService, syncService]];
        
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
                
                CBUUID *fullCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_MOVE_CHARACTERISTIC_FULL_UUID];
                
                NSArray *characteristics = @[fullCharacteristic];
                [peripheral discoverCharacteristics:characteristics forService:service];
                
            }
            
            if ([service.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_SYNC_UUID]) {
                
                CBUUID *includeCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_SYNC_CHARACTERISTIC_INCLUDE_UUID];
                CBUUID *abandonCharacteristic = [CBUUID UUIDWithString:CURTAIN_SERVICE_SYNC_CHARACTERISTIC_ABANDON_UUID];
                
                NSArray *characteristics = @[includeCharacteristic, abandonCharacteristic];
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
                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                for (CCSchedule *schedule in self.schedule) {
                    if ([schedule.active boolValue] == YES && [schedule.isSynchronized boolValue] == NO) {
                        [self syncScheduledAction:schedule];
                    }
                }
                
                NSLog(@"Authentication successful.");
                
            }else{
                
                NSLog(@"Authentication keys doesn't match.");
                
                [self.discoveredPeripherals removeObject:peripheral];
                [self.ignoredPeripherals addObject:peripheral];
                
            }
            
        }
        
        if ([characteristic.UUID.UUIDString isEqualToString:CURTAIN_SERVICE_SYNC_CHARACTERISTIC_INCLUDE_UUID]) {
            
            NSLog(@"Reponse from the scheduler service.");
            
            if (error) {
                
                NSLog(@"Error %@", error.description);
                
            }else{
                
                NSLog(@"Fucking fucks it worked...");
                
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
    
    CGFloat baseY;
    CGFloat sidesPadding = 15;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    UITableViewCell *cell;
    
    UIImageView *imageView;
    UILabel *groupLabel;
    UILabel *titleLabel;
    UILabel *stateLabel;
    
    UISwitch *accessorySwitch;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDevice];
        
        if (cell == nil) {
            
            baseY = 10;
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifierDevice];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(sidesPadding, baseY, 80, 80)];
            imageView.tag = CELL_DEVICE_IMAGE_VIEW_TAG;
            [cell.contentView addSubview:imageView];
            
            groupLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidesPadding+80+10, baseY, screenSize.width-(2*sidesPadding)-80-10, 20)];
            groupLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            groupLabel.tag = CELL_DEVICE_LABEL_GROUP_TAG;
            [cell.contentView addSubview:groupLabel];
            
            baseY += groupLabel.frame.size.height;
            
            titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidesPadding+80+10, baseY, screenSize.width-(2*sidesPadding)-80-10, 20)];
            titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            titleLabel.tag = CELL_DEVICE_LABEL_TITLE_TAG;
            [cell.contentView addSubview:titleLabel];
            
            baseY += titleLabel.frame.size.height;
            
            stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidesPadding+80+10, baseY, screenSize.width-(2*sidesPadding)-80-10, 20)];
            stateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            stateLabel.tag = CELL_DEVICE_LABEL_STATE_TAG;
            [cell.contentView addSubview:stateLabel];
            
            imageView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
            //groupLabel.backgroundColor = [UIColor greenColor];
            //titleLabel.backgroundColor = [UIColor orangeColor];
            //stateLabel.backgroundColor = [UIColor purpleColor];
            
        }else{
            
            imageView = [cell viewWithTag:CELL_DEVICE_IMAGE_VIEW_TAG];
            groupLabel = [cell viewWithTag:CELL_DEVICE_LABEL_GROUP_TAG];
            titleLabel = [cell viewWithTag:CELL_DEVICE_LABEL_TITLE_TAG];
            stateLabel = [cell viewWithTag:CELL_DEVICE_LABEL_STATE_TAG];
            
        }
        
        imageView.image = self.image;
        groupLabel.text = self.device.group.name;
        titleLabel.text = self.device.name;
        stateLabel.text = [NSString stringWithFormat:@"State: %@.", [self prettyPeripheralState:self.peripheral.state]];
        
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                     [self prettyStringForAction:[schedule.action integerValue]],
                                     [self prettyStringForRepeat:schedule.repeat]];
        
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
        view.delegate = self;
        view.managedObjectContext = self.managedObjectContext;
        view.device = self.device;
        
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:view];
        [self presentViewController:navCon animated:YES completion:nil];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
