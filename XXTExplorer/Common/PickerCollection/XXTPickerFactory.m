//
//  XXTPickerFactory.m
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerFactory.h"
#import "XXTPickerNavigationController.h"
#import "XXTPickerSnippetTask.h"
#import "XXTPickerSnippet.h"
#import <LGAlertView/LGAlertView.h>

@interface XXTPickerFactory ()

@end

@implementation XXTPickerFactory

+ (instancetype)sharedInstance {
    static XXTPickerFactory *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)presentTaskAlert:(XXTPickerSnippetTask *)task withError:(NSError *)error {
    LGAlertView *alert = [LGAlertView alertViewWithTitle:NSLocalizedString(@"Snippet Error", nil)
                                                 message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), task.snippet.name, error.localizedFailureReason, error.localizedDescription]
                                                   style:LGAlertViewStyleAlert
                                            buttonTitles:nil
                                       cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                  destructiveButtonTitle:nil
                                           actionHandler:nil
                                           cancelHandler:^(LGAlertView * _Nonnull alertView) { [alertView dismissAnimated]; }
                                      destructiveHandler:nil];
    [alert showAnimated];
}

- (void)beginTask:(XXTPickerSnippetTask *)pickerTask fromViewController:(UIViewController *)viewController {
    UIViewController <XXTBasePicker> *nextPicker = [pickerTask nextPicker];
    if ([nextPicker conformsToProtocol:@protocol(XXTBasePicker)]) {
        nextPicker.pickerTask = pickerTask;
        nextPicker.pickerFactory = self;
        if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]])
        {
            [viewController.navigationController pushViewController:nextPicker animated:YES];
        }
        else
        {
            XXTPickerNavigationController *navigationController = [[XXTPickerNavigationController alloc] initWithRootViewController:nextPicker];
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [viewController presentViewController:navigationController animated:YES completion:nil];
        }
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(pickerFactory:taskShouldFinished:responseBlock:)]) {
            @weakify(self);
            [_delegate pickerFactory:self taskShouldFinished:pickerTask responseBlock:^(BOOL shouldFinish, NSError *responseError) {
                @strongify(self);
                if (shouldFinish) {
                    if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]]) {
                        [viewController.navigationController dismissViewControllerAnimated:YES completion:^{
                            if (self->_delegate && [self->_delegate respondsToSelector:@selector(pickerFactory:taskDidFinished:)]) {
                                [self->_delegate pickerFactory:self taskDidFinished:pickerTask];
                            }
                        }];
                    }
                } else {
                    [self presentTaskAlert:pickerTask withError:responseError];
                }
            }];
        }
    }
}

- (void)performNextStep:(UIViewController <XXTBasePicker> *)viewController {
    if ([[viewController class] respondsToSelector:@selector(pickerKeyword)]) {
        id pickerResult = [viewController performSelector:@selector(pickerResult)];
        if (!pickerResult) {
            return;
        }
        XXTPickerSnippetTask *pickerTaskObj = [viewController performSelector:@selector(pickerTask)];
        if (![pickerTaskObj isKindOfClass:[XXTPickerSnippetTask class]]) {
            return;
        }
        XXTPickerSnippetTask *pickerTask = [pickerTaskObj copy];
        [pickerTask addResult:pickerResult];
        UIViewController <XXTBasePicker> *nextPicker = [pickerTask nextPicker];
        if ([nextPicker conformsToProtocol:@protocol(XXTBasePicker)]) {
            nextPicker.pickerTask = pickerTask;
            nextPicker.pickerFactory = self;
        }
        BOOL shouldEnter = YES;
        if (_delegate && [_delegate respondsToSelector:@selector(pickerFactory:taskShouldEnterNextStep:)]) {
            shouldEnter = [_delegate pickerFactory:self taskShouldEnterNextStep:pickerTask];
        }
        if (shouldEnter && nextPicker)
        {
            [viewController.navigationController pushViewController:nextPicker animated:YES];
        }
    }

}

- (void)performFinished:(UIViewController <XXTBasePicker> *)viewController {
    if ([viewController respondsToSelector:@selector(pickerResult)] &&
        [viewController respondsToSelector:@selector(pickerTask)]) {
        id pickerResult = [viewController performSelector:@selector(pickerResult)];
        if (!pickerResult) {
            return;
        }
        XXTPickerSnippetTask *pickerTaskObj = [viewController performSelector:@selector(pickerTask)];
        if (![pickerTaskObj isKindOfClass:[XXTPickerSnippetTask class]]) {
            return;
        }
        XXTPickerSnippetTask *pickerTask = [pickerTaskObj copy];
        [pickerTask addResult:pickerResult];
        if (_delegate && [_delegate respondsToSelector:@selector(pickerFactory:taskShouldFinished:responseBlock:)]) {
            @weakify(self);
            [_delegate pickerFactory:self taskShouldFinished:pickerTask responseBlock:^(BOOL shouldFinish, NSError *responseError) {
                @strongify(self);
                if (shouldFinish) {
                    [viewController.navigationController dismissViewControllerAnimated:YES completion:^{
                        if (self->_delegate && [self->_delegate respondsToSelector:@selector(pickerFactory:taskDidFinished:)]) {
                            [self->_delegate pickerFactory:self taskDidFinished:pickerTask];
                        }
                    }];
                } else {
                    [self presentTaskAlert:pickerTask withError:responseError];
                }
            }];
        }
    }
}

- (void)performUpdateStep:(UIViewController <XXTBasePicker> *)viewController {
    XXTPickerNavigationController *navController = (XXTPickerNavigationController *)viewController.navigationController;
    if ([viewController respondsToSelector:@selector(pickerTask)]) {
        XXTPickerSnippetTask *currentTask = [viewController performSelector:@selector(pickerTask)];
        [navController.popupBar setTitle:[NSString stringWithFormat:@"%@ (%lu/%lu)", viewController.title, (unsigned long)currentTask.currentStep, (unsigned long)currentTask.totalStep]];
        [navController.popupBar setProgress:currentTask.currentProgress];
        if ([viewController respondsToSelector:@selector(pickerSubtitle)]) {
            NSString *subtitle = viewController.pickerSubtitle;
            if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]])
            {
                [navController.popupBar setSubtitle:subtitle];
            }
        }
        if ([viewController respondsToSelector:@selector(pickerAttributedSubtitle)]) {
            NSAttributedString *subtitle = viewController.pickerAttributedSubtitle;
            if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]])
            {
                [navController.popupBar setAttributedSubtitle:subtitle];
            }
        }
    } else {
        [navController.popupBar setHidden:YES];
    }
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
