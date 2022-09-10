//
//  StockedComponent.m
//  Warehouse
//
//  Created by Douglas Almeida on 09/09/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "StockedComponent.h"

@implementation StockedComponent

- (NSString *)description {
    return [NSString stringWithFormat:@"Stocked Component:\n\tID = %ld\n\tQuantity = %ld\n\tType = %@\n\tPart# = %@\n\tManufacturer = %@\n\tPackage = %@\n\tComments = %@\n\tRatings = %@",
            [self componentID],
            [self stockedQuantity],
            [self componentType],
            [self partNumber],
            [self manufacturer],
            [self packageCode],
            [self comments],
            [[self ratings] description]];
}

@end
