//
//  XXTECodeViewerController+NavigationBar.h
//  XXTExplorer
//
//  Created by Darwin on 8/1/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTECodeViewerController.h"

NS_ASSUME_NONNULL_BEGIN

@interface XXTECodeViewerController (NavigationBar)

- (BOOL)isDarkMode;
- (void)renderNavigationBarTheme:(BOOL)restore;

@end

NS_ASSUME_NONNULL_END
