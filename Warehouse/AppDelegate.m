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

@interface AppDelegate ()

@property (readwrite) WHDatabaseController *databaseController;
@property (strong) WHMainWindowController *mainWindowController;
@property (strong) WHPreferencesWindowController *preferencesWindowController;

@end

@implementation AppDelegate

+ (void)initialize {
    // Resgistrar configuração
    NSDictionary *defaultValues = @{ @"kDBFileLocation" : @"" };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *dbFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"kDBFileLocation"];
    _databaseController = [[WHDatabaseController alloc] initWithDatabasePath:dbFilePath];
    [self showMainWindow];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (_databaseController) {
        [_databaseController closeDatabase];
    }
}


- (IBAction)preferencesMenuItemClicked:(NSMenuItem *)sender {
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[WHPreferencesWindowController alloc] init];
    }
    [_preferencesWindowController showWindow:nil];
}


- (void)showMainWindow {
    if (!_mainWindowController) {
        _mainWindowController = [[WHMainWindowController alloc] initWithAppDelegate:self];
    }
    [_mainWindowController showWindow:nil];
}

@end
