//
//  XXTESegmentedController.h
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTESegmentedControl.h"

@interface XXTESegmentedController : UIViewController

@property (nonatomic, strong, readonly) XXTESegmentedControl *segmentedControl;
@property (nonatomic, strong, readonly) UIScrollView *pageScrollView;
@property (nonatomic, assign) BOOL lazyload;
    
- (void)setViewControllers:(NSArray <UIViewController *> *)viewControllers;
    
- (void)childViewControllerWillAppear:(NSUInteger)page animated:(BOOL)animated NS_REQUIRES_SUPER;
- (void)childViewControllerDidAppear:(NSUInteger)page animated:(BOOL)animated NS_REQUIRES_SUPER;
- (void)childViewControllerWillDisappear:(NSUInteger)page animated:(BOOL)animated NS_REQUIRES_SUPER;
- (void)childViewControllerDidDisappear:(NSUInteger)page animated:(BOOL)animated NS_REQUIRES_SUPER;

@end
