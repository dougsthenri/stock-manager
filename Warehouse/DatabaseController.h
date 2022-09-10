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

@property (class, readonly, strong) DatabaseController *sharedController; //Instância singleton
@property (readonly) NSArray<NSString *> *dateColumns;

- (void)openDatabaseAtPath:(NSString *)path;
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
- (nullable NSDictionary *)recordForPartNumber:(NSString *)partNumber
                                  manufacturer:(nullable NSString *)manufacturer;
- (void)stockReplenishmentWithParameters:(NSDictionary *)parameters;
- (void)stockWithdrawalWithParameters:(NSDictionary *)parameters;

+ (NSDate *)dateWithClearedTimeComponentsFromDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
