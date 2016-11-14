//
//  SettingsViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/13/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "SettingsViewController.h"
#import "GroupsViewController.h"


@interface SettingsViewController ()

@end


@implementation SettingsViewController

@synthesize managedObjectContext = _managedObjectContext;

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    // Create navigation bar button items.
    
    UIBarButtonItem *doneBBI;
    
    doneBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView)];
    
    self.navigationItem.rightBarButtonItem = doneBBI;
    
}

#pragma mark - Private

- (void)dismissView {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
    }
    
    if (indexPath.row == 0) {
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = @"Groups";
        
    }
    
    return cell;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        
        GroupsViewController *view = [[GroupsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        view.managedObjectContext = self.managedObjectContext;
        [self.navigationController pushViewController:view animated:YES];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
