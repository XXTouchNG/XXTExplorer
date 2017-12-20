//
//  XXTEEditorSearchAccessoryView.h
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorSearchAccessoryView;

@protocol XXTEEditorSearchAccessoryViewDelegate <NSObject>
- (void)searchAccessoryViewShouldMatchPrev:(XXTEEditorSearchAccessoryView *)accessoryView;
- (void)searchAccessoryViewShouldMatchNext:(XXTEEditorSearchAccessoryView *)accessoryView;

@end

@interface XXTEEditorSearchAccessoryView : UIInputView

@property (nonatomic, weak) id <XXTEEditorSearchAccessoryViewDelegate> accessoryDelegate;
@property (nonatomic, assign) UIBarStyle barStyle;

@property (nonatomic, strong) UIBarButtonItem *prevItem;
@property (nonatomic, strong) UIBarButtonItem *nextItem;
@property (nonatomic, strong) UILabel *countLabel;

@end
