//
//  XXTPickerFactory.h
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTPickerNavigationController.h"
#import "XXTPickerTask.h"

@class XXTPickerFactory;

@protocol XXTPickerFactoryDelegate <NSObject>

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerTask *)task;
- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerTask *)task;

@end

@interface XXTPickerFactory : NSObject

@property (nonatomic, weak) id <XXTPickerFactoryDelegate> delegate;

//@property (nonatomic, weak) id callbackObject;
//@property (nonatomic, assign) SEL callbackSelector;
//@property (nonatomic, strong) UIColor *frontColor;

//+ (instancetype)sharedInstance;
+ (NSBundle *)bundle;
- (void)executeTask:(XXTPickerTask *)pickerTask fromViewController:(UIViewController *)viewController;
- (void)performNextStep:(UIViewController *)viewController;
- (void)performFinished:(UIViewController *)viewController;
- (void)performUpdateStep:(UIViewController *)viewController;

@end
