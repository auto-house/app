//
//  GroupsViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/13/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface GroupsViewController : UITableViewController <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UITextFieldDelegate>

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end
