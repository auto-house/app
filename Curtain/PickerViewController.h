//
//  PickerViewController.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/30/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//


#import <UIKit/UIKit.h>


@protocol PickerDelegate;


@interface PickerViewController : UITableViewController

@property (nonatomic, retain) id<PickerDelegate> delegate;

@property (nonatomic, retain) NSString *key;
@property (nonatomic) BOOL allowsMultipleSelections;
@property (nonatomic, retain) NSString *navigationBarTitle;
@property (nonatomic, retain) NSArray *data;

@end


@protocol PickerDelegate <NSObject>

- (void)valuesPicked:(NSArray *)values forKey:(NSString *)key;

@end
