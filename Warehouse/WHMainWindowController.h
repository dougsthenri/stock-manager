//
//  WHMainWindowController.h
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AppDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WHMainWindowController : NSWindowController <NSControlTextEditingDelegate, NSComboBoxDelegate, NSTableViewDataSource>

@property AppDelegate *appDelegate;

- (instancetype)initWithAppDelegate:(AppDelegate *)delegate;

@end

NS_ASSUME_NONNULL_END
