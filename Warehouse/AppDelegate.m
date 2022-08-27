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

@property (weak) IBOutlet NSWindow *mainWindow;
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
    _mainWindowController = [[WHMainWindowController alloc] initWithWindowNibName:@"WHMainWindowController"];
    [_mainWindowController showWindow:nil];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
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
