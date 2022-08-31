//
//  WHRegistrationWindowController.h
//  Warehouse
//
//  Created by Douglas Almeida on 28/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WHDatabaseController;

NS_ASSUME_NONNULL_BEGIN

@interface WHRegistrationWindowController : NSWindowController

-(instancetype)initWithDatabaseController:(WHDatabaseController *)controller;

@end

NS_ASSUME_NONNULL_END
