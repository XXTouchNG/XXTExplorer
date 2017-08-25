//
//  XXTPickerFactory.m
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerFactory.h"
#import "XXTBasePicker.h"
#import "XXTPickerNavigationController.h"

@interface XXTPickerFactory ()

@end

@implementation XXTPickerFactory

//+ (id)sharedInstance {
//    static XXTPickerFactory *sharedInstance = nil;
//    static dispatch_once_t once;
//    dispatch_once(&once, ^{
//        sharedInstance = [[self alloc] init];
//        sharedInstance.frontColor = [UIColor colorWithRed:26.f/255.f green:161.f/255.f blue:230.f/255.f alpha:.98f];
//    });
//    
//    return sharedInstance;
//}

//- (instancetype)init {
//    if (self = [super init]) {
//        self.frontColor = [UIColor colorWithRed:26.f/255.f green:161.f/255.f blue:230.f/255.f alpha:.98f];
//    }
//    return self;
//}

+ (NSBundle *)bundle {
    static dispatch_once_t onceToken;
    static NSBundle *bundle = nil;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle mainBundle];
    });
    return bundle;
}

- (void)executeTask:(XXTPickerTask *)pickerTask fromViewController:(UIViewController *)viewController {
    id nextPicker = [[pickerTask nextStepClass] new];
    if (nextPicker) {
        if ([nextPicker respondsToSelector:@selector(setPickerTask:)])
        {
            [nextPicker performSelector:@selector(setPickerTask:) withObject:pickerTask];
        }
        if (nextPicker && [nextPicker respondsToSelector:@selector(setPickerFactory:)])
        {
            [nextPicker performSelector:@selector(setPickerFactory:) withObject:self];
        }
        if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]]) {
            [viewController.navigationController pushViewController:nextPicker animated:YES];
        } else {
            XXTPickerNavigationController *popupNavigationController = [[XXTPickerNavigationController alloc] initWithRootViewController:nextPicker];
            [viewController presentViewController:popupNavigationController animated:YES completion:nil];
        }
    } else {
        BOOL shouldFinish = YES;
        if (_delegate && [_delegate respondsToSelector:@selector(pickerFactory:taskShouldFinished:)]) {
            shouldFinish = [_delegate pickerFactory:self taskShouldFinished:pickerTask];
        }
        if (shouldFinish) {
            [viewController.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)performNextStep:(UIViewController *)viewController {

    if ([[viewController class] respondsToSelector:@selector(pickerKeyword)]) {
        NSString *pickerResult = [[viewController performSelector:@selector(pickerResult)] mutableCopy];
        if (!pickerResult || pickerResult.length == 0) {
            return;
        }
        XXTPickerTask *pickerTask = [[viewController performSelector:@selector(pickerTask)] mutableCopy];
        NSString *code = pickerTask.code;
        NSRange range = [code rangeOfString:[[viewController class] performSelector:@selector(pickerKeyword)]];
        pickerTask.code = [code stringByReplacingCharactersInRange:range
                                                        withString:pickerResult];
        id nextPicker = [[pickerTask nextStepClass] new];
        if (nextPicker && [nextPicker respondsToSelector:@selector(setPickerTask:)])
        {
            [nextPicker performSelector:@selector(setPickerTask:) withObject:pickerTask];
        }
        if (nextPicker && [nextPicker respondsToSelector:@selector(setPickerFactory:)])
        {
            [nextPicker performSelector:@selector(setPickerFactory:) withObject:self];
        }
        BOOL shouldEnter = YES;
        if (_delegate && [_delegate respondsToSelector:@selector(pickerFactory:taskShouldEnterNextStep:)]) {
            shouldEnter = [_delegate pickerFactory:self taskShouldEnterNextStep:pickerTask];
        }
        if (shouldEnter && nextPicker) {
            [viewController.navigationController pushViewController:nextPicker animated:YES];
        }
    }

}

- (void)performFinished:(UIViewController *)viewController {

//    if (_callbackObject && _callbackSelector && [_callbackObject respondsToSelector:_callbackSelector] && [[viewController class] respondsToSelector:@selector(pickerKeyword)]) {
//        NSString *pickerResult = [[viewController performSelector:@selector(pickerResult)] mutableCopy];
//        if (!pickerResult || pickerResult.length == 0) {
//            return;
//        }
//        XXTPickerTask *pickerTask = [[viewController performSelector:@selector(pickerTask)] mutableCopy];
//        NSString *code = pickerTask.code;
//        NSRange range = [code rangeOfString:[[viewController class] performSelector:@selector(pickerKeyword)]];
//        pickerTask.code = [code stringByReplacingCharactersInRange:range
//                                                        withString:pickerResult];
//        [_callbackObject performSelector:_callbackSelector withObject:pickerTask];
//        _callbackObject = nil;
//        _callbackSelector = NULL;
//    }
    
    if ([viewController respondsToSelector:@selector(pickerResult)] && [viewController respondsToSelector:@selector(pickerTask)]) {
        NSString *pickerResult = [[viewController performSelector:@selector(pickerResult)] mutableCopy];
        if (!pickerResult || pickerResult.length == 0) {
            return;
        }
        XXTPickerTask *pickerTask = [[viewController performSelector:@selector(pickerTask)] mutableCopy];
        NSString *code = pickerTask.code;
        NSRange range = [code rangeOfString:[[viewController class] performSelector:@selector(pickerKeyword)]];
        pickerTask.code = [code stringByReplacingCharactersInRange:range
                                                        withString:pickerResult];
        BOOL shouldFinish = YES;
        if (_delegate && [_delegate respondsToSelector:@selector(pickerFactory:taskShouldFinished:)]) {
            shouldFinish = [_delegate pickerFactory:self taskShouldFinished:pickerTask];
        }
        if (shouldFinish) {
            [viewController.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }

}

- (void)performUpdateStep:(UIViewController *)viewController {

    XXTPickerNavigationController *navController = (XXTPickerNavigationController *)viewController.navigationController;
    
    if ([viewController respondsToSelector:@selector(pickerTask)]) {
        XXTPickerTask *currentTask = [viewController performSelector:@selector(pickerTask)];
        [navController.popupBar setTitle:[NSString stringWithFormat:@"%@ (%lu/%lu)", viewController.title, (unsigned long)currentTask.currentStep, (unsigned long)currentTask.totalStep]];
        [navController.popupBar setProgress:currentTask.currentProgress];
        
        if ([viewController respondsToSelector:@selector(pickerSubtitle)]) {
            NSString *subtitle = [viewController performSelector:@selector(pickerSubtitle)];
            if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]]) {
                [navController.popupBar setSubtitle:subtitle];
            }
        }
        if ([viewController respondsToSelector:@selector(pickerAttributedSubtitle)]) {
            NSAttributedString *subtitle = [viewController performSelector:@selector(pickerAttributedSubtitle)];
            if ([viewController.navigationController isKindOfClass:[XXTPickerNavigationController class]]) {
                [navController.popupBar setAttributedSubtitle:subtitle];
            }
        }
    } else {
        [navController.popupBar setHidden:YES];
    }

}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTPickerFactory dealloc]");
#endif
}

@end
