//
//  RegistrationWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 28/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "RegistrationWindowController.h"
#import "MainWindowController.h"
#import "DatabaseController.h"

@interface RegistrationWindowController ()

@property (weak) DatabaseController *databaseController;

@property (weak) IBOutlet NSComboBox *manufacturerComboBox;
@property (weak) IBOutlet NSComboBox *componentTypeComboBox;
@property (weak) IBOutlet NSComboBox *packageCodeComboBox;
@property (weak) IBOutlet NSTextField *commentsTextField;
@property (weak) IBOutlet NSView *noRatingsPlaceholderView;
@property (weak) IBOutlet NSSegmentedControl *ratingsSegmentedControl;

@property (weak) IBOutlet NSTextField *quantityTextField;
@property (weak) IBOutlet NSStepper *quantityStepper;
@property (weak) IBOutlet NSTextField *originTextField;
@property (weak) IBOutlet NSDatePicker *acquisitionDatePicker;
@property (weak) IBOutlet NSButton *dateUnknownCheckbox;

@property NSString *lastManufacturerInput;
@property NSArray *ratingMenuTitles;
@property NSMenu *ratingsMenu;

@end

@implementation RegistrationWindowController

- (instancetype)initWithDatabaseController:(DatabaseController *)controller {
    self = [super initWithWindowNibName:@"RegistrationWindowController"];
    if (self) {
        _databaseController = controller;
        _ratingMenuTitles = @[
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
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSArray *componentTypes = [_databaseController componentTypes];
    [_componentTypeComboBox addItemsWithObjectValues:componentTypes];
    NSArray *manufacturers = [_databaseController manufacturers];
    [_manufacturerComboBox addItemsWithObjectValues:manufacturers];
    NSArray *packageCodes = [_databaseController packageCodes];
    [_packageCodeComboBox addItemsWithObjectValues:packageCodes];
    [_quantityStepper setMaxValue:FLT_MAX];
    [self buildRatingsMenu];
    [self loadPersistedInput];
    [self clearInputForm];
}


- (IBAction)manufacturerComboBoxEdited:(id)sender {
    NSString *manufacturer = [[_manufacturerComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([manufacturer length] > 0 && ![manufacturer isEqualToString:_lastManufacturerInput]) {
        _lastManufacturerInput = manufacturer;
        [self checkExistingPartNumber:_partNumber manufacturer:manufacturer];
    }
}


- (IBAction)ratingsSegmentedControlClicked:(id)sender {
    NSInteger selectedItem = [_ratingsSegmentedControl selectedSegment];
    if (selectedItem == 0) {
        NSPoint menuLocation = NSMakePoint(0, [sender frame].size.height);
        [_ratingsMenu popUpMenuPositioningItem:nil atLocation:menuLocation inView:sender];
    } else if (selectedItem == 1) {
        //... Remover rating selecionada
    }
}


- (IBAction)quantityStepperClicked:(id)sender {
    int quantity = [_quantityStepper intValue];
    [_quantityTextField setIntValue:quantity];
}


- (IBAction)dateUnknownCheckboxClicked:(id)sender {
    BOOL datePickerEnabled = [_dateUnknownCheckbox state] == NSControlStateValueOn ? NO : YES;
    [self setDatePicker:_acquisitionDatePicker enabled:datePickerEnabled];
}


- (IBAction)okButtonClicked:(id)sender {
    //... Verificar campos obrigatórios
    //... SQL INSERT
    [self persistLastAcquisitionInput];
    [self close];
}


- (IBAction)cancelButtonClicked:(id)sender {
    [self close];
}


- (void)clearInputForm {
    _lastManufacturerInput = nil;
    [_manufacturerComboBox setStringValue:@""];
    [_componentTypeComboBox setStringValue:@""];
    [_packageCodeComboBox setStringValue:@""];
    [_commentsTextField setStringValue:@""];
    //... Limpar tabela de características
    [self loadPersistedInput];
    [_quantityStepper setIntValue:1];
    [_quantityTextField setIntValue:1];
    [[self window] makeFirstResponder:_manufacturerComboBox];
}


- (void)addSelectedRating:(id)sender {
    NSMenuItem *menuItem = sender;
    
    NSLog(@"Add %@ rating!", _ratingMenuTitles[[menuItem tag]]); //***
    
    switch ([menuItem tag]) {
        case 0: //Tensão
            //...
            break;
        case 1: //Corrente
            //...
            break;
        case 2: //Potência
            //...
            break;
        case 3: //Resistência
            //...
            break;
        case 4: //Indutância
            //...
            break;
        case 5: //Capacitância
            //...
            break;
        case 6: //Frequência
            //...
            break;
        case 7: //Tolerância
            //...
            break;
        default:
            break;
    }
}


- (void)checkExistingPartNumber:(NSString *)partNumber manufacturer:(NSString *)manufacturer {
    if ([_databaseController isRegisteredPartNumber:_partNumber manufacturer:manufacturer]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert setMessageText:[NSString stringWithFormat:@"%@ from manufacturer %@ is already on the database.", _partNumber, manufacturer]];
        [alert setInformativeText:@"You may update its stock."];
        [alert runModal];
        //... Preencher os dados retornados para o part# preexistente e mudar todos os campos (exceto fabricante e estoque) para somente leitura
        //... Ativar {popover de incremento | campo} de estoque da janela de registro
    } else {
        //... Tornar editáveis todos os campos (exceto fabricante e estoque)
    }
}


- (void)buildRatingsMenu {
    _ratingsMenu = [[NSMenu alloc] initWithTitle:@""];
    for (int i = 0; i < [_ratingMenuTitles count]; i++) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:_ratingMenuTitles[i]
                                                          action:@selector(addSelectedRating:)
                                                   keyEquivalent:@""];
        [menuItem setTag:i];
        [menuItem setTarget:self];
        [_ratingsMenu addItem:menuItem];
    }
}


- (void)setDatePicker:(NSDatePicker *)datePicker enabled:(BOOL)enabled {
    [datePicker setEnabled:enabled];
    [datePicker setTextColor:enabled ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
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
    } else {
        [_dateUnknownCheckbox setState:NSControlStateValueOn];
        [_acquisitionDatePicker setDateValue:[NSDate date]]; //Data atual (GMT)
        [self setDatePicker:_acquisitionDatePicker enabled:NO];
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
