//
//  XXTENumberTextInputObject.m
//  XXTExplorer
//
//  Created by Zheng on 09/04/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTENumberTextInputObject.h"
#import <XUI/XUIViewShaker.h>

@interface XXTENumberTextInputObject () <UITextFieldDelegate>
@property (nonatomic, strong) XUIViewShaker *shaker;

@end

@implementation XXTENumberTextInputObject

+ (NSRegularExpression *)numberRegex {
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d*)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    });
    return regex;
}

- (void)setTextInput:(UITextField *)textInput {
    _textInput = textInput;
    textInput.delegate = self; // weak refs
    _shaker = [[XUIViewShaker alloc] initWithView:textInput];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *origText = textField.text;
    NSString *newText = [origText stringByReplacingCharactersInRange:range withString:string];
    if (newText.length > self.maxLength) {
        [self.shaker shake];
        return NO;
    }
    BOOL match = ([[[self class] numberRegex] firstMatchInString:newText options:0 range:NSMakeRange(0, newText.length)] != nil);
    if (!match) {
        [self.shaker shake];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)shake {
    [self.shaker shake];
}

- (void)dealloc {
    
}

@end
