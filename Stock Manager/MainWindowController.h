//
//  MainWindowController.h
//  Stock Manager
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DatabaseController;

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController : NSWindowController <NSControlTextEditingDelegate, NSTableViewDataSource, NSTableViewDelegate>

- (void)closeWindows;

@end

NS_ASSUME_NONNULL_END
