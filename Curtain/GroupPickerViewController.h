//
//  GroupPickerViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/11/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CCGroup.h"


@protocol GroupPickerDelegate;

@interface GroupPickerViewController : UITableViewController

@property (nonatomic, retain) id<GroupPickerDelegate> delegate;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end


@protocol GroupPickerDelegate <NSObject>

- (void)pickedGroup:(CCGroup *)group;

@end
