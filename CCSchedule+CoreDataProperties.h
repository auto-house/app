//
//  CCSchedule+CoreDataProperties.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 12/2/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCSchedule.h"


NS_ASSUME_NONNULL_BEGIN

@interface CCSchedule (CoreDataProperties)

+ (NSFetchRequest<CCSchedule *> *)fetchRequest;

@property (nonatomic) int16_t action;
@property (nullable, nonatomic, copy) NSDate *creationDate;
@property (nullable, nonatomic, copy) NSString *repeat;
@property (nullable, nonatomic, copy) NSNumber *active;
@property (nullable, nonatomic, copy) NSDate *time;
@property (nullable, nonatomic, copy) NSNumber *notify;
@property (nullable, nonatomic, retain) CCDevice *device;

@end

NS_ASSUME_NONNULL_END
