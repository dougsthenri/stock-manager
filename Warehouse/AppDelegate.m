//
//  AppDelegate.m
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "AppDelegate.h"
#import "WHMainWindowController.h"
#import "WHPreferencesWindowController.h"
#import "FMDB.h"

@interface AppDelegate ()

@property (strong) WHMainWindowController *mainWindowController;
@property (strong) WHPreferencesWindowController *preferencesWindowController;

@property FMDatabase *db;

@end

@implementation AppDelegate

+ (void)initialize {
    // Resgistrar configuração
    NSDictionary *defaultValues = @{ @"kDBFileLocation" : @"" };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *dbFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"kDBFileLocation"];
    _db = [FMDatabase databaseWithPath:dbFilePath];
    if (![_db open]) {
        _db = nil;
        return;
    }
    _mainWindowController = [[WHMainWindowController alloc] initWithWindowNibName:@"WHMainWindowController"];
    [_mainWindowController showWindow:nil];
    
    //***
    FMResultSet *s = [_db executeQuery:@"SELECT * FROM stock WHERE component_type = ?", FMDB_SQL_NULLABLE(@"IC")];
    while ([s next]) {
        NSString *rowValue = [s stringForColumn:@"part_number"];
        NSLog(@"Part#: %@", rowValue);
    }
    [s close];
    //***
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (_db) {
        [_db close];
    }
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


- (IBAction)preferencesMenuItemClicked:(NSMenuItem *)sender {
    if (![self preferencesWindowController]) {
        _preferencesWindowController = [[WHPreferencesWindowController alloc] initWithWindowNibName:@"WHPreferencesWindowController"];
    }
    [_preferencesWindowController showWindow:nil];
}

@end
