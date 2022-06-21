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


@implementation XXTEEditorController (Menu)

- (void)registerMenuActions {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *shiftLeftItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Shift Left", nil) action:@selector(menuActionShiftLeft:)];
    UIMenuItem *shiftRightItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Shift Right", nil) action:@selector(menuActionShiftRight:)];
    UIMenuItem *commentItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"(Un)Comment", nil) action:@selector(menuActionComment:)];
    [menuController setMenuItems:@[commentItem, shiftLeftItem, shiftRightItem]];
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
        ) {
        if (!self.textView.isFirstResponder) {
            return NO;
        }
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

@end
