//
//  PreferencesWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "PreferencesWindowController.h"

@implementation PreferencesWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"PreferencesWindowController"];
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    [[self window] setContentMaxSize:NSMakeSize(FLT_MAX, 100.0)];
}


- (IBAction)changeButtonClicked:(id)sender {
    NSString *currentFilePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"kDBFileLocation"];
    NSOpenPanel *filePicker = [NSOpenPanel openPanel];
    [filePicker setCanChooseDirectories:NO];
    [filePicker setAllowsMultipleSelection:NO];
    if ([filePicker runModal] == NSModalResponseOK) {
        NSString *filePath = [NSString stringWithUTF8String:[[filePicker URL] fileSystemRepresentation]];
        if (![filePath isEqualToString:currentFilePath]) {
            [[NSUserDefaults standardUserDefaults] setObject:filePath forKey:@"kDBFileLocation"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"APPDatabasePathDidChangeNotification"
                                                                object:self];
        }
    }
}

@end
