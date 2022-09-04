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

@end

@implementation RegistrationWindowController

- (instancetype)initWithDatabaseController:(DatabaseController *)controller {
    self = [super initWithWindowNibName:@"RegistrationWindowController"];
    if (self) {
        _databaseController = controller;
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
}


- (IBAction)okButtonClicked:(id)sender {
    //... Verificar campos obrigatórios
    NSString *manufacturer = [_manufacturerComboBox stringValue];
    if ([_databaseController databaseKnowsPartNumber:_partNumber fromManufacturer:manufacturer]) {
        //... Alertar usuário
    }
    //... SQL UPDATE
    [self close];
    //... Automaticamente buscar o novo part#, selecioná-lo e ativar seu popover de incremento de estoque na janela principal, mobilizando-a a através de notificação [do gerenciador do banco de dados] ou por delegação
}


- (IBAction)cancelButtonClicked:(id)sender {
    [self close];
}


- (void)clearInputForm {
    [_manufacturerComboBox setStringValue:@""];
    [_componentTypeComboBox setStringValue:@""];
    [_packageCodeComboBox setStringValue:@""];
    [_commentsTextField setStringValue:@""];
    //... Limpar tabela de características
    [[self window] makeFirstResponder:_manufacturerComboBox];
}

#pragma mark - NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    // Campo do fabricante
    NSString *manufacturer = [_manufacturerComboBox stringValue];
    if ([_databaseController databaseKnowsPartNumber:_partNumber fromManufacturer:manufacturer]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Update Stock"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setAlertStyle:NSAlertStyleWarning];
        NSString *alertMessage = [NSString stringWithFormat:@"%@ from manufacturer %@ is already on the database.", _partNumber, manufacturer];
        [alert setInformativeText:@"Proceed to update its stock."];
        [alert setMessageText:alertMessage];
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                [[self window] close];
                //... Automaticamente buscar o novo part#, selecioná-lo e ativar seu popover de incremento de estoque na janela principal, mobilizando-a a através de notificação [do gerenciador do banco de dados] ou por delegação
            }
        }];
        return NO;
    }
    return YES;
}

@end
