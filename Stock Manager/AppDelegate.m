//
//  AppDelegate.m
//  Stock Manager
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "AppDelegate.h"
#import "DatabaseController.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"

@interface AppDelegate ()

@property (strong) MainWindowController *mainWindowController;
@property (strong) PreferencesWindowController *preferencesWindowController;

@end

@implementation AppDelegate

/*
 Chaves opcionais para persistência de estado do aplicativo:
 kLastAcquisitionDate
 kLastAcquisitionOrigin
 kLastExpenditureDate
 kLastExpenditureDestination
 */
+ (void)initialize {
    // Register configuration
    NSDictionary *defaultValues = @{ @"kDBFileLocation" : @"" };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(databasePathDidChangeNotification:)
                                                     name:@"APPDatabasePathDidChangeNotification"
                                                   object:nil];
    }
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setUpMainWindow];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[DatabaseController sharedController] closeDatabase];
}


- (IBAction)preferencesMenuItemClicked:(NSMenuItem *)sender {
    [self showPreferencesWindow];
}


- (IBAction)stockMenuItemClicked:(id)sender {
    [self showMainWindow];
}


- (void)setUpMainWindow {
    NSString *dbFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"kDBFileLocation"];
    if ([[DatabaseController sharedController] openDatabaseAtPath:dbFilePath]) {
        [self showMainWindow];
    } else {
        [self missingDatabaseUserAlert];
    }
}


- (void)showMainWindow {
    if (!_mainWindowController) {
        [self setMainWindowController:[[MainWindowController alloc] init]];
    }
    [_mainWindowController showWindow:nil];
}


- (void)showPreferencesWindow {
    if (!_preferencesWindowController) {
        [self setPreferencesWindowController:[[PreferencesWindowController alloc] init]];
    }
    [_preferencesWindowController showWindow:nil];
}


- (void)missingDatabaseUserAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert setMessageText:@"Could not access the database."];
    NSString *dbFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"kDBFileLocation"];
    [alert setInformativeText:[NSString stringWithFormat:@"File '%@' is unavailable or invalid. Provide a database file path on settings.", dbFilePath]];
    [alert addButtonWithTitle:@"Settings..."];
    [alert addButtonWithTitle:@"Quit"];
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [self showPreferencesWindow];
    } else {
        [NSApp terminate:nil];
    }
}

#pragma mark - Notification Handlers

- (void)databasePathDidChangeNotification:(NSNotification *)notification {
    [_mainWindowController closeWindows];
    [self setMainWindowController:nil];
    [self setUpMainWindow];
}

@end
