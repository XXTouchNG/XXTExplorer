// The MIT License (MIT)
//
// Copyright (c) 2015-2016 forkingdog ( https://github.com/forkingdog )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "UINavigationController+XXTEFullscreenPopGesture.h"
#import <objc/runtime.h>

@interface _XXTEFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation _XXTEFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Ignore when no view controller is pushed into the navigation stack.
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    // Disable when the active view controller doesn't allow interactive pop.
    UIViewController *topViewController = self.navigationController.viewControllers.lastObject;
    if (topViewController.xxte_interactivePopDisabled) {
        return NO;
    }

    // Ignore pan gesture when the navigation controller is currently in transition.
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    // Prevent calling the handler when the gesture begins in an opposite direction.
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    return YES;
}

@end

typedef void (^_XXTEViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (XXTEFullscreenPopGesturePrivate)

@property (nonatomic, copy) _XXTEViewControllerWillAppearInjectBlock xxte_willAppearInjectBlock;

@end

@implementation UIViewController (XXTEFullscreenPopGesturePrivate)

+ (void)load
{
    Method originalMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(xxte_viewWillAppear:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)xxte_viewWillAppear:(BOOL)animated
{
    // Forward to primary implementation.
    [self xxte_viewWillAppear:animated];
    
    if (self.xxte_willAppearInjectBlock) {
        self.xxte_willAppearInjectBlock(self, animated);
    }
}

- (_XXTEViewControllerWillAppearInjectBlock)xxte_willAppearInjectBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setXxte_willAppearInjectBlock:(_XXTEViewControllerWillAppearInjectBlock)block
{
    objc_setAssociatedObject(self, @selector(xxte_willAppearInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UINavigationController (XXTEFullscreenPopGesture)

+ (void)load
{
    // Inject "-pushViewController:animated:"
    Method originalMethod = class_getInstanceMethod(self, @selector(pushViewController:animated:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(xxte_pushViewController:animated:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)xxte_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.xxte_fullscreenPopGestureRecognizer]) {
        
        // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.xxte_fullscreenPopGestureRecognizer];

        // Forward the gesture events to the private handler of the onboard gesture recognizer.
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        self.xxte_fullscreenPopGestureRecognizer.delegate = self.xxte_popGestureRecognizerDelegate;
        [self.xxte_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];

        // Disable the onboard gesture recognizer.
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    
    // Handle perferred navigation bar appearance.
    [self xxte_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    
    // Forward to primary implementation.
    [self xxte_pushViewController:viewController animated:animated];
}

- (void)xxte_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController
{
    if (!self.xxte_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    _XXTEViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:viewController.xxte_prefersNavigationBarHidden animated:animated];
        }
    };
    
    // Setup will appear inject block to appearing view controller.
    // Setup disappearing view controller as well, because not every view controller is added into
    // stack by pushing, maybe by "-setViewControllers:".
    appearingViewController.xxte_willAppearInjectBlock = block;
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.xxte_willAppearInjectBlock) {
        disappearingViewController.xxte_willAppearInjectBlock = block;
    }
}

- (_XXTEFullscreenPopGestureRecognizerDelegate *)xxte_popGestureRecognizerDelegate
{
    _XXTEFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);

    if (!delegate) {
        delegate = [[_XXTEFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)xxte_fullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);

    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

- (BOOL)xxte_viewControllerBasedNavigationBarAppearanceEnabled
{
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.xxte_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    return YES;
}

- (void)setXxte_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)enabled
{
    SEL key = @selector(xxte_viewControllerBasedNavigationBarAppearanceEnabled);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (XXTEFullscreenPopGesture)

- (BOOL)xxte_interactivePopDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setXxte_interactivePopDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(xxte_interactivePopDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)xxte_prefersNavigationBarHidden
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setXxte_prefersNavigationBarHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(xxte_prefersNavigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
