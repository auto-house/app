//
//  CBManager.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "BLEManager.h"


@interface BLEManager ()

@property (nonatomic, retain) NSMutableArray *peripherals;
@property (nonatomic, retain) CBCentralManager *centralManager;

@end


@implementation BLEManager

#pragma mark - Lifecycle

+ (id)sharedManager {
    
    static dispatch_once_t onceToken;
    static BLEManager *sharedManager = nil;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        self.peripherals = [[NSMutableArray alloc] init];
        
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
        self.centralManager.delegate = self;
        
    }
    
    return self;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBManagerStatePoweredOn) {
        
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        
    }
    
}

- (void)centralManager:(CBCentralManager *)central
            didDiscoverPeripheral:(CBPeripheral *)peripheral
                advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                    RSSI:(NSNumber *)RSSI {
    
    if ([self.peripherals containsObject:peripheral]) {
        
        // Update RSSI.
        // Decrease the miss advertising count.
        
    }else{
        
        // The peripheral discovered is not in the list yet.
        
        [self.peripherals addObject:peripheral];
        
        //
        
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    //
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    //
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didDiscoverCharacteristicsForService:(nonnull CBService *)service
                error:(nullable NSError *)error {
    
    //
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    //
    
}

@end
