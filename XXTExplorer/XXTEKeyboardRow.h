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

@property(nonatomic, weak) UITextView *textView;
@property(nonatomic, assign) XXTEKeyboardButtonStyle style;
@property(nonatomic, copy) NSString *tabString;

@property(nonatomic, assign) XXTEKeyboardButtonColorStyle colorStyle;

@end
