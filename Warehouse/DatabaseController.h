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

@property (class, readonly, strong) DatabaseController *sharedController; //Singleton
@property (readonly) NSArray<NSString *> *dateColumns;

- (void)openDatabaseAtPath:(NSString *)path;
- (void)closeDatabase;
- (BOOL)isNullableColumn:(NSString *)column table:(NSString *)table;
- (NSArray *)componentTypes;
- (NSArray *)manufacturers;
- (NSArray *)packageCodes;

- (NSMutableArray<NSDictionary *> *)incrementalSearchResultsForPartNumber:(NSString *)partNumber;

- (NSMutableArray<NSDictionary *> *)searchResultsForComponentType:(NSString *)type;

- (NSMutableArray<NSDictionary *> *)stockReplenishmentsForPartNumber:(NSString *)partNumber
                                                        manufacturer:(NSString *)manufacturer;

- (NSMutableArray<NSDictionary *> *)stockWithdrawalsForPartNumber:(NSString *)partNumber
                                                     manufacturer:(NSString *)manufacturer;

- (BOOL)isRegisteredPartNumber:(NSString *)partNumber manufacturer:(NSString *)manufacturer;
- (void)stockReplenishmentWithParameters:(NSDictionary *)parameters;
- (void)stockWithdrawalWithParameters:(NSDictionary *)parameters;

+ (NSDate *)dateWithClearedTimeComponentsFromDate:(NSDate *)date;

@end

@protocol DatabaseObserver <NSObject>

//... Notificação de atualização do banco

@end

NS_ASSUME_NONNULL_END
