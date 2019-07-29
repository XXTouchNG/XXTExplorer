//
//  XXTPickerNavigationController.m
//  XXTPickerCollection
//
//  Created by Zheng on 29/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerNavigationController.h"
#import "XXTBasePicker.h"
#import "XXTPickerFactory.h"

#import <objc/runtime.h>

static CGFloat const XXTPickerNavigationPreviewBarHeight = 44.f;
static const void *ObjectTagKey = &ObjectTagKey;

@interface XXTPickerNavigationController () <UINavigationControllerDelegate>
@property (nonatomic, assign) BOOL viewTransitionInProgress;

@end

@implementation XXTPickerNavigationController {
    BOOL isFirstLoaded;
}

- (UIEdgeInsets)safeAreaInsets {
    if (@available(iOS 11.0, *)) {
        return self.view.safeAreaInsets;
    } else {
        return UIEdgeInsetsZero;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        self.delegate = self;
        [self setupAppearance];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        self.delegate = self;
        rootViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
    UINavigationBar *barAppearance = [UINavigationBar appearance];
    [barAppearance setTintColor:[UIColor whiteColor]];
    [barAppearance setBarTintColor:XXTColorDefault()];
    [barAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[self class], nil];
    [navigationBarAppearance setTintColor:[UIColor whiteColor]];
    [navigationBarAppearance setBarTintColor:XXTColorDefault()];
    [navigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        [navigationBarAppearance setTranslucent:NO];
    }
    XXTE_END_IGNORE_PARTIAL
    
    UIBarButtonItem *barButtonItemAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    [barButtonItemAppearance setTintColor:[UIColor whiteColor]];
    
//    if (@available(iOS 13.0, *)) {
//        barAppearance.scrollEdgeAppearance = barAppearance.standardAppearance;
//        navigationBarAppearance.scrollEdgeAppearance = navigationBarAppearance.standardAppearance;
//    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    if (@available(iOS 11.0, *)) {
        self.navigationBar.translucent = YES;
    } else {
        self.navigationBar.translucent = NO;
    }
    
    [self.view addSubview:self.popupBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!isFirstLoaded) {
        isFirstLoaded = YES;
        self.popupBar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - (XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom), CGRectGetWidth(self.view.bounds), XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom);
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIView Getters

- (XXTPickerPreviewBar *)popupBar {
    if (!_popupBar) {
        XXTPickerPreviewBar *popupBar = [[XXTPickerPreviewBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - (XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom), CGRectGetWidth(self.view.bounds), XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom)];
        popupBar.userInteractionEnabled = YES;
        popupBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewBarTapped:)];
        [popupBar addGestureRecognizer:tapGesture];
        _popupBar = popupBar;
    }
    return _popupBar;
}

#pragma mark - Preview

- (void)previewBarTapped:(XXTPickerPreviewBar *)sender {
    
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (navigationController == self) {
        if ([viewController respondsToSelector:@selector(pickerFactory)]) {
            UIViewController *pickerController = viewController;
            [self.view bringSubviewToFront:self.popupBar];
            if ([pickerController respondsToSelector:@selector(tableView)])
            {
                UITableViewController *tablePickerController = (UITableViewController *)viewController;
                UIEdgeInsets insets1 = tablePickerController.tableView.contentInset;
                insets1.bottom += CGRectGetHeight(self.popupBar.bounds);
                UIEdgeInsets insets2 = tablePickerController.tableView.scrollIndicatorInsets;
                insets2.bottom += CGRectGetHeight(self.popupBar.bounds);
                tablePickerController.tableView.contentInset = insets1;
                tablePickerController.tableView.scrollIndicatorInsets = insets2;
            }
        }
    }
    if ([viewController conformsToProtocol:@protocol(XXTBasePicker)]) {
        if (YES == self.popupBar.hidden) {
            self.popupBar.hidden = NO;
            [UIView animateWithDuration:.2f animations:^{
                self.popupBar.frame = CGRectMake(0, self.view.bounds.size.height - (XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom), self.view.bounds.size.width, XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom);
            } completion:^(BOOL finished) {
                
            }];
        }
    } else {
        if (NO == self.popupBar.hidden) {
            [UIView animateWithDuration:.2f animations:^{
                self.popupBar.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, XXTPickerNavigationPreviewBarHeight + self.safeAreaInsets.bottom);
            } completion:^(BOOL finished) {
                if (finished) self.popupBar.hidden = YES;
            }];
        }
    }
    self.viewTransitionInProgress = NO;
}

#pragma mark - Consistent

- (void)setViewTransitionInProgress:(BOOL)property {
    _viewTransitionInProgress = property;
}

- (BOOL)isViewTransitionInProgress {
    return _viewTransitionInProgress;
}

#pragma mark - Intercept Pop, Push, PopToRootVC
/// @name Intercept Pop, Push, PopToRootVC

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    //-- This is not a recursion, due to method swizzling the call below calls the original  method.
    return [super popToRootViewControllerAnimated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    //-- This is not a recursion, due to method swizzling the call below calls the original  method.
    return [super popToViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    //-- This is not a recursion, due to method swizzling the call below calls the original  method.
    return [super popViewControllerAnimated:animated];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //-- If we are already pushing a view controller, we dont push another one.
    if (self.isViewTransitionInProgress == NO) {
        //-- This is not a recursion, due to method swizzling the call below calls the original  method.
        [super pushViewController:viewController animated:animated];
        if (animated) {
            self.viewTransitionInProgress = YES;
        }
    }
}

// If the user doesnt complete the swipe-to-go-back gesture, we need to intercept it and set the flag to NO again.
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    id<UIViewControllerTransitionCoordinator> tc = navigationController.topViewController.transitionCoordinator;
    [tc notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.viewTransitionInProgress = NO;
        //--Reenable swipe back gesture.
        self.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)viewController;
        [self.interactivePopGestureRecognizer setEnabled:YES];
    }];
    //-- Method swizzling wont work in the case of a delegate so:
    //-- forward this method to the original delegate if there is one different than ourselves.
    if (navigationController.delegate != self) {
        [navigationController.delegate navigationController:navigationController
                                     willShowViewController:viewController
                                                   animated:animated];
    }
}

@end
