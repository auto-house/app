//
//  ScheduleViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/30/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "PickerViewController.h"
#import "CCDevice.h"
#import "CCSchedule.h"


typedef NS_ENUM(NSInteger, SchedulableAction) {
    SchedulableActionOpen,
    SchedulableActionClose,
    SchedulableActionBlink
};

typedef NS_ENUM(NSInteger, Weekday) {
    WeekdaySunday,
    WeekdayMonday,
    WeekdayTuesday,
    WeekdayWednesday,
    WeekdayThursday,
    WeekdayFriday,
    WeekdaySaturday
};


@protocol ScheduleViewControllerDelegate;


@interface ScheduleViewController : UITableViewController <PickerDelegate>

@property (nonatomic, retain) id<ScheduleViewControllerDelegate> delegate;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CCDevice *device;

@end


@protocol ScheduleViewControllerDelegate <NSObject>

- (void)scheduledActionCreated:(CCSchedule *)schedule;

@end
