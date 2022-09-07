//
//  AppDelegate.m
//  Warehouse
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
    // Resgistrar configuração
    NSDictionary *defaultValues = @{ @"kDBFileLocation" : @"" };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *dbFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"kDBFileLocation"];
    [[DatabaseController sharedController] openDatabaseAtPath:dbFilePath];
    [self showMainWindow];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[DatabaseController sharedController] closeDatabase];
}


- (IBAction)preferencesMenuItemClicked:(NSMenuItem *)sender {
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[PreferencesWindowController alloc] init];
    }
    [_preferencesWindowController showWindow:nil];
}


- (void)showMainWindow {
    if (!_mainWindowController) {
        _mainWindowController = [[MainWindowController alloc] init];
    }
    [_mainWindowController showWindow:nil];
}

@end
