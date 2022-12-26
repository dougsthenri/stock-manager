//
//  StockDecrementViewController.m
//  Stock Manager
//
//  Created by Douglas Almeida on 31/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "StockDecrementViewController.h"
#import "DatabaseController.h"

@interface StockDecrementViewController ()

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTextField *quantityTextField;
@property (weak) IBOutlet NSStepper *quantityStepper;
@property (weak) IBOutlet NSTextField *destinationTextField;
@property (weak) IBOutlet NSDatePicker *expenditureDatePicker;
@property (weak) IBOutlet NSButton *dateUnknownCheckbox;
@property (weak) IBOutlet NSLayoutConstraint *variableHeightConstraint;

@end

@implementation StockDecrementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_variableHeightConstraint setConstant:20]; //Date field initially hidden
    [_quantityStepper setMaxValue:FLT_MAX];
    [self resetQuantity];
    [self loadPersistedInput];
}


- (void)viewWillAppear {
    // Keep last destination and date entries to sequentially remove items with the same destination
    [self resetQuantity];
    [super viewWillAppear];
}


- (IBAction)quantityStepperClicked:(id)sender {
    int quantity = [_quantityStepper intValue];
    [_quantityTextField setIntValue:quantity];
}


- (IBAction)unknownDateCheckboxClicked:(id)sender {
    BOOL hideDatePicker = [_dateUnknownCheckbox state] == NSControlStateValueOn ? YES : NO;
    if (hideDatePicker) {
        [_expenditureDatePicker setHidden:YES];
        [_variableHeightConstraint setConstant:20];
    } else {
        [_variableHeightConstraint setConstant:51];
        [_expenditureDatePicker setHidden:NO];
    }
}


- (IBAction)deductFromStockButtonClicked:(id)sender {
    NSNumber *quantity = [NSNumber numberWithInteger:[_quantityTextField integerValue]];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"component_id" : _selectedComponentID,
        @"quantity"     : quantity
    }];
    NSString *destination = [[_destinationTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([destination length] > 0) {
        [parameters setObject:destination forKey:@"destination"];
    }
    if ([_dateUnknownCheckbox state] == NSControlStateValueOff) {
        NSDate *dateSpent = [DatabaseController dateWithClearedTimeComponentsFromDate:[_expenditureDatePicker dateValue]];
        [parameters setObject:dateSpent forKey:@"date_spent"];
    }
    [[DatabaseController sharedController] stockWithdrawalWithParameters:parameters];
    [self persistLastExpenditureInput]; //For sequential removal of components with the same destination
    [_popover close];
}


- (void)resetQuantity {
    [_quantityStepper setIntValue:1];
    [_quantityTextField setIntValue:1];
}


- (void)setExpenditureDatePickerHidden:(BOOL)hidden {
    if (hidden) {
        [_expenditureDatePicker setHidden:YES];
        [_variableHeightConstraint setConstant:20];
    } else {
        [_variableHeightConstraint setConstant:51];
        [_expenditureDatePicker setHidden:NO];
    }
}


- (void)persistLastExpenditureInput {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([_dateUnknownCheckbox state] == NSControlStateValueOff) {
        [userDefaults setObject:[_expenditureDatePicker dateValue] forKey:@"kLastExpenditureDate"];
    } else {
        [userDefaults removeObjectForKey:@"kLastExpenditureDate"];
    }
    NSString *destination = [[_destinationTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([[_destinationTextField stringValue] length] > 0) {
        [userDefaults setObject:destination forKey:@"kLastExpenditureDestination"];
    } else {
        [userDefaults removeObjectForKey:@"kLastExpenditureDestination"];
    }
}


- (void)loadPersistedInput {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastWithdrawalDate = [userDefaults objectForKey:@"kLastExpenditureDate"];
    if (lastWithdrawalDate) {
        [_dateUnknownCheckbox setState:NSControlStateValueOff];
        [_expenditureDatePicker setDateValue:lastWithdrawalDate];
        [self setExpenditureDatePickerHidden:NO];
    } else {
        [_expenditureDatePicker setDateValue:[NSDate date]]; //Current date (GMT)
        [self setExpenditureDatePickerHidden:YES];
    }
    NSString *lastDestination = [userDefaults stringForKey:@"kLastExpenditureDestination"];
    [_destinationTextField setStringValue:lastDestination ?: @""];
}

#pragma mark - NSTextFieldDelegate

-(void)controlTextDidChange:(NSNotification *)obj {
    // Quantity text field
    int quantity = [_quantityTextField intValue];
    [_quantityStepper setIntValue:quantity];
}

@end
