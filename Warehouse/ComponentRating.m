//
//  ComponentRating.m
//  Warehouse
//
//  Created by Douglas Almeida on 07/09/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "ComponentRating.h"

@implementation ComponentRating

+ (NSString *)prefixForMagnitude:(NSInteger)magnitude {
    static NSArray *prefixes = nil;
    if (!prefixes) {
        prefixes = @[
            @"p",   //10^-12
            @"n",   //10^-9
            @"µ",   //10^-6
            @"m",   //10^-3
            @"",    //10^0
            @"k",   //10^3
            @"M",   //10^6
            @"G",   //10^9
            @"T"    //10^12
        ];
    }
    if (magnitude < -12 || magnitude > 12) {
        return [NSString stringWithFormat:@"(x10^%ld)", magnitude];
    }
    return prefixes[magnitude / 3 + 4];
}


+ (NSArray *)ratingNames {
    static NSArray *names = nil;
    if (!names) {
        names = @[
            @"Voltage",
            @"Current",
            @"Power",
            @"Resistance",
            @"Inductance",
            @"Capacitance",
            @"Frequency",
            @"Tolerance"
        ];
    }
    return names;
}


- (instancetype)initWithValue:(double)value {
    self = [super init];
    if (self) {
        double orderOfThreeMagnitudes = 0.0;
        if (value > 0.0) {
            orderOfThreeMagnitudes = floor(log10(value) / 3);
        } else if (value < 0.0) {
            orderOfThreeMagnitudes = floor(log10(fabs(value)) / 3);
        }
        _orderOfMagnitude = 3 * (NSInteger)orderOfThreeMagnitudes;
        _engineeringValue = [NSNumber numberWithDouble:value / pow(10.0, _orderOfMagnitude)];
    }
    return self;
}


- (double)value {
    return [_engineeringValue doubleValue] * pow(10.0, _orderOfMagnitude);
}


- (nonnull NSString *)name {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You must override '%@' in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


- (nonnull NSString *)unitSymbol {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You must override '%@' in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


- (nonnull NSString *)engineeringUnit {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You must override '%@' in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


@end

#pragma mark - VoltageRating

@implementation VoltageRating

- (NSString *)name {
    return @"Voltage";
}


- (NSString *)unitSymbol {
    return @"V";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - CurrentRating

@implementation CurrentRating

- (NSString *)name {
    return @"Current";
}


- (NSString *)unitSymbol {
    return @"A";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - PowerRating

@implementation PowerRating

- (NSString *)name {
    return @"Power";
}


- (NSString *)unitSymbol {
    return @"W";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - ResistanceRating

@implementation ResistanceRating

- (NSString *)name {
    return @"Resistance";
}


- (NSString *)unitSymbol {
    return @"Ω";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - InductanceRating

@implementation InductanceRating

- (NSString *)name {
    return @"Inductance";
}


- (NSString *)unitSymbol {
    return @"H";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - CapacitanceRating

@implementation CapacitanceRating

- (NSString *)name {
    return @"Capacitance";
}


- (NSString *)unitSymbol {
    return @"F";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - FrequencyRating

@implementation FrequencyRating

- (NSString *)name {
    return @"Frequency";
}


- (NSString *)unitSymbol {
    return @"Hz";
}


- (NSString *)engineeringUnit {
    NSString *prefix = [ComponentRating prefixForMagnitude:[super orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}

@end

#pragma mark - ToleranceRating

@implementation ToleranceRating

- (NSString *)name {
    return @"Tolerance";
}


- (NSString *)unitSymbol {
    return @"%";
}


- (NSNumber *)engineeringValue {
    return [NSNumber numberWithDouble: [super value]];
}


- (NSString *)engineeringUnit {
    return [self unitSymbol];
}

@end
