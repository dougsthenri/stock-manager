//
//  StockDecrementViewController.m
//  Warehouse
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
    [_variableHeightConstraint setConstant:20]; //Campo de data inicialmente escondido
    [_quantityStepper setMaxValue:FLT_MAX];
    [self resetQuantity];
    [self loadPersistedInput];
}


- (void)viewWillAppear {
    // Manter últimas entradas de destino e data para remover sequencialmente itens com mesma destinação
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
    //... SQL UPDATE
    [self persistLastExpenditureInput]; //Para retirada sequencial de componentes com uma mesma destinação
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
        [_expenditureDatePicker setDateValue:[NSDate date]]; //Data atual (GMT)
        [self setExpenditureDatePickerHidden:YES];
    }
    NSString *lastDestination = [userDefaults stringForKey:@"kLastExpenditureDestination"];
    [_destinationTextField setStringValue:lastDestination ?: @""];
}

#pragma mark - NSTextFieldDelegate

-(void)controlTextDidChange:(NSNotification *)obj {
    // Campo de texto de quantidade
    int quantity = [_quantityTextField intValue];
    [_quantityStepper setIntValue:quantity];
}

@end