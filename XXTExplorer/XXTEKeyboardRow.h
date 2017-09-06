//
//  XXTEKeyboardRow.h
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XXTEKeyboardButtonStyle) {
    XXTEKeyboardButtonStylePhone,
    XXTEKeyboardButtonStyleTablet
};

typedef NS_ENUM(NSUInteger, XXTEKeyboardButtonColorStyle) {
    XXTEKeyboardButtonColorStyleLight,
    XXTEKeyboardButtonColorStyleDark
};

@interface XXTEKeyboardRow : UIInputView

@property(nonatomic, weak) id <UITextInput> textInput;
@property(nonatomic, assign, readonly) XXTEKeyboardButtonStyle style;
@property(nonatomic, assign, setter=setColorStyle:) XXTEKeyboardButtonColorStyle colorStyle;
@property(nonatomic, copy, setter=setTabString:) NSString *tabString;

@end
