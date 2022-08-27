//
//  WHMainWindowController.m
//  Warehouse
//
//  Created by Douglas Almeida on 26/08/22.
//  Copyright © 2022 Douglas Almeida. All rights reserved.
//

#import "WHMainWindowController.h"

@interface WHMainWindowController ()

@property (weak) IBOutlet NSPopover *componentAdditionPopover;
@property (weak) IBOutlet NSPopover *componentRetrievalPopover;
@property (weak) IBOutlet NSPopover *replenishmentsHistoryPopover;
@property (weak) IBOutlet NSPopover *withdrawalsHistoryPopover;

@end

@implementation WHMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
}


- (IBAction)componentAdditionButtonClicked:(id)sender {
    //... Limpar campos e carregar auto-compleção para o campo origem
    [_componentAdditionPopover showRelativeToRect:[sender bounds]
                                           ofView:sender
                                    preferredEdge:NSMinXEdge];
}


- (IBAction)componentRetrievalButtonClicked:(id)sender {
    //... Limpar campos e carregar auto-compleção para o campo destino
    [_componentRetrievalPopover showRelativeToRect:[sender bounds]
                                            ofView:sender
                                     preferredEdge:NSMinXEdge];
}


- (IBAction)stockReplenishmentsButtonClicked:(id)sender {
    //... Popular tabela para o componente selecionado
    [_replenishmentsHistoryPopover showRelativeToRect:[sender bounds]
                                               ofView:sender
                                        preferredEdge:NSMinYEdge];
}



- (IBAction)previousRetrievalsButtonClicked:(id)sender {
    //... Popular tabela para o componente selecionado
    [_withdrawalsHistoryPopover showRelativeToRect:[sender bounds]
                                            ofView:sender
                                     preferredEdge:NSMinYEdge];
}

@end
