//
//  ViewController.m
//  Curtain
//
//  Created by Mateus Nunes on 09/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


//
// scanning
//  -> found one
//      -> is the green led blinking? YES!
//          -> name the curtain
//              -> save the peripheral information
//
//


#import "ViewController.h"

#define SCANNING_VIEW_INDICATOR_TAG 10001
#define SCANNING_VIEW_TITLE_TAG     10002
#define SCANNING_VIEW_DETAIL_TAG    10003

#define BLINK_VIEW_TITLE_TAG    20001
#define BLINK_VIEW_DETAIL_TAG   20002


@interface ViewController ()

@property (nonatomic, retain) NSMutableArray *peripherals;
@property (nonatomic, retain) CBCentralManager *cbManager;

@end


@implementation ViewController

@synthesize peripherals = _peripherals;
@synthesize cbManager = _cbManager;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"BLE Services";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.peripherals = [[NSMutableArray alloc] init];
    
    self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    [self setupUI];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
}

#pragma mark - Private

- (UIView *)scanningView {
    
    CGFloat y;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    static UIView *view;
    
    if (view == nil) {
        
        view = [[UIView alloc] init];
        
        y = 0;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.frame = CGRectMake(20, y, 0, 0);
        [indicatorView sizeToFit];
        [indicatorView startAnimating];
        indicatorView.tag = SCANNING_VIEW_INDICATOR_TAG;
        [view addSubview:indicatorView];
        
        y += indicatorView.frame.size.height;
        y += 20;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, screenSize.width-40, 40)];
        titleLabel.font = [UIFont systemFontOfSize:24];
        titleLabel.text = @"Scanning";
        titleLabel.tag = SCANNING_VIEW_TITLE_TAG;
        [view addSubview:titleLabel];
        
        y += titleLabel.frame.size.height;
        y += 10;
        
        
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, screenSize.width-40, 50)];
        detailLabel.numberOfLines = 0;
        detailLabel.font = [UIFont systemFontOfSize:18];
        detailLabel.text = @"Make sure the curtain controller is powered on. Stay close to it and wait.";
        detailLabel.tag = SCANNING_VIEW_DETAIL_TAG;
        [view addSubview:detailLabel];
        
        y += detailLabel.frame.size.height;
        
        view.frame = CGRectMake(0, 0, screenSize.width, y);
        
    }
    
    return view;
    
}

- (UIView *)blinkView {
    
    CGFloat y;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    static UIView *view;
    
    if (view == nil) {
        
        view = [[UIView alloc] init];
        
        y = 0;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, screenSize.width-40, 40)];
        titleLabel.font = [UIFont systemFontOfSize:24];
        titleLabel.text = @"Is the green LED blinking?";
        titleLabel.tag = BLINK_VIEW_TITLE_TAG;
        [view addSubview:titleLabel];
        
        y += titleLabel.frame.size.height;
        y += 10;
        
        
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, screenSize.width-40, 50)];
        detailLabel.numberOfLines = 0;
        detailLabel.font = [UIFont systemFontOfSize:18];
        detailLabel.text = @"The LED is located to the right of the power button.";
        detailLabel.tag = BLINK_VIEW_DETAIL_TAG;
        [view addSubview:detailLabel];
        
        y += detailLabel.frame.size.height;
        
        view.frame = CGRectMake(0, 0, screenSize.width, y);
        
    }
    
    return view;
    
}

- (void)setupUI {
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    UIView *scanningView = [self scanningView];
    
    scanningView.frame = CGRectMake((screenSize.width-scanningView.frame.size.width)/2,
                                    (screenSize.height-scanningView.frame.size.height)/2,
                                    scanningView.frame.size.width,
                                    scanningView.frame.size.height);
    
    [self.view addSubview:scanningView];
    
}

- (void)moveFromView:(UIView *)fromView toView:(UIView *)toView scrollingSide:(NSInteger)side {
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    toView.frame = CGRectMake(screenSize.width, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height);
    [self.view addSubview:toView];
    
    [UIView animateWithDuration:1 animations:^{
        
        fromView.frame = CGRectMake(
                                    -screenSize.width,
                                    fromView.frame.origin.y,
                                    fromView.frame.size.width,
                                    fromView.frame.size.height
                                    );
        
        toView.frame = CGRectMake(
                                  0,
                                  toView.frame.origin.y,
                                  toView.frame.size.width,
                                  toView.frame.size.height
                                  );
        
    }];
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBManagerStatePoweredOn) {
        
        CBUUID *uuid = [CBUUID UUIDWithString:@"ff51b30e-d7e2-4d93-8842-a7c4a57dfb07"];
        [central scanForPeripheralsWithServices:@[uuid] options:nil];
        
    }else{
        
        [central stopScan];
        self.peripherals = nil;
        
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self centralManager:nil didDiscoverPeripheral:nil advertisementData:nil RSSI:nil];
            
        });
        
    });
    
}

- (void)centralManager:(CBCentralManager *)central
            didDiscoverPeripheral:(CBPeripheral *)peripheral
                advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                    RSSI:(NSNumber *)RSSI {
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    //[central connectPeripheral:peripheral options:nil];
    
    UIView *scanningView = [self scanningView];
    UIView *blinkView = [self blinkView];
    
    blinkView.frame = CGRectMake(
                                 (screenSize.width-blinkView.frame.size.width)/2,
                                 (screenSize.height-blinkView.frame.size.height)/2,
                                 blinkView.frame.size.width,
                                 blinkView.frame.size.height
                                 );
    
    [self moveFromView:scanningView toView:blinkView scrollingSide:0];
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"Connected to %@.", peripheral.name);
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services) {
        
        NSLog(@"Discovered service %@.", service);
        [peripheral discoverCharacteristics:nil forService:service];
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didDiscoverCharacteristicsForService:(nonnull CBService *)service
                error:(nullable NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"Discovered characteristic %@.", characteristic);
        
        NSData *data = [@"connect" dataUsingEncoding:NSUTF8StringEncoding];
        
        [peripheral readValueForCharacteristic:characteristic];
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
            didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                error:(NSError *)error {
    
    NSData *data = characteristic.value;
    NSString *json = [NSString stringWithUTF8String:data.bytes];
    
    NSLog(@"Value of characteristic %@", json);
    
}

@end
