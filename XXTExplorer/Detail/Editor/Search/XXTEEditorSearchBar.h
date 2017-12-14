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

@interface XXTEEditorSearchBar : UIView

@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, strong) XXTEEditorSearchField *searchField;
@property (nonatomic, strong) XXTEEditorSearchAccessoryView *searchAccessoryView;

@end
