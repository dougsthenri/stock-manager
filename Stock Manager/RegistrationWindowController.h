//
//  RegistrationWindowController.h
//  Stock Manager
//
//  Created by Douglas Almeida on 28/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DatabaseController;

NS_ASSUME_NONNULL_BEGIN

@interface RegistrationWindowController : NSWindowController <NSTextFieldDelegate, NSTableViewDataSource, NSTabViewDelegate>

@property NSString *partNumber;

- (void)clearInputForm;

@end

@interface RatingValueTableCellView : NSTableCellView

@property (nullable, assign) IBOutlet NSPopUpButton *popUpButton;

@end

NS_ASSUME_NONNULL_END
