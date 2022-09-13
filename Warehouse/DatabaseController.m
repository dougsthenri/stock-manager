//
//  DatabaseController.m
//  Warehouse
//
//  Created by Douglas Almeida on 30/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "DatabaseController.h"
#import "FMDB.h"
#import "ComponentRating.h"

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
        _database = nil;
        return;
    }
    // Configurar o banco de dados
    if (![self enableCaseSensitiveLike]) {
        [_database close];
        NSLog(@"Controller failed to set case sensitive LIKE for database.");
    }
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


- (NSNumber *)stockForComponentID:(NSNumber *)componentID {
    NSNumber *stock = nil;
    FMResultSet *resultSet = [_database executeQuery:@"SELECT quantity FROM stock WHERE component_id = ?", componentID];
    [resultSet next];
    if ([resultSet columnCount]) {
        stock = [NSNumber numberWithInteger:[resultSet longForColumn:@"quantity"]];
    }
    [resultSet close];
    return stock;
}


- (NSMutableDictionary *)componentFromResultSet:(FMResultSet *)resultSet {
    NSMutableDictionary *component = [[NSMutableDictionary alloc] init];
    [component setObject:[NSNumber numberWithInteger:[resultSet longForColumn:@"component_id"]] forKey:@"component_id"];
    [component setObject:[NSNumber numberWithInteger:[resultSet longForColumn:@"quantity"]] forKey:@"quantity"];
    [component setObject:[resultSet stringForColumn:@"part_number"] forKey:@"part_number"];
    [component setObject:[resultSet stringForColumn:@"component_type"] forKey:@"component_type"];
    if (![resultSet columnIsNull:@"manufacturer"]) {
        [component setObject:[resultSet stringForColumn:@"manufacturer"] forKey:@"manufacturer"];
    }
    if (![resultSet columnIsNull:@"package_code"]) {
        [component setObject:[resultSet stringForColumn:@"package_code"] forKey:@"package_code"];
    }
    if (![resultSet columnIsNull:@"comments"]) {
        [component setObject:[resultSet stringForColumn:@"comments"] forKey:@"comments"];
    }
    if (![resultSet columnIsNull:@"voltage_rating"]) {
        double voltage = [resultSet doubleForColumn:@"voltage_rating"];
        VoltageRating *voltageRating = [[VoltageRating alloc] initWithValue:voltage];
        [component setObject:voltageRating forKey:@"voltage_rating"];
    }
    if (![resultSet columnIsNull:@"current_rating"]) {
        double current = [resultSet doubleForColumn:@"current_rating"];
        CurrentRating *currentRating = [[CurrentRating alloc] initWithValue:current];
        [component setObject:currentRating forKey:@"current_rating"];
    }
    if (![resultSet columnIsNull:@"power_rating"]) {
        double power = [resultSet doubleForColumn:@"power_rating"];
        PowerRating *powerRating = [[PowerRating alloc] initWithValue:power];
        [component setObject:powerRating forKey:@"power_rating"];
    }
    if (![resultSet columnIsNull:@"resistance_rating"]) {
        double resistance = [resultSet doubleForColumn:@"resistance_rating"];
        ResistanceRating *resistanceRating = [[ResistanceRating alloc] initWithValue:resistance];
        [component setObject:resistanceRating forKey:@"resistance_rating"];
    }
    if (![resultSet columnIsNull:@"inductance_rating"]) {
        double inductance = [resultSet doubleForColumn:@"inductance_rating"];
        InductanceRating *inductanceRating = [[InductanceRating alloc] initWithValue:inductance];
        [component setObject:inductanceRating forKey:@"inductance_rating"];
    }
    if (![resultSet columnIsNull:@"capacitance_rating"]) {
        double capacitance = [resultSet doubleForColumn:@"capacitance_rating"];
        CapacitanceRating *capacitanceRating = [[CapacitanceRating alloc] initWithValue:capacitance];
        [component setObject:capacitanceRating forKey:@"capacitance_rating"];
    }
    if (![resultSet columnIsNull:@"frequency_rating"]) {
        double frequency = [resultSet doubleForColumn:@"frequency_rating"];
        FrequencyRating *frequencyRating = [[FrequencyRating alloc] initWithValue:frequency];
        [component setObject:frequencyRating forKey:@"frequency_rating"];
    }
    if (![resultSet columnIsNull:@"tolerance_rating"]) {
        double tolerance = [resultSet doubleForColumn:@"tolerance_rating"];
        ToleranceRating *toleranceRating = [[ToleranceRating alloc] initWithValue:tolerance];
        [component setObject:toleranceRating forKey:@"tolerance_rating"];
    }
    return component;
}


- (NSMutableArray<NSMutableDictionary *> *)incrementalSearchResultsForPartNumber:(NSString *)partNumber {
    NSMutableArray<NSMutableDictionary *> *searchResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT * FROM stock WHERE part_number LIKE ?", [partNumber stringByAppendingString:@"%"]];
    while ([resultSet next]) {
        [searchResults addObject:[self componentFromResultSet:resultSet]];
    }
    [resultSet close];
    return searchResults;
}


- (NSMutableArray<NSMutableDictionary *> *)searchResultsForComponentType:(NSString *)type {
    NSMutableArray<NSMutableDictionary *> *searchResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT * FROM stock WHERE component_type = ?", type];
    while ([resultSet next]) {
        [searchResults addObject:[self componentFromResultSet:resultSet]];
    }
    [resultSet close];
    return searchResults;
}


