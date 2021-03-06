//
//  CCDevice+CoreDataProperties.m
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCDevice+CoreDataProperties.h"

@implementation CCDevice (CoreDataProperties)

+ (NSFetchRequest<CCDevice *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Device"];
}

@dynamic authKey;
@dynamic creationDate;
@dynamic encryptionKey;
@dynamic imageUrl;
@dynamic name;
@dynamic peripheral;
@dynamic group;

@end
