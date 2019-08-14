//
//  XXTEEditorTextView+TextRange.h
//  XXTExplorer
//
//  Created by MMM on 8/14/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface XXTEEditorTextView (TextRange)

- (NSRange)fixedSelectedTextRange;
- (UITextRange *)textRangeFromNSRange:(NSRange)range;
- (CGRect)lineRectForRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
