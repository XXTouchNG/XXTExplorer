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
    XXTEKeyboardToolbarRowDevicePhone = 0,
    XXTEKeyboardToolbarRowDeviceTablet,
} XXTEKeyboardToolbarRowDevice;

typedef enum : NSUInteger {
    XXTEKeyboardToolbarRowButtonTab = 0,
    XXTEKeyboardToolbarRowButtonUndo,
    XXTEKeyboardToolbarRowButtonPicker,
    XXTEKeyboardToolbarRowButtonRedo,
    XXTEKeyboardToolbarRowButtonDismiss,
} XXTEKeyboardToolbarRowButton;

@class XXTEKeyboardToolbarRow;

@protocol XXTEKeyboardToolbarRowDelegate <NSObject>
- (void)keyboardRow:(XXTEKeyboardToolbarRow *)keyboardRow buttonTappedAtIndex:(NSUInteger)index;
@end

@interface XXTEKeyboardToolbarRow : UIInputView

@property (nonatomic, strong) NSString *tabString;
@property (nonatomic, assign, setter=setStyle:) XXTEKeyboardToolbarRowStyle style;
@property (nonatomic, assign, readonly) XXTEKeyboardToolbarRowDevice device;
@property (nonatomic, weak) id <UITextInput> textInput;

@end
