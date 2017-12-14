//
//  XXTEEditorController+State.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+State.h"

#import "XXTENotificationCenterDefines.h"
#import "XXTEEditorTextView.h"

@implementation XXTEEditorController (State)

- (void)registerStateNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotifications:) name:XXTENotificationEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextViewNotifications:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextViewNotifications:) name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextViewNotifications:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)dismissStateNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XXTENotificationEvent object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

#pragma mark - Notifications

- (void)handleApplicationNotifications:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidEnterBackground])
    {
        [self saveDocumentIfNecessary];
    }
}

- (void)handleTextViewNotifications:(NSNotification *)aNotification {
    id <UITextInput> textInput = aNotification.object;
    if (textInput != self.textView) {
        return;
    }
    if ([aNotification.name isEqualToString:UITextViewTextDidBeginEditingNotification]) {
        // Begin
        [self invalidateSyntaxCaches];
    } else if ([aNotification.name isEqualToString:UITextViewTextDidEndEditingNotification]) {
        // End
        [self saveDocumentIfNecessary];
        if (self.navigationController) {
            [self reloadAttributesIfNecessary];
        }
    } else if ([aNotification.name isEqualToString:UITextViewTextDidChangeNotification]) {
        // Changed
        if ([textInput isKindOfClass:[XXTEEditorTextView class]]) {
            XXTEEditorTextView *textView = (XXTEEditorTextView *)textInput;
            if ([textView isEditable]) {
                [self setNeedsSaveDocument];
                [self setNeedsReloadAttributes];
            }
        }
    }
}

@end
