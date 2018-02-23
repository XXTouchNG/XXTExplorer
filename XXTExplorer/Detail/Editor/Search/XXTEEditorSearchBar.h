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

static CGFloat const XXTEEditorSearchBarHeight = 88.f;

@class XXTEEditorSearchBar;

@protocol XXTEEditorSearchBarDelegate <NSObject>

@optional
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldReturn:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldDidChange:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldClear:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldBeginEditing:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldDidBeginEditing:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldEndEditing:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldDidEndEditing:(UITextField *)textField;

@optional
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldReturn:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldDidChange:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldClear:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldBeginEditing:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldDidBeginEditing:(UITextField *)textField;
- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldEndEditing:(UITextField *)textField;
- (void)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldDidEndEditing:(UITextField *)textField;

@optional
- (void)searchBarDidCancel:(XXTEEditorSearchBar *)searchBar;

@end

@interface XXTEEditorSearchBar : UIView

@property (nonatomic, weak) id <XXTEEditorSearchBarDelegate> delegate;

@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, strong) UIView *searchInputAccessoryView;
@property (nonatomic, assign) UIKeyboardAppearance searchKeyboardAppearance;

@property (nonatomic, strong) NSString *replaceText;
@property (nonatomic, strong) UIView *replaceInputAccessoryView;
@property (nonatomic, assign) UIKeyboardAppearance replaceKeyboardAppearance;

@end
