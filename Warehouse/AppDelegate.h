//
//  AppDelegate.h
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WHDatabaseController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly) WHDatabaseController *databaseController;

@end
