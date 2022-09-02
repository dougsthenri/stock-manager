//
//  WHMainWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHMainWindowController.h"
#import "WHDatabaseController.h"
#import "WHRegistrationWindowController.h"
#import "WHStockIncrementViewController.h"
#import "WHStockDecrementViewController.h"

@interface WHMainWindowController ()

@property (weak) IBOutlet NSSearchField *partNumberSearchField;
@property (weak) IBOutlet NSPopUpButton *componentTypeSelectionButton;
@property (weak) IBOutlet NSPopover *selectedStockIncrementPopover;
@property (weak) IBOutlet NSPopover *selectedStockDecrementPopover;
@property (weak) IBOutlet NSPopover *selectedStockHistoryPopover;
@property (weak) IBOutlet NSTableView *searchResultsTableView;
@property (weak) IBOutlet NSTableView *stockReplenishmentsTableView;
@property (weak) IBOutlet NSTableView *stockWithdrawalsTableView;
@property (weak) IBOutlet NSButton *addPartNumberButton;
@property (weak) IBOutlet NSButton *increaseSelectedStockButton;
@property (weak) IBOutlet NSButton *decreaseSelectedStockButton;
@property (weak) IBOutlet NSButton *stockHistoryButton;

@property (weak) WHDatabaseController *databaseController; //... IBOutlet para dbCtlr de janelas e vistas filhas? Ou usar classe "singleton" para o gerenciador do banco de dados inicializado em AppDelegate
@property WHRegistrationWindowController *registrationWindowController;
@property NSArray *searchResults;
@property NSArray *stockReplenishments;
@property NSArray *stockWithdrawals;

@end

@implementation WHMainWindowController

- (instancetype)initWithDatabaseController:(WHDatabaseController *)controller {
    self = [super initWithWindowNibName:@"WHMainWindowController"];
    if (self) {
        _databaseController = controller;
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSArray *componentTypes = [_databaseController componentTypes];
    [_componentTypeSelectionButton addItemsWithTitles:componentTypes];
}


- (IBAction)partNumberSearchFieldEdited:(id)sender {
    NSString *partNumber = [[_partNumberSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([partNumber length] > 0) {
        [_addPartNumberButton setEnabled:YES];
        NSString *manufacturer; //... Será sempre "nil" aqui. A filtragem por "manufacturer" ocorre após a busca por Part#
        //... Verificar filtragem por fabricante, apenas. Limpar todos os [outros] filtros?
        NSArray<NSDictionary *> *searchResults;
        searchResults = [_databaseController incrementalSearchResultsForPartNumber:partNumber
                                                                      manufacturer:manufacturer];
        [self updateSearchResults:searchResults];
    } else {
        [_addPartNumberButton setEnabled:NO];
        [_partNumberSearchField setStringValue:@""];
        [self updateSearchResults:nil];
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
        searchResults = [_databaseController searchResultsForComponentType:componentType
                                                                  criteria:searchCriteria];
        [self updateSearchResults:searchResults];
    } else {
        [self updateSearchResults:nil];
    }
}


- (IBAction)increaseSelectedStockButtonClicked:(id)sender {
    [_selectedStockIncrementPopover showRelativeToRect:[sender bounds]
                                                ofView:sender
                                         preferredEdge:NSMinYEdge];
}


- (IBAction)decreaseSelectedStockButtonClicked:(id)sender {
    [_selectedStockDecrementPopover showRelativeToRect:[sender bounds]
                                                ofView:sender
                                         preferredEdge:NSMinYEdge];
}


- (IBAction)stockHistoryButtonClicked:(id)sender {
    NSInteger selectedRow = [_searchResultsTableView selectedRow];
    NSString *partNumber = _searchResults[selectedRow][@"part_number"];
    NSString *manufacturer = _searchResults[selectedRow][@"manufacturer"];
    _stockReplenishments = [_databaseController stockReplenishmentsForPartNumber:partNumber
                                                                    manufacturer:manufacturer];
    [_stockReplenishmentsTableView reloadData];
    [_stockReplenishmentsTableView deselectAll:nil];
    _stockWithdrawals = [_databaseController stockWithdrawalsForPartNumber:partNumber
                                                              manufacturer:manufacturer];
    [_stockWithdrawalsTableView reloadData];
    [_stockWithdrawalsTableView deselectAll:nil];
    [_selectedStockHistoryPopover showRelativeToRect:[sender bounds]
                                              ofView:sender
                                       preferredEdge:NSMinYEdge];
}


- (IBAction)addPartNumberButtonClicked:(id)sender {
    if (!_registrationWindowController) {
        _registrationWindowController = [[WHRegistrationWindowController alloc] initWithDatabaseController:_databaseController];
    }
    [_registrationWindowController clearInputForm];
    [_registrationWindowController setPartNumber:[_partNumberSearchField stringValue]];
    [_registrationWindowController showWindow:nil];
}


- (void)updateSearchResults:(NSArray<NSDictionary *> *)results {
    _searchResults = results;
    [_searchResultsTableView deselectAll:nil];
    for (NSString *columnID in WH_NULLABLE_COLUMNS_STOCK) {
        NSTableColumn *column = [_searchResultsTableView tableColumnWithIdentifier:columnID];
        [column setHidden:YES];
        for (NSDictionary *row in results) {
            if (![row[columnID] isEqual:[NSNull null]]) {
                [column setHidden:NO];
            }
        }
    }
    [_searchResultsTableView reloadData];
    if (_searchResults) {
        //... Habilitar seleção de filtros?
    } else {
        //... Limpar todos os filtros [e desabilitar seleção deles]?
    }
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
    // Condicionar valor para exibição
    if ([value isEqual:[NSNull null]]) {
        value = @"";
    } else if ([WH_DATE_COLUMNS containsObject:columnID]) {
        NSDate *date = [_databaseController decodeDate:value];
        value = date;
    }
    return value;
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
