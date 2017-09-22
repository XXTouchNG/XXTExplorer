//
//  XXTEEditorController+Menu.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+Menu.h"

#import "XXTEAppDefines.h"
#import "XXTEEditorDefaults.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

#import "XXTEEditorTextView.h"

#import "XXTECommonNavigationController.h"
#import "XXTPickerFactory.h"
#import "XXTPickerSnippet.h"

#import "XXTPickerNavigationController.h"

#import "XXTEEditorLanguage.h"

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
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    if (
        action == @selector(menuActionComment:)
        || action == @selector(menuActionShiftLeft:)
        || action == @selector(menuActionShiftRight:)
        || action == @selector(menuActionCodeBlocks:)
        ) {
        if (YES == isReadOnlyMode
            || nil == self.language) {
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

- (void)menuActionCodeBlocks:(UIMenuItem *)sender {
    NSString *snippetPath = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:@"snippets"];
    XXTExplorerItemPicker *itemPicker = [[XXTExplorerItemPicker alloc] initWithEntryPath:snippetPath];
    itemPicker.delegate = self;
    itemPicker.allowedExtensions = @[ @"snippet" ];
    XXTPickerNavigationController *navigationController = [[XXTPickerNavigationController alloc] initWithRootViewController:itemPicker];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (NSRange)fixedSelectedTextRange {
    NSRange selectedRange = [self.textView selectedRange];
    NSString *stringRef = self.textView.text;
    NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
    [stringRef getLineStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:selectedRange];
    return NSMakeRange(lineStart, contentsEnd - lineStart);
}

- (UITextRange *)textRangeFromNSRange:(NSRange)range {
    UITextPosition *startPosition = [self.textView positionFromPosition:self.textView.beginningOfDocument offset:(NSInteger)range.location];
    UITextPosition *endPosition = [self.textView positionFromPosition:startPosition offset:(NSInteger)range.length];
    UITextRange *textRange = [self.textView textRangeFromPosition:startPosition toPosition:endPosition];
    return textRange;
}

- (void)menuActionShiftLeft:(UIMenuItem *)sender {
    BOOL softTab = XXTEDefaultsBool(XXTEEditorSoftTabs, NO);
    NSUInteger tabWidth = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4); // config
    NSString *tabWidthString = softTab ? [@"" stringByPaddingToLength:tabWidth withString:@" " startingAtIndex:0] : @"\t";
    
    NSRange fixedRange = [self fixedSelectedTextRange];
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
    [self.textView replaceRange:[self textRangeFromNSRange:fixedRange] withText:resultStr];
}

- (void)menuActionShiftRight:(UIMenuItem *)sender {
    BOOL softTab = XXTEDefaultsBool(XXTEEditorSoftTabs, NO);
    NSUInteger tabWidth = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4); // config
    NSString *tabWidthString = softTab ? [@"" stringByPaddingToLength:tabWidth withString:@" " startingAtIndex:0] : @"\t";
    
    NSRange fixedRange = [self fixedSelectedTextRange];
    NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
    NSMutableString *mutStr = [[NSMutableString alloc] initWithString:tabWidthString];
    [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        [mutStr appendFormat:@"%@\n%@", line, tabWidthString];
    }];
    NSString *resultStr = [mutStr substringToIndex:mutStr.length - tabWidthString.length - 1];
    [self.textView replaceRange:[self textRangeFromNSRange:fixedRange] withText:resultStr];
}

- (void)menuActionComment:(UIMenuItem *)sender {
    NSString *singleComment = self.language.comments[kTextMateCommentStart];
    if (singleComment) {
        NSRange fixedRange = [self fixedSelectedTextRange];
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
        [self.textView replaceRange:[self textRangeFromNSRange:fixedRange] withText:resultStr];
        return;
    }
    
    NSString *doubleCommentStart = self.language.comments[kTextMateCommentMultilineStart];
    NSString *doubleCommentEnd = self.language.comments[kTextMateCommentMultilineEnd];
    if (doubleCommentStart && doubleCommentEnd) {
        NSRange fixedRange = [self fixedSelectedTextRange];
        NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
        NSMutableString *mutStr = [NSMutableString new];
        [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            [mutStr appendFormat:@"%@%@%@\n", doubleCommentStart, line, doubleCommentEnd];
        }];
        NSString *resultStr = [mutStr substringToIndex:mutStr.length - 1];
        [self.textView replaceRange:[self textRangeFromNSRange:fixedRange] withText:resultStr];
        return;
    }
    
}

#pragma mark - XXTExplorerItemPickerDelegate

- (void)itemPickerDidCancelSelectingItem:(XXTExplorerItemPicker *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self setNeedsFocusTextView];
    }];
}

- (void)itemPicker:(XXTExplorerItemPicker *)picker didSelectItemAtPath:(NSString *)path {
    NSError *initError = nil;
    XXTPickerSnippet *snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:path Error:&initError];
    if (initError) {
        [self presentErrorAlertController:initError];
        return;
    }
    XXTPickerFactory *pickerFactory = [[XXTPickerFactory alloc] init];
    pickerFactory.delegate = self;
    [pickerFactory executeTask:snippet fromViewController:picker];
    self.pickerFactory = pickerFactory; // you must hold the factory until its tasks are all finished.
}

#pragma mark - XXTPickerFactoryDelegate

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippet *)task {
    return YES;
}

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippet *)task {
    blockUserInteractions(self, YES, 0);
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
            blockUserInteractions(self, NO, 0);
            if (taskResult) {
                [self replaceSelectedRangeInTextView:self.textView withString:taskResult];
                [self setNeedsFocusTextView];
            } else {
                [self presentErrorAlertController:error];
            }
        });
    });
    return YES;
}

- (void)replaceSelectedRangeInTextView:(UITextView *)textView withString:(NSString *)string {
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

- (void)presentErrorAlertController:(NSError *)error {
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        NSString *entryName = [self.entryPath lastPathComponent];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 8.0, *)) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Snippet Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), entryName, error.localizedDescription, error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Snippet Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), entryName, error.localizedDescription, error.localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alertView show];
        }
        XXTE_END_IGNORE_PARTIAL
    });
}

@end
