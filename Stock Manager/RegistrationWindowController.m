//
//  RegistrationWindowController.m
//  Stock Manager
//
//  Created by Douglas Almeida on 28/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "RegistrationWindowController.h"
#import "DatabaseController.h"
#import "ComponentRating.h"

@interface RegistrationWindowController ()

@property (weak) IBOutlet NSComboBox *manufacturerComboBox;
@property (weak) IBOutlet NSComboBox *componentTypeComboBox;
@property (weak) IBOutlet NSComboBox *packageCodeComboBox;
@property (weak) IBOutlet NSTextField *commentsTextField;
@property (weak) IBOutlet NSTableView *ratingsTableView;
@property (weak) IBOutlet NSView *noRatingsPlaceholderView;
@property (weak) IBOutlet NSSegmentedControl *ratingsSegmentedControl;

@property (weak) IBOutlet NSTextField *quantityTextField;
@property (weak) IBOutlet NSStepper *quantityStepper;
@property (weak) IBOutlet NSTextField *originTextField;
@property (weak) IBOutlet NSDatePicker *acquisitionDatePicker;
@property (weak) IBOutlet NSButton *dateUnknownCheckbox;

@property (weak) IBOutlet NSButton *registerButton;

@property NSString *lastManufacturerInput;
@property NSMenu *ratingAdditionMenu;
@property NSMutableArray<ComponentRating *> *componentRatings;
@property BOOL stockUpdateModeOn;
@property NSNumber *preexistingComponentID;

@end

@implementation RegistrationWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"RegistrationWindowController"];
    if (self) {
        _componentRatings = [[NSMutableArray alloc] init];
        _stockUpdateModeOn = NO;
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSArray *componentTypes = [[DatabaseController sharedController] componentTypes];
    [_componentTypeComboBox addItemsWithObjectValues:componentTypes];
    NSArray *manufacturers = [[DatabaseController sharedController] manufacturers];
    [_manufacturerComboBox addItemsWithObjectValues:manufacturers];
    NSArray *packageCodes = [[DatabaseController sharedController] packageCodes];
    [_packageCodeComboBox addItemsWithObjectValues:packageCodes];
    [_quantityStepper setMaxValue:FLT_MAX];
    [self buildRatingsMenu];
    [self loadPersistedInput];
    [self clearInputFieldsKeepManufacturer:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(popUpButtonWillPopUpNotification:)
                                                 name:@"NSPopUpButtonWillPopUpNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(componentRegisteredNotification:)
                                                 name:@"DBCComponentRegisteredNotification"
                                               object:nil];
}


