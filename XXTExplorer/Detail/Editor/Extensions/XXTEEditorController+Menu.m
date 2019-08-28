//
//  XXTEEditorController+Menu.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+Menu.h"

#import "XXTEEditorLanguage.h"
#import "XXTEEditorDefaults.h"
#import "XXTEEditorTextView.h"
#import "UITextView+TextRange.h"

#import "XXTENavigationController.h"
#import "XXTPickerFactory.h"
#import "XXTPickerSnippet.h"
#import "XXTPickerSnippetTask.h"

#import "XXTPickerNavigationController.h"


@implementation XXTEEditorController (Menu)

- (void)registerMenuActions {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *codeBlocksItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Code Snippets", nil) action:@selector(menuActionCodeBlocks:)];
    UIMenuItem *shiftLeftItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Shift Left", nil) action:@selector(menuActionShiftLeft:)];
    UIMenuItem *shiftRightItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Shift Right", nil) action:@selector(menuActionShiftRight:)];
    UIMenuItem *commentItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"(Un)Comment", nil) action:@selector(menuActionComment:)];
    [menuController setMenuItems:@[codeBlocksItem, commentItem, shiftLeftItem, shiftRightItem]];
}

- (void)dismissMenuActions {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems:nil];
}

#pragma mark - Menu Actions

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    if (
        action == @selector(menuActionComment:)
        || action == @selector(menuActionShiftLeft:)
        || action == @selector(menuActionShiftRight:)
        || action == @selector(menuActionCodeBlocks:)
        ) {
        if (YES == isReadOnlyMode ||
            YES == isLockedState ||
            nil == self.language) {
            return NO;
        }
    }
    if (
        action == @selector(menuActionComment:)
        || action == @selector(menuActionShiftLeft:)
        || action == @selector(menuActionShiftRight:)
        ) {
        NSRange selectedRange = [self.textView selectedRange];
        if (selectedRange.length == 0) {
            return NO;
        }
    }
    if (
        action == @selector(menuActionComment:)
        ) {
        NSString *singleComment = self.language.comments[kTextMateCommentStart];
        NSString *doubleCommentStart = self.language.comments[kTextMateCommentMultilineStart];
        NSString *doubleCommentEnd = self.language.comments[kTextMateCommentMultilineEnd];
        if (!singleComment && !doubleCommentStart && !doubleCommentEnd)
            return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)menuActionCodeBlocks:(UIMenuItem *)senderOrNil {
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
        [self setNeedsFocusTextView];
    }
    
    NSString *snippetPath = [XXTERootPath() stringByAppendingPathComponent:@"snippets"];
    XXTExplorerItemPicker *itemPicker = [[XXTExplorerItemPicker alloc] initWithEntryPath:snippetPath];
    itemPicker.title = NSLocalizedString(@"Code Snippets", nil);
    itemPicker.delegate = self;
    itemPicker.allowedExtensions = @[ @"snippet" ];
    XXTPickerNavigationController *navigationController = [[XXTPickerNavigationController alloc] initWithRootViewController:itemPicker];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navigationController.presentationController.delegate = self;
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void)menuActionShiftLeft:(UIMenuItem *)sender {
    BOOL softTab = XXTEDefaultsBool(XXTEEditorSoftTabs, NO);
    NSUInteger tabWidth = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4); // config
    NSString *tabWidthString = softTab ? [@"" stringByPaddingToLength:tabWidth withString:@" " startingAtIndex:0] : @"\t";
    
    NSRange fixedRange = [self.textView fixedSelectedTextRange];
    NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
    NSMutableString *mutStr = [NSMutableString new];
    [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSRange firstTabRange = [line rangeOfString:tabWidthString];
        if (firstTabRange.location == 0) {
            line = [line stringByReplacingCharactersInRange:firstTabRange withString:@""];
        }
        [mutStr appendFormat:@"%@\n", line];
    }];
    NSString *resultStr = [mutStr substringToIndex:mutStr.length - 1];
    [self.textView replaceRange:[self.textView textRangeFromNSRange:fixedRange] withText:resultStr];
}

