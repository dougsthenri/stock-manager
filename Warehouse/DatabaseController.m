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
@property NSISO8601DateFormatter *dateFormatter;
@property (readwrite) NSArray<NSString *> *dateColumns;

@end

@implementation DatabaseController

+ (instancetype)sharedController {
    static DatabaseController *controller = nil;
    if (!controller) {
        controller = [[DatabaseController alloc] init];
    }
    return controller;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
        [_dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        _dateColumns = @[
            @"date_acquired",
            @"date_spent"
        ];
    }
    return self;
}


- (void)openDatabaseAtPath:(NSString *)path {
    _database = [FMDatabase databaseWithPath:path];
    [_database setDateFormat:_dateFormatter];
    if (![_database open]) {
        NSLog(@"Controller failed to open database file '%@'.", path);
    }
    // Configurar o banco de dados
    if (![self enableCaseSensitiveLike]) {
        [_database close];
        NSLog(@"Controller failed to set case sensitive LIKE for database.");
    }
    //... Experimentar modo WAL
}


- (void)closeDatabase {
    [_database close];
    _database = nil;
}


- (BOOL)enableCaseSensitiveLike {
    FMResultSet *resultSet = [_database executeQuery:@"PRAGMA case_sensitive_like=ON"];
    BOOL querySucceeded = resultSet && ![_database hadError];
    [resultSet close];
    return querySucceeded;
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


- (NSMutableArray<NSDictionary *> *)incrementalSearchResultsForPartNumber:(NSString *)partNumber {
    NSMutableArray<NSDictionary *> *searchResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT * FROM stock WHERE part_number LIKE ?", [partNumber stringByAppendingString:@"%"]];
    while ([resultSet next]) {
        NSDictionary *result = [resultSet resultDictionary];
        [searchResults addObject:result];
    }
    [resultSet close];
    return searchResults;
}


- (NSMutableArray<NSDictionary *> *)searchResultsForComponentType:(NSString *)type {
    NSMutableArray<NSDictionary *> *searchResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT * FROM stock WHERE component_type = ?", type];
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
        NSNumber *quantity = [NSNumber numberWithInteger:[resultSet longForColumn:@"quantity"]];
        NSDate *dateAcquired = [resultSet dateForColumn:@"date_acquired"];
        NSString *origin = [resultSet stringForColumn:@"origin"];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                quantity, @"quantity",
                                dateAcquired ?: [NSNull null], @"date_acquired",
                                origin ?: [NSNull null], @"origin",
                                nil];
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
        NSNumber *quantity = [NSNumber numberWithInteger:[resultSet longForColumn:@"quantity"]];
        NSDate *dateSpent = [resultSet dateForColumn:@"date_spent"];
        NSString *destination = [resultSet stringForColumn:@"destination"];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                quantity, @"quantity",
                                dateSpent ?: [NSNull null], @"date_spent",
                                destination ?: [NSNull null], @"destination",
                                nil];
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}


- (BOOL)isRegisteredPartNumber:(NSString *)partNumber manufacturer:(NSString *)manufacturer {
    FMResultSet *resultSet = [_database executeQuery:@"SELECT part_number FROM stock WHERE part_number = ? AND manufacturer = ?", partNumber, manufacturer];
    BOOL isRegistered = [resultSet next];
    [resultSet close];
    return isRegistered;
}


- (void)stockReplenishmentWithParameters:(NSDictionary *)parameters {
    [_database beginExclusiveTransaction];
    NSNumber *quantity = [parameters objectForKey:@"quantity"];
    NSString *partNumber = [parameters objectForKey:@"part_number"];
    NSString *manufacturer = [parameters objectForKey:@"manufacturer"];
    [_database executeUpdate:@"UPDATE stock SET quantity = quantity + ? WHERE part_number = ? AND manufacturer = ?", quantity, partNumber, manufacturer];
    NSDate *dateAcquired = [parameters objectForKey:@"date_acquired"];
    NSString *origin = [parameters objectForKey:@"origin"];
    [_database executeUpdate:@"INSERT INTO acquisitions(part_number, manufacturer, quantity, date_acquired) VALUES(?, ?, ?, ?, ?)", partNumber, manufacturer, quantity, FMDB_SQL_NULLABLE(dateAcquired), FMDB_SQL_NULLABLE(origin)];
    [_database commit];
    //... Lançar notificação!
}


- (void)stockWithdrawalWithParameters:(NSDictionary *)parameters {
    [_database beginExclusiveTransaction];
    NSString *updateCommand = @"UPDATE stock SET quantity = quantity - ? WHERE part_number = ? AND manufacturer = ?";
    NSNumber *quantity = [parameters objectForKey:@"quantity"];
    NSString *partNumber = [parameters objectForKey:@"part_number"];
    NSString *manufacturer = [parameters objectForKey:@"manufacturer"];
    [_database executeUpdate:updateCommand, quantity, partNumber, manufacturer];
    NSDate *dateSpent = [parameters objectForKey:@"date_spent"];
    NSString *destination = [parameters objectForKey:@"destination"];
    [_database executeUpdate:@"INSERT INTO expenditures VALUES(?, ?, ?, ?, ?)", partNumber, manufacturer, quantity,  FMDB_SQL_NULLABLE(dateSpent), FMDB_SQL_NULLABLE(destination)];
    [_database commit];
    //... Lançar notificação!
}


+ (NSDate *)dateWithClearedTimeComponentsFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSDateComponents *dateComponents = [calendar componentsInTimeZone:timeZone fromDate:date];
    [dateComponents setHour:0];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    [dateComponents setNanosecond:0];
    return [calendar dateFromComponents:dateComponents];
}

@end
