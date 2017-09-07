//
//  XXTEEditorTextInput.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTextInput.h"

@implementation XXTEEditorTextInput

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
            NSRange lastBreak = [stringRef rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
            
            NSUInteger idx = lastBreak.location + 1;
            
            if (lastBreak.location == NSNotFound) idx = 0;
            else if (lastBreak.location + lastBreak.length == range.location) return YES;
            
            NSMutableString *tabStr = [NSMutableString new];
            for (; idx < range.location; idx++)
            {
                char thisChar = (char) [stringRef characterAtIndex:idx];
                if (thisChar != ' ' && thisChar != '\t') break;
                else [tabStr appendFormat:@"%c", (char)thisChar];
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

@end
