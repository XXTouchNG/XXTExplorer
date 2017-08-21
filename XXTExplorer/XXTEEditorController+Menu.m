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

#import "XXTEEditorTextView.h"

#import "SKHelper.h"
#import "SKHelperConfig.h"

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
    if (action == @selector(menuActionComment:) ||
        action == @selector(menuActionShiftLeft:) ||
        action == @selector(menuActionShiftRight:) ||
        action == @selector(menuActionCodeBlocks:)
        ) {
        if (YES == isReadOnlyMode || nil == self.helper.language) {
            return NO;
        }
    }
    if (action == @selector(menuActionComment:) ||
        action == @selector(menuActionShiftLeft:) ||
        action == @selector(menuActionShiftRight:)
        ) {
        NSRange selectedRange = [self.textView selectedRange];
        if (selectedRange.length == 0) {
            return NO;
        }
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)menuActionCodeBlocks:(UIMenuItem *)sender {
    
}

- (NSRange)fixedSelectedTextRange {
    NSRange selectedRange = [self.textView selectedRange];
    NSString *stringRef = self.textView.text;
    NSRange prevBreak = [stringRef rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, selectedRange.location)];
    if (prevBreak.location == NSNotFound)
    {
        prevBreak = NSMakeRange(0, 0);
    }
    return NSMakeRange(prevBreak.location + prevBreak.length,
                       selectedRange.location + selectedRange.length - prevBreak.location - prevBreak.length);
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
    NSString *symbol = self.helper.config.languageLineCommentSymbol;
    if (!symbol)
        return;
    
    NSRange fixedRange = [self fixedSelectedTextRange];
    NSString *selectedText = [self.textView.text substringWithRange:fixedRange];
    __block BOOL hasComment = NO;
    [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if (line.length != 0) {
            hasComment = NO;
            for (NSUInteger i = 0; i < line.length - symbol.length - 1; i++) {
                char c1 = (char) [line characterAtIndex:i];
                if (c1 == ' ' || c1 == '\t') {
                    continue;
                }
                if ([line rangeOfString:symbol options:0 range:NSMakeRange(i, symbol.length)].location != NSNotFound) {
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
            BOOL commentFirst = ([testLine rangeOfString:symbol].location == 0);
            if (commentFirst) {
                NSRange firstCommentRange = [line rangeOfString:symbol];
                if (firstCommentRange.location != NSNotFound) {
                    line = [line stringByReplacingCharactersInRange:firstCommentRange withString:@""];
                }
            }
            [mutStr appendFormat:@"%@\n", line];
        }];
    } else {
        [selectedText enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            [mutStr appendFormat:@"%@%@\n", symbol, line];
        }];
    }
    NSString *resultStr = [mutStr substringToIndex:mutStr.length - 1];
    [self.textView replaceRange:[self textRangeFromNSRange:fixedRange] withText:resultStr];
}

@end
