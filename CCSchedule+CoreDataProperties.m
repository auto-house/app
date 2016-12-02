//
//  CCSchedule+CoreDataProperties.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 12/2/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCSchedule+CoreDataProperties.h"

@implementation CCSchedule (CoreDataProperties)

+ (NSFetchRequest<CCSchedule *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Schedule"];
}

@dynamic action;
@dynamic creationDate;
@dynamic repeat;
@dynamic active;
@dynamic time;
@dynamic notify;
@dynamic device;

@end
