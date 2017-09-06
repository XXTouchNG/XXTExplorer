//
//  XXTEKeyboardRow.h
//  XXTExplorer
//
//  Created by Zheng on 06/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XXTEKeyboardRowStyleLight = 0,
    XXTEKeyboardRowStyleDark,
} XXTEKeyboardRowStyle;

typedef enum : NSUInteger {
    XXTEKeyboardRowDevicePhone = 0,
    XXTEKeyboardRowDeviceTablet,
} XXTEKeyboardRowDevice;

typedef enum : NSUInteger {
    XXTEKeyboardRowButtonTab = 0,
    XXTEKeyboardRowButtonUndo,
    XXTEKeyboardRowButtonPicker,
    XXTEKeyboardRowButtonRedo,
    XXTEKeyboardRowButtonDismiss,
} XXTEKeyboardRowButton;

@class XXTEKeyboardRow;

@protocol XXTEKeyboardRowDelegate <NSObject>
- (void)keyboardRow:(XXTEKeyboardRow *)keyboardRow buttonTappedAtIndex:(NSUInteger)index;
@end

@interface XXTEKeyboardRow : UIInputView

@property (nonatomic, strong) NSString *tabString;
@property (nonatomic, assign, setter=setStyle:) XXTEKeyboardRowStyle style;
@property (nonatomic, assign, readonly) XXTEKeyboardRowDevice device;
@property (nonatomic, weak) id <UITextInput> textInput;

@end
