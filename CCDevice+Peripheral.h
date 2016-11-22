//
//  CCGroup+Peripheral.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/18/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CCDevice.h"

@interface CCDevice (Peripheral)

@property (nonatomic, retain) CBPeripheral *peripheral;

@end
