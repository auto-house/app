//
//  DevicePickerViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CCDevice.h"


@protocol DevicePickerDelegate;

@interface DevicePickerViewController : UITableViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, retain) id<DevicePickerDelegate> delegate;
@property (nonatomic, retain) CBCentralManager *centralManager;

@end


@protocol DevicePickerDelegate <NSObject>

- (void)pickedDevice:(NSDictionary *)info;

@end
