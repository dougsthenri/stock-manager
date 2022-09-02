//
//  WHDatabaseController.h
//  Warehouse
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WH_NULLABLE_COLUMNS_STOCK @[ \
    @"voltage_rating",               \
    @"current_rating",               \
    @"power_rating",                 \
    @"resistance_rating",            \
    @"inductance_rating",            \
    @"capacitance_rating",           \
    @"frequency_rating",             \
    @"tolerance_rating",             \
    @"package_code",                 \
    @"comments"                      \
]

#define WH_DATE_COLUMNS @[ \
    @"date_spent",         \
    @"date_acquired",      \
]

NS_ASSUME_NONNULL_BEGIN

@interface WHDatabaseController : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;
- (void)closeDatabase;
- (nullable NSDate *)decodeDate:(NSString *)date;
- (nullable NSString *)encodeDate:(NSDate *)date;
- (NSArray *)componentTypes;
- (NSArray *)manufacturers;
- (NSArray *)packageCodes;

- (BOOL)databaseKnowsPartNumber:(NSString *)partNumber
             fromManufacturer:(NSString *)manufacturer;

- (nonnull NSArray<NSDictionary *> *)incrementalSearchResultsForPartNumber:(nonnull NSString *)partNumber
                                                              manufacturer:(nullable NSString *)manufacturer;

- (nonnull NSArray<NSDictionary *> *)searchResultsForComponentType:(nonnull NSString *)type
                                                          criteria:(nullable NSDictionary *)criteria;

- (NSArray<NSDictionary *> *)stockReplenishmentsForPartNumber:(NSString *)partNumber
                                                 manufacturer:(NSString *)manufacturer;

- (NSArray<NSDictionary *> *)stockWithdrawalsForPartNumber:(NSString *)partNumber
                                              manufacturer:(NSString *)manufacturer;

@end

@protocol WHDatabaseObserver <NSObject>

//... DATABASE UPDATED NOTIFICATION

@end

NS_ASSUME_NONNULL_END
