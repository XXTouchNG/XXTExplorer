//
//  XUISecureEditTextCell.m
//  XXTExplorer
//
//  Created by Zheng on 29/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUISecureEditTextCell.h"
#import "XUILogger.h"

@interface XUISecureEditTextCell () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *xui_secureTextField;

@end

@implementation XUISecureEditTextCell

@synthesize xui_value = _xui_value;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return NO;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"alignment": [NSString class],
      @"keyboard": [NSString class],
      @"autoCaps": [NSString class],
      @"placeholder": [NSString class],
      @"bestGuess": [NSString class],
      @"noAutoCorrect": [NSNumber class],
      @"isIP": [NSNumber class],
      @"isURL": [NSNumber class],
      @"isNumeric": [NSNumber class],
      @"isDecimalPad": [NSNumber class],
      @"isEmail": [NSNumber class],
      @"value": [NSString class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        NSString *alignmentString = cellEntry[@"alignment"];
        if (alignmentString) {
            NSArray <NSString *> *validAlignment = @[ @"left", @"right", @"center", @"natural", @"justified" ];
            if (![validAlignment containsObject:alignmentString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"alignment\" (\"%@\") is invalid.", nil), alignmentString];
            }
        }
        NSString *keyboardString = cellEntry[@"keyboard"];
        if (keyboardString) {
            NSArray <NSString *> *validKeyboard = @[ @"numbers", @"phone", @"ascii", @"default" ];
            if (![validKeyboard containsObject:keyboardString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"keyboard\" (\"%@\") is invalid.", nil), keyboardString];
            }
        }
        NSString *autoCapsString = cellEntry[@"autoCaps"];
        if (autoCapsString) {
            NSArray <NSString *> *validAutoCaps = @[ @"sentences", @"words", @"all", @"none" ];
            if (![validAutoCaps containsObject:autoCapsString]) {
                superResult = NO;
                checkType = kXUICellFactoryErrorUnknownEnumDomain;
                @throw [NSString stringWithFormat:NSLocalizedString(@"key \"autoCaps\" (\"%@\") is invalid.", nil), autoCapsString];
            }
        }
    } @catch (NSString *exceptionReason) {
        NSError *exceptionError = [NSError errorWithDomain:checkType code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (error) {
            *error = exceptionError;
        }
    } @finally {
        
    }
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.xui_secureTextField.delegate = self;
    self.xui_secureTextField.secureTextEntry = YES;
    self.xui_secureTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)setXui_keyboard:(NSString *)xui_keyboard {
    _xui_keyboard = xui_keyboard;
    if ([xui_keyboard isEqualToString:@"numbers"]) {
        self.xui_secureTextField.keyboardType = UIKeyboardTypeNumberPad;
    }
    else if ([xui_keyboard isEqualToString:@"phone"]) {
        self.xui_secureTextField.keyboardType = UIKeyboardTypePhonePad;
    }
    else if ([xui_keyboard isEqualToString:@"ascii"]) {
        self.xui_secureTextField.keyboardType = UIKeyboardTypeASCIICapable;
    }
    else {
        self.xui_secureTextField.keyboardType = UIKeyboardTypeDefault;
    }
}

- (void)setXui_autoCaps:(NSString *)xui_autoCaps {
    _xui_autoCaps = xui_autoCaps;
    if ([xui_autoCaps isEqualToString:@"sentences"]) {
        self.xui_secureTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }
    else if ([xui_autoCaps isEqualToString:@"words"]) {
        self.xui_secureTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }
    else if ([xui_autoCaps isEqualToString:@"all"]) {
        self.xui_secureTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    }
    else {
        self.xui_secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
}

- (void)setXui_placeholder:(NSString *)xui_placeholder {
    _xui_placeholder = xui_placeholder;
    self.xui_secureTextField.placeholder = xui_placeholder;
}

- (void)setXui_bestGuess:(NSString *)xui_bestGuess {
    _xui_bestGuess = xui_bestGuess;
    self.xui_secureTextField.text = xui_bestGuess;
}

- (void)setXui_noAutoCorrect:(NSNumber *)xui_noAutoCorrect {
    _xui_noAutoCorrect = xui_noAutoCorrect;
    BOOL noAutoCorrect = [xui_noAutoCorrect boolValue];
    self.xui_secureTextField.autocorrectionType = noAutoCorrect ? UITextAutocorrectionTypeNo : UITextAutocorrectionTypeYes;
}

- (void)setXui_isIP:(NSNumber *)xui_isIP {
    _xui_isIP = xui_isIP;
    self.xui_secureTextField.keyboardType = UIKeyboardTypeDecimalPad;
}

- (void)setXui_isURL:(NSNumber *)xui_isURL {
    _xui_isURL = xui_isURL;
    self.xui_secureTextField.keyboardType = UIKeyboardTypeURL;
}

- (void)setXui_isEmail:(NSNumber *)xui_isEmail {
    _xui_isEmail = xui_isEmail;
    self.xui_secureTextField.keyboardType = UIKeyboardTypeEmailAddress;
}

- (void)setXui_isNumeric:(NSNumber *)xui_isNumeric {
    _xui_isNumeric = xui_isNumeric;
    self.xui_secureTextField.keyboardType = UIKeyboardTypeNumberPad;
}

- (void)setXui_isDecimalPad:(NSNumber *)xui_isDecimalPad {
    _xui_isDecimalPad = xui_isDecimalPad;
    self.xui_secureTextField.keyboardType = UIKeyboardTypeDecimalPad;
}

- (void)setXui_alignment:(NSString *)xui_alignment {
    _xui_alignment = xui_alignment;
    if ([xui_alignment isEqualToString:@"left"]) {
        self.xui_secureTextField.textAlignment = NSTextAlignmentLeft;
    }
    else if ([xui_alignment isEqualToString:@"center"]) {
        self.xui_secureTextField.textAlignment = NSTextAlignmentCenter;
    }
    else if ([xui_alignment isEqualToString:@"right"]) {
        self.xui_secureTextField.textAlignment = NSTextAlignmentRight;
    }
    else if ([xui_alignment isEqualToString:@"natural"]) {
        self.xui_secureTextField.textAlignment = NSTextAlignmentNatural;
    }
    else if ([xui_alignment isEqualToString:@"justified"]) {
        self.xui_secureTextField.textAlignment = NSTextAlignmentJustified;
    }
    else {
        self.xui_secureTextField.textAlignment = NSTextAlignmentNatural;
    }
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.xui_secureTextField.enabled = enabled;
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    self.xui_secureTextField.text = xui_value;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.xui_value = textField.text;
    [self.defaultsService saveDefaultsFromCell:self];
}

@end