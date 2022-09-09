//
//  ComponentRating.h
//  Warehouse
//
//  Created by Douglas Almeida on 07/09/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ComponentRating <NSObject>

- (NSString *)name;
- (NSString *)unitSymbol;
- (NSString *)engineeringUnit;

@end

@interface ComponentRating : NSObject <ComponentRating>

@property (readonly) NSNumber *engineeringValue;
@property (readonly) NSInteger orderOfMagnitude;

+ (NSString *)prefixForMagnitude:(NSInteger)magnitude;
+ (NSArray *)ratingNames;
- (instancetype)initWithValue:(double)value;
- (double)value;

@end

#pragma mark - Subclasses

@interface VoltageRating : ComponentRating
@end

@interface CurrentRating : ComponentRating
@end

@interface PowerRating : ComponentRating
@end

@interface ResistanceRating : ComponentRating
@end

@interface InductanceRating : ComponentRating
@end

@interface CapacitanceRating : ComponentRating
@end

@interface FrequencyRating : ComponentRating
@end

@interface ToleranceRating : ComponentRating
@end

NS_ASSUME_NONNULL_END
