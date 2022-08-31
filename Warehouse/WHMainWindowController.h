//
//  WHMainWindowController.h
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WHDatabaseController;

NS_ASSUME_NONNULL_BEGIN

@interface WHMainWindowController : NSWindowController <NSControlTextEditingDelegate, NSTableViewDataSource, NSTableViewDelegate>

- (instancetype)initWithDatabaseController:(WHDatabaseController *)controller;

@end

NS_ASSUME_NONNULL_END
