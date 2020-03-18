//
//  XXTEEditorController+TerminalControl.m
//  XXTExplorer
//
//  Created by MMM on 8/14/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorController+TerminalControl.h"
#import "XXTEEditorTextView.h"
#import "XXTEEditorMaskView.h"


@implementation XXTEEditorController (TerminalControl)

- (void)terminalDidTerminateWithSuccess:(UIViewController *)sender {
    
}

- (void)terminalDidTerminate:(UIViewController *)sender withError:(NSError *)error {
    return;
    if (@available(iOS 9.0, *)) {
        NSString *errorDescription = error.localizedDescription;
        if (!errorDescription) {
            return;
        }
        static NSRegularExpression *lineNumberRegex = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            lineNumberRegex = [NSRegularExpression regularExpressionWithPattern:@":([0-9]+):\\s*(.*)$" options:kNilOptions error:nil];
        });
        NSTextCheckingResult *matchResult = [lineNumberRegex firstMatchInString:errorDescription options:kNilOptions range:NSMakeRange(0, errorDescription.length)];
        if (matchResult.numberOfRanges != 3) {
            return;
        }
        NSInteger lineNumber = [[errorDescription substringWithRange:[matchResult rangeAtIndex:1]] integerValue];
        NSString *errorReason = [errorDescription substringWithRange:[matchResult rangeAtIndex:2]];
#ifdef DEBUG
        NSLog(@"%ld: %@", (long)lineNumber, errorReason);
#endif
        
        [self.maskView removeAllLineMasks];
        XXTEEditorLineMask *newMask = [[XXTEEditorLineMask alloc] init];
        newMask.lineIndex = lineNumber - 1;
        newMask.maskType = XXTEEditorLineMaskError;
        newMask.maskDescription = errorReason;
        [self.maskView addLineMask:newMask];
        [self.maskView scrollToLineMask:newMask animated:!XXTE_IS_FULLSCREEN(sender)];
    }
}

@end
