//
//  StockIncrementViewController.m
//  Warehouse
//
//  Created by Douglas Almeida on 31/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "StockIncrementViewController.h"
#import "DatabaseController.h"

@interface StockIncrementViewController ()

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTextField *quantityTextField;
@property (weak) IBOutlet NSStepper *quantityStepper;
@property (weak) IBOutlet NSTextField *originTextField;
@property (weak) IBOutlet NSDatePicker *acquisitionDatePicker;
@property (weak) IBOutlet NSButton *dateUnknownCheckbox;
@property (weak) IBOutlet NSLayoutConstraint *variableHeightConstraint;

@end

@implementation StockIncrementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_variableHeightConstraint setConstant:20]; //Campo de data inicialmente escondido
    [_quantityStepper setMaxValue:FLT_MAX];
    [self resetQuantity];
    [self loadPersistedInput];
}


- (void)viewWillAppear {
    [self loadPersistedInput];
    [self resetQuantity];
    [super viewWillAppear];
}


- (IBAction)quantityStepperClicked:(id)sender {
    int quantity = [_quantityStepper intValue];
    [_quantityTextField setIntValue:quantity];
}


- (IBAction)unknownDateCheckboxClicked:(id)sender {
    BOOL hideDatePicker = [_dateUnknownCheckbox state] == NSControlStateValueOn ? YES : NO;
    [self setAcquisitionDatePickerHidden:hideDatePicker];
}


- (IBAction)addToStockButtonClicked:(id)sender {
    NSNumber *quantity = [NSNumber numberWithInteger:[_quantityTextField integerValue]];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       _selectedPartNumber, @"part_number",
                                       _selectedManufacturer, @"manufacturer",
                                       quantity, @"quantity",
                                       nil];
    NSString *origin = [[_originTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([origin length] > 0) {
        [parameters setObject:origin forKey:@"origin"];
    }
    if ([_dateUnknownCheckbox state] == NSControlStateValueOff) {
        NSDate *dateAcquired = [DatabaseController dateWithClearedTimeComponentsFromDate:[_acquisitionDatePicker dateValue]];
        [parameters setObject:dateAcquired forKey:@"date_acquired"];
    }
    [[DatabaseController sharedController] stockReplenishmentWithParameters:parameters];
    [self persistLastAcquisitionInput]; //Para adição sequencial de componentes de uma mesma origem
    [_popover close];
}


- (void)resetQuantity {
    [_quantityStepper setIntValue:1];
    [_quantityTextField setIntValue:1];
}


- (void)setAcquisitionDatePickerHidden:(BOOL)hidden {
    if (hidden) {
        [_acquisitionDatePicker setHidden:YES];
        [_variableHeightConstraint setConstant:20];
    } else {
        [_variableHeightConstraint setConstant:51];
        [_acquisitionDatePicker setHidden:NO];
    }
}


- (void)persistLastAcquisitionInput {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([_dateUnknownCheckbox state] == NSControlStateValueOff) {
        [userDefaults setObject:[_acquisitionDatePicker dateValue] forKey:@"kLastAcquisitionDate"];
    } else {
        [userDefaults removeObjectForKey:@"kLastAcquisitionDate"];
    }
    NSString *origin = [[_originTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([[_originTextField stringValue] length] > 0) {
        [userDefaults setObject:origin forKey:@"kLastAcquisitionOrigin"];
    } else {
        [userDefaults removeObjectForKey:@"kLastAcquisitionOrigin"];
    }
}


- (void)loadPersistedInput {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastAcquisitionDate = [userDefaults objectForKey:@"kLastAcquisitionDate"];
    if (lastAcquisitionDate) {
        [_dateUnknownCheckbox setState:NSControlStateValueOff];
        [_acquisitionDatePicker setDateValue:lastAcquisitionDate];
        [self setAcquisitionDatePickerHidden:NO];
    } else {
        [_dateUnknownCheckbox setState:NSControlStateValueOn];
        [_acquisitionDatePicker setDateValue:[NSDate date]]; //Data atual (GMT)
        [self setAcquisitionDatePickerHidden:YES];
    }
    NSString *lastOrigin = [userDefaults stringForKey:@"kLastAcquisitionOrigin"];
    [_originTextField setStringValue:lastOrigin ?: @""];
}

#pragma mark - NSTextFieldDelegate

-(void)controlTextDidChange:(NSNotification *)obj {
    // Campo de texto de quantidade
    int quantity = [_quantityTextField intValue];
    [_quantityStepper setIntValue:quantity];
}

@end
