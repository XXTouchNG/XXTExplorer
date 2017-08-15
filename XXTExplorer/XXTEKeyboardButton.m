//
//  XXTEKeyboardButton.m
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEKeyboardButton.h"
#import "XXTEKeyboardButtonView.h"

@interface XXTEKeyboardButton ()

@property(nonatomic, strong) UILabel *inputLabel;
@property(nonatomic, strong) XXTEKeyboardButtonView *buttonView;
@property(nonatomic, assign) XXTEKeyboardButtonPosition position;
@property(nonatomic, assign) CGFloat keyCornerRadius UI_APPEARANCE_SELECTOR;

@property(nonatomic, strong) NSMutableArray <UILabel *> *labels;
@property(nonatomic, assign) CGFloat labelWidth;
@property(nonatomic, assign) CGFloat labelHeight;
@property(nonatomic, assign) CGFloat leftInset;
@property(nonatomic, assign) CGFloat rightInset;
@property(nonatomic, assign) CGFloat topInset;
@property(nonatomic, assign) CGFloat bottomInset;
@property(nonatomic, assign) CGFloat fontSize;
@property(nonatomic, assign) CGFloat bigFontSize;
@property(nonatomic, assign) BOOL trackPoint;
@property(nonatomic, assign) BOOL tabButton;
@property(nonatomic, assign) CGPoint touchBeginPoint;
@property(nonatomic, strong) NSDate *firstTapDate;
@property(nonatomic, assign) CGRect startLocation;

@end

#define TIME_INTERVAL_FOR_DOUBLE_TAP 0.4

@implementation XXTEKeyboardButton

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // Styling
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    self.layer.masksToBounds = NO;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

    if (_style == XXTEKeyboardButtonStylePhone) {
        _labelWidth = 14.f;
        _labelHeight = 14.f;
        _leftInset = 4.f;
        _rightInset = 4.f;
        _topInset = 2.f;
        _bottomInset = 2.5f;
        _fontSize = 10.f;
        _bigFontSize = 14.f;
    } else if (_style == XXTEKeyboardButtonStyleTablet) {
        _labelWidth = 20.f;
        _labelHeight = 20.f;
        _leftInset = 9.f;
        _rightInset = 9.f;
        _topInset = 3.f;
        _bottomInset = 8.f;
        _fontSize = 15.f;
        _bigFontSize = 20.f;
    }

    self.labels = [[NSMutableArray alloc] init];

    UIFont *f = [UIFont fontWithName:@"CourierNewPSMT" size:_fontSize];
    UIFont *bf = [UIFont fontWithName:@"CourierNewPSMT" size:_bigFontSize];

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(_leftInset, _topInset, _labelWidth, _labelHeight)];
    l.textAlignment = NSTextAlignmentLeft;
    l.text = @"1";
    l.font = f;
    [self addSubview:l];
    [l setHighlightedTextColor:[UIColor whiteColor]];
    l.backgroundColor = [UIColor clearColor];
    [self.labels addObject:l];

    l = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - _labelWidth - _rightInset, _topInset, _labelWidth, _labelHeight)];
    l.textAlignment = NSTextAlignmentRight;
    l.text = @"2";
    l.font = f;
    l.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:l];
    [l setHighlightedTextColor:[UIColor whiteColor]];
    l.backgroundColor = [UIColor clearColor];
    [self.labels addObject:l];

    l = [[UILabel alloc] initWithFrame:CGRectIntegral(CGRectMake((self.frame.size.width - _labelWidth - _leftInset - _rightInset) / 2 + _leftInset, (self.frame.size.height - _labelHeight - _topInset - _bottomInset) / 2 + _topInset, _labelWidth, _labelHeight))];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"3";
    l.font = bf;
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:l];
    [l setHighlightedTextColor:[UIColor whiteColor]];
    l.backgroundColor = [UIColor clearColor];
    [self.labels addObject:l];

    l = [[UILabel alloc] initWithFrame:CGRectMake(_leftInset, (self.frame.size.height - _labelHeight - _bottomInset), _labelWidth, _labelHeight)];
    l.textAlignment = NSTextAlignmentLeft;
    l.text = @"4";
    l.font = f;
    [self addSubview:l];
    [l setHighlightedTextColor:[UIColor whiteColor]];
    l.backgroundColor = [UIColor clearColor];
    [self.labels addObject:l];

    l = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - _labelWidth - _rightInset, (self.frame.size.height - _labelHeight - _bottomInset), _labelWidth, _labelHeight)];
    l.textAlignment = NSTextAlignmentRight;
    l.text = @"5";
    l.font = f;
    l.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:l];
    [l setHighlightedTextColor:[UIColor whiteColor]];
    l.backgroundColor = [UIColor clearColor];
    [self.labels addObject:l];

    _firstTapDate = [[NSDate date] dateByAddingTimeInterval:-1];

    [self updateDisplayStyle];
}