- (void)menuActionShiftRight:(UIMenuItem *)sender {
    BOOL softTab = XXTEDefaultsBool(XXTEEditorSoftTabs, NO);
    NSUInteger tabWidth = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4); // config
    NSString *tabWidthString = softTab ? [@"" stringByPaddingToLength:tabWidth withString:@" " startingAtIndex:0] : @"\t";
    
    NSRange fixedRange = [self.textView fixedSelectedTextRange];
    NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
    NSMutableString *mutStr = [[NSMutableString alloc] initWithString:tabWidthString];
    [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        [mutStr appendFormat:@"%@\n%@", line, tabWidthString];
    }];
    NSString *resultStr = [mutStr substringToIndex:mutStr.length - tabWidthString.length - 1];
    [self.textView replaceRange:[self.textView textRangeFromNSRange:fixedRange] withText:resultStr];
}

- (void)menuActionComment:(UIMenuItem *)sender {
    NSString *singleComment = self.language.comments[kTextMateCommentStart];
    if (singleComment) {
        NSRange fixedRange = [self.textView fixedSelectedTextRange];
        NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
        __block BOOL hasComment = NO;
        [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            if (line.length != 0) {
                hasComment = NO;
                for (NSUInteger i = 0; i < line.length - singleComment.length - 1; i++) {
                    char c1 = (char) [line characterAtIndex:i];
                    if (c1 == ' ' || c1 == '\t') {
                        continue;
                    }
                    if ([line rangeOfString:singleComment options:0 range:NSMakeRange(i, singleComment.length)].location != NSNotFound) {
                        hasComment = YES;
                        break;
                    } else {
                        hasComment = NO;
                        *stop = YES;
                    }
                }
            }
        }];
        NSMutableString *mutStr = [NSMutableString new];
        if (hasComment) {
            [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
                NSString *testLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                BOOL commentFirst = ([testLine rangeOfString:singleComment].location == 0);
                if (commentFirst) {
                    NSRange firstCommentRange = [line rangeOfString:singleComment];
                    if (firstCommentRange.location != NSNotFound) {
                        line = [line stringByReplacingCharactersInRange:firstCommentRange withString:@""];
                    }
                }
                [mutStr appendFormat:@"%@\n", line];
            }];
        } else {
            [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
                [mutStr appendFormat:@"%@%@\n", singleComment, line];
            }];
        }
        NSString *resultStr = [mutStr substringToIndex:mutStr.length - 1];
        [self.textView replaceRange:[self.textView textRangeFromNSRange:fixedRange] withText:resultStr];
        return;
    }
    
    NSString *doubleCommentStart = self.language.comments[kTextMateCommentMultilineStart];
    NSString *doubleCommentEnd = self.language.comments[kTextMateCommentMultilineEnd];
    if (doubleCommentStart && doubleCommentEnd) {
        NSRange fixedRange = [self.textView fixedSelectedTextRange];
        NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
        NSMutableString *mutStr = [NSMutableString new];
        [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            [mutStr appendFormat:@"%@%@%@\n", doubleCommentStart, line, doubleCommentEnd];
        }];
        NSString *resultStr = [mutStr substringToIndex:mutStr.length - 1];
        [self.textView replaceRange:[self.textView textRangeFromNSRange:fixedRange] withText:resultStr];
        return;
    }
    
}

#pragma mark - XXTExplorerItemPickerDelegate

- (void)itemPickerDidCancelSelectingItem:(XXTExplorerItemPicker *)picker {
    [self setNeedsFocusTextView];
    @weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        if (!XXTE_IS_FULLSCREEN(picker)) {
            [self focusTextViewIfNecessary];
        }
    }];
}

- (void)itemPicker:(XXTExplorerItemPicker *)picker didSelectItemAtPath:(NSString *)path {
    NSError *initError = nil;
    XXTPickerSnippet *snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:path Error:&initError];
    if (initError) {
        [self presentErrorAlertController:initError fromController:picker];
        return;
    }
    XXTPickerSnippetTask *task = [[XXTPickerSnippetTask alloc] initWithSnippet:snippet];
    XXTPickerFactory *pickerFactory = [XXTPickerFactory sharedInstance];
    pickerFactory.delegate = self;
    [pickerFactory beginTask:task fromViewController:picker];
}

#pragma mark - XXTPickerFactoryDelegate

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippetTask *)task {
    return YES;
}

