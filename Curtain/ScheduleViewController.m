//
//  ScheduleViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/30/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "ScheduleViewController.h"
#import "PickerViewController.h"
#import "CCSchedule.h"

#define CELL_DOUBLE_ACCESSORIES_TEXT_LABEL      10001
#define CELL_DOUBLE_ACCESSORIES_ACCESSORY_LABEL 10002


@interface ScheduleViewController ()

@property (nonatomic) BOOL editingTime;

@property (nonatomic, retain) NSDate *time;
@property (nonatomic) NSInteger action;
@property (nonatomic, retain) NSString *repeat;
@property (nonatomic) BOOL notify;

@end


@implementation ScheduleViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"New Scheduled Action";
    
    self.editingTime = YES;
    
    self.time = [NSDate date];
    self.action = 0;
    self.repeat = 0;
    self.notify = NO;
    
    // Navigation bar button items.
    
    UIBarButtonItem *cancelItem, *saveItem;
    
    cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissController)];
    saveItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveSchedule)];
    
    self.navigationItem.leftBarButtonItem = cancelItem;
    self.navigationItem.rightBarButtonItem = saveItem;
    
}

#pragma mark - NSObjects

- (NSDateFormatter *)timeDateFormatter {
    
    static NSDateFormatter *formatter;
    
    if (formatter == nil) {
        
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeStyle = NSDateFormatterShortStyle;
        
    }
    
    return formatter;
}

- (NSString *)prettyStringForAction:(NSInteger)action {
    
    NSString *string;
    
    switch (action) {
        case SchedulableActionOpen:
            string = @"Open";
            break;
        case SchedulableActionClose:
            string = @"Close";
            break;
        case SchedulableActionBlink:
            string = @"Blink";
            break;
    }
    
    return string;
}

- (NSString *)prettyStringForRepeat:(NSString *)repeat {
    
    NSString *string = @"";
    NSArray *days = [repeat componentsSeparatedByString:@","];
    
    if (days.count == 7) {
        
        string = @"Everyday";
        
    }else{
        
        for (NSString *day in days) {
            
            NSString *append = @"";
            NSInteger d = [day integerValue];
            
            switch (d) {
                case WeekdaySunday:
                    append = @"Sun ";
                    break;
                case WeekdayMonday:
                    append = @"Mon ";
                    break;
                case WeekdayTuesday:
                    append = @"Tue ";
                    break;
                case WeekdayWednesday:
                    append = @"Wed ";
                    break;
                case WeekdayThursday:
                    append = @"Thr ";
                    break;
                case WeekdayFriday:
                    append = @"Fri ";
                    break;
                case WeekdaySaturday:
                    append = @"Sat ";
                    break;
                    
            }
            
            string = [string stringByAppendingString:append];
            
        }
        
    }
    
    return string;
}

- (NSArray *)actionsData {
    
    NSArray *data = @[
                      @{
                          @"title": @"Open",
                          @"value": @(SchedulableActionOpen)
                          },
                      @{
                          @"title": @"Close",
                          @"value": @(SchedulableActionClose)
                          },
                      @{
                          @"title": @"Blink",
                          @"value": @(SchedulableActionBlink)
                          }
                      ];
    
    return data;
}

- (NSArray *)repeatsData {
    
    NSArray *data = @[
                      @{
                          @"title": @"Every Sunday",
                          @"value": @(WeekdaySunday)
                          },
                      @{
                          @"title": @"Every Monday",
                          @"value": @(WeekdayMonday)
                          },
                      @{
                          @"title": @"Every Tuesday",
                          @"value": @(WeekdayTuesday)
                          },
                      @{
                          @"title": @"Every Wednesday",
                          @"value": @(WeekdayWednesday)
                          },
                      @{
                          @"title": @"Every Thursday",
                          @"value": @(WeekdayThursday)
                          },
                      @{
                          @"title": @"Every Friday",
                          @"value": @(WeekdayFriday)
                          },
                      @{
                          @"title": @"Every Saturday",
                          @"value": @(WeekdaySaturday)
                          }
                      ];
    
    return data;
}

#pragma mark - Private

