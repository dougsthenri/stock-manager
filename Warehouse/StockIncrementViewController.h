//
//  StockIncrementViewController.h
//  Warehouse
//
//  Created by Douglas Almeida on 31/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface StockIncrementViewController : NSViewController <NSTextFieldDelegate>

@property NSString *selectedPartNumber;
@property NSString *selectedManufacturer;

@end

NS_ASSUME_NONNULL_END
