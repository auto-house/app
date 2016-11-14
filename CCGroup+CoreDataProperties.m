//
//  CCGroup+CoreDataProperties.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/13/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCGroup+CoreDataProperties.h"

@implementation CCGroup (CoreDataProperties)

+ (NSFetchRequest<CCGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Group"];
}

@dynamic creationDate;
@dynamic name;
@dynamic device;

@end
