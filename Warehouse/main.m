//
//  main.m
//  Warehouse
//
//  Created by Douglas Almeida on 25/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//***
#import "ComponentRating.h"
//***

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        
        //***
        ComponentRating *aRating;
        VoltageRating *anotherRating = [[VoltageRating alloc] initWithValue:2222.0];
        aRating = anotherRating;
        NSLog(@"%@ = %@ %@ or %f %@", [aRating name], [aRating engineeringValue], [aRating engineeringUnit], [aRating value], [aRating unitSymbol]);
        
        VoltageRating *rating1 = [[VoltageRating alloc] initWithValue:0.0];
        NSLog(@"%@ = %@ %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit]);
        rating1 = [[VoltageRating alloc] initWithValue:33.0];
        NSLog(@"%@ = %@ %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit]);
        rating1 = [[VoltageRating alloc] initWithValue:1.0];
        NSLog(@"%@ = %@ %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit]);
        rating1 = [[VoltageRating alloc] initWithValue:0.006];
        NSLog(@"%@ = %@ %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit]);
        rating1 = [[VoltageRating alloc] initWithValue:5032000];
        NSLog(@"%@ = %@ %@ or %f %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit], [rating1 value], [rating1 unitSymbol]);
        rating1 = [[VoltageRating alloc] initWithValue:-999.0];
        NSLog(@"%@ = %@ %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit]);
        rating1 = [[VoltageRating alloc] initWithValue:-0.6];
        NSLog(@"%@ = %@ %@", [rating1 name], [rating1 engineeringValue], [rating1 engineeringUnit]);
        
        ResistanceRating *rating2 = [[ResistanceRating alloc] initWithValue:333333.3];
        NSLog(@"%@ = %@ %@", [rating2 name], [rating2 engineeringValue], [rating2 engineeringUnit]);
        
        FrequencyRating *rating3 = [[FrequencyRating alloc] initWithValue:9E12];
        NSLog(@"%@ = %@ %@", [rating3 name], [rating3 engineeringValue], [rating3 engineeringUnit]);
        rating3 = [[FrequencyRating alloc] initWithValue:1.24E-23];
        NSLog(@"%@ = %@ %@", [rating3 name], [rating3 engineeringValue], [rating3 engineeringUnit]);
        
        ToleranceRating *rating4 = [[ToleranceRating alloc] initWithValue:0.1];
        NSLog(@"%@ = %@ %@", [rating4 name], [rating4 engineeringValue], [rating4 engineeringUnit]);
        rating4 = [[ToleranceRating alloc] initWithValue:20];
        NSLog(@"%@ = %@ %@", [rating4 name], [rating4 engineeringValue], [rating4 engineeringUnit]);
        //***
        
    }
    return NSApplicationMain(argc, argv);
}
