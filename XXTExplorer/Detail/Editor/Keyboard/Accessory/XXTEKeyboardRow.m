//
//  XXTEKeyboardRow.m
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEKeyboardRow.h"
#import "XXTEKeyboardButton.h"

static NSString * const XXTEKeyboardRowPhoneDefaultSequence = @"TTTTT()\"[]{}'<>\\/$´`RRRRR~^|€£-+=%*!?#@&_:;,.";
static NSString * const XXTEKeyboardRowPadDefaultSequence = @"TTTTT()\"[]{}'<>\\/$´`~^|€£RRRRR-+=%*!?#@&_:;,.1203467589";

@interface XXTEKeyboardRow ()

@property (nonatomic, assign) NSUInteger buttonCount;
@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat barHeight;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) CGFloat leftMargin;
@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat buttonSpacing;
@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, strong) NSMutableArray <XXTEKeyboardButton *> *buttons;

@end

@implementation XXTEKeyboardRow

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero inputViewStyle:UIInputViewStyleKeyboard]) {
        [self setupWithKeymap:nil];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame inputViewStyle:UIInputViewStyleKeyboard]) {
        [self setupWithKeymap:nil];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame inputViewStyle:(UIInputViewStyle)inputViewStyle {
    if (self = [super initWithFrame:frame inputViewStyle:inputViewStyle]) {
        [self setupWithKeymap:nil];
    }
    return self;
}

- (instancetype)initWithKeymap:(NSString *)keymap {
    if (self = [super initWithFrame:CGRectZero inputViewStyle:UIInputViewStyleKeyboard]) {
        [self setupWithKeymap:keymap];
    }
    return self;
}

- (void)setupWithKeymap:(NSString *)keymap {
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            _buttonType = XXTEKeyboardButtonTypePhone;
            break;
        case UIUserInterfaceIdiomPad:
            _buttonType = XXTEKeyboardButtonTypeTablet;
            break;
        default:
            break;
    }

    NSString *keys = nil;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    _barWidth = MIN(screenSize.width, screenSize.height);
    if (_buttonType == XXTEKeyboardButtonTypePhone) {
        _buttonCount = 9;
        _buttonSpacing = 4.f;
        _topMargin = 0.f;
        _leftMargin = 6.f;
        _buttonWidth = (_barWidth - (_buttonSpacing * (_buttonCount - 1)) - (_leftMargin * 2)) / _buttonCount;
        _buttonHeight = _buttonWidth;
        _barHeight = _buttonHeight + _buttonSpacing * 2;
        keys = keymap ?: XXTEKeyboardRowPhoneDefaultSequence;
    } else if (_buttonType == XXTEKeyboardButtonTypeTablet) {
        _buttonCount = 11;
        _barHeight = 72.f;
        _buttonHeight = 60.f;
        _leftMargin = 7.f;
        _topMargin = 1.f;
        _buttonSpacing = 13.f;
        _buttonWidth = 57.f;
        keys = keymap ?: XXTEKeyboardRowPadDefaultSequence;
    }

    self.frame = CGRectMake(0, 0, _barWidth, _barHeight);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _leftMargin = (_barWidth - _buttonWidth * _buttonCount - _buttonSpacing * (_buttonCount - 1)) / 2;
    self.buttons = [NSMutableArray new];
    for (int i = 0; i < _buttonCount; i++) {
        XXTEKeyboardButton *keyboardButton = [[XXTEKeyboardButton alloc] initWithFrame:CGRectMake(_leftMargin + i * (_buttonSpacing + _buttonWidth), _topMargin + (_barHeight - _buttonHeight) / 2, _buttonWidth, _buttonHeight)];
        keyboardButton.style = self.buttonType;
        keyboardButton.input = [keys substringWithRange:NSMakeRange((NSUInteger) (i * 5), 5)];
        keyboardButton.translatesAutoresizingMaskIntoConstraints = NO;
        keyboardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:keyboardButton];
        [self.buttons addObject:keyboardButton];
    }
}

- (void)setTabString:(NSString *)tabString {
    _tabString = tabString;
    for (XXTEKeyboardButton *btn in self.buttons) {
        btn.tabString = tabString;
    }
}

- (void)setTextInput:(id <UITextInput>)textInput {
    _textInput = textInput;
    if (textInput) {
        for (XXTEKeyboardButton *button in self.buttons) {
            button.textInput = textInput;
        }
    }
}

- (void)setColorStyle:(XXTEKeyboardRowStyle)colorStyle {
    _colorStyle = colorStyle;
    for (XXTEKeyboardButton *button in self.buttons) {
        button.colorStyle = colorStyle;
    }
}

@end
