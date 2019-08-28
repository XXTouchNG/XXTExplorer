//
//  XXTEEditorTextInput.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTextInput.h"
#import "UITextView+TextRange.h"
#import "XXTEEditorLanguage.h"
#import "XXTEEditorMaskView.h"

static NSUInteger kXXTEEditorTextInputMaximumBracketCheckCharacterCount = 1024 * 10;  // 10k


@interface XXTEEditorTextInput ()

@property (nonatomic, strong) NSRegularExpression *increaseIndentPattern;
@property (nonatomic, strong) NSRegularExpression *decreaseIndentPattern;

@end

@implementation XXTEEditorTextInput

#pragma mark - Setters

- (void)setInputLanguage:(XXTEEditorLanguage *)inputLanguage {
    _inputLanguage = inputLanguage;
    
    if (inputLanguage) {
        
        /// Caching increase indent pattern
        NSString *increaseIndentPatternExpr = inputLanguage.indent[@"increaseIndentPattern"];
        if (increaseIndentPatternExpr) {
            _increaseIndentPattern = [[NSRegularExpression alloc] initWithPattern:increaseIndentPatternExpr options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnixLineSeparators error:nil];
        }
        
        /// Caching decrease indent pattern
        NSString *decreaseIndentPatternExpr = inputLanguage.indent[@"decreaseIndentPattern"];
        if (decreaseIndentPatternExpr) {
            _decreaseIndentPattern = [[NSRegularExpression alloc] initWithPattern:decreaseIndentPatternExpr options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnixLineSeparators error:nil];
        }
        
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView {
    
    if (!self.autoBrackets) {
        return;
    }
    
    /// Auto Brackets (Flash Animation)
    NSRange selectedRange = textView.selectedRange;
    if (selectedRange.location > 0 &&
        selectedRange.length == 0) {
        
        /// Original text
        NSString *stringRef = textView.text;
        
        /// Find previous character
        unichar previousChar = [stringRef characterAtIndex:(selectedRange.location - 1)];
        
        if (previousChar == '{' || previousChar == '[' || previousChar == '(') {
            /// If it is a head bracket,
            /// should match a tail bracket
            unichar findChar;
            if (previousChar == '{') {
                findChar = '}';
            } else if (previousChar == '[') {
                findChar = ']';
            } else { /* previousChar == '(' */
                findChar = ')';
            }
            
            /// Find the matching tail bracket
            NSRange findRange = NSMakeRange(NSNotFound, 0);
            NSUInteger prevCount = 0;
            NSRange searchRange = NSMakeRange(selectedRange.location, MIN(stringRef.length - selectedRange.location, kXXTEEditorTextInputMaximumBracketCheckCharacterCount));
            for (NSUInteger idx = searchRange.location; idx < NSMaxRange(searchRange); idx++) {
                unichar ch = [stringRef characterAtIndex:idx];
                if (ch == previousChar) {
                    prevCount++;
                } else if (ch == findChar) {
                    if (prevCount == 0) {
                        findRange = NSMakeRange(idx, 1);
                        break;
                    }
                    prevCount--;
                }
                
            }
            
            /// Found
            if (findRange.location != NSNotFound) {
                [self.inputMaskView flashRange:findRange];
            }
        }
        else if (selectedRange.location > 1 && (previousChar == '}' || previousChar == ']' || previousChar == ')')) {
            /// If it is a tail bracket,
            /// should match a head bracket
            unichar findChar;
            if (previousChar == '}') {
                findChar = '{';
            } else if (previousChar == ']') {
                findChar = '[';
            } else { /*  previousChar == ')' */
                findChar = '(';
            }
            
            /// Find the matching head bracket
            NSRange findRange = NSMakeRange(NSNotFound, 0);
            NSUInteger prevCount = 0;
            NSUInteger searchStart = ((selectedRange.location - 1) < kXXTEEditorTextInputMaximumBracketCheckCharacterCount ? 0 : ((selectedRange.location - 1) - kXXTEEditorTextInputMaximumBracketCheckCharacterCount));
            NSUInteger searchEnd = (selectedRange.location - 1);
            for (NSUInteger idx = searchEnd - 1; idx >= searchStart; idx--) {
                unichar ch = [stringRef characterAtIndex:idx];
                if (ch == previousChar) {
                    prevCount++;
                } else if (ch == findChar) {
                    if (prevCount == 0) {
                        findRange = NSMakeRange(idx, 1);
                        break;
                    }
                    prevCount--;
                }
                
            }
            
            /// Found
            if (findRange.location != NSNotFound) {
                [self.inputMaskView flashRange:findRange];
            }
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    /// Available only when enter character
    if (text.length == 1 &&
        range.length == 0) {
        
        /// Receive ASCII from keyboard input
        unichar replChar = [text characterAtIndex:0];
        
        /// Auto Indents, just like what Textastic do
        if (self.autoIndent && nil != self.tabWidthString) {
            
            /// Replaced text
            NSString *stringRef = [textView.text stringByReplacingCharactersInRange:range withString:text];
            
            /// Get text line range
            NSUInteger lineStart = 0;
            NSUInteger contentsEnd = 0;
            [stringRef getLineStart:&lineStart end:NULL contentsEnd:&contentsEnd forRange:range];
            if (range.location + range.length < contentsEnd) {
                contentsEnd = range.location + range.length;
            }
            NSRange lineRange = NSMakeRange(lineStart, contentsEnd - lineStart + 1);
            NSString *lineRef = [stringRef substringWithRange:lineRange];
            
            BOOL shouldIncrease = NO;
            BOOL shouldDecrease = NO;
            
            /// Check auto increase
            if (shouldIncrease == NO && shouldDecrease == NO && nil != self.increaseIndentPattern) {
                if (replChar == '\n') {  // Increasement only occurs when input character is '\n'
                    NSTextCheckingResult *increaseCheck = [self.increaseIndentPattern firstMatchInString:lineRef options:NSMatchingWithTransparentBounds range:NSMakeRange(0, lineRef.length)];
                    if (increaseCheck && increaseCheck.range.location != NSNotFound) {
                        shouldIncrease = YES;
                    }
                }
            }
            
            /// Check auto decrease
            if (shouldIncrease == NO && shouldDecrease == NO && nil != self.decreaseIndentPattern) {
                if (replChar != '\n') {  // Decreasement may occur at any time
                    NSTextCheckingResult *decreaseCheck = [self.decreaseIndentPattern firstMatchInString:lineRef options:NSMatchingWithTransparentBounds range:NSMakeRange(0, lineRef.length)];
                    if (decreaseCheck && decreaseCheck.range.location != NSNotFound) {
                        shouldDecrease = YES;
                    }
                }
            }
            
            /// Perform auto indent
            if (shouldIncrease || shouldDecrease || replChar == '\n') {
                
                /// Find tab or space before current line
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
                
                if (shouldIncrease || replChar == '\n') {
                    /// Perform increase
                    if (shouldIncrease) {
                        [tabStr appendString:[[NSString alloc] initWithString:self.tabWidthString]];
                    }
                    /// Or continue with current indent
                    [textView insertText:[@"\n" stringByAppendingString:tabStr]];
                    /// Handled
                    return NO;
                }
                else if (shouldDecrease) {
                    /// Find available decrease range
                    NSRange lastTabRange = [tabStr rangeOfString:self.tabWidthString options:NSBackwardsSearch range:NSMakeRange(0, tabStr.length)];
                    if (lastTabRange.location != NSNotFound) {
                        /// Perform decrease
                        [tabStr deleteCharactersInRange:lastTabRange];
                        /// Replace actual line range
                        NSRange actualLineRange = NSMakeRange(lineRange.location, lineRange.length - 1);
                        UITextRange *lineTextRange = [textView textRangeFromNSRange:actualLineRange];
                        NSString *charsLeft = [stringRef substringWithRange:NSMakeRange(idx, range.location - idx + 1)];
                        [textView replaceRange:lineTextRange withText:[tabStr stringByAppendingString:charsLeft]];
                        /// Handled
                        return NO;
                    }
                }
            }
        }
        
        /// Auto Brackets
        if (self.autoBrackets) {
            if (replChar == '{' || replChar == '[' || replChar == '(') {
                if (replChar == '{')
                    [textView insertText:@"{}"];
                else if (replChar == '[')
                    [textView insertText:@"[]"];
                else if (replChar == '(')
                    [textView insertText:@"()"];
                /// Adjust caret position
                [textView setSelectedRange:NSMakeRange(range.location + 1, 0)];
                /// Handled
                return NO;
            }
        }
        
        /// Character Overlaps
        if (replChar == '}' || replChar == ']' || replChar == ')' || replChar == '"') {
            NSString *stringRef = textView.text;
            /// Has next character
            if (range.location < stringRef.length) {
                unichar nextCharacter = [stringRef characterAtIndex:range.location];
                /// Overlap the same character
                if (replChar == nextCharacter) {
                    /// Adjust caret position
                    [textView setSelectedRange:NSMakeRange(range.location + 1, 0)];
                    /// Handled
                    return NO;
                }
            }
        }
    }
    
    /// Not handled
    return YES;
}

#pragma mark - UIScrollViewDelegate (Message Forwarding)

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [_scrollViewDelegate scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [_scrollViewDelegate scrollViewDidScrollToTop:scrollView];
}

@end
