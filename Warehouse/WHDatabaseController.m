//
//  WHDatabaseController.m
//  Warehouse
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHDatabaseController.h"
#import "FMDB.h"

@interface WHDatabaseController ()

@property FMDatabase *database;

@end

@implementation WHDatabaseController

- (instancetype)initWithDatabasePath:(NSString *)path {
    self = [super init];
    if (self) {
        _database = [FMDatabase databaseWithPath:path];
        if (![_database open]) {
            return nil;
        }
    }
    return self;
}


- (void)closeDatabase {
    [_database close];
}


- (NSArray *)componentTypes {
    NSMutableArray<NSString *> *componentTypes = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT component_type FROM stock GROUP BY component_type"];
    while ([resultSet next]) {
        NSString *type = [resultSet stringForColumnIndex:0];
        [componentTypes addObject:type];
    }
    [resultSet close];
    return componentTypes;
}


- (NSArray<NSDictionary *> *)searchResultsForIncrementalPartNumber:(NSString *)partNumber
                                                      manufacturer:(NSString *)manufacturer {
    NSMutableArray<NSDictionary *> *searchResults = [[NSMutableArray alloc] init];
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT * FROM stock WHERE part_number LIKE '%@%%'", partNumber];
    if (manufacturer) {
        [query appendFormat:@" AND manufacturer = '%@'", manufacturer];
    }
    FMResultSet *resultSet = [_database executeQuery:query];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [searchResults addObject:result];
    }
    [resultSet close];
    return searchResults;
}


- (NSArray<NSDictionary *> *)searchResultsForComponentType:(NSString *)type
                                                  criteria:(NSDictionary *)criteria {
    NSMutableArray<NSDictionary *> *searchResults = [[NSMutableArray alloc] init];
    NSMutableString *query = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM stock WHERE component_type = '%@'", type];
    if (criteria) {
        for (NSString *columnName in criteria) {
            [query appendFormat:@" AND %@ %@", columnName, criteria[columnName]]; //... Critério deve incluir operador relacional! e.g.: "voltage_rating <= 90"
        }
    }
    FMResultSet *resultSet = [_database executeQuery:query];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [searchResults addObject:result];
    }
    [resultSet close];
    return searchResults;
}


- (NSArray<NSDictionary *> *)stockReplenishmentsForPartNumber:(NSString *)partNumber
                                                 manufacturer:(NSString *)manufacturer {
    NSMutableArray<NSDictionary *> *queryResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQueryWithFormat:@"SELECT quantity, date, origin FROM acquisitions WHERE part_number = %@ AND manufacturer = %@", partNumber, manufacturer];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}


- (NSArray<NSDictionary *> *)stockWithdrawalsForPartNumber:(NSString *)partNumber
                                              manufacturer:(NSString *)manufacturer {
    NSMutableArray<NSDictionary *> *queryResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQueryWithFormat:@"SELECT quantity, date, destination FROM expenditures WHERE part_number = %@ AND manufacturer = %@", partNumber, manufacturer];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}

@end
