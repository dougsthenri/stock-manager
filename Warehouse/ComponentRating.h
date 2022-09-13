//
//  ComponentRating.h
//  Warehouse
//
//  Created by Douglas Almeida on 07/09/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ComponentRating : NSObject

@property (readonly) NSNumber *significand;
@property (readonly) NSInteger orderOfMagnitude;
@property (readonly) NSString *name;
@property (readonly) NSString *unitSymbol;

+ (NSArray<NSString *> *)ratingNames;
+ (BOOL)magnitude:(NSInteger *)magnitude forPrefix:(NSString *)prefix;

- (instancetype)initWithValue:(double)value;
- (void)setValue:(double)value;
- (double)value;
- (NSString *)engineeringValue;
- (NSString *)prefixedUnitSymbol;
- (NSArray *)allPrefixedUnitSymbols;

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
