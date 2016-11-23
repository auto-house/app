//
//  DeviceViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CCDevice.h"


@interface DeviceViewController : UITableViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, retain) CBCentralManager *centralManager;
@property (nonatomic, retain) CCDevice *device;
@property (nonatomic, retain) UIImage *image;

@end
