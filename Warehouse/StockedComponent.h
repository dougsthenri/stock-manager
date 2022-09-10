//
//  StockedComponent.h
//  Warehouse
//
//  Created by Douglas Almeida on 09/09/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComponentRating.h"

NS_ASSUME_NONNULL_BEGIN

@interface StockedComponent : NSObject

@property NSInteger componentID;
@property NSInteger stockedQuantity;
@property NSString *componentType;
@property NSString *partNumber;
@property NSString *manufacturer;
@property NSString *packageCode;
@property NSString *comments;
@property NSDictionary<NSString *, ComponentRating *> *ratings;

@end

NS_ASSUME_NONNULL_END
