//
//  SetupViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DevicePickerViewController.h"
#import "GroupPickerViewController.h"


@interface SetupViewController : UITableViewController <
                                                        UINavigationControllerDelegate,
                                                        UIImagePickerControllerDelegate,
                                                        UITextFieldDelegate,
                                                        DevicePickerDelegate,
                                                        GroupPickerDelegate
                                                        >

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CBCentralManager *centralManager;

@end
