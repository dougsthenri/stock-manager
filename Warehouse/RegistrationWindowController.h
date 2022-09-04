//
//  RegistrationWindowController.h
//  Warehouse
//
//  Created by Douglas Almeida on 28/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DatabaseController;

NS_ASSUME_NONNULL_BEGIN

@interface RegistrationWindowController : NSWindowController <NSControlTextEditingDelegate>

@property NSString *partNumber;

- (instancetype)initWithDatabaseController:(DatabaseController *)controller;
- (void)clearInputForm;

@end

NS_ASSUME_NONNULL_END
