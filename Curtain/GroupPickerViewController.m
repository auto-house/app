//
//  GroupPickerViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "GroupPickerViewController.h"
#import "CCGroup.h"


@interface GroupPickerViewController ()

@property (nonatomic, retain) NSMutableArray *groups;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;

@end


@implementation GroupPickerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Groups";
    
    // Fetch Groups.
    
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Group"];
    self.groups = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
    }
    
    CCGroup *group = [self.groups objectAtIndex:indexPath.row];
    
    cell.accessoryType = (self.selectedIndexPath == indexPath ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
    cell.textLabel.text = group.name;
    
    return cell;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath != self.selectedIndexPath) {
        
        CCGroup *group = [self.groups objectAtIndex:indexPath.row];
        
        NSArray *rows = (self.selectedIndexPath == nil ? @[indexPath] : @[self.selectedIndexPath, indexPath]);
        self.selectedIndexPath = indexPath;
        [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if ([self.delegate respondsToSelector:@selector(pickedGroup:)]) {
            [self.delegate pickedGroup:group];
        }
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
