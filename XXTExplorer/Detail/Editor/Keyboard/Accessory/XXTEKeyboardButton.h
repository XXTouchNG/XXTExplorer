//
//  XXTEKeyboardButton.h
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEKeyboardRow.h"

typedef NS_ENUM(NSUInteger, XXTEKeyboardButtonPosition) {
    XXTEKeyboardButtonPositionLeft,
    XXTEKeyboardButtonPositionInner,
    XXTEKeyboardButtonPositionRight,
    XXTEKeyboardButtonPositionCount
};


@interface XXTEKeyboardButton : UIControl

@property (nonatomic, copy) NSString *input;
@property (nonatomic, copy) NSString *output;
@property (nonatomic, weak) id <UITextInput> textInput;
@property (nonatomic, weak) id <XXTEKeyboardButtonDelegate> actionDelegate;

@property (nonatomic, assign) BOOL selecting;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *tabString;

@property (nonatomic, assign) XXTEKeyboardButtonType style;
@property (nonatomic, readonly) XXTEKeyboardButtonPosition position;
@property (nonatomic, assign) XXTEKeyboardRowStyle colorStyle;

@end
