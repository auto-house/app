//
//  DeviceViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <NotificationCenter/NotificationCenter.h>
#import <UserNotifications/UserNotifications.h>
#import "CCDevice.h"
#import "ScheduleViewController.h"


typedef NS_ENUM(NSInteger, CurtainAction) {
    CurtainActionOpen = 1,
    CurtainActionClose
};


@interface DeviceViewController : UITableViewController <CBCentralManagerDelegate, CBPeripheralDelegate, ScheduleViewControllerDelegate>

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) CBCentralManager *centralManager;
@property (nonatomic, retain) CCDevice *device;
@property (nonatomic, retain) UIImage *image;

@end
