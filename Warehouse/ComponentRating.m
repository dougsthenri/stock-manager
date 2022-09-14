//
//  ComponentRating.m
//  Warehouse
//
//  Created by Douglas Almeida on 07/09/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "ComponentRating.h"

@interface ComponentRating ()

@property (readwrite) NSNumber *significand;
@property (readwrite) NSInteger orderOfMagnitude;
@property (readwrite) NSString *name;
@property (readwrite) NSString *unitSymbol;

@end

@implementation ComponentRating

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


+ (NSArray *)prefixes {
    static NSArray *prefixes = nil;
    if (!prefixes) {
        prefixes = @[
            @"f",   //10^-15
            @"p",   //10^-12
            @"n",   //10^-9
            @"µ",   //10^-6
            @"m",   //10^-3
            @"",    //10^0
            @"k",   //10^3
            @"M",   //10^6
            @"G",   //10^9
            @"T",   //10^12
            @"P"    //10^15
        ];
    }
    return prefixes;
}


+ (NSString *)prefixForMagnitude:(NSInteger)magnitude {
    NSInteger prefixCount = [[ComponentRating prefixes] count];
    NSInteger prefixingRange = (prefixCount - 1) / 2;
    if (magnitude < -3 * prefixingRange || magnitude > 3 * prefixingRange) {
        return [NSString stringWithFormat:@" x 10^%ld ", magnitude];
    }
    return [[ComponentRating prefixes] objectAtIndex: (long)magnitude / (long)3 + prefixingRange];
}


+ (BOOL)magnitude:(NSInteger *)magnitude forPrefix:(NSString *)prefix {
    NSInteger prefixIndex = [[ComponentRating prefixes] indexOfObject:prefix];
    if (prefixIndex != NSNotFound) {
        *magnitude = (6 * (double)prefixIndex - 3 * (double)[[ComponentRating prefixes] count] + 3) / 2;
        return YES;
    }
    return NO;
}


+ (NSNumberFormatter *)numberFormatter {
    static NSNumberFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setLocalizesFormat:YES];
        [formatter setMaximumIntegerDigits:3];
        [formatter setMaximumFractionDigits:4];
    }
    return formatter;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _significand = @0;
        _orderOfMagnitude = 0;
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super init];
    if (self) {
        [self setValue:value];
    }
    return self;
}


- (void)setValue:(double)value {
    double orderOfThreeMagnitudes = 0.0;
    if (value > 0.0) {
        orderOfThreeMagnitudes = floor(log10(value) / 3);
    } else if (value < 0.0) {
        orderOfThreeMagnitudes = floor(log10(fabs(value)) / 3);
    }
    [self setOrderOfMagnitude: 3 * (NSInteger)orderOfThreeMagnitudes];
    [self setSignificand:[NSNumber numberWithDouble:value / pow(10.0, _orderOfMagnitude)]];
}


- (double)value {
    return [_significand doubleValue] * pow(10.0, _orderOfMagnitude);
}


- (NSString *)engineeringValue {
    return [NSString stringWithFormat:@"%@ %@%@",
            [[ComponentRating numberFormatter] stringFromNumber:[self significand]],
            [ComponentRating prefixForMagnitude:[self orderOfMagnitude]],
            [self unitSymbol]];
}


- (NSString *)prefixedUnitSymbol {
    NSString *prefix = [ComponentRating prefixForMagnitude:[self orderOfMagnitude]];
    return [prefix stringByAppendingString:[self unitSymbol]];
}


- (NSArray *)allPrefixedUnitSymbols {
    NSMutableArray *symbols = [[NSMutableArray alloc] initWithCapacity:[[ComponentRating prefixes] count]];
    for (NSString *prefix in [ComponentRating prefixes]) {
        NSString *prefixedSymbol = [prefix stringByAppendingString:[self unitSymbol]];
        [symbols addObject:prefixedSymbol];
    }
    return symbols;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ Rating: %@\n", [self name], [self engineeringValue]];
}

@end

#pragma mark - VoltageRating

@implementation VoltageRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Voltage"];
        [super setUnitSymbol:@"V"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Voltage"];
        [super setUnitSymbol:@"V"];
    }
    return self;
}

@end

#pragma mark - CurrentRating

@implementation CurrentRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Current"];
        [super setUnitSymbol:@"A"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Current"];
        [super setUnitSymbol:@"A"];
    }
    return self;
}

@end

#pragma mark - PowerRating

@implementation PowerRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Power"];
        [super setUnitSymbol:@"W"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Power"];
        [super setUnitSymbol:@"W"];
    }
    return self;
}

@end

#pragma mark - ResistanceRating

@implementation ResistanceRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Resistance"];
        [super setUnitSymbol:@"Ω"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Resistance"];
        [super setUnitSymbol:@"Ω"];
    }
    return self;
}

@end

#pragma mark - InductanceRating

@implementation InductanceRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Inductance"];
        [super setUnitSymbol:@"H"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Inductance"];
        [super setUnitSymbol:@"H"];
    }
    return self;
}

@end

#pragma mark - CapacitanceRating

@implementation CapacitanceRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Capacitance"];
        [super setUnitSymbol:@"F"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Capacitance"];
        [super setUnitSymbol:@"F"];
    }
    return self;
}

@end

#pragma mark - FrequencyRating

@implementation FrequencyRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Frequency"];
        [super setUnitSymbol:@"Hz"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Frequency"];
        [super setUnitSymbol:@"Hz"];
    }
    return self;
}

@end

#pragma mark - ToleranceRating

@implementation ToleranceRating

- (instancetype)init {
    self = [super init];
    if (self) {
        [super setName:@"Tolerance"];
        [super setUnitSymbol:@"%"];
    }
    return self;
}


- (instancetype)initWithValue:(double)value {
    self = [super initWithValue:value];
    if (self) {
        [super setName:@"Tolerance"];
        [super setUnitSymbol:@"%"];
    }
    return self;
}


- (void)setValue:(double)value {
    [super setSignificand:[NSNumber numberWithDouble:value]];
    // A ordem de magnitude nunca será alterada de zero
}


- (NSString *)engineeringValue {
    return [NSString stringWithFormat:@"%@%@",
            [NSNumber numberWithDouble:[super value]],
            [self unitSymbol]];
}


- (NSString *)prefixedUnitSymbol {
    return [self unitSymbol];
}


- (NSArray *)allPrefixedUnitSymbols {
    return @[ @"%" ];
}

@end
