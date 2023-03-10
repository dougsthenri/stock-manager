//
//  DatabaseController.h
//  Stock Manager
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DatabaseController : NSObject

@property (class, readonly, strong) DatabaseController *sharedController; //Singleton instance
@property (readonly) NSArray<NSString *> *dateColumns;

- (BOOL)openDatabaseAtPath:(NSString *)path;
- (void)closeDatabase;
- (BOOL)isNullableColumn:(NSString *)column table:(NSString *)table;
- (NSArray *)componentTypes;
- (NSArray *)manufacturers;
- (NSArray *)packageCodes;
- (NSNumber *)stockForComponentID:(NSNumber *)componentID;
- (NSMutableArray<NSMutableDictionary *> *)incrementalSearchResultsForPartNumber:(NSString *)partNumber;
- (NSMutableArray<NSMutableDictionary *> *)searchResultsForComponentType:(NSString *)type;
- (NSMutableArray<NSDictionary *> *)stockReplenishmentsForComponentID:(NSNumber *)component_id;
- (NSMutableArray<NSDictionary *> *)stockWithdrawalsForComponentID:(NSNumber *)component_id;
- (nullable NSMutableDictionary *)recordForPartNumber:(NSString *)partNumber
                                         manufacturer:(NSString *)manufacturer;
- (void)stockReplenishmentWithParameters:(NSDictionary *)parameters;
- (void)stockWithdrawalWithParameters:(NSDictionary *)parameters;
- (void)registerComponentWithParameters:(NSDictionary *)parameters;

+ (NSDate *)dateWithClearedTimeComponentsFromDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
