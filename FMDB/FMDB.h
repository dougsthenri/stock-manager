/*
 FMDB v2.7
 
 Modified to use ISO 8601 format and local time zone for data.
 Douglas Almeida - 01/09/2022
 */

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double FMDBVersionNumber;
FOUNDATION_EXPORT const unsigned char FMDBVersionString[];

#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"
#import "FMDatabasePool.h"

#define SQLITE_OPEN_READWRITE 0x00000002
#define FMDB_SQL_NULLABLE(OBJ) ((OBJ) ?: [NSNull null])
