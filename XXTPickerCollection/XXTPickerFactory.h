//
//  XXTPickerFactory.h
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTPickerFactory, XXTPickerSnippet;

@protocol XXTPickerFactoryDelegate <NSObject>

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippet *)task;
- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippet *)task;

@end

@interface XXTPickerFactory : NSObject

@property (nonatomic, weak) id <XXTPickerFactoryDelegate> delegate;

- (void)executeTask:(XXTPickerSnippet *)pickerTask fromViewController:(UIViewController *)viewController;
- (void)performNextStep:(UIViewController *)viewController;
- (void)performFinished:(UIViewController *)viewController;
- (void)performUpdateStep:(UIViewController *)viewController;

@end
