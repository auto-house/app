//
//  CBManager.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface BLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (id)sharedManager;

- (void)startScanning:(void (^)(NSError *error))completion;

- (void)findDeviceWithAuthKey:(NSString *)key completion:(void (^)(CBPeripheral *peripheral, NSError *error))completion;

@end
