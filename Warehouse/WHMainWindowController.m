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

@property (weak) IBOutlet NSSearchField *partNumberSearchField;
@property (weak) IBOutlet NSPopUpButton *componentTypeSelectionButton;
@property (weak) IBOutlet NSPopover *selectedStockIncrementPopover;
@property (weak) IBOutlet NSPopover *selectedStockDecrementPopover;
@property (weak) IBOutlet NSPopover *selectedStockHistoryPopover;
@property (weak) IBOutlet NSTableView *searchResultsTableView;
@property (weak) IBOutlet NSTableView *stockReplenishmentsTableView;
@property (weak) IBOutlet NSTableView *stockWithdrawalsTableView;
@property (weak) IBOutlet NSButton *increaseSelectedStockButton; //... Mover p/ WHStockIncrementViewController
@property (weak) IBOutlet NSButton *decreaseSelectedStockButton; //... Mover p/ WHStockDecrementViewController
@property (weak) IBOutlet NSButton *stockHistoryButton;
@property WHRegistrationWindowController *registrationWindowController;
@property NSArray *searchResults;
@property NSArray *stockReplenishments;
@property NSArray *stockWithdrawals;

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
    [_componentTypeSelectionButton addItemsWithTitles:componentTypes];
}


- (IBAction)partNumberSearchFieldEdited:(id)sender {
    NSString *partNumber = [[_partNumberSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([partNumber length] > 0) {
        NSString *manufacturer;
        //... Verificar filtragem por fabricante
        NSArray<NSDictionary *> *searchResults;
        searchResults = [[_appDelegate databaseController] searchResultsForIncrementalPartNumber:partNumber
                                                                                    manufacturer:manufacturer];
        [self updateSearchResults:searchResults];
    } else {
        [_partNumberSearchField setStringValue:@""];
        [self clearSearchResults];
    }
}

- (IBAction)componentTypePopupSelected:(id)sender {
    [_partNumberSearchField abortEditing];
    [_partNumberSearchField setStringValue:@""];
    if ([_componentTypeSelectionButton indexOfSelectedItem] > 1) {
        NSString *componentType = [_componentTypeSelectionButton titleOfSelectedItem];
        NSMutableDictionary *searchCriteria;
        //... Levantar critérios de filtragem
        NSArray<NSDictionary *> *searchResults;
        searchResults = [[_appDelegate databaseController] searchResultsForComponentType:componentType
                                                                                criteria:searchCriteria];
        [self updateSearchResults:searchResults];
    } else {
        [self clearSearchResults];
    }
}


- (IBAction)increaseSelectedStockButtonClicked:(id)sender {
    //... Limpar campos e carregar auto-compleção para o campo origem
    [_selectedStockIncrementPopover showRelativeToRect:[sender bounds]
                                            ofView:sender
                                     preferredEdge:NSMinYEdge];
}


- (IBAction)decreaseSelectedStockButtonClicked:(id)sender {
    //... Limpar campos e carregar auto-compleção para o campo destino
    [_selectedStockDecrementPopover showRelativeToRect:[sender bounds]
                                            ofView:sender
                                     preferredEdge:NSMinYEdge];
}


- (IBAction)stockHistoryButtonClicked:(id)sender {
    NSInteger selectedRow = [_searchResultsTableView selectedRow];
    NSString *partNumber = _searchResults[selectedRow][@"part_number"];
    NSString *manufacturer = _searchResults[selectedRow][@"manufacturer"];
    _stockReplenishments = [[_appDelegate databaseController] stockReplenishmentsForPartNumber:partNumber
                                                                                  manufacturer:manufacturer];
    [_stockReplenishmentsTableView reloadData];
    _stockWithdrawals = [[_appDelegate databaseController] stockWithdrawalsForPartNumber:partNumber
                                                                            manufacturer:manufacturer];
    [_stockWithdrawalsTableView reloadData];
    [_selectedStockHistoryPopover showRelativeToRect:[sender bounds]
                                      ofView:sender
                               preferredEdge:NSMinYEdge];
}


- (IBAction)addToStockButtonClicked:(id)sender {
    //... SQL UPDATE
    [_selectedStockIncrementPopover close];
}


- (IBAction)deductFromStockButtonClicked:(id)sender {
    //... SQL UPDATE
    [_selectedStockDecrementPopover close];
}


- (IBAction)enrollComponentButtonClicked:(id)sender {
    if (!_registrationWindowController) {
        _registrationWindowController = [[WHRegistrationWindowController alloc] init];
    }
    //... Limpar/preencher campos (obter dicas de campos preenchidos dajanela principal) e popular auto-compleção
    [_registrationWindowController showWindow:nil];
}


- (void)updateSearchResults:(NSArray<NSDictionary *> *)results {
    _searchResults = results;
    [_searchResultsTableView deselectAll:nil];
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
    [_searchResultsTableView deselectAll:nil];
    for (NSString *columnID in WH_NULLABLE_COLUMNS) {
        NSTableColumn *tableColumn = [_searchResultsTableView tableColumnWithIdentifier:columnID];
        [tableColumn setHidden:YES];
    }
    [_searchResultsTableView reloadData];
}

#pragma mark - NSControlTextEditingDelegate

-(void)controlTextDidBeginEditing:(NSNotification *)obj {
    NSString *controlID = [[obj object] identifier];
    if ([controlID isEqualToString:[_partNumberSearchField identifier]]) {
        [_componentTypeSelectionButton selectItemAtIndex:0];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSString *tableID = [tableView identifier];
    if ([tableID isEqualToString:[_stockReplenishmentsTableView identifier]]) {
        return [_stockReplenishments count];
    } else if ([tableID isEqualToString:[_stockWithdrawalsTableView identifier]]) {
        return [_stockWithdrawals count];
    } else /* Tabela de resultados de busca */ {
        return [_searchResults count];
    }
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *tableID = [tableView identifier];
    NSString *columnID = [tableColumn identifier];
    id value;
    if ([tableID isEqualToString:[_stockReplenishmentsTableView identifier]]) {
        NSDictionary *entry = _stockReplenishments[row];
        value = entry[columnID];
    } else if ([tableID isEqualToString:[_stockWithdrawalsTableView identifier]]) {
        NSDictionary *entry = _stockWithdrawals[row];
        value = entry[columnID];
    } else /* Tabela de resultados de busca */ {
        NSDictionary *result = _searchResults[row];
        value = result[columnID];
    }
    //... Criar NSDates para um grupo seleto de colunas
    return [value isEqual:[NSNull null]] ? @"" : value;
}

#pragma mark - NSTableViewDelegate

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Tabela de resultados de busca
    NSInteger selectedRow = [_searchResultsTableView selectedRow];
    if (selectedRow < 0) {
        [_stockHistoryButton setEnabled:NO];
        [_increaseSelectedStockButton setEnabled:NO];
        [_decreaseSelectedStockButton setEnabled:NO];
    } else {
        [_stockHistoryButton setEnabled:YES];
        [_increaseSelectedStockButton setEnabled:YES];
        [_decreaseSelectedStockButton setEnabled:YES];
    }
}

@end
