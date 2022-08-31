//
//  WHRegistrationWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 28/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHRegistrationWindowController.h"
#import "WHDatabaseController.h"

@interface WHRegistrationWindowController ()

@property WHDatabaseController *databaseController;

@end

@implementation WHRegistrationWindowController

- (instancetype)initWithDatabaseController:(WHDatabaseController *)controller
{
    self = [super initWithWindowNibName:@"WHRegistrationWindowController"];
    if (self) {
        _databaseController = controller;
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction)okButtonClicked:(id)sender {
    //... SQL UPDATE
    [self close];
}


- (IBAction)cancelButtonClicked:(id)sender {
    [self close];
}

@end
