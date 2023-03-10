//
//  MainWindowController.m
//  Stock Manager
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "MainWindowController.h"
#import "DatabaseController.h"
#import "ComponentRating.h"
#import "RegistrationWindowController.h"
#import "StockIncrementViewController.h"
#import "StockDecrementViewController.h"

#define TABLE_CELL_LATERAL_SPACING 2.0

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
@property NSString *partNumberSearchTerm;
@property NSMutableArray<NSMutableDictionary *> *searchResults;
@property NSMutableArray *stockReplenishments;
@property NSMutableArray *stockWithdrawals;
@property NSDateFormatter *dateFormatter;
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
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    NSArray *componentTypes = [[DatabaseController sharedController] componentTypes];
    [_componentTypeSelectionButton addItemsWithTitles:componentTypes];
    // Hide nullable columns from search results
    for (NSTableColumn *column in [_searchResultsTableView tableColumns]) {
        if ([[DatabaseController sharedController] isNullableColumn:[column identifier] table:@"stock"]) {
            [column setHidden:YES];
        }
    }
    [_searchResultsTableView sizeToFit];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stockUpdatedNotification:)
                                                 name:@"DBCStockUpdatedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(componentRegisteredNotification:)
                                                 name:@"DBCComponentRegisteredNotification"
                                               object:nil];
}


- (void)closeWindows {
    [[_registrationWindowController window] close];
    [[self window] close];
}


- (IBAction)partNumberSearchFieldEdited:(id)sender {
    NSString *partNumber = [[self partNumberSearchTerm] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([partNumber length] > 0) {
        [self setSearchResults:[[DatabaseController sharedController] incrementalSearchResultsForPartNumber:partNumber]];
    } else {
        [self setPartNumberSearchTerm:@""];
        [self setSearchResults:nil];
    }
    [self updateSearchResultsTable];
}

- (IBAction)componentTypePopupSelected:(id)sender {
    [_partNumberSearchField abortEditing];
    [self setPartNumberSearchTerm:@""];
    NSString *componentType = [_componentTypeSelectionButton titleOfSelectedItem];
    [self setSearchResults:[[DatabaseController sharedController] searchResultsForComponentType:componentType]];
    [self updateSearchResultsTable];
}


- (IBAction)stockActionsSegmentedControlClicked:(id)sender {
    NSInteger selectedSegmentIndex = [_stockActionsSegmentedControl selectedSegment];
    if (selectedSegmentIndex == 0) {
        // Stock increment
        StockIncrementViewController *popoverViewController = (StockIncrementViewController *)[_selectedStockIncrementPopover contentViewController];
        [popoverViewController setSelectedComponentID:_selectedComponentID];
        NSRect bounds = [self relativeBoundsForSegmentedControl:sender
                                                   segmentIndex:selectedSegmentIndex];
        [_selectedStockIncrementPopover showRelativeToRect:bounds
                                                    ofView:sender
                                             preferredEdge:NSMinYEdge];
    } else if (selectedSegmentIndex == 1) {
        // Stock decrement
        StockDecrementViewController *popoverViewController = (StockDecrementViewController *)[_selectedStockDecrementPopover contentViewController];
        [popoverViewController setSelectedComponentID:_selectedComponentID];
        NSRect bounds = [self relativeBoundsForSegmentedControl:sender
                                                   segmentIndex:selectedSegmentIndex];
        [_selectedStockDecrementPopover showRelativeToRect:bounds
                                                    ofView:sender
                                             preferredEdge:NSMinYEdge];
    } else if (selectedSegmentIndex == 2) {
        // Stock history
        [self setStockReplenishments:[[DatabaseController sharedController] stockReplenishmentsForComponentID:_selectedComponentID]];
        [_stockReplenishmentsTableView reloadData];
        [_stockReplenishmentsTableView deselectAll:nil];
        [_stockReplenishmentsTableView sizeToFit];
        [self setStockWithdrawals:[[DatabaseController sharedController] stockWithdrawalsForComponentID:_selectedComponentID]];
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


- (IBAction)searchResultsTableFooterClicked:(id)sender {
    [_searchResultsTableView deselectAll:nil];
}


- (IBAction)addPartNumberButtonClicked:(id)sender {
    if (!_registrationWindowController) {
        [self setRegistrationWindowController:[[RegistrationWindowController alloc] init]];
    }
    [_registrationWindowController clearInputForm];
    [_registrationWindowController setPartNumber:[self partNumberSearchTerm]];
    [_registrationWindowController showWindow:nil];
}


- (void)updateSearchResultsTable {
    [_searchResultsTableView setSortDescriptors:@[]];
    [_searchResultsTableView reloadData];
    // Hide entirely empty non-essential columns
    for (NSTableColumn *column in [_searchResultsTableView tableColumns]) {
        NSString *columnID = [column identifier];
        if ([[DatabaseController sharedController] isNullableColumn:columnID table:@"stock"]) {
            [column setHidden:YES];
            for (NSDictionary *result in _searchResults) {
                id value = result[columnID];
                if (value) {
                    [column setHidden:NO];
                    break;
                }
            }
        }
    }
    [_searchResultsTableView sizeToFit];
    [self reassertSearchResultSelection];
}


- (void)reassertSearchResultSelection {
    if (_selectedComponentID) {
        for (NSMutableDictionary *searchResult in _searchResults) {
            NSNumber *componentID = searchResult[@"component_id"];
            if ([componentID isEqualToNumber:_selectedComponentID]) {
                NSInteger selectedRowIndex = [_searchResults indexOfObject:searchResult];
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:selectedRowIndex];
                [_searchResultsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
                [_searchResultsTableView scrollRowToVisible:selectedRowIndex];
                return;
            }
        }
        [self setSelectedComponentID:nil]; //Component no longer present among search results
        [self disableSelectedStockControls];
    }
}


- (void)disableSelectedStockControls {
    [_stockActionsSegmentedControl setEnabled:NO forSegment:0];
    [_stockActionsSegmentedControl setEnabled:NO forSegment:1];
    [_stockActionsSegmentedControl setEnabled:NO forSegment:2];
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
    // Part number search field
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
    return 0; //Unknown table
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Column and view identifiers are identical and correspond to column names in the database
    NSString *columnID = [tableColumn identifier];
    NSTableCellView *cellView = nil;
    NSString *tableID = [tableView identifier];
    if ([tableID isEqualToString:[_searchResultsTableView identifier]]) {
        id value = _searchResults[row][columnID];
        if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"part_number"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:value];
        } else if ([columnID isEqualToString:@"component_type"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:value];
        } else if ([columnID isEqualToString:@"manufacturer"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:value];
            }
        } else if ([columnID isEqualToString:@"package_code"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:value];
            }
        } else if ([columnID isEqualToString:@"comments"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:value];
            }
        } else if ([columnID isEqualToString:@"voltage_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(VoltageRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"current_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(CurrentRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"power_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(PowerRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"resistance_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(ResistanceRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"inductance_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(InductanceRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"capacitance_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(CapacitanceRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"frequency_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(FrequencyRating *)value engineeringValue]];
            }
        } else if ([columnID isEqualToString:@"tolerance_rating"]) {
            if (value) {
                cellView = [tableView makeViewWithIdentifier:columnID owner:self];
                NSTextField *textField = [cellView textField];
                [textField setStringValue:[(ToleranceRating *)value engineeringValue]];
            }
        }
    } else if ([tableID isEqualToString:[_stockReplenishmentsTableView identifier]]) {
        id value = _stockReplenishments[row][columnID];
        if ([columnID isEqualToString:@"id"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"date_acquired"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : [_dateFormatter stringFromDate:value]];
        } else if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"origin"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : value];
        }
    } else if ([tableID isEqualToString:[_stockWithdrawalsTableView identifier]]) {
        id value = _stockWithdrawals[row][columnID];
        if ([columnID isEqualToString:@"id"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"date_spent"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : [_dateFormatter stringFromDate:value]];
        } else if ([columnID isEqualToString:@"quantity"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setIntegerValue:[(NSNumber *)value integerValue]];
        } else if ([columnID isEqualToString:@"destination"]) {
            cellView = [tableView makeViewWithIdentifier:columnID owner:self];
            NSTextField *textField = [cellView textField];
            [textField setStringValue:[value isEqualTo:[NSNull null]] ? @"Unknown" : value];
        }
    }
    return cellView;
}


- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
    // Search results table
    NSArray<NSSortDescriptor *> *sortDescriptors = [_searchResultsTableView sortDescriptors];
    [_searchResults sortUsingDescriptors:sortDescriptors];
    [_searchResultsTableView reloadData];
    [self reassertSearchResultSelection];
}

#pragma mark - NSTableViewDelegate

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Search results table
    NSInteger selectedRow = [_searchResultsTableView selectedRow];
    if (selectedRow < 0) {
        [self setSelectedComponentID:nil];
        [self disableSelectedStockControls];
    } else {
        [self setSelectedComponentID:_searchResults[selectedRow][@"component_id"]];
        [_stockActionsSegmentedControl setEnabled:YES forSegment:0];
        [_stockActionsSegmentedControl setEnabled:YES forSegment:2];
        NSInteger selectedQuantity = [(NSNumber *)_searchResults[selectedRow][@"quantity"] integerValue];
        [_stockActionsSegmentedControl setEnabled:selectedQuantity > 0 forSegment:1];
    }
}


- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column {
    CGFloat widthToFit = 0.0;
    NSInteger rowCount = [tableView numberOfRows];
    for (NSInteger row = 0; row < rowCount; row++) {
        NSTableCellView *cellView = [tableView viewAtColumn:column row:row makeIfNecessary:NO];
        if (cellView) {
            CGFloat intrinsicContentWidth = [[cellView textField] intrinsicContentSize].width;
            widthToFit = MAX(intrinsicContentWidth + 2 * TABLE_CELL_LATERAL_SPACING, widthToFit);
        }
    }
    return widthToFit;
}

#pragma mark - Notification Handlers

- (void)stockUpdatedNotification:(NSNotification *)notification {
    NSNumber *updatedComponentID = [[notification userInfo] objectForKey:@"UpdatedComponentID"];
    NSNumber *updatedQuantity = [[DatabaseController sharedController] stockForComponentID:updatedComponentID];
    for (NSMutableDictionary *searchResult in _searchResults) {
        NSNumber *componentID = searchResult[@"component_id"];
        if ([componentID isEqualToNumber:updatedComponentID]) {
            [searchResult setObject:updatedQuantity forKey:@"quantity"];
            [self updateSearchResultsTable];
            break;
        }
    }
}


- (void)componentRegisteredNotification:(NSNotification *)notification {
    NSArray *componentTypes = [[DatabaseController sharedController] componentTypes];
    for (NSInteger i = [_componentTypeSelectionButton numberOfItems] - 1; i > 1; i--) {
        [_componentTypeSelectionButton removeItemAtIndex:i];
    }
    [_componentTypeSelectionButton addItemsWithTitles:componentTypes];
    NSString *partNumber = [[notification userInfo] objectForKey:@"PartNumber"];
    if (![[self window] isVisible]) {
        [self showWindow:nil];
    }
    [_partNumberSearchField abortEditing];
    [self setPartNumberSearchTerm:partNumber];
    [self setSearchResults:[[DatabaseController sharedController] incrementalSearchResultsForPartNumber:partNumber]];
    [self updateSearchResultsTable];
}

@end