- (void)didMoveToSuperview {
    [self updateButtonPosition];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
    [self updateButtonPosition];
}

- (void)setInput:(NSString *)input {
    _input = input;

    for (NSUInteger i = 0; i < MIN(input.length, 5); i++) {
        UILabel *currentLabel = self.labels[i];
        NSString *currentChar = [input substringWithRange:NSMakeRange(i, 1)];
        [currentLabel setText:currentChar];
        [currentLabel setAdjustsFontSizeToFitWidth:YES];

        NSString *flag = [input substringToIndex:1];
        if ([flag isEqualToString:@"◉"] || [flag isEqualToString:@"T"]) {

            self.trackPoint = [flag isEqualToString:@"◉"];
            self.tabButton = [flag isEqualToString:@"T"];

            if (i != 2)
                [currentLabel setHidden:YES];
            else {
                [currentLabel setFont:[UIFont systemFontOfSize:self.bounds.size.width * .6f]];
                if (self.trackPoint) {
                    [currentLabel setTextColor:[UIColor redColor]];
                    [currentLabel setText:@"◉"];
                    [currentLabel setFrame:self.bounds];
                } else {
                    [currentLabel setText:@"→"];
                    [currentLabel setFrame:self.bounds];
                }
            }
        } else {
            if (i == 2) {
                [currentLabel setFont:[UIFont systemFontOfSize:self.bigFontSize]];
            }
        }
    }
}

- (void)setStyle:(XXTEKeyboardButtonStyle)style {
    [self willChangeValueForKey:NSStringFromSelector(@selector(style))];
    _style = style;
    [self didChangeValueForKey:NSStringFromSelector(@selector(style))];

    [self updateDisplayStyle];
}

- (void)setTextInput:(id <UITextInput>)textInput {
    NSAssert([textInput conformsToProtocol:@protocol(UITextInput)], @"<XXTEKeyboardButton> The text input object must conform to the UITextInput protocol!");

    [self willChangeValueForKey:NSStringFromSelector(@selector(textInput))];
    _textInput = textInput;
    [self didChangeValueForKey:NSStringFromSelector(@selector(textInput))];
}

#pragma mark - Internal - UI

- (void)selectLabel:(int)idx {
    if (idx == -1) {
        self.output = nil;
    } else {
        self.output = self.labels[(NSUInteger) idx].text;
        [self.buttonView setNeedsDisplay];
    }
}

- (void)showInputView {
    [self hideInputView];
    self.buttonView = [[XXTEKeyboardButtonView alloc] initWithKeyboardButton:self];
    [self.window addSubview:self.buttonView];
}

- (void)hideInputView {
    [self.buttonView removeFromSuperview];
    self.buttonView = nil;

    [self setNeedsDisplay];
}

- (void)updateDisplayStyle {
    switch (_style) {
        case XXTEKeyboardButtonStylePhone:
            _keyCornerRadius = 4.f;
            break;

        case XXTEKeyboardButtonStyleTablet:
            _keyCornerRadius = 6.f;
            break;

        default:
            break;
    }

    [self setNeedsDisplay];
}

#pragma mark - Internal - Text Handling

- (void)trackPointStarted {
    _startLocation = [_textInput caretRectForPosition:_textInput.selectedTextRange.start];
}

- (void)trackPointMovedX:(CGFloat)xdiff Y:(CGFloat)ydiff selecting:(BOOL)selecting {
    CGRect loc = _startLocation;

    loc.origin.y += ((UITextView *) _textInput).font.lineHeight;

    UITextPosition *p1 = [_textInput closestPositionToPoint:loc.origin];

    loc.origin.x -= xdiff;
    loc.origin.y -= ydiff;

    UITextPosition *p2 = [_textInput closestPositionToPoint:loc.origin];

    if (!selecting) {
        p1 = p2;
    }
    UITextRange *r = [_textInput textRangeFromPosition:p1 toPosition:p2];

    _textInput.selectedTextRange = r;
}