- (void)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippetTask *)task responseBlock:(void (^)(BOOL, NSError *))responseCallback {
    UIViewController *blockVC = blockInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error = nil;
        NSString *taskResult = nil;
        id result = [task generateWithError:&error];
        if ([result isKindOfClass:[NSString class]]) {
            taskResult = result;
        } else if ([result respondsToSelector:@selector(description)]) {
            taskResult = [result description];
        }
        dispatch_async_on_main_queue(^{
            blockInteractions(blockVC, NO);
            if (taskResult) {
                [self replaceSelectedRangeInTextView:self.textView withString:taskResult];
                [self setNeedsSaveDocument];
                [self setNeedsFocusTextView];
                responseCallback(YES, nil);
            } else {
                // [self presentErrorAlertController:error];
                responseCallback(NO, error);
            }
        });
    });
}

- (void)pickerFactory:(XXTPickerFactory *)factory taskDidFinished:(XXTPickerSnippetTask *)task {
    [self saveDocumentIfNecessary];
    [self focusTextViewIfNecessary];
}

- (void)replaceSelectedRangeInTextView:(UITextView *)textView
                            withString:(NSString *)string {
    UITextView *textInput = textView;
    NSRange selectedNSRange = textInput.selectedRange;
    UITextRange *selectedRange = [textInput selectedTextRange];
    
    NSString *stringRef = textInput.text;
    NSRange lastBreak = [stringRef rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, selectedNSRange.location)];
    
    NSUInteger idx = lastBreak.location + 1;
    
    BOOL autoIndent = YES;
    if (lastBreak.location == NSNotFound) {
        idx = 0;
    }
    else if (lastBreak.location + lastBreak.length == selectedNSRange.location) {
        autoIndent = NO;
    }
    
    NSString *replaceCode = nil;
    if (autoIndent) {
        NSMutableString *tabStr = [NSMutableString new];
        [tabStr appendString:@"\n"];
        for (; idx < selectedNSRange.location; idx++) {
            char thisChar = (char) [stringRef characterAtIndex:idx];
            if (thisChar != ' ' && thisChar != '\t') break;
            else [tabStr appendFormat:@"%c", (char)thisChar];
        }
        NSMutableString *mutableCode = [string mutableCopy];
        [mutableCode replaceOccurrencesOfString:@"\n"
                                     withString:tabStr
                                        options:NSCaseInsensitiveSearch
                                          range:NSMakeRange(0, mutableCode.length)];
        replaceCode = [mutableCode copy];
    } else {
        replaceCode = [string copy];
    }
    [textInput replaceRange:selectedRange withText:replaceCode];
    
    NSRange modelCurPos = [replaceCode rangeOfString:@"@@"];
    if (modelCurPos.location != NSNotFound) {
        NSRange curPos = NSMakeRange(
                                     selectedNSRange.location
                                     + modelCurPos.location, 2
                                     );
        UITextPosition *insertPos = [textInput positionFromPosition:selectedRange.start offset:curPos.location];
        
        UITextPosition *beginPos = [textInput beginningOfDocument];
        UITextPosition *startPos = [textInput positionFromPosition:beginPos offset:[textInput offsetFromPosition:beginPos toPosition:insertPos]];
        UITextRange *textRange = [textInput textRangeFromPosition:startPos toPosition:startPos];
        [textInput setSelectedTextRange:textRange];
        
        UITextPosition *curBegin = [textInput beginningOfDocument];
        UITextPosition *curStart = [textInput positionFromPosition:curBegin offset:curPos.location];
        UITextPosition *curEnd = [textInput positionFromPosition:curStart offset:curPos.length];
        UITextRange *curRange = [textInput textRangeFromPosition:curStart toPosition:curEnd];
        [textInput replaceRange:curRange withText:@""];
    }
}

#pragma mark - Snippet Error

- (void)presentErrorAlertController:(NSError *)error fromController:(UIViewController *)controller {
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        NSString *entryName = [self.entryPath lastPathComponent];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 8.0, *)) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Snippet Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), entryName, error.localizedFailureReason, error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [controller presentViewController:alertController animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Snippet Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), entryName, error.localizedFailureReason, error.localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alertView show];
        }
        XXTE_END_IGNORE_PARTIAL
    });
}

@end
