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


@interface DevicesViewController ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CBCentralManager *centralManager;

@end


@implementation DevicesViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Devices";
    
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
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Device %li", (long)indexPath.row];
    
    return cell;
}

@end
