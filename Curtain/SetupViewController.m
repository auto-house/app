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

@property (nonatomic, retain) NSString *authKey;
@property (nonatomic, retain) NSString *encryptionKey;
@property (nonatomic, retain) CBPeripheral *peripheral;

@property (nonatomic, retain) CCGroup *group;
@property (nonatomic, retain) NSString *nickname;
@property (nonatomic, retain) UIImage *image;

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

- (void)presentImagePickerWithSource:(UIImagePickerControllerSourceType)source {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (void)presentImageSourcePickerActionSheet {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Image Source" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    [alert addAction:libraryAction];
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentImagePickerWithSource:UIImagePickerControllerSourceTypeCamera];
    }];
    [alert addAction:cameraAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)registerDevice {
    
    NSError *error;
    
    NSDate *creationDate = [NSDate date];
    NSNumber *interval = [NSNumber numberWithDouble:[creationDate timeIntervalSince1970]];
    NSString *name = [interval.stringValue stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *imageName = [NSString stringWithFormat:@"%@.png", name];
    NSString *imageUrl = imageName;
    
    // Save image to the disk.
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:imageUrl];
    
    NSData *imageData = UIImagePNGRepresentation(self.image);
    [imageData writeToFile:filePath atomically:YES];
    
    // Create the database entity.
    
    CCDevice *device = [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext:self.managedObjectContext];
    
    device.creationDate = creationDate;
    
    device.authKey = self.authKey;
    device.encryptionKey = self.encryptionKey;
    
    device.group = self.group;
    device.name = self.nickname;
    device.imageUrl = imageUrl;
    
    // Persist the data.
    
    if ([self.managedObjectContext save:&error]) {
        
        if ([self.delegate respondsToSelector:@selector(linkedDevice:)]) {
            [self.delegate linkedDevice:device];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }else{
        
        NSLog(@"Failed to save the device with error: %@.", error);
        
    }
    
}

#pragma mark - Device picker delegate

- (void)pickedDevice:(NSDictionary *)info {
    
    NSString *authKey = [info objectForKey:@"authKey"];
    NSString *encryptionKey = [info objectForKey:@"encryptionKey"];
    CBPeripheral *peripheral = [info objectForKey:@"peripheral"];
    
    self.authKey = authKey;
    self.encryptionKey = encryptionKey;
    self.peripheral = peripheral;
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

#pragma mark - Group picker delegate

- (void)pickedGroup:(CCGroup *)group {
    
    self.group = group;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField endEditing:YES];
    
    self.nickname = textField.text;
    
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    self.nickname = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    return YES;
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    UIImageView *imageView = (UIImageView *)cell.accessoryView;
    imageView.image = self.image;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0 ? 4 : 1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0 && indexPath.row == 3 ? 100 : 44);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    static NSString * const cellIdentifierDoubleAccessories = @"cell-identifier-double-accessories";
    static NSString * const cellIdentifierTextInput = @"cell-identifier-text-input";
    static NSString * const cellIdentifierImageView  = @"cell-identifier-image-view";
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat leftPadding = tableView.separatorInset.left;
    
    UITableViewCell *cell;
    UILabel *accessoryLabel;
    UITextField *textField;
    UIImageView *imageView;
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0 || indexPath.row == 1) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDoubleAccessories];
            
            if (cell == nil) {
                
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDoubleAccessories];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding+100, 0, screenSize.width-leftPadding-leftPadding-100-10-8, 44)];
                accessoryLabel.textAlignment = NSTextAlignmentRight;
                accessoryLabel.textColor = [UIColor colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1];
                accessoryLabel.tag = CELL_DOUBLE_ACCESSORIES_TEXT_LABEL;
                [cell.contentView addSubview:accessoryLabel];
                
            }else{
                
                accessoryLabel = [cell viewWithTag:CELL_DOUBLE_ACCESSORIES_TEXT_LABEL];
                
            }
            
            if (indexPath.row == 0) {
                
                cell.textLabel.text = @"Device";
                accessoryLabel.text = (self.peripheral == nil ? @"" : self.peripheral.name);
                
            }else{
                
                cell.textLabel.text = @"Group";
                accessoryLabel.text = (self.group == nil ? @"" : self.group.name);
                
            }
            
        }else if (indexPath.row == 2) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierTextInput];
            
            if (cell == nil) {
                
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierTextInput];
                
                textField = [[UITextField alloc] initWithFrame:CGRectMake(leftPadding+100, 0, screenSize.width-leftPadding-leftPadding-100, 44)];
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.returnKeyType = UIReturnKeyDone;
                textField.textAlignment = NSTextAlignmentRight;
                textField.textColor = [UIColor colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1];
                textField.placeholder = @"Ex: Master Bedroom Curatain";
                textField.delegate = self;
                textField.tag = CELL_TEXT_INPUT_TEXT_FIELD;
                [cell.contentView addSubview:textField];
                
            }else{
                
                textField = [cell viewWithTag:CELL_TEXT_INPUT_TEXT_FIELD];
                
            }
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"Nickname";
            
        }else{
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierImageView];
            
            if (cell == nil) {
                
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierImageView];
                
                imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
                imageView.backgroundColor = [UIColor orangeColor];
                cell.accessoryView = imageView;
                
            }
            
            cell.textLabel.text = @"Image";
            imageView.image = self.image;
            
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
            
        }else if (indexPath.row == 3) {
            
            [self presentImageSourcePickerActionSheet];
            
        }
        
    }else{
        
        [self registerDevice];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
