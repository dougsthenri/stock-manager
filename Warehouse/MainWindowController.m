//
//  MainWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "MainWindowController.h"
#import "DatabaseController.h"
#import "RegistrationWindowController.h"
#import "StockIncrementViewController.h"
#import "StockDecrementViewController.h"

// Para controles segmentados como aqueles nos rodapés das tabelas
#define HISTORY_BUTTON_SEGMENT_INDEX   2

@interface MainWindowController ()

@property (weak) IBOutlet NSSearchField *partNumberSearchField;
@property (weak) IBOutlet NSButton *addPartNumberButton;
@property (weak) IBOutlet NSPopUpButton *componentTypeSelectionButton;

@property (weak) IBOutlet NSPopover *selectedStockIncrementPopover;
@property (weak) IBOutlet NSPopover *selectedStockDecrementPopover;
@property (weak) IBOutlet NSPopover *selectedStockHistoryPopover;
@property (weak) IBOutlet NSSegmentedControl *stockActionsSegmentedControl;

@property (weak) IBOutlet NSTableView *searchResultsTableView;
@property (weak) IBOutlet NSTableView *stockReplenishmentsTableView;
@property (weak) IBOutlet NSTableView *stockWithdrawalsTableView;

@property (weak) DatabaseController *databaseController;
@property RegistrationWindowController *registrationWindowController;
@property NSMutableArray *searchResults;
@property NSMutableArray *stockReplenishments;
@property NSMutableArray *stockWithdrawals;
@property NSDateFormatter *dateFormatter;
@property NSNumberFormatter *percentFormatter;

@end

@implementation MainWindowController

