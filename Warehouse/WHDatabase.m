//
//  WHDatabase.m
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHDatabase.h"
#import <sqlite3.h>

@interface WHDatabase ()

@property NSURL *dbFileLocation;

@end

@implementation WHDatabase

- (instancetype)initWithDBFile:(NSString *)dbFileLocation {
    self = [super init];
    if (self) {
        NSURL *dbFileURL = [NSURL fileURLWithPath:[dbFileLocation stringByExpandingTildeInPath]
                                      isDirectory:NO];
        _dbFileLocation = dbFileURL;
        
        // Conectar ao banco de dados
        if (![[NSFileManager defaultManager] fileExistsAtPath:[dbFileURL absoluteString]]) {
            NSLog(@"Database file not found.");
            return nil;
        }
        //...
    }
    return self;
}

@end
