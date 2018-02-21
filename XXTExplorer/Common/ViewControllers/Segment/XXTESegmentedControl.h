//
//  XXTESegmentedControl.h
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTESegmentedControl : UIControl <UIScrollViewDelegate>
    
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, assign, readonly) NSUInteger numberOfSegments;

@property (nonatomic, strong) UIColor *dividerColor; // default is light gray
@property (nonatomic, strong) UIColor *indicatorColor; // default is red

@property (nonatomic, strong) UIColor *selectedTitleColor; // default is red
@property (nonatomic, strong) UIColor *titleColor; // default is black
@property (nonatomic, strong) UIFont *titleFont; // default is system font 20.0

@property (nonatomic, assign) CGFloat segmentMargin; // default is 20.0
@property (nonatomic, assign) UIEdgeInsets segmentInsets;
@property (nonatomic, assign) CGFloat indicatorHeight; // default is 3.0

@property (nonatomic, assign) CGFloat animationDelay; // default is 0.2
@property (nonatomic, assign) BOOL scrollsToSelectedSegment;
    
- (instancetype)initWithSegments:(NSArray *)segments; // items should be NSStrings
    
- (void)setSegments:(NSArray *)segments;
- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment; // insert before segment number. 0..#segments. value pinned
- (void)removeSegmentAtIndex:(NSUInteger)segment;
- (void)removeAllSegments;
    
- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment;
- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment;
    
- (NSUInteger)selectedSegmentIndex;
- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex;
- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex animated:(BOOL)animated;

@end
