//
//  XXTESegmentedController.m
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESegmentedController.h"

@interface XXTESegmentedController () <UIScrollViewDelegate>
    @property (nonatomic, strong) NSArray <UIViewController *> *preparedViewControllers;
    @property (nonatomic, assign) NSUInteger selectedIndex;
    
    @end

@implementation XXTESegmentedController {
    BOOL _isFirstLoading;
}
    
#pragma mark - Initializers
    
- (instancetype)init {
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}
    
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    return self;
}
    
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self configure];
    }
    return self;
}
    
- (void)configure {
    _isFirstLoading = YES;
    _selectedIndex = 0;
    
    self.pageScrollView.backgroundColor = [UIColor whiteColor];
    
    XXTESegmentedControl *segmentedControl = [[XXTESegmentedControl alloc] init];
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl = segmentedControl;
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.pagingEnabled = YES;
    scrollView.delegate = self;
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    _pageScrollView = scrollView;
}
    
#pragma mark - Forward
    
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}
    
#pragma mark - Rotation
    
- (void)willAnimateRotationToInterfaceOrientation:(__unused UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
    {
        [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
        CGSize navigationBarSize = self.navigationController.navigationBar.frame.size;
        UIView *titleView = self.navigationItem.titleView;
        CGRect titleViewFrame = titleView.frame;
        titleViewFrame.size = navigationBarSize;
        self.navigationItem.titleView.frame = titleViewFrame;
    }
    
#pragma mark - Life Cycle
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    
    [self.segmentedControl setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0)];
    [self.pageScrollView setFrame:self.view.bounds];
    
    [self.navigationItem setTitleView:self.segmentedControl];
    [self.view addSubview:self.pageScrollView];
    
    [self updateControllers];
}
    
- (void)updateControllers {
    NSArray <UIViewController *> *preparedViewControllers = self.preparedViewControllers;
    
    NSMutableArray <NSString *> *segments = [[NSMutableArray alloc] init];
    for (UIViewController *child in preparedViewControllers) {
        if (child.title) {
            [segments addObject:child.title];
        } else {
            [segments addObject:@"..."];
        }
    }
    [self.segmentedControl setSegments:[segments copy]];
    [self.pageScrollView setContentOffset:CGPointZero animated:NO];
    
    if (preparedViewControllers.count > 0) {
        [self setSelectedIndex:0];
        if (self.lazyload) {
            [self updateChildControllerAtIndex:self.selectedIndex];
        } else {
            for (NSUInteger idx = 0; idx < self.preparedViewControllers.count; idx++)
            {
                [self updateChildControllerAtIndex:idx];
            }
        }
    }
}
    
- (void)updateChildControllerAtIndex:(NSUInteger)idx {
    NSArray <UIViewController *> *preparedViewControllers = self.preparedViewControllers;
    if (idx < preparedViewControllers.count) {
        UIViewController *controller = preparedViewControllers[idx];
        NSUInteger previousPage = self.selectedIndex;
        if (previousPage != idx) {
            [self childViewControllerWillDisappear:previousPage animated:NO];
        }
        [self childViewControllerWillAppear:idx animated:NO];
        BOOL alreadyLoaded = [self.childViewControllers containsObject:controller];
        if (!alreadyLoaded) {
            [self addChildViewController:controller];
            [self.pageScrollView addSubview:controller.view];
            [controller didMoveToParentViewController:self];
        }
        BOOL switchPage = (previousPage != idx);
        if (switchPage)
        {
            [self childViewControllerDidDisappear:previousPage animated:NO];
        }
        if (alreadyLoaded ||
            !switchPage)
        {
            [self childViewControllerDidAppear:idx animated:NO];
        }
    }
}
    
