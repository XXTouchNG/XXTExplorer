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

@interface XXTEKeyboardRow : UIInputView

@property(nonatomic, weak) id <UITextInput> textInput;
@property(nonatomic, assign) XXTEKeyboardButtonType buttonType;
@property(nonatomic, copy) NSString *tabString;

@property(nonatomic, assign) XXTEKeyboardRowStyle colorStyle;

- (instancetype)initWithKeymap:(NSString *)keymap;

@end
