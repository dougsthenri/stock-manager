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
    [_acquisitionDatePicker setDateValue:[NSDate date]]; //Data atual (GMT)
}


- (void)viewWillAppear {
    // Manter últimas entradas de origem e data para adicionar sequencialmente itens de mesma origem
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
        [_acquisitionDatePicker setHidden:YES];
        [_variableHeightConstraint setConstant:20];
    } else {
        [_variableHeightConstraint setConstant:51];
        [_acquisitionDatePicker setHidden:NO];
    }
}


- (IBAction)addToStockButtonClicked:(id)sender {
    //... SQL UPDATE
    [_popover close];
}


- (void)resetQuantity {
    [_quantityStepper setIntValue:1];
    [_quantityTextField setIntValue:1];
}

#pragma mark - NSTextFieldDelegate

-(void)controlTextDidChange:(NSNotification *)obj {
    // Campo de texto de quantidade
    int quantity = [_quantityTextField intValue];
    [_quantityStepper setIntValue:quantity];
}

@end
