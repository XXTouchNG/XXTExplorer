//
//  XXTEEditorController+NavigationBar.h
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController.h"

@interface XXTEEditorController (NavigationBar)

- (BOOL)isDarkMode;
- (void)renderNavigationBarTheme:(BOOL)restore;

@end
