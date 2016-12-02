//
//  PickerViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/30/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "PickerViewController.h"


@interface PickerViewController ()

@property (nonatomic, retain) NSMutableArray *selection;

@end


@implementation PickerViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.navigationBarTitle;
    
    self.selection = [[NSMutableArray alloc] init];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    for (NSIndexPath *indexPath in self.selection) {
        NSDictionary *item = [self.data objectAtIndex:indexPath.row];
        NSNumber *value = [item objectForKey:@"value"];
        [values addObject:value];
    }
    
    if ([self.delegate respondsToSelector:@selector(valuesPicked:forKey:)]) {
        [self.delegate valuesPicked:values forKey:self.key];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const cellIdentifierDefault = @"cell-identifier-default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierDefault];
    }
    
    NSDictionary *item = [self.data objectAtIndex:indexPath.row];
    NSString *title = [item objectForKey:@"title"];
    
    cell.textLabel.text = title;
    cell.accessoryType = ([self.selection containsObject:indexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.selection containsObject:indexPath]) {
        
        // Remove selection.
        
        [self.selection removeObject:indexPath];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }else{
        
        // Add selection.
        
        if (self.allowsMultipleSelections == NO && self.selection.count > 0) {
            
            NSIndexPath *previousSelection = [self.selection firstObject];
            [self.selection removeAllObjects];
            [tableView reloadRowsAtIndexPaths:@[previousSelection] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
        
        [self.selection addObject:indexPath];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
