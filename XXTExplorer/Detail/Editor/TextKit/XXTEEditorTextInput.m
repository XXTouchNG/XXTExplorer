//
//  XXTEEditorTextInput.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTextInput.h"
#import "XXTEEditorLanguage.h"

@interface XXTEEditorTextInput ()

@property (nonatomic, strong) NSRegularExpression *increaseIndentPattern;
@property (nonatomic, strong) NSRegularExpression *decreaseIndentPattern;

@end

@implementation XXTEEditorTextInput

#pragma mark - Setters

- (void)setLanguage:(XXTEEditorLanguage *)language {
    _language = language;
    if (language) {
        NSString *increaseIndentPatternExpr = language.indent[@"increaseIndentPattern"];
        if (increaseIndentPatternExpr) {
            _increaseIndentPattern = [[NSRegularExpression alloc] initWithPattern:increaseIndentPatternExpr options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnixLineSeparators error:nil];
        }
        NSString *decreaseIndentPatternExpr = language.indent[@"decreaseIndentPattern"];
        if (decreaseIndentPatternExpr) {
            _decreaseIndentPattern = [[NSRegularExpression alloc] initWithPattern:decreaseIndentPatternExpr options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnixLineSeparators error:nil];
        }
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (self.autoIndent) {
        if (text.length == 1 &&
            [text isEqualToString:@"\n"])
        {
            // Just like what Textastic do
            
            NSString *stringRef = textView.text;
            
            NSUInteger lineStart = 0;
            NSUInteger contentsEnd = 0;
            [stringRef getLineStart:&lineStart end:NULL contentsEnd:&contentsEnd forRange:range];
            NSRange lineRange = NSMakeRange(lineStart, contentsEnd - lineStart);
            NSString *lineRef = [stringRef substringWithRange:lineRange];
            
            BOOL shouldIncrease = NO;
            BOOL shouldDecrease = NO;
            
            if (shouldIncrease == NO && shouldDecrease == NO) {
                if (self.increaseIndentPattern) {
                    NSTextCheckingResult *increaseCheck = [self.increaseIndentPattern firstMatchInString:lineRef options:NSMatchingWithTransparentBounds range:NSMakeRange(0, lineRef.length)];
                    if (increaseCheck && increaseCheck.range.location != NSNotFound) {
                        shouldIncrease = YES;
                    }
                }
            }
            
            if (shouldIncrease == NO && shouldDecrease == NO) {
                if (self.decreaseIndentPattern) {
                    NSTextCheckingResult *decreaseCheck = [self.decreaseIndentPattern firstMatchInString:lineRef options:NSMatchingWithTransparentBounds range:NSMakeRange(0, lineRef.length)];
                    if (decreaseCheck && decreaseCheck.range.location != NSNotFound) {
                        shouldDecrease = YES;
                    }
                }
            }
            
            
            NSRange lastBreak = [stringRef rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
            NSUInteger idx = lastBreak.location + 1;
            
            if (lastBreak.location == NSNotFound) idx = 0;
            else if (lastBreak.location + lastBreak.length == range.location) return YES;
            
            NSMutableString *tabStr = [[NSMutableString alloc] init];
            for (; idx < range.location; idx++)
            {
                char thisChar = (char) [stringRef characterAtIndex:idx];
                if (thisChar != ' ' && thisChar != '\t') break;
                else [tabStr appendFormat:@"%c", (char)thisChar];
            }
            
            if (self.tabWidthString) {
                if (shouldIncrease) {
                    [tabStr appendString:[[NSString alloc] initWithString:self.tabWidthString]];
                } else if (shouldDecrease) {
                    NSRange lastTabRange = [tabStr rangeOfString:self.tabWidthString options:NSBackwardsSearch range:NSMakeRange(0, tabStr.length)];
                    if (lastTabRange.location != NSNotFound) {
                        [tabStr deleteCharactersInRange:lastTabRange];
                    }
                }
            }
            
            [textView insertText:[NSString stringWithFormat:@"\n%@", tabStr]];
            return NO;
        }
        else if (text.length == 0 &&
                 range.length == 1)
        {
            // Auto backward? No...
        }
    }
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [_scrollViewDelegate scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [_scrollViewDelegate scrollViewDidScrollToTop:scrollView];
}

@end