- (void)layoutControllers {
    CGRect bounds = self.view.bounds;
    CGFloat offset = CGRectGetWidth(bounds) * self.selectedIndex;
    [self.pageScrollView setContentOffset:CGPointMake(offset, 0) animated:YES];
    
    NSArray <UIViewController *> *controllers = self.childViewControllers;
    NSUInteger childCnt = controllers.count;
    for (NSUInteger idx = 0; idx < childCnt; idx++) {
        UIViewController *controller = controllers[idx];
        CGFloat xPos = CGRectGetWidth(bounds) * idx;
        CGRect newFrame = CGRectMake(xPos, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds));
        [controller.view setFrame:newFrame];
    }
    NSUInteger preparedCnt = self.preparedViewControllers.count;
    CGSize contentSize = CGSizeMake(CGRectGetWidth(bounds) * preparedCnt, CGRectGetHeight(bounds));
    [self.pageScrollView setContentSize:contentSize];
}
    
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_isFirstLoading) {
        [self childViewControllerWillAppear:self.selectedIndex animated:animated];
    }
}
    
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_isFirstLoading) {
        [self childViewControllerDidAppear:self.selectedIndex animated:animated];
    }
    _isFirstLoading = NO;
}
    
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self childViewControllerWillDisappear:self.selectedIndex animated:animated];
}
    
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self childViewControllerDidDisappear:self.selectedIndex animated:animated];
}
    
#pragma mark - Layout
    
- (void)viewDidLayoutSubviews {
    if (@available(iOS 11.0, *)) {
        
    } else {
        self.segmentedControl.frame = self.segmentedControl.superview.bounds;
    }
    [super viewDidLayoutSubviews];
    [self layoutControllers];
}
    
#pragma mark - Actions
    
- (void)segmentedControlChanged:(XXTESegmentedControl *)sender {
    [self updateChildControllerAtIndex:sender.selectedSegmentIndex];
    [self setSelectedIndex:sender.selectedSegmentIndex];
    [self layoutControllers];
}
    
#pragma mark - Setters
    
- (void)setViewControllers:(NSArray <UIViewController *> *)viewControllers {
    _preparedViewControllers = viewControllers;
    if ([self isViewLoaded]) {
        NSArray <UIViewController *> *internalControllers = self.childViewControllers;
        for (UIViewController *internalController in internalControllers) {
            NSUInteger idx = [self.preparedViewControllers indexOfObject:internalController];
            [self childViewControllerWillDisappear:idx animated:NO];
            
            [internalController willMoveToParentViewController:nil];
            [internalController.view removeFromSuperview];
            [internalController removeFromParentViewController];
            
            [self childViewControllerDidDisappear:idx animated:NO];
        }
        [self updateControllers];
        [self layoutControllers];
    }
}
    
#pragma mark - UIScrollViewDelegate
    
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.segmentedControl scrollViewDidScroll:scrollView];
}
    
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.segmentedControl scrollViewDidEndDecelerating:scrollView];
    [self updateChildControllerAtIndex:self.segmentedControl.selectedSegmentIndex];
    [self setSelectedIndex:self.segmentedControl.selectedSegmentIndex];
    [self layoutControllers];
}
    
#pragma mark - Child Appearance
    
- (void)childViewControllerWillAppear:(NSUInteger)page animated:(BOOL)animated {
    if (page < self.preparedViewControllers.count && page != NSNotFound) {
        UIViewController *controller = [self.preparedViewControllers objectAtIndex:page];
        [controller beginAppearanceTransition:YES animated:animated];
    }
}
    
- (void)childViewControllerDidAppear:(NSUInteger)page animated:(BOOL)animated {
    if (page < self.preparedViewControllers.count && page != NSNotFound) {
        UIViewController *controller = [self.preparedViewControllers objectAtIndex:page];
        [controller endAppearanceTransition];
    }
}
    
- (void)childViewControllerWillDisappear:(NSUInteger)page animated:(BOOL)animated  {
    if (page < self.preparedViewControllers.count && page != NSNotFound) {
        UIViewController *controller = [self.preparedViewControllers objectAtIndex:page];
        if ([self.childViewControllers containsObject:controller]) {
            [controller beginAppearanceTransition:NO animated:animated];
        }
    }
}
    
- (void)childViewControllerDidDisappear:(NSUInteger)page animated:(BOOL)animated {
    if (page < self.preparedViewControllers.count && page != NSNotFound) {
        UIViewController *controller = [self.preparedViewControllers objectAtIndex:page];
        if ([self.childViewControllers containsObject:controller]) {
            [controller endAppearanceTransition];
        }
    }
}
    
#pragma mark - Memory
    
- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}
    
@end

