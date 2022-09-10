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

@property RegistrationWindowController *registrationWindowController;
@property NSMutableArray *searchResults;
@property NSMutableArray *stockReplenishments;
@property NSMutableArray *stockWithdrawals;
@property NSDateFormatter *dateFormatter;
@property NSNumberFormatter *percentFormatter;
@property NSNumber *selectedComponentID;

@end

@implementation MainWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"MainWindowController"];
    if (self) {
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
    NSArray *componentTypes = [[DatabaseController sharedController] componentTypes];
    [_componentTypeSelectionButton addItemsWithTitles:componentTypes];
    // Ocultar colunas anuláveis dos resultados de busca
    for (NSTableColumn *column in [_searchResultsTableView tableColumns]) {
        if ([[DatabaseController sharedController] isNullableColumn:[column identifier] table:@"stock"]) {
            [column setHidden:YES];
        }
    }
    [_searchResultsTableView sizeToFit];
}


- (IBAction)partNumberSearchFieldEdited:(id)sender {
    NSString *partNumber = [[_partNumberSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([partNumber length] > 0) {
        [_addPartNumberButton setEnabled:YES];
        _searchResults = [[DatabaseController sharedController] incrementalSearchResultsForPartNumber:partNumber];
    } else {
        [_addPartNumberButton setEnabled:NO];
        [_partNumberSearchField setStringValue:@""];
        _searchResults = nil;
    }
    [self updateSearchResultsTable];
}

- (IBAction)componentTypePopupSelected:(id)sender {
    [_partNumberSearchField abortEditing];
    [_partNumberSearchField setStringValue:@""];
    NSString *componentType = [_componentTypeSelectionButton titleOfSelectedItem];
    _searchResults = [[DatabaseController sharedController] searchResultsForComponentType:componentType];
    [self updateSearchResultsTable];
}


- (IBAction)stockActionsSegmentedControlClicked:(id)sender {
    NSInteger selectedSegmentIndex = [_stockActionsSegmentedControl selectedSegment];
    if (selectedSegmentIndex == 0) {
        // Incremento de estoque
        StockIncrementViewController *popoverViewController = (StockIncrementViewController *)[_selectedStockIncrementPopover contentViewController];
        [popoverViewController setSelectedComponentID:_selectedComponentID];
        NSRect bounds = [self relativeBoundsForSegmentedControl:sender
                                                   segmentIndex:selectedSegmentIndex];
        [_selectedStockIncrementPopover showRelativeToRect:bounds
                                                    ofView:sender
                                             preferredEdge:NSMinYEdge];
    } else if (selectedSegmentIndex == 1) {
        // Decremento de estoque
        StockDecrementViewController *popoverViewController = (StockDecrementViewController *)[_selectedStockDecrementPopover contentViewController];
        [popoverViewController setSelectedComponentID:_selectedComponentID];
        NSRect bounds = [self relativeBoundsForSegmentedControl:sender
                                                   segmentIndex:selectedSegmentIndex];
        [_selectedStockDecrementPopover showRelativeToRect:bounds
                                                    ofView:sender
                                             preferredEdge:NSMinYEdge];
    } else if (selectedSegmentIndex == 2) {
        // Histórico de movimentações de estoque
        _stockReplenishments = [[DatabaseController sharedController] stockReplenishmentsForComponentID:_selectedComponentID];
        [_stockReplenishmentsTableView reloadData];
        [_stockReplenishmentsTableView deselectAll:nil];
        [_stockReplenishmentsTableView sizeToFit];
        _stockWithdrawals = [[DatabaseController sharedController] stockWithdrawalsForComponentID:_selectedComponentID];
        [_stockWithdrawalsTableView reloadData];
        [_stockWithdrawalsTableView deselectAll:nil];
        [_stockWithdrawalsTableView sizeToFit];
        NSRect bounds = [self relativeBoundsForSegmentedControl:sender
                                                   segmentIndex:selectedSegmentIndex];
        [_selectedStockHistoryPopover showRelativeToRect:bounds
                                                  ofView:sender
                                           preferredEdge:NSMinYEdge];
    }
}


- (IBAction)addPartNumberButtonClicked:(id)sender {
    if (!_registrationWindowController) {
        _registrationWindowController = [[RegistrationWindowController alloc] init];
    }
    [_registrationWindowController clearInputForm];
    [_registrationWindowController setPartNumber:[_partNumberSearchField stringValue]];
    [_registrationWindowController showWindow:nil];
}


- (void)updateSearchResultsTable {
    NSNumber *selectedComponentID = _selectedComponentID;
    [_searchResultsTableView deselectAll:nil];
    if (_searchResults) {
        //... Aplicar filtros selecionados aos resultados de busca
        //... Habilitar seleção de filtros?
    } else {
        //... Limpar todos os filtros [e desabilitar seleção deles]?
    }
    [_searchResultsTableView reloadData];
    // Ocultar colunas opcionais inteiramente vazias
    for (NSTableColumn *column in [_searchResultsTableView tableColumns]) {
        NSString *columnID = [column identifier];
        if ([[DatabaseController sharedController] isNullableColumn:columnID table:@"stock"]) {
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
    if (selectedComponentID) {
        // Reafirmar seleção se o componente ainda estiver presente
        for (NSDictionary *searchResult in _searchResults) {
            NSNumber *componentID = searchResult[@"component_id"];
            if ([componentID isEqualTo:selectedComponentID]) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[_searchResults indexOfObject:searchResult]];
                [_searchResultsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
                break;
            }
        }
    }
}


- (NSRect)relativeBoundsForSegmentedControl:(NSSegmentedControl *)control
                               segmentIndex:(NSInteger)index {
    CGRect bounds = [control bounds];
    CGFloat controlWidth = [control frame].size.width;
    bounds.size.width = controlWidth / [control segmentCount];
    bounds.origin.x += index * bounds.size.width;
    return bounds;
}

#pragma mark - NSControlTextEditingDelegate

-(void)controlTextDidBeginEditing:(NSNotification *)obj {
    // Campo de busca por número de peça
    [_componentTypeSelectionButton selectItemAtIndex:0];
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


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Os identificadores das colunas e de suas respectivas vistas são idênticos e correspondem aos nomes das colunas no banco de dados
    NSString *columnID = [tableColumn identifier];
    NSTableCellView *cellView;
    NSString *tableID = [tableView identifier];
    if ([tableID isEqualToString:[_searchResultsTableView identifier]]) {
        id value = _searchResults[row][columnID];
        if ([columnID isEqualToString:@"part_number"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:value];
        } else if ([columnID isEqualToString:@"manufacturer"]) {
            if (![value isEqualTo:[NSNull null]]) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:value];
            }
        } else if ([columnID isEqualToString:@"component_type"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:value];
        } else if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
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
        if ([columnID isEqualToString:@"id"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"date_acquired"]) {
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
        if ([columnID isEqualToString:@"id"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:nil];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"date_spent"]) {
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
        _selectedComponentID = nil;
        [_stockActionsSegmentedControl setEnabled:NO forSegment:0];
        [_stockActionsSegmentedControl setEnabled:NO forSegment:1];
        [_stockActionsSegmentedControl setEnabled:NO forSegment:2];
        //... Fechar eventuais popovers?
    } else {
        _selectedComponentID = _searchResults[selectedRow][@"component_id"];
        [_stockActionsSegmentedControl setEnabled:YES forSegment:0];
        [_stockActionsSegmentedControl setEnabled:YES forSegment:2];
        NSInteger selectedQuantity = [(NSNumber *)_searchResults[selectedRow][@"quantity"] integerValue];
        [_stockActionsSegmentedControl setEnabled:selectedQuantity > 0 forSegment:1];
    }
}

@end
