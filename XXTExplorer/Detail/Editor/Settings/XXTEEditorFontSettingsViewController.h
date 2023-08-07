//
//  XXTEEditorFontSettingsViewController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorFontSettingsViewController;

@protocol XXTEEditorFontSettingsViewControllerDelegate <NSObject>

- (void)fontSettingsViewControllerSettingsDidChanged:(XXTEEditorFontSettingsViewController *)controller;

@end

@interface XXTEEditorFontSettingsViewController : UITableViewController

+ (NSArray <NSDictionary *> *)fontMetas;
+ (NSArray <UIFont *> *)availableFonts;
+ (NSDictionary <NSString *, UIFont *> *)availableFontsMappings;

@property (nonatomic, weak) id <XXTEEditorFontSettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedFontName;

@end
