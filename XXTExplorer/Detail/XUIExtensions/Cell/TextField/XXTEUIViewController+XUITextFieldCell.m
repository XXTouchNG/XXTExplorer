//
//  XXTEUIViewController+XUITextFieldCell.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/18.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEUIViewController+XUITextFieldCell.h"
#import "XXTEMasterViewController.h"

#import <XUI/XUITextFieldCell.h>
#import <XUI/XUIStrings.h>

#import <LGAlertView/LGAlertView.h>

@implementation XXTEUIViewController (XUITextFieldCell)

- (void)tableView:(UITableView *)tableView XUITextFieldCell:(UITableViewCell *)cell
{
    
    if (NO == XXTE_SYSTEM_8) {
        return;
    }
    
    XUITextFieldCell *textFieldCell = (XUITextFieldCell *)cell;
    if (textFieldCell.xui_prompt.length == 0) return;
    
    BOOL readonly = (textFieldCell.xui_readonly != nil && [textFieldCell.xui_readonly boolValue] == YES);
    if (readonly) return;
    
    NSString *regexString = textFieldCell.xui_validationRegex;
    NSRegularExpression *validationRegex = nil;
    if (regexString.length > 0)
    {
        NSError *regexError = nil;
        validationRegex = [[NSRegularExpression alloc] initWithPattern:regexString options:0 error:&regexError];
        if (!validationRegex)
        {
            [self presentErrorAlertController:regexError];
            return;
        }
    }
    
    NSUInteger maxLength = UINT_MAX;
    if (textFieldCell.xui_maxLength)
        maxLength = [textFieldCell.xui_maxLength unsignedIntegerValue];
    
    NSString *raw = textFieldCell.xui_value;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    NSString *alertTitle = textFieldCell.xui_prompt ? [self.adapter localizedString:[NSString stringWithString:textFieldCell.xui_prompt]] : nil;
    NSString *alertBody = textFieldCell.xui_message ? [self.adapter localizedString:[NSString stringWithString:textFieldCell.xui_message]] : nil;
    NSString *okTitle = textFieldCell.xui_okTitle ? [self.adapter localizedString:[NSString stringWithString:textFieldCell.xui_okTitle]] : nil;
    if (okTitle.length == 0) okTitle = [XUIStrings localizedStringForString:@"OK"];
    NSString *cancelTitle = textFieldCell.xui_cancelTitle ? [self.adapter localizedString:[NSString stringWithString:textFieldCell.xui_cancelTitle]] : nil;
    if (cancelTitle.length == 0) cancelTitle = [XUIStrings localizedStringForString:@"Cancel"];
    
    @weakify(self);
    LGAlertView *alertController = [LGAlertView alertViewWithTextFieldsAndTitle:alertTitle
                                                                        message:alertBody
                                                             numberOfTextFields:1
                                                         textFieldsSetupHandler:^(UITextField * _Nonnull textField, NSUInteger index) {
                                                             if (index == 0) {
                                                                 [XUITextFieldCell resetTextFieldStatus:textField];
                                                                 [XUITextFieldCell reloadTextAttributes:textField forTextFieldCell:textFieldCell];
                                                                 [XUITextFieldCell reloadPlaceholderAttributes:textField forTextFieldCell:textFieldCell];
                                                                 [XUITextFieldCell reloadTextFieldStatus:textField forTextFieldCell:textFieldCell isPrompt:YES];
                                                                 textField.delegate = textFieldCell;
                                                             }
                                                         } buttonTitles:@[ okTitle ]
                                                              cancelButtonTitle:cancelTitle
                                                         destructiveButtonTitle:nil
                                                                  actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                                                                      @strongify(self);
                                                                      if (index == 0) {
                                                                          UITextField *textField = [alertView.textFieldsArray firstObject];
                                                                          if (textField)
                                                                          {
                                                                              [XUITextFieldCell savePrompt:textField forTextFieldCell:textFieldCell];
                                                                          }
                                                                          [center removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
                                                                          [alertView dismissAnimated];
                                                                      }
                                                                  } cancelHandler:^(LGAlertView * _Nonnull alertView) {
                                                                      @strongify(self);
                                                                      [center removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
                                                                      [alertView dismissAnimated];
                                                                  } destructiveHandler:nil];
    alertController.cancelButtonEnabled = YES;
    [alertController setButtonEnabled:NO atIndex:0];
    
    if (self.theme.isBackgroundDark == NO) {
        [XXTEMasterViewController setupAlertDefaultAppearance:alertController];
    } else {
        [XXTEMasterViewController setupAlertDarkAppearance:alertController];
    }
    
    [alertController showAnimated];
    
    @weakify(alertController);
    [center addObserverForName:UITextFieldTextDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull aNotification) {
        @strongify(alertController);
        UITextField *textField = (UITextField *)aNotification.object;
        NSString *content = textField.text;
        if ([content isEqualToString:raw]) {
            [alertController setButtonEnabled:NO atIndex:0];
        } else {
            if (validationRegex)
            {
                NSTextCheckingResult *result
                = [validationRegex firstMatchInString:content options:0 range:NSMakeRange(0, content.length)];
                if (!result)
                { // validation failed
                    [alertController setButtonEnabled:NO atIndex:0];
                }
                else
                {
                    [alertController setButtonEnabled:YES atIndex:0];
                }
            }
            else
            {
                [alertController setButtonEnabled:YES atIndex:0];
            }
        }
    }];
    
}

@end
