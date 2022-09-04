//
//  DatabaseController.m
//  Warehouse
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "DatabaseController.h"
#import "FMDB.h"

@interface DatabaseController ()

@property FMDatabase *database;
@property (readwrite) NSArray<NSString *> *dateColumns;

@end

@implementation DatabaseController

- (instancetype)initWithDatabasePath:(NSString *)path {
    self = [super init];
    if (self) {
        _database = [FMDatabase databaseWithPath:path];
        NSISO8601DateFormatter *dateFormatter = [FMDatabase storeableDateFormatISO8601];
        [_database setDateFormat:dateFormatter];
        if (![_database open]) {
            return nil;
        }
        if (![self enableCaseSensitiveLike]) {
            [_database close];
            return nil;
        }
        _dateColumns = @[
            @"date_acquired",
            @"date_spent"
        ];
    }
    return self;
}


- (BOOL)enableCaseSensitiveLike {
    FMResultSet *resultSet = [_database executeQuery:@"PRAGMA case_sensitive_like=ON"];
    BOOL querySucceeded = resultSet && ![_database hadError];
    [resultSet close];
    return querySucceeded;
}


- (void)closeDatabase {
    [_database close];
}


- (NSDate *)decodeDate:(NSString *)date {
    return [_database dateFromString:date];
}


- (NSString *)encodeDate:(NSDate *)date {
    return [_database stringFromDate:date];
}


- (NSArray *)groupsFromColumn:(NSString *)columnName table:(NSString *)tableName {
    NSMutableArray<NSString *> *groups = [[NSMutableArray alloc] init];
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ GROUP BY %@", columnName, tableName, columnName];
    FMResultSet *resultSet = [_database executeQuery:query];
    while ([resultSet next]) {
        NSString *groupName = [resultSet stringForColumnIndex:0];
        if (groupName) {
            [groups addObject:groupName];
        }
    }
    [resultSet close];
    return [groups copy];
}


- (NSArray *)componentTypes {
    return [self groupsFromColumn:@"component_type" table:@"stock"];
}


- (NSArray *)manufacturers {
    return [self groupsFromColumn:@"manufacturer" table:@"stock"];
}


- (NSArray *)packageCodes {
    return [self groupsFromColumn:@"package_code" table:@"stock"];
}


- (BOOL)databaseKnowsPartNumber:(NSString *)partNumber
               fromManufacturer:(NSString *)manufacturer {
    FMResultSet *resultSet = [_database executeQuery:@"SELECT part_number FROM stock WHERE part_number = ? AND manufacturer = ?", partNumber, manufacturer];
    BOOL hasMatch = [resultSet next];
    [resultSet close];
    //... Gera uma notificação em caso positivo? A janela de busca e de registro, subscritoras da notificação, serão afetadas
    return hasMatch;
}


- (NSMutableArray<NSDictionary *> *)incrementalSearchResultsForPartNumber:(NSString *)partNumber
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


- (NSMutableArray<NSDictionary *> *)searchResultsForComponentType:(NSString *)type
                                                         criteria:(NSDictionary *)criteria {
    NSMutableArray<NSDictionary *> *searchResults = [[NSMutableArray alloc] init];
    NSMutableString *query = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM stock WHERE component_type = '%@'", type];
    if (criteria) {
        for (NSString *columnName in criteria) {
            [query appendFormat:@" AND %@ %@", columnName, criteria[columnName]]; //... Critério deve incluir operador relacional! e.g.: "voltage_rating <= 90". Cogitar um objeto SearchCriteria
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


- (NSMutableArray<NSDictionary *> *)stockReplenishmentsForPartNumber:(NSString *)partNumber
                                                        manufacturer:(NSString *)manufacturer {
    NSMutableArray<NSDictionary *> *queryResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT quantity, date_acquired, origin FROM acquisitions WHERE part_number = ? AND manufacturer = ? ORDER BY date_acquired DESC", partNumber, manufacturer];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}


- (NSMutableArray<NSDictionary *> *)stockWithdrawalsForPartNumber:(NSString *)partNumber
                                                     manufacturer:(NSString *)manufacturer {
    NSMutableArray<NSDictionary *> *queryResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT quantity, date_spent, destination FROM expenditures WHERE part_number = ? AND manufacturer = ? ORDER BY date_spent DESC", partNumber, manufacturer];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}


- (BOOL)isNullableColumn:(NSString *)column table:(NSString *)table {
    BOOL isNullable = NO;
    FMResultSet *resultSet = [_database getTableSchema:table];
    while ([resultSet next]) {
        NSString *columnName = [resultSet stringForColumn:@"name"];
        if ([columnName isEqualToString:column]) {
            isNullable = ![resultSet boolForColumn:@"notnull"];
            break;
        }
    }
    [resultSet close];
    return isNullable;
}

@end
