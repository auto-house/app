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


@interface DevicesViewController ()

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
    self.tableView.rowHeight = 70;
    
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
    
    for (CCDevice *device in devices) {
        NSLog(@"Name:%@ AuthKey:%@ EncryptionKey:%@ ImageUrl:%@", device.name, device.authKey, device.encryptionKey, device.imageUrl);
    }
    
    self.devices = [NSMutableArray arrayWithArray:devices];
    self.images = [[NSMutableDictionary alloc] init];
    
}

#pragma mark - Private

- (void)openSettings {
    
    SettingsViewController *view = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    view.managedObjectContext = self.managedObjectContext;
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:view];
    [self presentViewController:navCon animated:YES completion:nil];
    
}

- (void)setupDevice {
    
    BOOL foo = YES;
    
    if (self.centralManager.state == CBManagerStatePoweredOn || foo) {
        
        SetupViewController *view = [[SetupViewController alloc] initWithStyle:UITableViewStyleGrouped];
        view.managedObjectContext = self.managedObjectContext;
        view.centralManager = self.centralManager;
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:view];
        [self presentViewController:navCon animated:YES completion:nil];
        
    }else{
        
        NSLog(@"Ops, looks like the core bluetooth central manager is not powered on.");
        
    }
    
}

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

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
            
        case CBManagerStatePoweredOn:
            NSLog(@"centralManagerDidUpdate: CBManagerStatePoweredOn");
            break;
        
        case CBManagerStatePoweredOff:
            NSLog(@"centralManagerDidUpdate: CBManagerStatePoweredOff");
            break;
        
        case CBManagerStateUnsupported:
            NSLog(@"centralManagerDidUpdate: CBManagerStateUnsupported");
            break;
        
        case CBManagerStateUnauthorized:
            NSLog(@"centralManagerDidUpdate: CBManagerStateUnauthorized");
            break;
            
        case CBManagerStateResetting:
            NSLog(@"centralManagerDidUpdate: CBManagerStateResetting");
            break;
            
        case CBManagerStateUnknown:
            NSLog(@"centralManagerDidUpdate: CBManagerStateUnknown");
            break;
            
    }
    
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
    view.centralManager = self.centralManager;
    view.device = device;
    view.image = image;
    
    [self.navigationController pushViewController:view animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
