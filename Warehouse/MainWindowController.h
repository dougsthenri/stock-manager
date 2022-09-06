//
//  MainWindowController.h
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DatabaseController;

// Para controles segmentados em rodapés de tabelas
#define PLUS_BUTTON_SEGMENT_INDEX   0
#define MINUS_BUTTON_SEGMENT_INDEX  1

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController : NSWindowController <NSControlTextEditingDelegate, NSTableViewDataSource, NSTableViewDelegate>

- (instancetype)initWithDatabaseController:(DatabaseController *)controller;
+ (NSRect)relativeBoundsForSegmentedControl:(NSSegmentedControl *)control
                               segmentIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
