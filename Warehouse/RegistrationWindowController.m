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

@property NSString *lastManufacturerInput;
@property NSMenu *ratingAdditionMenu;
@property NSMutableArray *componentRatings; //UNDO MARK

@end

@implementation RegistrationWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"RegistrationWindowController"];
    if (self) {
        _componentRatings = [[NSMutableArray alloc] init];
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
    [self clearInputForm];
}


- (IBAction)manufacturerComboBoxEdited:(id)sender {
    NSString *manufacturer = [[_manufacturerComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([manufacturer length] > 0 && ![manufacturer isEqualToString:_lastManufacturerInput]) {
        _lastManufacturerInput = manufacturer;
        [self checkExistingPartNumber:_partNumber manufacturer:manufacturer];
    }
}


- (IBAction)ratingValueEdited:(NSTextField *)sender {
    NSInteger selectedRow = [_ratingsTableView rowForView:sender];
    //... registrar valor
    NSLog(@"Editou na linha %ld", selectedRow); //***
}


- (IBAction)ratingUnitSelected:(NSPopUpButton *)sender {
    NSInteger selectedRow = [_ratingsTableView rowForView:sender];
    //... registrar magnitude
    NSLog(@"Selecionou na linha %ld", selectedRow); //***
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
    //... Verificar campos obrigatórios. O campo do fabricante pode ser deixado vazio (fabricante desconhecido, inserido como nulo)
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
    [_componentRatings insertObject:rating atIndex:0];
    [_noRatingsPlaceholderView setHidden:YES];
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


- (void)checkExistingPartNumber:(NSString *)partNumber manufacturer:(NSString *)manufacturer {
    NSDictionary *previousRecord = [[DatabaseController sharedController] recordForPartNumber:partNumber
                                                                                 manufacturer:manufacturer];
    if (previousRecord) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert setMessageText:[NSString stringWithFormat:@"%@ from manufacturer %@ is already on the database.", _partNumber, manufacturer]];
        NSInteger quantity = [[previousRecord objectForKey:@"quantity"] integerValue];
        [alert setInformativeText:[NSString stringWithFormat:@"Its current stock is %ld unit%@.", quantity, quantity == 1 ? @"" : @"s"]];
        [alert runModal];
        //... Preencher os dados retornados para o part# preexistente e mudar todos os campos (exceto fabricante e estoque) para somente leitura (ou desabilitá-los)
        //... Ativar campo de estoque
    } else {
        //... Tornar editáveis (ou reabilitar) todos os campos exceto fabricante e estoque
    }
}


- (void)buildRatingsMenu {
    _ratingAdditionMenu = [[NSMenu alloc] initWithTitle:@""];
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
        //...
    }
    return cellView;
}

@end
