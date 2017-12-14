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

@interface XXTEEditorSearchAccessoryView : UIToolbar

@property (nonatomic, weak) id <XXTEEditorSearchAccessoryViewDelegate> accessoryDelegate;
@property (nonatomic, strong) UILabel *countLabel;

- (void)reloadItemTintColor;

@end
