//
//  XXTEEditorThemeSettingsViewController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorThemeSettingsViewController;

@protocol XXTEEditorThemeSettingsViewControllerDelegate <NSObject>

- (void)themeSettingsViewControllerSettingsDidChanged:(XXTEEditorThemeSettingsViewController *)controller;

@end

@interface XXTEEditorThemeSettingsViewController : UITableViewController

@property (nonatomic, weak) id <XXTEEditorThemeSettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedThemeName;
@property (nonatomic, strong) NSDictionary *selectedThemeEntry;

- (instancetype)initWithStyle:(UITableViewStyle)style definesPath:(NSString *)path;

@end
