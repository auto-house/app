//
//  GroupsViewController.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/13/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import "GroupsViewController.h"
#import "CCGroup.h"

#define ALERT_CONTROLLER_CREATE_GROUP_TEXT_FIELD_TAG 10001


@interface GroupsViewController ()

@property (nonatomic, retain) NSMutableArray *groups;

@property (nonatomic, retain) UIAlertController *alertController;
@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate> alertControllerTransitioningDelegate;

@end


@implementation GroupsViewController

@synthesize managedObjectContext = _managedObjectContext;

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Groups";
    
    // Fetch groups.
    
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Group"];
    self.groups = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
    
    // Create navigation bar button items.
    
    UIBarButtonItem *addBBI;
    
    addBBI = [[UIBarButtonItem alloc]
              initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
              target:self
              action:@selector(createGroup)];
    
    self.navigationItem.rightBarButtonItem = addBBI;
    
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

- (void)createGroup {
    
    UIAlertController *alert;
    UIAlertAction *confirmAction, *dismissAction;
    
    NSString *title = NSLocalizedString(@"Create Group", nil);
    NSString *message = NSLocalizedString(@"Type the group's name.", nil);
    NSString *confirmActionTitle = NSLocalizedString(@"Create", nil);
    NSString *dismissActionTitle = NSLocalizedString(@"Cancel", nil);
    
    alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Confirm action.
    confirmAction = [UIAlertAction actionWithTitle:confirmActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        NSError *error;
        NSInteger index;
        NSString *title, *message;
        NSString *name = [[[alert textFields] firstObject] text];
        
        if (name.length > 0 ) {
            
            CCGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:self.managedObjectContext];
            group.name = name;
            group.creationDate = [NSDate date];
            
            if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
                
                title = NSLocalizedString(@"Error", nil);
                message = NSLocalizedString(@"Please, try again.", nil);
                
                // Somehting went wrong while creating the category. Report.
                [self.managedObjectContext rollback];
                [self alertViewWithTitle:title forMessage:message];
                
            }else{
                
                // Find the index of the created category, sorted alphabetically, in the categories source array.
                index = [self.groups indexOfObject:group
                                     inSortedRange:NSMakeRange(0, self.groups.count)
                                           options:NSBinarySearchingInsertionIndex
                                   usingComparator:^NSComparisonResult(CCGroup *a, CCGroup *b){
                                           return [a.name compare:b.name];
                                       }];
                [self.groups insertObject:group atIndex:index];
                
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                
            }
        }
        
    }];
    confirmAction.enabled = NO;
    [alert addAction:confirmAction];
    
    // Dismiss action.
    dismissAction = [UIAlertAction actionWithTitle:dismissActionTitle style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:dismissAction];
    
    // Add a text field where the new category's name will be entered.
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.tag = ALERT_CONTROLLER_CREATE_GROUP_TEXT_FIELD_TAG;
        textField.delegate = self;
        textField.keyboardAppearance = UIKeyboardAppearanceAlert;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.placeholder = NSLocalizedString(@"Name", nil);
    }];
    
    // Set the alert transitioning delegate. A custom transition helps dismiss the keyboard faster.
    self.alertControllerTransitioningDelegate = alert.transitioningDelegate;
    alert.transitioningDelegate = self;
    
    // Keep a reference to the alert controller, used to enable/disable alert controller actions.
    self.alertController = nil;
    self.alertController = alert;
    
    // Present alert controller.
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    // Disable the alert action validate button when the input text is empty.
    // For the create group controller.
    
    if (textField.tag == ALERT_CONTROLLER_CREATE_GROUP_TEXT_FIELD_TAG) {
        if (self.alertController) {
            UIAlertAction *renameAction = [self.alertController.actions firstObject];
            renameAction.enabled = ([[textField.text stringByReplacingCharactersInRange:range withString:string] length] > 0);
        }
    }
    
    return YES;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([destination isBeingPresented]) {
        [self animatePresentation:transitionContext];
    }else{
        [self animateDismissal:transitionContext];
    }
    
}

- (void)animatePresentation:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    // Custom animation for when displaying an alert controller.
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = transitionContext.containerView;
    
    fromController.view.frame = container.bounds;
    toController.view.frame = container.bounds;
    toController.view.alpha = 0.0f;
    [container addSubview:toController.view];
    [fromController beginAppearanceTransition:NO animated:YES];
    
    [UIView animateWithDuration:0.4 animations:^{
        toController.view.alpha = 1.0;
    } completion:^(BOOL finished){
        [fromController endAppearanceTransition];
        [transitionContext completeTransition:YES];
    }];
    
}

- (void)animateDismissal:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    // Custom animation for when dismissing an alert controller, hides the keyboard faster.
    UIViewController *alertController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [toController beginAppearanceTransition:YES animated:YES];
    
    // Immediately hide the alert controller view.
    alertController.view.alpha = 0.0;
    
    // Animate the dismissal of the alert controller dimmed superview.
    [UIView animateWithDuration:0.4 animations:^{
        alertController.view.superview.alpha = 0;
        [alertController.view endEditing:YES];
    } completion:^(BOOL finished){
        [toController endAppearanceTransition];
        [transitionContext completeTransition:YES];
    }];
    
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
    cell.textLabel.text = group.name;
    
    return cell;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