- (instancetype)initWithDatabaseController:(DatabaseController *)controller {
    self = [super initWithWindowNibName:@"MainWindowController"];
    if (self) {
        _databaseController = controller;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];
        _percentFormatter = [[NSNumberFormatter alloc] init];
        [_percentFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        [_percentFormatter setMultiplier:@1.0];
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSArray *componentTypes = [_databaseController componentTypes];
    [_componentTypeSelectionButton addItemsWithTitles:componentTypes];
    // Ocultar colunas anuláveis dos resultados de busca
    for (NSTableColumn *column in [_searchResultsTableView tableColumns]) {
        if ([_databaseController isNullableColumn:[column identifier] table:@"stock"]) {
            [column setHidden:YES];
        }
    }
    [_searchResultsTableView sizeToFit];
}


- (IBAction)partNumberSearchFieldEdited:(id)sender {
    NSString *partNumber = [[_partNumberSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([partNumber length] > 0) {
        [_addPartNumberButton setEnabled:YES];
        NSString *manufacturer; //... Será sempre "nil" aqui. A filtragem por "manufacturer" ocorre após a busca por Part#
        //... Verificar filtragem por fabricante, apenas. Limpar todos os [outros] filtros?
        _searchResults = [_databaseController incrementalSearchResultsForPartNumber:partNumber
                                                                       manufacturer:manufacturer];
        [self updateSearchResults];
    } else {
        [_addPartNumberButton setEnabled:NO];
        [_partNumberSearchField setStringValue:@""];
        _searchResults = nil;
        [self updateSearchResults];
    }
}

- (IBAction)componentTypePopupSelected:(id)sender {
    [_partNumberSearchField abortEditing];
    [_partNumberSearchField setStringValue:@""];
    NSString *componentType = [_componentTypeSelectionButton titleOfSelectedItem];
    NSMutableDictionary *searchCriteria;
    //... Levantar critérios de filtragem
    _searchResults = [_databaseController searchResultsForComponentType:componentType
                                                               criteria:searchCriteria];
    [self updateSearchResults];
}


- (IBAction)stockActionsSegmentedControlClicked:(id)sender {
    NSInteger selectedIndex = [_stockActionsSegmentedControl selectedSegment];
    if (selectedIndex == PLUS_BUTTON_SEGMENT_INDEX) {
        NSRect bounds = [MainWindowController relativeBoundsForSegmentedControl:sender
                                                                   segmentIndex:selectedIndex];
        [_selectedStockIncrementPopover showRelativeToRect:bounds
                                                    ofView:sender
                                             preferredEdge:NSMinYEdge];
    } else if (selectedIndex == MINUS_BUTTON_SEGMENT_INDEX) {
        NSRect bounds = [MainWindowController relativeBoundsForSegmentedControl:sender
                                                                   segmentIndex:selectedIndex];
        [_selectedStockDecrementPopover showRelativeToRect:bounds
                                                    ofView:sender
                                             preferredEdge:NSMinYEdge];
    } else if (selectedIndex == HISTORY_BUTTON_SEGMENT_INDEX) {
        NSInteger selectedRow = [_searchResultsTableView selectedRow];
        NSString *partNumber = _searchResults[selectedRow][@"part_number"];
        NSString *manufacturer = _searchResults[selectedRow][@"manufacturer"];
        _stockReplenishments = [_databaseController stockReplenishmentsForPartNumber:partNumber
                                                                        manufacturer:manufacturer];
        [_stockReplenishmentsTableView reloadData];
        [_stockReplenishmentsTableView deselectAll:nil];
        [_stockReplenishmentsTableView sizeToFit];
        _stockWithdrawals = [_databaseController stockWithdrawalsForPartNumber:partNumber
                                                                  manufacturer:manufacturer];
        [_stockWithdrawalsTableView reloadData];
        [_stockWithdrawalsTableView deselectAll:nil];
        [_stockWithdrawalsTableView sizeToFit];
        NSRect bounds = [MainWindowController relativeBoundsForSegmentedControl:sender
                                                                   segmentIndex:selectedIndex];
        [_selectedStockHistoryPopover showRelativeToRect:bounds
                                                  ofView:sender
                                           preferredEdge:NSMinYEdge];
    }
}


- (IBAction)addPartNumberButtonClicked:(id)sender {
    if (!_registrationWindowController) {
        _registrationWindowController = [[RegistrationWindowController alloc] initWithDatabaseController:_databaseController];
    }
    [_registrationWindowController clearInputForm];
    [_registrationWindowController setPartNumber:[_partNumberSearchField stringValue]];
    [_registrationWindowController showWindow:nil];
}


- (void)updateSearchResults {
    [_searchResultsTableView reloadData];
    [_searchResultsTableView deselectAll:nil];
    // Ocultar colunas inteiramente vazias
    for (NSTableColumn *column in [_searchResultsTableView tableColumns]) {
        NSString *columnID = [column identifier];
        if ([_databaseController isNullableColumn:columnID table:@"stock"]) {
            [column setHidden:YES];
            for (NSDictionary *result in _searchResults) {
                id value = result[columnID];
                if (![value isEqual:[NSNull null]]) {
                    [column setHidden:NO];
                    break;
                }
            }
        }
    }
    [_searchResultsTableView sizeToFit];
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
    if ([tableID isEqualToString:[_searchResultsTableView identifier]]) {
        return [_searchResults count];
    }
    if ([tableID isEqualToString:[_stockReplenishmentsTableView identifier]]) {
        return [_stockReplenishments count];
    }
    if ([tableID isEqualToString:[_stockWithdrawalsTableView identifier]]) {
        return [_stockWithdrawals count];
    }
    return 0; //Tabela desconhecida
}


/*
 Os identificadores das colunas e de suas respectivas vistas são idênticos e correspondem aos nomes das colunas no banco de dados
 */
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *tableID = [tableView identifier];
    NSString *columnID = [tableColumn identifier];
    NSTableCellView *cellView;
    if ([tableID isEqualToString:[_searchResultsTableView identifier]]) {
        id value = _searchResults[row][columnID];
        if ([columnID isEqualToString:@"part_number"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:_searchResults[row][columnID]];
        } else if ([columnID isEqualToString:@"manufacturer"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:_searchResults[row][columnID]];
        } else if ([columnID isEqualToString:@"component_type"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:_searchResults[row][columnID]];
        } else if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            NSNumber *numericValue = _searchResults[row][columnID];
            [textField setIntegerValue:[numericValue integerValue]];
        } else if ([columnID isEqualToString:@"voltage_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"current_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"power_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"resistance_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"inductance_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"capacitance_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"frequency_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setDoubleValue:[(NSNumber *)value doubleValue]];
            }
        } else if ([columnID isEqualToString:@"tolerance_rating"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[_percentFormatter stringFromNumber:(NSNumber *)value]];
            }
        } else if ([columnID isEqualToString:@"package_code"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:value];
            }
        } else if ([columnID isEqualToString:@"comments"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:value];
            }
        }
    } else if ([tableID isEqualToString:[_stockReplenishmentsTableView identifier]]) {
        id value = _stockReplenishments[row][columnID];
        if ([columnID isEqualToString:@"date_acquired"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : [_dateFormatter stringFromDate:value]];
        } else if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"origin"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : value];
        }
    } else if ([tableID isEqualToString:[_stockWithdrawalsTableView identifier]]) {
        id value = _stockWithdrawals[row][columnID];
        if ([columnID isEqualToString:@"date_spent"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : [_dateFormatter stringFromDate:value]];
        } else if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"destination"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : value];
        }
    }
    return cellView;
}

#pragma mark - NSTableViewDelegate

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Tabela de resultados de busca
    NSInteger selectedRow = [_searchResultsTableView selectedRow];
    if (selectedRow < 0) {
        [_stockActionsSegmentedControl setEnabled:NO forSegment:HISTORY_BUTTON_SEGMENT_INDEX];
        [_stockActionsSegmentedControl setEnabled:NO forSegment:PLUS_BUTTON_SEGMENT_INDEX];
        [_stockActionsSegmentedControl setEnabled:NO forSegment:MINUS_BUTTON_SEGMENT_INDEX];
    } else {
        [_stockActionsSegmentedControl setEnabled:YES forSegment:HISTORY_BUTTON_SEGMENT_INDEX];
        [_stockActionsSegmentedControl setEnabled:YES forSegment:PLUS_BUTTON_SEGMENT_INDEX];
        NSInteger selectedQuantity = [(NSNumber *)_searchResults[selectedRow][@"quantity"] integerValue];
        [_stockActionsSegmentedControl setEnabled:selectedQuantity > 0 forSegment:MINUS_BUTTON_SEGMENT_INDEX];
    }
}

#pragma mark - Utilities

+ (NSRect)relativeBoundsForSegmentedControl:(NSSegmentedControl *)control
                               segmentIndex:(NSInteger)index {
    CGRect bounds = [control bounds];
    CGFloat controlWidth = [control frame].size.width;
    bounds.size.width = controlWidth / [control segmentCount];
    bounds.origin.x += index * bounds.size.width;
    return bounds;
}

@end