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
#import "XXTEAppDefines.h"

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
    if (XXTE_PAD) {
        
    } else {
        if (XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO)) {
            self.textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        [self reloadViewConstraints];
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardDidAppear:(NSNotification *)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    UITextView *textView = self.textView;
    UITextRange * selectionRange = [textView selectedTextRange];
    CGRect selectionStartRect = [textView caretRectForPosition:selectionRange.start];
    CGRect selectionEndRect = [textView caretRectForPosition:selectionRange.end];
    CGPoint selectionCenterPoint = (CGPoint){(selectionStartRect.origin.x + selectionEndRect.origin.x)/2,(selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
    
    if (!CGRectContainsPoint(aRect, selectionCenterPoint) ) {
        [textView scrollRectToVisible:CGRectMake(selectionStartRect.origin.x, selectionStartRect.origin.y, selectionEndRect.origin.x - selectionStartRect.origin.x, selectionStartRect.size.height) animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillDisappear:(NSNotification *)aNotification
{
    if (XXTE_PAD) {
        
    } else {
        if (XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO)) {
            self.textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }
        [self reloadViewConstraints];
    }
    
    UITextView *textView = self.textView;
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardDidDisappear:(NSNotification *)aNotification
{
    [self saveDocumentIfNecessary];
}

@end
