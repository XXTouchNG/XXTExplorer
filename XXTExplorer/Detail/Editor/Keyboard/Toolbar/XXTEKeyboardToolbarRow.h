//
//  XXTEKeyboardToolbarRow.h
//  XXTExplorer
//
//  Created by Zheng on 06/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XXTEKeyboardToolbarRowStyleLight = 0,
    XXTEKeyboardToolbarRowStyleDark,
} XXTEKeyboardToolbarRowStyle;

typedef enum : NSUInteger {
    XXTEKeyboardToolbarRowButtonTypeUndo = 0,
    XXTEKeyboardToolbarRowButtonTypeRedo,
    XXTEKeyboardToolbarRowButtonTypeDismiss,
} XXTEKeyboardToolbarRowButtonType;

@class XXTEKeyboardToolbarRow;

@protocol XXTEKeyboardToolbarRowDelegate <NSObject>
- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapUndo:(UIBarButtonItem *)sender;
- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapRedo:(UIBarButtonItem *)sender;
- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapDismiss:(UIBarButtonItem *)sender;
@end

@interface XXTEKeyboardToolbarRow : UIInputView

@property (nonatomic, assign, setter=setStyle:) XXTEKeyboardToolbarRowStyle style;
@property (nonatomic, weak) id <XXTEKeyboardToolbarRowDelegate> delegate;
@property (nonatomic, strong) UIBarButtonItem *undoItem;
@property (nonatomic, strong) UIBarButtonItem *redoItem;
@property (nonatomic, strong) UIBarButtonItem *dismissItem;

@end
