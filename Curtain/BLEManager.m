//
//  CBManager.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "BLEManager.h"

#define FIND_DEVICE_LOOKING_TIMEOUT 10


@interface BLEManager ()

@property (nonatomic, copy) void (^startScanningCompletionBlock)(NSError *error);

@property (nonatomic, retain) NSMutableArray *peripherals;
@property (nonatomic, retain) NSMutableArray *authenticatedPeripherals;

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
        self.authenticatedPeripherals = [[NSMutableArray alloc] init];
        
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
        self.centralManager.delegate = self;
        
    }
    
    return self;
}

#pragma mark - Public

- (void)startScanning:(void (^)(NSError *error))completion {
    
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        
        completion(nil);
        
    }else{
        
        self.startScanningCompletionBlock = completion;
        
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        
    }
    
}

- (void)findDeviceWithAuthKey:(NSString *)key completion:(void (^)(CBPeripheral *peripheral, NSError *error))completion {
    
    NSError *error;
    
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        
        [self performSelector:@selector(checkDevice:) withObject:@[key, completion] afterDelay:FIND_DEVICE_LOOKING_TIMEOUT];
        
    }else{
        
        error = [NSError errorWithDomain:@"Core bluetooth central manager is not powered on." code:1000 userInfo:nil];
        
        completion(nil, error);
        
    }
    
}

#pragma mark - Private

- (void)checkDevice:(NSArray *)details {
    
    NSString *key = [details objectAtIndex:0];
    void (^completion)(CBPeripheral *peripheral, NSError *error) = [details objectAtIndex:1];
    
    CBPeripheral *peripheral;
    
    for (NSDictionary *info in self.authenticatedPeripherals) {
        if ([[info objectForKey:@"authKey"] isEqualToString:key]) {
            
            
            
        }
    }
    
    if (peripheral == nil) {
        
        //
        
    }else{
        
        NSError *error = [NSError errorWithDomain:@"Unable to find peripheral." code:1001 userInfo:nil];
        
        completion(nil, error);
        
    }
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBManagerStatePoweredOn) {
        
        self.startScanningCompletionBlock(nil);
        
    }else{
        
        NSError *error = [NSError errorWithDomain:@"Core bluetooth central manager is not powered on." code:1000 userInfo:nil];
        
        self.startScanningCompletionBlock(error);
        
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
