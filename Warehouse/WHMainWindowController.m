//
//  WHMainWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHMainWindowController.h"
#import "WHRegistrationWindowController.h"
#import "AppDelegate.h"

#define WH_NULLABLE_COLUMNS @[  \
    @"voltage_rating",          \
    @"current_rating",          \
    @"power_rating",            \
    @"resistance_rating",       \
    @"inductance_rating",       \
    @"capacitance_rating",      \
    @"frequency_rating",        \
    @"tolerance_rating",        \
    @"package_code",            \
    @"comments"                 \
]

@interface WHMainWindowController ()

@property (weak) IBOutlet NSTextField *partNumberSearchField;
@property (weak) IBOutlet NSComboBox *componentTypeSearchBox;
@property (weak) IBOutlet NSPopover *selectedItemAdditionPopover;
@property (weak) IBOutlet NSPopover *selectedItemRemovalPopover;
@property (weak) IBOutlet NSPopover *stockHistoryPopover;
@property (weak) IBOutlet NSTableView *searchResultsTableView;
@property WHRegistrationWindowController *registrationWindowController;
@property NSString *lastSearchedPartNumber;
@property NSString *lastSearchedComponentType;
@property NSArray *searchResults;

@end

@implementation WHMainWindowController

- (instancetype)initWithAppDelegate:(AppDelegate *)delegate {
    self = [super initWithWindowNibName:@"WHMainWindowController"];
    if (self) {
        _appDelegate = delegate;
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSArray *componentTypes = [[_appDelegate databaseController] componentTypes];
    [_componentTypeSearchBox addItemsWithObjectValues:componentTypes];
    [_componentTypeSearchBox setNumberOfVisibleItems:0.4 * [componentTypes count]];
}


- (IBAction)partNumberSearchFieldEdited:(id)sender {
    NSString *partNumber = [[_partNumberSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([partNumber length] > 0) {
        if (![partNumber isEqualToString:_lastSearchedPartNumber]) {
            _lastSearchedPartNumber = partNumber;
            NSString *manufacturer;
            //... Verificar filtragem por fabricante
            NSArray<NSDictionary *> *searchResults = [[_appDelegate databaseController] searchResultsForPartNumber:partNumber
                                                                                 manufacturer:manufacturer];
            [self updateSearchResults:searchResults];
        }
    } else {
        [_partNumberSearchField setStringValue:@""];
        [self clearSearchResults];
    }
}


- (IBAction)componentTypeSearchBoxEdited:(id)sender {
    NSString *componentType = [[_componentTypeSearchBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([componentType length] > 0) {
        if (![componentType isEqualToString:_lastSearchedComponentType]) {
            _lastSearchedComponentType = componentType;
            [_componentTypeSearchBox selectText:nil];
            NSMutableDictionary *searchCriteria;
            //... Levantar critérios de filtragem
            NSArray<NSDictionary *> *searchResults = [[_appDelegate databaseController] searchResultsForComponentType:componentType
                                                                                        criteria:searchCriteria];
            [self updateSearchResults:searchResults];
        }
    } else {
        [_componentTypeSearchBox setStringValue:@""];
        [self clearSearchResults];
    }
}


- (IBAction)enrollComponentButtonClicked:(id)sender {
    if (!_registrationWindowController) {
        _registrationWindowController = [[WHRegistrationWindowController alloc] init];
    }
    //... Limpar/preencher campos (obter dicas de campos preenchidos dajanela principal) e popular auto-compleção
    [_registrationWindowController showWindow:nil];
}


- (IBAction)selectedItemAdditionButtonClicked:(id)sender {
    //... Limpar campos e carregar auto-compleção para o campo origem
    [_selectedItemAdditionPopover showRelativeToRect:[sender bounds]
                                            ofView:sender
                                     preferredEdge:NSMinYEdge];
}


- (IBAction)selectedItemRemovalButtonClicked:(id)sender {
    //... Limpar campos e carregar auto-compleção para o campo destino
    [_selectedItemRemovalPopover showRelativeToRect:[sender bounds]
                                            ofView:sender
                                     preferredEdge:NSMinYEdge];
}


- (IBAction)stockHistoryButtonClicked:(id)sender {
    //... Popular tabelas
    [_stockHistoryPopover showRelativeToRect:[sender bounds]
                                      ofView:sender
                               preferredEdge:NSMinYEdge];
}


- (IBAction)addToStockButtonClicked:(id)sender {
    //... SQL UPDATE
    [_selectedItemAdditionPopover close];
}


- (IBAction)deductFromStockButtonClicked:(id)sender {
    //... SQL UPDATE
    [_selectedItemRemovalPopover close];
}


- (void)updateSearchResults:(NSArray<NSDictionary *> *)results {
    _searchResults = results;
    for (NSString *columnID in WH_NULLABLE_COLUMNS) {
        NSTableColumn *column = [_searchResultsTableView tableColumnWithIdentifier:columnID];
        [column setHidden:YES];
        for (NSDictionary *row in results) {
            if (![row[columnID] isEqual:[NSNull null]]) {
                [column setHidden:NO];
            }
        }
    }
    [_searchResultsTableView reloadData];
}


- (void)clearSearchResults {
    _searchResults = nil;
    for (NSString *columnID in WH_NULLABLE_COLUMNS) {
        NSTableColumn *tableColumn = [_searchResultsTableView tableColumnWithIdentifier:columnID];
        [tableColumn setHidden:YES];
    }
    [_searchResultsTableView reloadData];
    [_partNumberSearchField setStringValue:@""];
    [_componentTypeSearchBox setStringValue:@""];
}

#pragma mark - NSControlTextEditingDelegate

-(BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(cancelOperation:)) {
        // Tecla ESC pressionada na caixa de texto
        [self clearSearchResults];
        return YES;
    }
    return NO; //Ação não tratada aqui
}


-(void)controlTextDidBeginEditing:(NSNotification *)obj {
    NSString *controlID = [[obj object] identifier];
    if ([controlID isEqualToString:[_partNumberSearchField identifier]]) {
        [_componentTypeSearchBox setStringValue:@""];
    } else if ([controlID isEqualToString:[_componentTypeSearchBox identifier]]) {
        [_partNumberSearchField setStringValue:@""];
    }
}

#pragma mark - NSComboBoxDelegate

-(void)comboBoxSelectionDidChange:(NSNotification *)notification {
    NSString *controlID = [[notification object] identifier];
    if ([controlID isEqualToString:[_componentTypeSearchBox identifier]]) {
        [_partNumberSearchField setStringValue:@""];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_searchResults count]; //Tabela de resultados de pesquisa
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Tabela de resultados de pesquisa
    NSDictionary *result = [_searchResults objectAtIndex:row];
    NSString *columnID = [tableColumn identifier];
    id tableCell = result[columnID];
    return [tableCell isEqual:[NSNull null]] ? @"" : tableCell;
}

@end