- (void)alertViewWithTitle:(NSString *)title forMessage:(NSString *)message {
    
    UIAlertController *alertController;
    UIAlertAction *dismissalAction;
    
    alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    dismissalAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:dismissalAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)dismissController {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)saveSchedule {
    
    NSError *error;
    
    CCSchedule *schedule = [NSEntityDescription insertNewObjectForEntityForName:@"Schedule" inManagedObjectContext:self.managedObjectContext];
    
    schedule.device = self.device;
    schedule.creationDate = [NSDate date];
    schedule.action = @(self.action);
    schedule.repeat = self.repeat;
    schedule.active = @YES;
    schedule.notify = @(self.notify);
    schedule.isSynchronized = @NO;
    schedule.time = self.time;
    
    if ([self.managedObjectContext save:&error]) {
        
        if ([self.delegate respondsToSelector:@selector(scheduledActionCreated:)]) {
            [self.delegate scheduledActionCreated:schedule];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }else{
        
        [self alertViewWithTitle:@"Error" forMessage:@"Failed to persist the schedule."];
        
    }
    
}

- (void)datePickerValueChanged:(id)sender {
    
    UIDatePicker *picker = sender;
    
    self.time = picker.date;
    
    NSDateFormatter *formatter = [self timeDateFormatter];
    UITableViewCell *timeCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UILabel *timeLabel = (UILabel *) timeCell.accessoryView;
    timeLabel.text = [formatter stringFromDate:self.time];
    
}

- (void)switchValueChanged:(id)sender {
    
    UISwitch *theSwitch = sender;
    
    self.notify = theSwitch.on;
    
}

#pragma mark - Picker delegate

- (void)valuesPicked:(NSArray *)values forKey:(NSString *)key {
    
    NSLog(@"Values picked %@", values);
    
    // sort
    // store the components separed by a comma
    // to string, and bam, store it
    // its easier
    
    NSInteger indexOffset = (self.editingTime ? 1 : 0);
    
    if ([key isEqualToString:@"action"]) {
        
        self.action = [[values firstObject] integerValue];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(1 + indexOffset) inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }else if ([key isEqualToString:@"repeat"]) {
        
        self.repeat = [values componentsJoinedByString:@","];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(2 + indexOffset) inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.editingTime ? 5 : 4);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row == 1 && self.editingTime ? 150 : 44);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierAccessoryLabel = @"cell-identifier-accessory-label";
    static NSString * const cellIdentifierAccessorySwitch = @"cell-identifier-acessory-switch";
    static NSString * const cellIdentifierDoubleAccessories = @"cell-identifier-double-accessories";
    static NSString * const cellIdentifierDatePicker = @"cell-identifier-date-picker";
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat leftPadding = tableView.separatorInset.left;
    
    NSInteger indexOffset = (self.editingTime ? 1 : 0);
    
    NSDateFormatter *formatter = [self timeDateFormatter];
    
    UITableViewCell *cell;
    UILabel *accessoryLabel;
    UISwitch *accessorySwitch;
    UIDatePicker *datePicker;
    
    if (indexPath.row == 0) {
        
        // Cells with a text label as accessory view.
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierAccessoryLabel];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierAccessoryLabel];
            
            accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenSize.width-leftPadding-leftPadding-100-10-8, 44)];
            accessoryLabel.textAlignment = NSTextAlignmentRight;
            accessoryLabel.textColor = [UIColor colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1];
            
            cell.accessoryView = accessoryLabel;
            
        }else{
            
            accessoryLabel = (UILabel *) cell.accessoryView;
            
        }
        
        // Time row.
        
        cell.textLabel.text = @"Time";
        accessoryLabel.textColor = self.view.tintColor;
        accessoryLabel.text = [formatter stringFromDate:self.time];
        
    }else if (indexPath.row == 1 && self.editingTime) {
        
        // Cell containing a date picker.
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDatePicker];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDatePicker];
            cell.layer.masksToBounds = YES;
            
            datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(leftPadding, 0, screenSize.width-leftPadding, 150)];
            datePicker.datePickerMode = UIDatePickerModeTime;
            [datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            [cell.contentView addSubview:datePicker];
            
        }
        
    }else if (indexPath.row == (1 + indexOffset) || indexPath.row == (2 + indexOffset)) {
        
        // Cells with a text label and disclosure indicator as accessory views.
        
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
        
        if (indexPath.row == (1 + indexOffset)) {
            
            // Action row.
            
            cell.textLabel.text = @"Action";
            accessoryLabel.text = [self prettyStringForAction:self.action];
            
        }else{
            
            // Repeat row.
            
            cell.textLabel.text = @"Repeat";
            accessoryLabel.text = [self prettyStringForRepeat:self.repeat];
            
        }
        
    }else if (indexPath.row == (3 + indexOffset)){
        
        // Cells with a switch as accessory view.
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierAccessorySwitch];
        
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierAccessorySwitch];
            
            accessorySwitch = [[UISwitch alloc] init];
            [accessorySwitch sizeToFit];
            [accessorySwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = accessorySwitch;
            
        }else{
            
            accessorySwitch = (UISwitch *) cell.accessoryView;
            
        }
        
        cell.textLabel.text = @"Notify";
        accessorySwitch.on = self.notify;
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger indexOffset = (self.editingTime ? 1 : 0);
    
    if (indexPath.row == 0) {
        
        if (self.editingTime) {
            
            self.editingTime = NO;
            
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
            [tableView endUpdates];
            
        }else{
            
            self.editingTime = YES;
            
            [tableView beginUpdates];
            [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView endUpdates];
            
        }
        
    }else if (indexPath.row == (1 + indexOffset)) {
        
        // Pick an action.
        
        PickerViewController *view = [[PickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
        view.delegate = self;
        view.key = @"action";
        view.allowsMultipleSelections = NO;
        view.navigationBarTitle = @"Action";
        view.data = [self actionsData];
        
        [self.navigationController pushViewController:view animated:YES];
        
    }else if (indexPath.row == (2 + indexOffset)) {
        
        // Pick repeat days.
        
        PickerViewController *view = [[PickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
        view.delegate = self;
        view.key = @"repeat";
        view.allowsMultipleSelections = YES;
        view.navigationBarTitle = @"Repeat";
        view.data = [self repeatsData];
        
        [self.navigationController pushViewController:view animated:YES];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
