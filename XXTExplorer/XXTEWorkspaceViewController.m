//
//  XXTEWorkspaceViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEWorkspaceViewController.h"
#import "XXTENotificationCenterDefines.h"

@interface XXTEWorkspaceViewController ()
@property (nonatomic, strong) UIImageView *arrowPlaceholderImageView;
@property (nonatomic, strong) UIImageView *logoPlaceholderImageView;

@end

@implementation XXTEWorkspaceViewController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Workspace", nil);
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.arrowPlaceholderImageView.hidden = (self.splitViewController.displayMode != UISplitViewControllerDisplayModePrimaryHidden);
    
    [self.view addSubview:self.arrowPlaceholderImageView];
    [self.view addSubview:self.logoPlaceholderImageView];
    
    [self makeViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (XXTE_COLLAPSED) {
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    }
}

- (void)makeViewConstraints {
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.logoPlaceholderImageView
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeCenterX
                                 multiplier:1
                                   constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.logoPlaceholderImageView
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1
                                   constant:0]];
    [self.logoPlaceholderImageView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.logoPlaceholderImageView
                                  attribute:NSLayoutAttributeWidth
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeWidth
                                 multiplier:1
                                   constant:128.f]];
    [self.logoPlaceholderImageView addConstraint:
     [NSLayoutConstraint constraintWithItem:self.logoPlaceholderImageView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeHeight
                                 multiplier:1
                                   constant:128.f]];
}

#pragma mark - UIView Getters

- (UIImageView *)arrowPlaceholderImageView {
    if (!_arrowPlaceholderImageView) {
        UIImageView *arrowPlaceholderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 128.f, 128.f)];
        arrowPlaceholderImageView.contentMode = UIViewContentModeScaleAspectFill;
        arrowPlaceholderImageView.tintColor = [UIColor colorWithRed: 189.0/255.0 green: 195.0/255.0 blue: 199.0/255.0 alpha: 1.0];
        arrowPlaceholderImageView.image = [[UIImage imageNamed:@"XXTEWorkspacePlaceholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _arrowPlaceholderImageView = arrowPlaceholderImageView;
    }
    return _arrowPlaceholderImageView;
}

- (UIImageView *)logoPlaceholderImageView {
    if (!_logoPlaceholderImageView) {
        UIImageView *logoPlaceholderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 128.f, 128.f)];
        logoPlaceholderImageView.contentMode = UIViewContentModeScaleAspectFill;
        logoPlaceholderImageView.translatesAutoresizingMaskIntoConstraints = NO;
        logoPlaceholderImageView.tintColor = [UIColor colorWithRed: 189.0/255.0 green: 195.0/255.0 blue: 199.0/255.0 alpha: 1.0];
        logoPlaceholderImageView.image = [[UIImage imageNamed:@"XXTEAboutIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _logoPlaceholderImageView = logoPlaceholderImageView;
    }
    return _logoPlaceholderImageView;
}

#pragma mark - Notifications

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    NSString *displayModeValue = userInfo[XXTENotificationDetailDisplayMode];
    if ([eventType isEqualToString:XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode] && displayModeValue) {
        UISplitViewControllerDisplayMode displayMode = [((NSNumber *)displayModeValue) integerValue];
        self.arrowPlaceholderImageView.hidden = (displayMode == UISplitViewControllerDisplayModeAllVisible);
    }
}

#pragma mark - Memory

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog(@"- [XXTEWorkspaceViewController dealloc]");
#endif
}

@end
