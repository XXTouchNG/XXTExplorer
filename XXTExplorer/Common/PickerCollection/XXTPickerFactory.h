//
//  XXTPickerFactory.h
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTBasePicker.h"
#import "XXTPickerFactoryDelegate.h"


@class XXTPickerFactory, XXTPickerSnippetTask;

@interface XXTPickerFactory : NSObject

@property (nonatomic, weak) id <XXTPickerFactoryDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)beginTask:(XXTPickerSnippetTask *)pickerTask fromViewController:(UIViewController *)viewController;
- (void)performNextStep:(UIViewController <XXTBasePicker> *)viewController;
- (void)performFinished:(UIViewController <XXTBasePicker> *)viewController;
- (void)performUpdateStep:(UIViewController <XXTBasePicker> *)viewController;

@end
