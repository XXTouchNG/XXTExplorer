//
//  XXTEConfirmTextInputObject.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/8.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTEConfirmTextInputObject.h"
#import <XUI/XUIViewShaker.h>

@interface XXTEConfirmTextInputObject () <UITextFieldDelegate>
@property (nonatomic, strong) XUIViewShaker *shaker;

@end

@implementation XXTEConfirmTextInputObject

- (void)setTextInput:(UITextField *)textInput {
    _textInput = textInput;
    textInput.delegate = self; // weak refs
    _shaker = [[XUIViewShaker alloc] initWithView:textInput];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *origText = textField.text;
    NSString *newText = [origText stringByReplacingCharactersInRange:range withString:string];
    if ([self.confirmString isEqualToString:newText]) {
        [textField setText:newText];
        [textField resignFirstResponder];
        [textField setEnabled:NO];
        self.confirmHandler(textField);
        return NO;
    } else if ([self.confirmString hasPrefix:newText]) {
        return YES;
    } else if ([newText isEqualToString:@""]) {
        return YES;
    }
    [self.shaker shake];
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return NO;
}

- (void)dealloc {
    
}

@end