- (void)insertText:(NSString *)text {
    BOOL shouldInsertText = YES;

    if ([self.textInput isKindOfClass:[UITextView class]]) {
        // Call UITextViewDelegate methods if necessary
        UITextView *textView = (UITextView *) self.textInput;
        NSRange selectedRange = textView.selectedRange;

        if ([textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldInsertText = [textView.delegate textView:textView shouldChangeTextInRange:selectedRange replacementText:text];
        }
    } else if ([self.textInput isKindOfClass:[UITextField class]]) {
        // Call UITextFieldDelgate methods if necessary
        UITextField *textField = (UITextField *) self.textInput;
        NSRange selectedRange = [self textInputSelectedRange];

        if ([textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            shouldInsertText = [textField.delegate textField:textField shouldChangeCharactersInRange:selectedRange replacementString:text];
        }
    }

    if (shouldInsertText) {
        [self.textInput insertText:text];
    }
}

- (NSRange)textInputSelectedRange {
    UITextPosition *beginning = self.textInput.beginningOfDocument;

    UITextRange *selectedRange = self.textInput.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;

    const NSInteger location = [self.textInput offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self.textInput offsetFromPosition:selectionStart toPosition:selectionEnd];

    return NSMakeRange((NSUInteger) location, (NSUInteger) length);
}

- (void)selectionComplete {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UITextRange *selectionRange = [_textInput selectedTextRange];
    CGRect selectionStartRect = [_textInput caretRectForPosition:selectionRange.start];
    CGRect selectionEndRect = [_textInput caretRectForPosition:selectionRange.end];
    CGPoint selectionCenterPoint = (CGPoint) {(selectionStartRect.origin.x + selectionEndRect.origin.x) / 2, (selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
    [menuController setTargetRect:[_textInput caretRectForPosition:[_textInput closestPositionToPoint:selectionCenterPoint withinRange:selectionRange]] inView:(UITextView *) _textInput];
    [menuController setMenuVisible:YES animated:YES];
}

#pragma mark - Internal - Configuration

- (void)updateButtonPosition {
    // Determine the button sposition state based on the superview padding
    CGFloat leftPadding = CGRectGetMinX(self.frame);
    CGFloat rightPadding = CGRectGetMaxX(self.superview.frame) - CGRectGetMaxX(self.frame);
    CGFloat minimumClearance = CGRectGetWidth(self.frame) / 2 + 8;

    if (leftPadding >= minimumClearance && rightPadding >= minimumClearance) {
        self.position = XXTEKeyboardButtonPositionInner;
    } else if (leftPadding > rightPadding) {
        self.position = XXTEKeyboardButtonPositionLeft;
    } else {
        self.position = XXTEKeyboardButtonPositionRight;
    }
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    _touchBeginPoint = [t locationInView:self];

    if (_trackPoint) {
        _selecting = fabs([_firstTapDate timeIntervalSinceNow]) < TIME_INTERVAL_FOR_DOUBLE_TAP;
        _firstTapDate = [NSDate date];

        [self trackPointStarted];
    }

    [self showInputView];
    [self selectLabel:2];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *t = [touches anyObject];
    CGPoint touchMovePoint = [t locationInView:self];

    CGFloat xdiff = _touchBeginPoint.x - touchMovePoint.x;
    CGFloat ydiff = _touchBeginPoint.y - touchMovePoint.y;
    CGFloat distance = (CGFloat) sqrt(xdiff * xdiff + ydiff * ydiff);

    if (_trackPoint) {
        [self trackPointMovedX:xdiff Y:ydiff selecting:_selecting];
        return;
    }

    if (distance > 250) {
        [self selectLabel:-1];
    } else if (!_tabButton && (distance > 20)) {
        CGFloat angle = (CGFloat) atan2(xdiff, ydiff);

        if (angle >= 0 && angle < M_PI_2) {
            [self selectLabel:0];
        } else if (angle >= 0 && angle >= M_PI_2) {
            [self selectLabel:3];
        } else if (angle < 0 && angle > -M_PI_2) {
            [self selectLabel:1];
        } else if (angle < 0 && angle <= -M_PI_2) {
            [self selectLabel:4];
        }
    } else {
        [self selectLabel:2];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    if (_output != nil) {
        if (_tabButton) {
            [[UIDevice currentDevice] playInputClick];
            [self insertText:self.tabString];
        } else if (_trackPoint) {
            if (_selecting) {
                [self selectionComplete];
            }
        } else {
            [[UIDevice currentDevice] playInputClick];
            [self insertText:self.output];
        }
    }

    [self selectLabel:-1];

    [self hideInputView];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self selectLabel:-1];
    [self hideInputView];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = [UIColor whiteColor];

    if (_style == XXTEKeyboardButtonStyleTablet && self.state == UIControlStateHighlighted) {
        color = [UIColor blackColor];
    }

    UIColor *shadow = [UIColor colorWithRed:136.f / 255.f green:138.f / 255.f blue:142.f / 255.f alpha:1.f];
    CGSize shadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat shadowBlurRadius = 0;

    UIBezierPath *roundedRectanglePath =
            [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 1) cornerRadius:self.keyCornerRadius];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
    [color setFill];
    [roundedRectanglePath fill];
    CGContextRestoreGState(context);
}

- (NSString *)tabString {
    if (!_tabString) {
        _tabString = @"\t";
    }
    return _tabString;
}

@end
