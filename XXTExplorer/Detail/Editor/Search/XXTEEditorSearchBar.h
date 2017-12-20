//
//  XXTEEditorSearchBar.h
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEEditorSearchField.h"
#import "XXTEEditorSearchAccessoryView.h"

static CGFloat const XXTEEditorSearchBarHeight = 44.f;

@class XXTEEditorSearchBar;

@protocol XXTEEditorSearchBarDelegate <NSObject>
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar textFieldShouldReturn:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar textFieldDidChange:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar textFieldShouldClear:(UITextField *)textField;

@end

@interface XXTEEditorSearchBar : UIView

@property (nonatomic, weak) id <XXTEEditorSearchBarDelegate> delegate;

@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIView *inputAccessoryView;
@property (nonatomic, assign) UIKeyboardAppearance keyboardAppearance;

@end
