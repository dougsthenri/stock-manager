//
//  WHPreferencesWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHPreferencesWindowController.h"

@interface WHPreferencesWindowController ()

@end

@implementation WHPreferencesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self window] setContentMaxSize:NSMakeSize(FLT_MAX, 100.0)];
}


- (IBAction)changeButtonClicked:(id)sender {
    NSOpenPanel *filePicker = [NSOpenPanel openPanel];
    [filePicker setCanChooseDirectories:NO];
    [filePicker setAllowsMultipleSelection:NO];
    
    if ([filePicker runModal] == NSModalResponseOK) {
        NSString *filePath = [NSString stringWithUTF8String:[[filePicker URL] fileSystemRepresentation]];
        [[NSUserDefaults standardUserDefaults] setObject:filePath forKey:@"kDBFileLocation"];
        //... Conscientizar o aplicativo da mudança
    }
}

@end
