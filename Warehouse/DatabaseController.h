//
//  DatabaseController.h
//  Warehouse
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DatabaseController : NSObject

@property (readonly) NSArray<NSString *> *dateColumns;

- (instancetype)initWithDatabasePath:(NSString *)path;
- (void)closeDatabase;
- (nullable NSDate *)decodeDate:(NSString *)date;
- (nullable NSString *)encodeDate:(NSDate *)date;
- (NSArray *)componentTypes;
- (NSArray *)manufacturers;
- (NSArray *)packageCodes;

- (BOOL)databaseKnowsPartNumber:(NSString *)partNumber
               fromManufacturer:(NSString *)manufacturer;

- (NSMutableArray<NSDictionary *> *)incrementalSearchResultsForPartNumber:(NSString *)partNumber
                                                             manufacturer:(nullable NSString *)manufacturer;

- (NSMutableArray<NSDictionary *> *)searchResultsForComponentType:(NSString *)type
                                                         criteria:(nullable NSDictionary *)criteria;

- (NSMutableArray<NSDictionary *> *)stockReplenishmentsForPartNumber:(NSString *)partNumber
                                                        manufacturer:(NSString *)manufacturer;

- (NSMutableArray<NSDictionary *> *)stockWithdrawalsForPartNumber:(NSString *)partNumber
                                                     manufacturer:(NSString *)manufacturer;

- (BOOL)isNullableColumn:(NSString *)column table:(NSString *)table;

@end

@protocol DatabaseObserver <NSObject>

//... DATABASE UPDATED NOTIFICATION

@end

NS_ASSUME_NONNULL_END
