//
//  DevicesViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "DevicesViewController.h"
#import "AppDelegate.h"
#import "SettingsViewController.h"
#import "SetupViewController.h"
#import "CCDevice.h"
#import "CCGroup.h"
#import "DeviceViewController.h"

#import "BLEManager.h"


@interface DevicesViewController ()

@property (nonatomic, retain) NSIndexPath *indexPathToDismiss;
@property (nonatomic, retain) NSIndexPath *indexPathToInsert;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CBCentralManager *centralManager;

@property (nonatomic, retain) NSMutableArray *devices;
@property (nonatomic, retain) NSMutableDictionary *images;

@end


@implementation DevicesViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Devices";
    self.tableView.rowHeight = 80;
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.managedObjectContext = delegate.persistentContainer.viewContext;
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    // Create navigation bar button items.
    
    UIBarButtonItem *setupBBI, *settingsBBI;
    
    settingsBBI = [[UIBarButtonItem alloc]
                   initWithTitle:@"Settings"
                   style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(openSettings)];
    
    setupBBI = [[UIBarButtonItem alloc]
                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                target:self
                action:@selector(setupDevice)];
    
    self.navigationItem.leftBarButtonItem = settingsBBI;
    self.navigationItem.rightBarButtonItem = setupBBI;
    
    // Fetch devices.
    
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Device"];
    NSArray *devices = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    self.devices = [NSMutableArray arrayWithArray:devices];
    self.images = [[NSMutableDictionary alloc] init];
    
    // Start the ble manager.
    
    /*
    BLEManager *manager = [BLEManager sharedManager];
    
    [manager startScanning:^(NSError *error) {
        
        if (error) {
            
            NSLog(@"BLE Manager star scanning error: %@", error);
            
        }else{
            
            for (CCDevice *device in self.devices) {
                
                [manager findDeviceWithAuthKey:device.authKey completion:^(CBPeripheral *peripheral, NSError *error) {
                    
                    NSLog(@"Found peripheral %@ %@", peripheral, error);
                    
                }];
                
            }
            
        }
        
    }];
    */
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // Deselect rows while the view is appearing.
    
    if (self.indexPathToDismiss) {
        
        [self.tableView deselectRowAtIndexPath:self.indexPathToDismiss animated:YES];
        
        self.indexPathToDismiss = nil;
        
    }
    
    // Animate the insertion of rows while the view is appearing.
    
    if (self.indexPathToInsert) {
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[self.indexPathToInsert] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        self.indexPathToInsert = nil;
        
    }
    
}

#pragma mark - NSObjects

- (UIImage *)cropImage:(UIImage *)image {
    
    UIImage *cropped;
    
    CGFloat side = MIN(image.size.width, image.size.height);
    CGSize size = CGSizeMake(side, side);
    
    CGFloat downScale = side/70;
    CGFloat borderWidth = downScale*20;
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextAddArc(context, side/2, side/2, (side-borderWidth)/2, 0, 2*M_PI, 0);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGRect clipRect = CGRectMake(0, 0, size.width, size.height);
    CGContextClipToRect(context, clipRect);
    CGRect cropRect = CGRectMake(-(image.size.width-size.width)/2, -(image.size.width-size.height)/2, image.size.width, image.size.height);
    CGContextDrawImage(context, cropRect, image.CGImage);
    
    cropped = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cropped;
}

#pragma mark - Private

- (void)alertViewWithTitle:(NSString *)title forMessage:(NSString *)message withDismissalTitle:(NSString *)dismissalTitle {
    
    // Presents an alert view controller with a single dismissal button.
    
    UIAlertController *alertController;
    UIAlertAction *dismissalAction;
    
    alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    dismissalAction = [UIAlertAction actionWithTitle:dismissalTitle style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:dismissalAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)lookForDevices {
    
    //
    
}

- (void)openSettings {
    
    // Open the application settings controller.
    
    SettingsViewController *view = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    view.managedObjectContext = self.managedObjectContext;
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:view];
    
    [self presentViewController:navCon animated:YES completion:nil];
    
}

- (void)setupDevice {
    
    // Open the device setup controller.
    // It requires the blueooth to be on. Report to the user, if, it is not.
    
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        
        SetupViewController *view = [[SetupViewController alloc] initWithStyle:UITableViewStyleGrouped];
        view.delegate = self;
        view.managedObjectContext = self.managedObjectContext;
        view.centralManager = self.centralManager;
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:view];
        [self presentViewController:navCon animated:YES completion:nil];
        
    }else{
        
        [self alertViewWithTitle:@"Error" forMessage:@"Bluetooth is off. " withDismissalTitle:@"Ok"];
        
    }
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (self.centralManager.state != CBManagerStatePoweredOn) {
        NSLog(@"The core blueooth central manager is not powered on.");
    }
    
}

#pragma mark - Setup device delegate

- (void)createdDevice:(CCDevice *)device {
    
    // A new device record has been created, update data sources.
    // Animate its corresponding row insertion when the view appears.
    
    self.indexPathToInsert = [NSIndexPath indexPathForRow:self.devices.count inSection:0];
    
    [self.devices addObject:device];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifierDefault];
        
    }
    
    CCDevice *device = [self.devices objectAtIndex:indexPath.row];
    UIImage *image = [self.images objectForKey:device.imageUrl];
    
    if (image == nil) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:device.imageUrl];
        
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        image = [self cropImage:[UIImage imageWithData:imageData]];
        
        [self.images setValue:image forKey:device.imageUrl];
        
    }
    
    cell.imageView.image = image;
    cell.textLabel.text = device.name;
    cell.detailTextLabel.text = device.group.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.indexPathToDismiss = indexPath;
    
    CCDevice *device = [self.devices objectAtIndex:indexPath.row];
    UIImage *image = [self.images objectForKey:device.imageUrl];
    
    if (image == nil) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:device.imageUrl];
        
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        image = [self cropImage:[UIImage imageWithData:imageData]];
        
        [self.images setValue:image forKey:device.imageUrl];
        
    }
    
    DeviceViewController *view = [[DeviceViewController alloc] initWithStyle:UITableViewStyleGrouped];
    view.managedObjectContext = self.managedObjectContext;
    view.centralManager = self.centralManager;
    view.device = device;
    view.image = image;
    
    [self.navigationController pushViewController:view animated:YES];
    
}

@end