- (IBAction)manufacturerComboBoxEdited:(id)sender {
    NSString *manufacturer = [[_manufacturerComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([manufacturer length] > 0 && ![manufacturer isEqualToString:_lastManufacturerInput]) {
        [self setLastManufacturerInput:manufacturer];
        [self checkIfExistingPartNumber:_partNumber manufacturer:manufacturer];
    }
}


- (IBAction)ratingValueEdited:(NSTextField *)sender {
    NSInteger selectedRow = [_ratingsTableView rowForView:sender];
    ComponentRating *rating = [_componentRatings objectAtIndex:selectedRow];
    NSInteger valueColumn = [_ratingsTableView columnWithIdentifier:@"RatingValue"];
    RatingValueTableCellView *selectedValueView = [_ratingsTableView viewAtColumn:valueColumn
                                                                              row:selectedRow
                                                                  makeIfNecessary:NO];
    NSTextField *textField = [selectedValueView textField];
    double newSignificand = [textField doubleValue];
    NSInteger magnitude = [rating orderOfMagnitude];
    [rating setValue: newSignificand * pow(10.0, magnitude)];
    // Sincronizar exibição com o valor gerado
    [textField setDoubleValue:[[rating significand] doubleValue]];
    NSPopUpButton *popUpButton = [selectedValueView popUpButton];
    [popUpButton selectItemWithTitle:[rating prefixedUnitSymbol]];
}


- (IBAction)ratingUnitSelected:(NSPopUpButton *)sender {
    NSInteger selectedRow = [_ratingsTableView rowForView:sender];
    ComponentRating *rating = [_componentRatings objectAtIndex:selectedRow];
    NSInteger valueColumn = [_ratingsTableView columnWithIdentifier:@"RatingValue"];
    RatingValueTableCellView *selectedValueView = [_ratingsTableView viewAtColumn:valueColumn
                                                                              row:selectedRow
                                                                  makeIfNecessary:NO];
    NSPopUpButton *popUpButton = [selectedValueView popUpButton];
    NSString *selectedTitle = [popUpButton titleOfSelectedItem];
    NSString *selectedPrefix = [selectedTitle stringByReplacingOccurrencesOfString:[rating unitSymbol]
                                                                        withString:@""];
    NSInteger newMagnitude;
    if ([ComponentRating magnitude:&newMagnitude forPrefix:selectedPrefix]) {
        double significand = [[rating significand] doubleValue];
        [rating setValue: significand * pow(10.0, newMagnitude)];
        // Sincronizar seleção com o valor gerado
        [popUpButton selectItemWithTitle:[rating prefixedUnitSymbol]];
    }
}


- (IBAction)ratingsSegmentedControlClicked:(id)sender {
    NSInteger selectedItem = [_ratingsSegmentedControl selectedSegment];
    if (selectedItem == 0) {
        NSPoint menuLocation = NSMakePoint(0, [sender frame].size.height);
        [_ratingAdditionMenu popUpMenuPositioningItem:nil atLocation:menuLocation inView:sender];
    } else if (selectedItem == 1) {
        [self removeSelectedRatings];
    } else if (selectedItem == 2) {
        [_ratingsTableView deselectAll:nil];
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


- (IBAction)registerButtonClicked:(id)sender {
    if ([self stockUpdateModeOn]) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:@{
            @"component_id" : _preexistingComponentID
        }];
        [self addAcquisitionInfoToParameters:parameters];
        [[DatabaseController sharedController] stockReplenishmentWithParameters:parameters];
    } else {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:@{
            @"part_number" : _partNumber
        }];
        NSString *manufacturer = [[_manufacturerComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([manufacturer length] > 0) {
            [parameters setObject:manufacturer forKey:@"manufacturer"];
        }
        NSString *componentType = [[_componentTypeComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![componentType length]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSAlertStyleInformational];
            [alert setMessageText:@"The Component's Type Must Be Informed."];
            [alert runModal];
            [[self window] makeFirstResponder:_componentTypeComboBox];
            return;
        }
        [parameters setObject:componentType forKey:@"component_type"];
        NSString *packageCode = [[_packageCodeComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([packageCode length] > 0) {
            [parameters setObject:packageCode forKey:@"package_code"];
        }
        NSString *comments = [[_commentsTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([comments length] > 0) {
            [parameters setObject:comments forKey:@"comments"];
        }
        for (ComponentRating *rating in _componentRatings) {
            if ([rating isKindOfClass:[VoltageRating class]]) {
                [parameters setObject:rating forKey:@"voltage_rating"];
            } else if ([rating isKindOfClass:[CurrentRating class]]) {
                [parameters setObject:rating forKey:@"current_rating"];
            } else if ([rating isKindOfClass:[PowerRating class]]) {
                [parameters setObject:rating forKey:@"power_rating"];
            } else if ([rating isKindOfClass:[ResistanceRating class]]) {
                [parameters setObject:rating forKey:@"resistance_rating"];
            } else if ([rating isKindOfClass:[InductanceRating class]]) {
                [parameters setObject:rating forKey:@"inductance_rating"];
            } else if ([rating isKindOfClass:[CapacitanceRating class]]) {
                [parameters setObject:rating forKey:@"capacitance_rating"];
            } else if ([rating isKindOfClass:[FrequencyRating class]]) {
                [parameters setObject:rating forKey:@"frequency_rating"];
            } else if ([rating isKindOfClass:[ToleranceRating class]]) {
                [parameters setObject:rating forKey:@"tolerance_rating"];
            }
        }
        [self addAcquisitionInfoToParameters:parameters];
        [[DatabaseController sharedController] registerComponentWithParameters:parameters];
    }
    [self persistLastAcquisitionInput];
    [self close];
}


- (IBAction)cancelButtonClicked:(id)sender {
    [self close];
}


- (void)addAcquisitionInfoToParameters:(NSMutableDictionary *)parameters {
    NSUInteger quantity = [_quantityTextField integerValue];
    [parameters setObject:[NSNumber numberWithInteger:quantity] forKey:@"quantity"];
    NSString *origin = [[_originTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([origin length] > 0) {
        [parameters setObject:origin forKey:@"origin"];
    }
    if ([_dateUnknownCheckbox state] == NSControlStateValueOff) {
        NSDate *dateAcquired = [DatabaseController dateWithClearedTimeComponentsFromDate:[_acquisitionDatePicker dateValue]];
        [parameters setObject:dateAcquired forKey:@"date_acquired"];
    }
}


- (void)clearInputFieldsKeepManufacturer:(BOOL)keepManufacturer {
    if ([self stockUpdateModeOn]) {
        [self setStockUpdateModeOn:NO];
        [[self window] setTitle:@"Register New Component"];
        [[self registerButton] setTitle:@"Register"];
        [_componentTypeComboBox setEnabled:YES];
        [_packageCodeComboBox setEnabled:YES];
        [_commentsTextField setEnabled:YES];
        [_ratingsTableView setEnabled:YES];
    }
    if (!keepManufacturer) {
        [_manufacturerComboBox setStringValue:@""];
        [self setLastManufacturerInput:nil];
    }
    [_componentTypeComboBox setStringValue:@""];
    [_packageCodeComboBox setStringValue:@""];
    [_commentsTextField setStringValue:@""];
    [self clearRatingsTable];
    [self loadPersistedInput];
    [_quantityStepper setIntValue:1];
    [_quantityTextField setIntValue:1];
    [[self window] makeFirstResponder:_manufacturerComboBox];
}


- (void)clearRatingsTable {
    [_componentRatings removeAllObjects];
    [_ratingsTableView deselectAll:nil];
    [_ratingsTableView reloadData];
    [_noRatingsPlaceholderView setHidden:NO];
    for (NSMenuItem *menuItem in [_ratingAdditionMenu itemArray]) {
        [menuItem setHidden:NO];
    }
    [_ratingsSegmentedControl setEnabled:YES forSegment:0];
}


- (void)addSelectedRating:(NSMenuItem *)menuItem {
    ComponentRating *rating = nil;
    switch ([menuItem tag]) {
        case 0:
            rating = [[VoltageRating alloc] init];
            break;
        case 1:
            rating = [[CurrentRating alloc] init];
            break;
        case 2:
            rating = [[PowerRating alloc] init];
            break;
        case 3:
            rating = [[ResistanceRating alloc] init];
            break;
        case 4:
            rating = [[InductanceRating alloc] init];
            break;
        case 5:
            rating = [[CapacitanceRating alloc] init];
            break;
        case 6:
            rating = [[FrequencyRating alloc] init];
            break;
        case 7:
            rating = [[ToleranceRating alloc] init];
            break;
        default:
            break;
    }
    if ([_componentRatings count] == 0) {
        [_noRatingsPlaceholderView setHidden:YES];
    }
    [_componentRatings insertObject:rating atIndex:0];
    [_ratingsTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             withAnimation:NSTableViewAnimationSlideDown];
    [menuItem setHidden:YES];
    if ([_componentRatings count] == [[ComponentRating ratingNames] count]) {
        [_ratingsSegmentedControl setEnabled:NO forSegment:0];
    }
}


- (void)removeSelectedRatings {
    NSIndexSet *selectedRows = [_ratingsTableView selectedRowIndexes];
    [_ratingsTableView removeRowsAtIndexes:selectedRows withAnimation:NSTableViewAnimationSlideUp];
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        ComponentRating *rating = _componentRatings[idx];
        NSString *menuTitle = [rating name];
        NSMenuItem *menuItem = [self->_ratingAdditionMenu itemWithTitle:menuTitle];
        [menuItem setHidden:NO];
    }];
    [_componentRatings removeObjectsAtIndexes:selectedRows];
    if ([_componentRatings count] == 0) {
        [_noRatingsPlaceholderView setHidden:NO];
    }
    [_ratingsSegmentedControl setEnabled:YES forSegment:0];
}


- (void)checkIfExistingPartNumber:(NSString *)partNumber manufacturer:(NSString *)manufacturer {
    NSDictionary *previousRecord = [[DatabaseController sharedController] recordForPartNumber:partNumber
                                                                                 manufacturer:manufacturer];
    if (previousRecord) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert setMessageText:[NSString stringWithFormat:@"%@ from manufacturer %@ is already on the database.", _partNumber, manufacturer]];
        NSInteger quantity = [[previousRecord objectForKey:@"quantity"] integerValue];
        [alert setInformativeText:[NSString stringWithFormat:@"Its current stock is %ld unit%@.", quantity, quantity == 1 ? @"" : @"s"]];
        [alert runModal];
        [self setPreexistingComponentID:[previousRecord objectForKey:@"component_id"]];
        // Exibir os dados retornados para o componente preexistente
        [self setStockUpdateModeOn:YES];
        [[self window] setTitle:@"Update Component Stock"];
        [[self registerButton] setTitle:@"Update"];
        [_componentTypeComboBox setStringValue:[previousRecord objectForKey:@"component_type"] ?: @""];
        [_componentTypeComboBox setEnabled:NO];
        [_packageCodeComboBox setStringValue:[previousRecord objectForKey:@"package_code"] ?: @""];
        [_packageCodeComboBox setEnabled:NO];
        [_commentsTextField setStringValue:[previousRecord objectForKey:@"comments"] ?: @""];
        [_commentsTextField setEnabled:NO];
        [_ratingsTableView setEnabled:NO];
        [self showRatingsOnRecord:previousRecord];
        [_ratingsSegmentedControl setEnabled:NO forSegment:0];
        [[self window] makeFirstResponder:_quantityTextField];
    } else if ([self stockUpdateModeOn]) {
        [self clearInputFieldsKeepManufacturer:YES];
    }
}


- (void)showRatingsOnRecord:(NSDictionary *)record {
    [_componentRatings removeAllObjects];
    ComponentRating *rating = [record objectForKey:@"voltage_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"current_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"power_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"resistance_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"inductance_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"capacitance_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"frequency_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    rating = [record objectForKey:@"tolerance_rating"];
    if (rating) {
        [_componentRatings addObject:rating];
    }
    if ([_componentRatings count] > 0) {
        [_noRatingsPlaceholderView setHidden:YES];
    }
    [_ratingsTableView deselectAll:nil];
    [_ratingsTableView reloadData];
}


- (void)buildRatingsMenu {
    [self setRatingAdditionMenu:[[NSMenu alloc] initWithTitle:@""]];
    NSArray *ratingNames = [ComponentRating ratingNames];
    for (int i = 0; i < [ratingNames count]; i++) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:ratingNames[i]
                                                          action:@selector(addSelectedRating:)
                                                   keyEquivalent:@""];
        [menuItem setTag:i];
        [menuItem setTarget:self];
        [_ratingAdditionMenu addItem:menuItem];
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


- (void)clearInputForm {
    [self clearInputFieldsKeepManufacturer:NO];
}

#pragma mark - NSTextFieldDelegate

-(void)controlTextDidChange:(NSNotification *)obj {
    // Campo de texto de quantidade
    int quantity = [_quantityTextField intValue];
    [_quantityStepper setIntValue:quantity];
}


-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [_ratingsTableView selectedRow];
    if (selectedRow < 0) {
        [_ratingsSegmentedControl setEnabled:NO forSegment:1];
    } else {
        [_ratingsSegmentedControl setEnabled:YES forSegment:1];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_componentRatings count];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Os identificadores das colunas e de suas respectivas vistas são idênticos
    ComponentRating *rating = _componentRatings[row];
    NSString *columnID = [tableColumn identifier];
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:columnID owner:self];
    if ([columnID isEqualToString:@"RatingName"]) {
        NSTextField *textField = [cellView textField];
        [textField setStringValue:[rating name]];
    } else if ([columnID isEqualToString:@"RatingValue"]) {
        NSTextField *textField = [cellView textField];
        [textField setDoubleValue:[[rating significand] doubleValue]];
        [textField setEnabled:![self stockUpdateModeOn]];
        NSPopUpButton *popUpButton = [(RatingValueTableCellView *)cellView popUpButton];
        [popUpButton removeAllItems]; //Caso a vista esteja sendo reutilizada
        [popUpButton addItemsWithTitles:[rating allPrefixedUnitSymbols]];
        [popUpButton selectItemWithTitle:[rating prefixedUnitSymbol]];
        [popUpButton setEnabled:![self stockUpdateModeOn]];
    }
    return cellView;
}

#pragma mark - Notification Handlers

- (void)popUpButtonWillPopUpNotification:(NSNotification *)notification {
    // Finalizar a edição em um campo de texto ao abrir o menu de um botão PopUp
    [[self window] makeFirstResponder:_ratingsTableView];
}


- (void)componentRegisteredNotification:(NSNotification *)notification {
    NSArray *componentTypes = [[DatabaseController sharedController] componentTypes];
    [_componentTypeComboBox removeAllItems];
    [_componentTypeComboBox addItemsWithObjectValues:componentTypes];
    NSArray *manufacturers = [[DatabaseController sharedController] manufacturers];
    [_manufacturerComboBox removeAllItems];
    [_manufacturerComboBox addItemsWithObjectValues:manufacturers];
    NSArray *packageCodes = [[DatabaseController sharedController] packageCodes];
    [_packageCodeComboBox removeAllItems];
    [_packageCodeComboBox addItemsWithObjectValues:packageCodes];
}

@end

#pragma mark - RatingValueTableCellView

@implementation RatingValueTableCellView

@end
