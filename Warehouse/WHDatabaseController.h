//
//  WHDatabaseController.h
//  Warehouse
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WHDatabaseController : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;
- (void)closeDatabase;
- (nonnull NSArray *)componentTypes;

- (nonnull NSArray<NSDictionary *> *)searchResultsForIncrementalPartNumber:(nonnull NSString *)partNumber
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
