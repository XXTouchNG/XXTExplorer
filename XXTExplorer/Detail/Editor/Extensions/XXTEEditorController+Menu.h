//
//  XXTEEditorController+Menu.h
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController.h"
#import "XXTExplorerItemPicker.h"
#import "XXTPickerFactory.h"

@interface XXTEEditorController (Menu) <XXTExplorerItemPickerDelegate, XXTPickerFactoryDelegate>

- (void)registerMenuActions;
- (void)dismissMenuActions;

@end
