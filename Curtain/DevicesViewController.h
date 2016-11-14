//
//  DevicesViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface DevicesViewController : UITableViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@end