- (NSMutableArray<NSDictionary *> *)stockReplenishmentsForComponentID:(NSNumber *)component_id {
    NSMutableArray<NSDictionary *> *queryResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT id, quantity, date_acquired, origin FROM acquisitions WHERE fk_component_id = ? ORDER BY date_acquired DESC", component_id];
    while ([resultSet next]) {
        NSNumber *acquisitionID = [NSNumber numberWithInteger:[resultSet longForColumn:@"id"]];
        NSNumber *quantity = [NSNumber numberWithInteger:[resultSet longForColumn:@"quantity"]];
        NSDate *dateAcquired = [resultSet dateForColumn:@"date_acquired"];
        NSString *origin = [resultSet stringForColumn:@"origin"];
        NSDictionary *result = @{
            @"id"               : acquisitionID,
            @"quantity"         : quantity,
            @"date_acquired"    : FMDB_SQL_NULLABLE(dateAcquired),
            @"origin"           : FMDB_SQL_NULLABLE(origin)
        };
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}


- (NSMutableArray<NSDictionary *> *)stockWithdrawalsForComponentID:(NSNumber *)component_id {
    NSMutableArray<NSDictionary *> *queryResults = [[NSMutableArray alloc] init];
    FMResultSet *resultSet = [_database executeQuery:@"SELECT id, quantity, date_spent, destination FROM expenditures WHERE fk_component_id = ? ORDER BY date_spent DESC", component_id];
    while ([resultSet next]) {
        NSNumber *expenditureID = [NSNumber numberWithInteger:[resultSet longForColumn:@"id"]];
        NSNumber *quantity = [NSNumber numberWithInteger:[resultSet longForColumn:@"quantity"]];
        NSDate *dateSpent = [resultSet dateForColumn:@"date_spent"];
        NSString *destination = [resultSet stringForColumn:@"destination"];
        NSDictionary *result = @{
            @"id"           : expenditureID,
            @"quantity"     : quantity,
            @"date_spent"   : FMDB_SQL_NULLABLE(dateSpent),
            @"destination"  : FMDB_SQL_NULLABLE(destination)
        };
        [queryResults addObject:result];
    }
    [resultSet close];
    return queryResults;
}


- (nullable NSMutableDictionary *)recordForPartNumber:(NSString *)partNumber
                                  manufacturer:(nullable NSString *)manufacturer {
    // Deve haver no máximo 1 registro com fabricante desconhecido (nulo) para um dado número de peça
    //... Cogitar um trigger para reforçar a regra acima no próprio banco. Alternativamente aceitar a inserção de múltiplos fabricantes desconhecidos para um dado número de peça (nesse caso, reescrever esse método)
    NSMutableDictionary *record = nil;
    FMResultSet *resultSet = [_database executeQuery:@"SELECT * FROM stock WHERE part_number = ? AND manufacturer = ?", partNumber, manufacturer ?: @"NULL"];
    [resultSet next];
    if ([resultSet columnCount]) {
        record = [self componentFromResultSet:resultSet];
    }
    [resultSet close];
    return record;
}


- (void)stockReplenishmentWithParameters:(NSDictionary *)parameters {
    [_database beginExclusiveTransaction];
    NSNumber *componentID = [parameters objectForKey:@"component_id"];
    NSNumber *quantity = [parameters objectForKey:@"quantity"];
    [_database executeUpdate:@"UPDATE OR ROLLBACK stock SET quantity = quantity + ? WHERE component_id = ?", quantity, componentID];
    NSDate *dateAcquired = [parameters objectForKey:@"date_acquired"];
    NSString *origin = [parameters objectForKey:@"origin"];
    [_database executeUpdate:@"INSERT OR ROLLBACK INTO acquisitions(fk_component_id, quantity, date_acquired, origin) VALUES(?, ?, ?, ?)", componentID, quantity, FMDB_SQL_NULLABLE(dateAcquired), FMDB_SQL_NULLABLE(origin)];
    [_database commit];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DBCStockUpdatedNotification"
                                                        object:self
                                                      userInfo:@{
                                                          @"UpdatedComponentID" : componentID
                                                      }];
}


- (void)stockWithdrawalWithParameters:(NSDictionary *)parameters {
    [_database beginExclusiveTransaction];
    NSNumber *componentID = [parameters objectForKey:@"component_id"];
    NSNumber *quantity = [parameters objectForKey:@"quantity"];
    [_database executeUpdate:@"UPDATE OR ROLLBACK stock SET quantity = quantity - ? WHERE component_id = ?", quantity, componentID];
    NSDate *dateSpent = [parameters objectForKey:@"date_spent"];
    NSString *destination = [parameters objectForKey:@"destination"];
    [_database executeUpdate:@"INSERT OR ROLLBACK INTO expenditures(fk_component_id, quantity, date_spent, destination) VALUES(?, ?, ?, ?)", componentID, quantity, FMDB_SQL_NULLABLE(dateSpent), FMDB_SQL_NULLABLE(destination)];
    [_database commit];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DBCStockUpdatedNotification"
                                                        object:self
                                                      userInfo:@{
                                                          @"UpdatedComponentID" : componentID
                                                      }];
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
