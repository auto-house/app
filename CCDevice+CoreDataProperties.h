//
//  CCDevice+CoreDataProperties.h
//  Curtain
//
//  Created by Mateus Nunes de B Magalhaes on 11/22/16.
//  Copyright © 2016 Mateus Nunes. All rights reserved.
//

#import "CCDevice.h"


NS_ASSUME_NONNULL_BEGIN

@interface CCDevice (CoreDataProperties)

+ (NSFetchRequest<CCDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *creationDate;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *imageUrl;
@property (nullable, nonatomic, copy) NSString *authKey;
@property (nullable, nonatomic, copy) NSString *encryptionKey;
@property (nullable, nonatomic, retain) CCGroup *group;

@end

NS_ASSUME_NONNULL_END
