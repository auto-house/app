//
//  CCGroup+CoreDataProperties.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/13/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCGroup (CoreDataProperties)

+ (NSFetchRequest<CCGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *creationDate;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSSet<CCDevice *> *device;

@end

@interface CCGroup (CoreDataGeneratedAccessors)

- (void)addDeviceObject:(CCDevice *)value;
- (void)removeDeviceObject:(CCDevice *)value;
- (void)addDevice:(NSSet<CCDevice *> *)values;
- (void)removeDevice:(NSSet<CCDevice *> *)values;

@end

NS_ASSUME_NONNULL_END
