//
//  XXTEWorkspaceViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEWorkspaceViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface XXTEWorkspaceViewController () <UIDropInteractionDelegate>

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UIDropInteraction *dropInteraction;
XXTE_END_IGNORE_PARTIAL

@property (nonatomic, strong) UIImageView *logoPlaceholderImageView;
@property (nonatomic, strong) UILabel *guideLabel;

@end

@implementation XXTEWorkspaceViewController

@synthesize entryPath = _entryPath;

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Workspace", nil);
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    
    if (@available(iOS 11.0, *))
    {
        UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
        [self.view addInteraction:dropInteraction];
        _dropInteraction = dropInteraction;
    }
    
    [self.view addSubview:self.logoPlaceholderImageView];
    [self.view addSubview:self.guideLabel];
    
    [self makeViewConstraints];

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
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
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.guideLabel
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.logoPlaceholderImageView
                                  attribute:NSLayoutAttributeCenterX
                                 multiplier:1
                                   constant:0.0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.guideLabel
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.logoPlaceholderImageView
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1
                                   constant:16.0]];
    [self.guideLabel addConstraint:
     [NSLayoutConstraint constraintWithItem:self.guideLabel
                                  attribute:NSLayoutAttributeWidth
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeWidth
                                 multiplier:1
                                   constant:256.f]];
    [self.guideLabel addConstraint:
     [NSLayoutConstraint constraintWithItem:self.guideLabel
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeHeight
                                 multiplier:1
                                   constant:16.f]];
}

#pragma mark - UIView Getters

- (UIImageView *)logoPlaceholderImageView {
    if (!_logoPlaceholderImageView) {
        UIImageView *logoPlaceholderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 128.f, 128.f)];
        logoPlaceholderImageView.contentMode = UIViewContentModeScaleAspectFill;
        logoPlaceholderImageView.translatesAutoresizingMaskIntoConstraints = NO;
        logoPlaceholderImageView.tintColor = [UIColor colorWithRed: 189.0/255.0 green: 195.0/255.0 blue: 199.0/255.0 alpha: 1.0];
        logoPlaceholderImageView.image = [[UIImage imageNamed:@"XUIAboutIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _logoPlaceholderImageView = logoPlaceholderImageView;
    }
    return _logoPlaceholderImageView;
}

- (UILabel *)guideLabel {
    if (!_guideLabel) {
        _guideLabel = [[UILabel alloc] init];
        _guideLabel.font = [UIFont systemFontOfSize:14.0];
        _guideLabel.textColor = [UIColor colorWithRed: 189.0/255.0 green: 195.0/255.0 blue: 199.0/255.0 alpha: 1.0];
        _guideLabel.numberOfLines = 1;
        _guideLabel.textAlignment = NSTextAlignmentCenter;
        _guideLabel.text = NSLocalizedString(@"Select item from the left panel", nil);
        _guideLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _guideLabel;
}

#pragma mark - Notifications

#pragma mark - Theme

- (void)renderNavigationBarTheme:(BOOL)restore {
    UIColor *barTintColor = XXTColorBarTint();
    UIColor *barTitleColor = [UIColor whiteColor];
    UINavigationController *navigation = self.navigationController;
    [navigation.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : barTitleColor}];
    navigation.navigationBar.tintColor = barTitleColor;
    navigation.navigationBar.barTintColor = barTintColor;
    navigation.navigationItem.leftBarButtonItem.tintColor = barTitleColor;
    navigation.navigationItem.rightBarButtonItem.tintColor = barTitleColor;
    for (UIBarButtonItem *item in navigation.navigationItem.leftBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    for (UIBarButtonItem *item in navigation.navigationItem.rightBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    self.navigationItem.leftBarButtonItem.tintColor = barTitleColor;
    self.navigationItem.rightBarButtonItem.tintColor = barTitleColor;
    for (UIBarButtonItem *item in self.navigationItem.leftBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - UIDropInteraction

XXTE_START_IGNORE_PARTIAL
- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session {
    return YES;
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session {
//    if (session.items.count != 1)
//    {
        return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
//    }
//    return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session {
//    [session.items enumerateObjectsUsingBlock:^(UIDragItem * _Nonnull dragItem, NSUInteger idx, BOOL * _Nonnull stop) {
//        [dragItem.itemProvider loadInPlaceFileRepresentationForTypeIdentifier:(NSString *)kUTTypeItem completionHandler:^(NSURL * _Nullable url, BOOL isInPlace, NSError * _Nullable error)
//        {
//            
//        }];
//    }];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
