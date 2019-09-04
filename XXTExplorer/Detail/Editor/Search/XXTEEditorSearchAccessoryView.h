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
- (void)searchAccessoryViewShouldReplace:(XXTEEditorSearchAccessoryView *)accessoryView;
- (void)searchAccessoryViewShouldReplaceAll:(XXTEEditorSearchAccessoryView *)accessoryView;
- (void)searchAccessoryView:(XXTEEditorSearchAccessoryView *)accessoryView didTapDismiss:(UIBarButtonItem *)sender;

@end

@interface XXTEEditorSearchAccessoryView : UIInputView

@property (nonatomic, weak) id <XXTEEditorSearchAccessoryViewDelegate> accessoryDelegate;
@property (nonatomic, assign) UIBarStyle barStyle;

@property (nonatomic, strong) UIBarButtonItem *prevItem;
@property (nonatomic, strong) UIBarButtonItem *nextItem;
@property (nonatomic, strong) UIBarButtonItem *replaceItem;
@property (nonatomic, strong) UIBarButtonItem *replaceAllItem;
@property (nonatomic, strong) UIBarButtonItem *dismissItem;
@property (nonatomic, strong) UILabel *countLabel;

@property (nonatomic, assign) BOOL replaceMode;
@property (nonatomic, assign) BOOL allowReplacement;
- (void)updateAccessoryView;

@end
