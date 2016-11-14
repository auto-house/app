//
//  CCDevice+CoreDataProperties.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/13/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDevice (CoreDataProperties)

+ (NSFetchRequest<CCDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) CCGroup *group;

@end

NS_ASSUME_NONNULL_END
