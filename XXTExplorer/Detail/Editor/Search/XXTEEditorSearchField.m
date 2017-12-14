//
//  XXTEEditorSearchField.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchField.h"

@implementation XXTEEditorSearchField

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.spellCheckingType = UITextSpellCheckingTypeNo;
    if (@available(iOS 11.0, *)) {
        self.smartDashesType = UITextSmartDashesTypeNo;
        self.smartQuotesType = UITextSmartQuotesTypeNo;
        self.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    }
    self.enablesReturnKeyAutomatically = YES;
    self.keyboardAppearance = UIKeyboardAppearanceDefault;
    if (@available(iOS 8.2, *)) {
        self.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightLight];
    } else {
        self.font = [UIFont systemFontOfSize:14.0];
    }
    self.textAlignment = NSTextAlignmentLeft;
    self.clearButtonMode = UITextFieldViewModeAlways;
    self.returnKeyType = UIReturnKeyNext;
}

- (void)setPlaceholder:(NSString *)placeholder {
    [super setPlaceholder:placeholder];
    [self reloadPlaceholder];
}

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    [self reloadPlaceholder];
}

- (void)reloadPlaceholder {
    if (self.placeholder.length && self.textColor) {
        NSMutableAttributedString *attrPlaceholder = [[NSMutableAttributedString alloc] initWithString:self.placeholder];
        UIColor *placeholderColor = [self.textColor colorWithAlphaComponent:0.3];
        UIFont *placeholderFont = nil;
        if (@available(iOS 8.2, *)) {
            placeholderFont = [UIFont systemFontOfSize:14.0 weight:UIFontWeightLight];
        } else {
            placeholderFont = [UIFont systemFontOfSize:14.0];
        }
        NSDictionary *placeholderAttrs =
        @{ NSForegroundColorAttributeName: placeholderColor, NSFontAttributeName: placeholderFont };
        [attrPlaceholder addAttributes:placeholderAttrs range:NSMakeRange(0, attrPlaceholder.length)];
        [self setAttributedPlaceholder:attrPlaceholder];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subView;
            [button setImage:[[button imageForState:UIControlStateNormal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                    forState:UIControlStateNormal];
            button.tintColor = self.tintColor;
        }
    }
}

@end
