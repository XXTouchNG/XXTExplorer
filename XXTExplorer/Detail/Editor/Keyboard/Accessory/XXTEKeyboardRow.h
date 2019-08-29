//
//  XXTEKeyboardRow.h
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XXTEKeyboardButtonType) {
    XXTEKeyboardButtonTypePhone,
    XXTEKeyboardButtonTypeTablet
};

typedef NS_ENUM(NSUInteger, XXTEKeyboardRowStyle) {
    XXTEKeyboardRowStyleLight,
    XXTEKeyboardRowStyleDark
};

typedef NS_ENUM(NSUInteger, XXTEKeyboardButtonAction) {
    XXTEKeyboardButtonActionUndo = 0,
    XXTEKeyboardButtonActionRedo,
    XXTEKeyboardButtonActionBackspace,
    XXTEKeyboardButtonActionKeyboardDismissal,
    XXTEKeyboardButtonActionSelectToLineBreak,
};

@class XXTEKeyboardButton;

@protocol XXTEKeyboardButtonDelegate <NSObject>
- (void)keyboardButton:(XXTEKeyboardButton *)button didTriggerAction:(XXTEKeyboardButtonAction)action;

@end

@interface XXTEKeyboardRow : UIInputView

@property (nonatomic, assign) XXTEKeyboardButtonType buttonType;
@property (nonatomic, assign) XXTEKeyboardRowStyle colorStyle;

@property (nonatomic, weak) id <UITextInput> textInput;
@property (nonatomic, weak) id <XXTEKeyboardButtonDelegate> actionDelegate;

@property (nonatomic, copy) NSString *tabString;
@property (nonatomic, copy, readonly) NSString *keymap;
- (instancetype)initWithKeymap:(NSString *)keymap;

@end
