//
//  XXTEEditorController+Keyboard.m
//  XXTExplorer
//
//  Created by Zheng on 17/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+Keyboard.h"
#import "XXTEEditorTextView.h"

#import "XXTEEditorDefaults.h"

#import "XXTEEditorToolbar.h"

@implementation XXTEEditorController (Keyboard)

#pragma mark - Keyboard

// Call this method somewhere in your view controller setup code.
- (void)registerKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidAppear:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDisappear:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDisappear:) name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)dismissKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardWillAppear:(NSNotification *)aNotification {
    if (self.presentedViewController) {
        return;
    }
    
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    NSDictionary* info = [aNotification userInfo];
    if (@available(iOS 9.0, *)) {
        BOOL isLocal = [info[UIKeyboardIsLocalUserInfoKey] boolValue];
        if (!isLocal) {
            return;
        }
    }
    
    if (XXTE_IS_IPAD) {
        
    } else {
        if (XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO)) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardDidAppear:(NSNotification *)aNotification
{
    if (self.presentedViewController) {
        return;
    }
    
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    NSDictionary* info = [aNotification userInfo];
    if (@available(iOS 9.0, *)) {
        BOOL isLocal = [info[UIKeyboardIsLocalUserInfoKey] boolValue];
        if (!isLocal) {
            return;
        }
    }
    
    CGSize kbSize = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
         insets = self.view.safeAreaInsets;
    }
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height - insets.bottom, 0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    XXTEEditorTextView *textView = self.textView;
    UITextRange *selectionRange = [textView selectedTextRange];
    CGRect selectionStartRect = [textView caretRectForPosition:selectionRange.start];
    CGRect selectionEndRect = [textView caretRectForPosition:selectionRange.end];
    CGPoint selectionCenterPoint = (CGPoint){(selectionStartRect.origin.x + selectionEndRect.origin.x) / 2,(selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
    
    if (!CGRectContainsPoint(aRect, selectionCenterPoint) ) {
        [textView scrollRectToVisible:CGRectMake(selectionStartRect.origin.x, selectionStartRect.origin.y, selectionEndRect.origin.x - selectionStartRect.origin.x, selectionStartRect.size.height) animated:YES consideringInsets:YES];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillDisappear:(NSNotification *)aNotification
{
    if (self.presentedViewController) {
        return;
    }
    
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    NSDictionary* info = [aNotification userInfo];
    if (@available(iOS 9.0, *)) {
        BOOL isLocal = [info[UIKeyboardIsLocalUserInfoKey] boolValue];
        if (!isLocal) {
            return;
        }
    }
    
    if (XXTE_IS_IPAD) {
        
    } else {
        if (XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO)) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
    }
    
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        // insets = self.view.safeAreaInsets;
    }
    UITextView *textView = self.textView;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(insets.top, insets.left, insets.bottom + kXXTEEditorToolbarHeight, insets.right);
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardDidDisappear:(NSNotification *)aNotification
{
    if (self.presentedViewController) {
        return;
    }
    
    NSDictionary* info = [aNotification userInfo];
    if (@available(iOS 9.0, *)) {
        BOOL isLocal = [info[UIKeyboardIsLocalUserInfoKey] boolValue];
        if (!isLocal) {
            return;
        }
    }
    
    [self saveDocumentIfNecessary];
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
