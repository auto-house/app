//
//  SetupViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "CCDevice.h"
#import "SetupViewController.h"
#import "DevicePickerViewController.h"
#import "GroupPickerViewController.h"

#define CELL_DOUBLE_ACCESSORIES_TEXT_LABEL      10002
#define CELL_DOUBLE_ACCESSORIES_ACCESSORY_LABEL 10002

#define CELL_TEXT_INPUT_TEXT_LABEL 20001
#define CELL_TEXT_INPUT_TEXT_FIELD 20002


@interface SetupViewController ()

@property (nonatomic, retain) CBPeripheral *peripheral;
@property (nonatomic, retain) CCGroup *group;
@property (nonatomic, retain) NSString *nickname;

@end


@implementation SetupViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Register Device";
    
    // Create navigation bar button items.
    
    UIBarButtonItem *cancelBBI;
    
    cancelBBI = [[UIBarButtonItem alloc]
                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                 target:self
                 action:@selector(cancelRegistration)];
    
    self.navigationItem.leftBarButtonItem = cancelBBI;
    
}

#pragma mark - Private

- (void)cancelRegistration {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Device picker delegate

- (void)pickedDevice:(CBPeripheral *)peripheral {
    
    self.peripheral = peripheral;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

#pragma mark - Group picker delegate

- (void)pickedGroup:(CCGroup *)group {
    
    self.group = group;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0 ? 3 : 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    static NSString * const cellIdentifierDoubleAccessories = @"cell-identifier-double-accessories";
    static NSString * const cellIdentifierTextInput = @"cell-identifier-text-input";
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat leftPadding = tableView.separatorInset.left;
    
    UITableViewCell *cell;
    UILabel *accessoryLabel;
    UITextField *textField;
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0 || indexPath.row == 1) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDoubleAccessories];
            
            if (cell == nil) {
                
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDoubleAccessories];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding+100, 0, screenSize.width-leftPadding-leftPadding-100-10-8, 44)];
                accessoryLabel.textAlignment = NSTextAlignmentRight;
                accessoryLabel.textColor = [UIColor colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1];
                accessoryLabel.text = @"Google";
                [cell.contentView addSubview:accessoryLabel];
                
                //accessoryLabel.backgroundColor = [UIColor orangeColor];
                
            }
            
            if (indexPath.row == 0) {
                
                cell.textLabel.text = @"Device";
                accessoryLabel.text = (self.peripheral == nil ? @"" : self.peripheral.name);
                
            }else{
                
                cell.textLabel.text = @"Group";
                accessoryLabel.text = (self.group == nil ? @"" : self.group.name);
                
            }
            
        }else{
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierTextInput];
            
            if (cell == nil) {
                
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierTextInput];
                
                textField = [[UITextField alloc] initWithFrame:CGRectMake(leftPadding+100, 0, screenSize.width-leftPadding-leftPadding-100, 44)];
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.returnKeyType = UIReturnKeyNext;
                textField.textAlignment = NSTextAlignmentRight;
                textField.textColor = [UIColor colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1];
                textField.placeholder = @"Ex: Master Bedroom Curatain";
                textField.delegate = self;
                textField.tag = CELL_TEXT_INPUT_TEXT_FIELD;
                [cell.contentView addSubview:textField];
                
                //textField.backgroundColor = [UIColor orangeColor];
                
            }
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"Nickname";
            
        }
        
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = self.view.tintColor;
        cell.textLabel.text = @"Register";
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            
            DevicePickerViewController *view = [[DevicePickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
            view.delegate = self;
            view.centralManager = self.centralManager;
            [self.navigationController pushViewController:view animated:YES];
            
        }else if (indexPath.row == 1) {
            
            GroupPickerViewController *view = [[GroupPickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
            view.delegate = self;
            view.managedObjectContext = self.managedObjectContext;
            [self.navigationController pushViewController:view animated:YES];
            
        }
        
    }else{
        
        CCDevice *device = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:self.managedObjectContext];
        device.name = self.nickname;
        
        // creation date
        // picture
        // connection key
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
