//
//  WHDatabase.h
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WHDatabase : NSObject

- (instancetype)initWithDBFile:(NSString *)dbFileLocation;

@end

NS_ASSUME_NONNULL_END
