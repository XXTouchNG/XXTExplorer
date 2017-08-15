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
@property(nonatomic, assign) XXTEKeyboardButtonStyle style;
@property(nonatomic, readonly) XXTEKeyboardButtonPosition position;
@property(nonatomic, copy) NSString *input;
@property(nonatomic, copy) NSString *output;
@property(nonatomic, weak) id <UITextInput> textInput;
@property(nonatomic, assign) BOOL selecting;
@property(nonatomic, copy) NSString *tabString;

@end
