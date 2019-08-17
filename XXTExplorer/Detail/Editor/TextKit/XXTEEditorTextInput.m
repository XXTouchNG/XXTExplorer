//
//  XXTEEditorTextInput.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTextInput.h"
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
        NSString *increaseIndentPatternExpr = inputLanguage.indent[@"increaseIndentPattern"];
        if (increaseIndentPatternExpr) {
            _increaseIndentPattern = [[NSRegularExpression alloc] initWithPattern:increaseIndentPatternExpr options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnixLineSeparators error:nil];
        }
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
    
    NSRange selectedRange = textView.selectedRange;
    if (selectedRange.location > 0 &&
        selectedRange.length == 0)
    {
        NSString *stringRef = textView.text;
        unichar previousChar = [stringRef characterAtIndex:(selectedRange.location - 1)];
        
        if (previousChar == '{' || previousChar == '[' || previousChar == '(')
        {
            unichar findChar;
            if (previousChar == '{') {
                findChar = '}';
            } else if (previousChar == '[') {
                findChar = ']';
            } else { /* previousChar == '(' */
                findChar = ')';
            }
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
            if (findRange.location != NSNotFound) {
                [self.inputMaskView flashRange:findRange];
            }
        }
        else if (selectedRange.location > 1 && (previousChar == '}' || previousChar == ']' || previousChar == ')'))
        {
            unichar findChar;
            if (previousChar == '}') {
                findChar = '{';
            } else if (previousChar == ']') {
                findChar = '[';
            } else { /*  previousChar == ')' */
                findChar = '(';
            }
            
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
            if (findRange.location != NSNotFound) {
                [self.inputMaskView flashRange:findRange];
            }
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (text.length == 1 &&
        range.length == 0) { // receive ASCII from keyboard input
        unichar replChar = [text characterAtIndex:0];
        
        if (self.autoIndent) {
            if (replChar == '\n') {
                // Just like what Textastic do
                
                NSString *stringRef = textView.text;
                
                NSUInteger lineStart = 0;
                NSUInteger contentsEnd = 0;
                [stringRef getLineStart:&lineStart end:NULL contentsEnd:&contentsEnd forRange:range];
                if (range.location + range.length < contentsEnd) {
                    contentsEnd = range.location + range.length;
                }
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
        }
        
        if (self.autoBrackets) {
            if (replChar == '{' || replChar == '[' || replChar == '(') {
                if (replChar == '{')
                {
                    [textView insertText:@"{}"];
                }
                else if (replChar == '[')
                {
                    [textView insertText:@"[]"];
                }
                else if (replChar == '(')
                {
                    [textView insertText:@"()"];
                }
                [textView setSelectedRange:NSMakeRange(range.location + 1, 0)];
                return NO;
            } else if (replChar == '}' || replChar == ']' || replChar == ')') {
                NSString *stringRef = textView.text;
                
                if (range.location < stringRef.length) {
                    unichar nextCharacter = [stringRef characterAtIndex:range.location];
                    
                    if ((nextCharacter == '}' || nextCharacter == ']' || nextCharacter == ')') && replChar == nextCharacter)
                    {
                        [textView setSelectedRange:NSMakeRange(range.location + 1, 0)];
                        return NO;
                    }
                }
            }
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
