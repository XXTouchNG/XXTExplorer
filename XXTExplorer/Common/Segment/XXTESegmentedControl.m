//
//  XXTESegmentedControl.m
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESegmentedControl.h"
#import "XXTESegmentedButton.h"

@interface XXTESegmentedControl ()
    
    @property (nonatomic, strong) NSMutableArray <NSString *> *items;
    @property (nonatomic, strong) NSMutableArray <XXTESegmentedButton *> *buttons;
    
    @property (nonatomic, strong) UIView *indicatorContainer;
    @property (nonatomic, strong) UIView *indicatorView;
    
    @end

@implementation XXTESegmentedControl {
    NSUInteger _selectedSegmentIndex;
}
    
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
    
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
    
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
    
- (instancetype)initWithSegments:(NSArray *)segments {
    self = [super init];
    if (self) {
        [self setup];
        [self.items removeAllObjects];
        [self.items addObjectsFromArray:segments];
        [self updateItems];
    }
    return self;
}
    
#pragma mark - Default Style
    
- (void)setup {
    _items = [[NSMutableArray alloc] init];
    _buttons = [[NSMutableArray alloc] init];
    
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    _dividerColor = [UIColor clearColor];
    
    _indicatorColor = [UIColor whiteColor];
    _selectedTitleColor = [UIColor whiteColor];
    _titleColor = [UIColor whiteColor];
    
    _titleFont = [UIFont boldSystemFontOfSize:16.0];
    
    _animationDelay = 0.33;
    _scrollsToSelectedSegment = YES;
    
    _segmentMargin = 20.0;
    _segmentInsets = UIEdgeInsetsMake(12.0, 12.0, 8.0, 12.0);
    _indicatorHeight = 2.0;
    _selectedSegmentIndex = 0;
    
    [self setupSubviews];
}
    
- (void)setupSubviews {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    _scrollView = scrollView;
    [self addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] init];
    _contentView = contentView;
    [scrollView addSubview:contentView];
    
    UIView *indicatorContainer = [[UIView alloc] init];
    _indicatorContainer = indicatorContainer;
    [contentView addSubview:indicatorContainer];
    
    UIView *indicatorView = [[UIView alloc] init];
    indicatorView.backgroundColor = self.indicatorColor;
    _indicatorView = indicatorView;
    [indicatorContainer addSubview:indicatorView];
}
    
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    self.scrollView.frame = bounds;
    CGRect contentFrame = self.contentView.frame;
    if (CGRectGetWidth(self.contentView.bounds) > CGRectGetWidth(bounds))
    {
        contentFrame.origin =
        CGPointMake(0.0, 0.0);
    }
    else
    {
        contentFrame.origin =
        CGPointMake( (CGRectGetWidth(bounds) - CGRectGetWidth(self.contentView.bounds)) / 2.0, 0.0);
    }
    [self.contentView setFrame:contentFrame];
}
    
#pragma mark - Items
    
- (void)updateItems {
    UIView *content = self.contentView;
    for (UIView *subview in content.subviews) {
        if ([subview isKindOfClass:[XXTESegmentedButton class]]) {
            [subview removeFromSuperview];
        }
    }
    
    NSMutableArray <XXTESegmentedButton *> *buttons = self.buttons;
    [buttons removeAllObjects];
    
    NSDictionary *attrs =
    @{
      NSFontAttributeName: self.titleFont,
      NSForegroundColorAttributeName: self.titleColor
      };
    
    NSDictionary *selAttrs =
    @{
      NSFontAttributeName: self.titleFont,
      NSForegroundColorAttributeName: self.selectedTitleColor
      };
    
    UIEdgeInsets insets = self.segmentInsets;
    CGFloat margin = self.segmentMargin;
    
    CGFloat prevBtnWidth = 0.0;
    CGFloat maxHeight = (self.items.count == 0) ? 44.0 : 0.0;
    
    NSUInteger selected = _selectedSegmentIndex;
    NSArray <NSString *> *items = self.items;
    NSUInteger cnt = items.count;
    for (NSUInteger idx = 0; idx < cnt; idx++) {
        @autoreleasepool {
            NSString *title = items[idx];
            NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:attrs];
            NSAttributedString *selAttrTitle = [[NSAttributedString alloc] initWithString:title attributes:selAttrs];
            
            XXTESegmentedButton *btn = [[XXTESegmentedButton alloc] init];
            
            [btn setAccessibilityIdentifier:[NSString stringWithFormat:@"XXTESegmentedButton-%@", title]];
            [btn setContentEdgeInsets:insets];
            [btn setAttributedTitle:attrTitle forState:UIControlStateNormal];
            [btn setAttributedTitle:selAttrTitle forState:UIControlStateSelected];
            [btn setSelected:(idx == selected)];
            
            [buttons addObject:btn];
            [btn sizeToFit];
            
            CGRect btnBound = btn.bounds;
            CGFloat xPos =
            margin * (1 + idx)
            + prevBtnWidth
            ;
            
            prevBtnWidth += btnBound.size.width;
            maxHeight = MAX(maxHeight, btnBound.size.height);
            
            CGRect btnFrame = CGRectMake(xPos, 0, btnBound.size.width, btnBound.size.height);
            [btn setFrame:btnFrame];
        }
    }
    
    CGFloat totalWidth =
    prevBtnWidth
    + margin * (cnt + 1)
    ;
    
    CGFloat indicatorHeight = self.indicatorHeight;
    
    CGSize contentSize = CGSizeMake(totalWidth, maxHeight + indicatorHeight);
    [self.scrollView setContentSize:contentSize];
    
    CGRect contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
    [content setFrame:contentRect];
    
    CGRect indicatorContainerRect = CGRectMake(0, contentSize.height - indicatorHeight, contentSize.width, indicatorHeight);
    [self.indicatorContainer setFrame:indicatorContainerRect];
    
    [self setSelectedSegmentIndex:selected animated:NO];
    for (XXTESegmentedButton *btn in buttons) {
        [btn addTarget:self action:@selector(segmentedButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [content addSubview:btn];
    }
    
    [self setNeedsLayout];
}
    
- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, self.scrollView.contentSize.height);
}
    
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    fitSize.height = self.scrollView.contentSize.height;
    return fitSize;
}
    
#pragma mark - Getters
    
- (NSUInteger)numberOfSegments {
    return self.items.count;
}
    
#pragma mark - Setters
    
- (void)setDividerColor:(UIColor *)dividerColor {
    _dividerColor = dividerColor;
    [self setNeedsDisplay];
}
    
- (void)setSelectedTitleColor:(UIColor *)selectedTextColor {
    _selectedTitleColor = selectedTextColor;
    NSDictionary *selAttrs =
    @{
      NSFontAttributeName: self.titleFont,
      NSForegroundColorAttributeName: self.selectedTitleColor
      };
    for (XXTESegmentedButton *btn in self.buttons) {
        NSString *title = [[btn attributedTitleForState:UIControlStateSelected] string];
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:selAttrs];
        [btn setAttributedTitle:attrTitle forState:UIControlStateSelected];
    }
}
    
- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    NSDictionary *attrs =
    @{
      NSFontAttributeName: self.titleFont,
      NSForegroundColorAttributeName: self.titleColor
      };
    for (XXTESegmentedButton *btn in self.buttons) {
        NSString *title = [[btn attributedTitleForState:UIControlStateNormal] string];
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:attrs];
        [btn setAttributedTitle:attrTitle forState:UIControlStateNormal];
    }
}
    
- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    [self updateItems];
}
    
- (void)setSegmentMargin:(CGFloat)segmentMargin {
    _segmentMargin = segmentMargin;
    [self updateItems];
}
    
- (void)setSegmentInsets:(UIEdgeInsets)segmentInsets {
    _segmentInsets = segmentInsets;
    [self updateItems];
}
    
- (void)setIndicatorHeight:(CGFloat)indicatorHeight {
    _indicatorHeight = indicatorHeight;
    [self updateItems];
}
    
- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment {
    [self.items insertObject:title atIndex:segment];
    [self updateItems];
}
    
- (void)removeSegmentAtIndex:(NSUInteger)segment {
    [self.items removeObjectAtIndex:segment];
    [self updateItems];
}
    
- (void)removeAllSegments {
    [self.items removeAllObjects];
    [self updateItems];
}
    
- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment {
    [self.items replaceObjectAtIndex:segment withObject:title];
    [self updateItems];
}
    
- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment {
    return self.items[segment];
}
    
- (NSUInteger)selectedSegmentIndex {
    return _selectedSegmentIndex;
}
    
- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex {
    [self setSelectedSegmentIndex:selectedSegmentIndex animated:YES];
}
    
- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex animated:(BOOL)animated
    {
        CGFloat delay = self.animationDelay;
        NSArray <XXTESegmentedButton *> *buttons = self.buttons;
        if (selectedSegmentIndex < buttons.count) {
            for (XXTESegmentedButton *btn in buttons) {
                if (btn.selected) {
                    if (animated) {
                        [UIView transitionWithView:btn
                                          duration:delay
                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                        animations:^{ btn.selected = NO; }
                                        completion:nil];
                    } else {
                        btn.selected = NO;
                    }
                }
            }
            XXTESegmentedButton *selectedBtn = buttons[selectedSegmentIndex];
            CGRect btnRect = selectedBtn.frame;
            CGRect toIndicatorRect = [self indicatorRectForPageAtIndex:selectedSegmentIndex];
            if (animated) {
                [UIView transitionWithView:selectedBtn
                                  duration:delay
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{ selectedBtn.selected = YES; }
                                completion:nil];
                [UIView animateWithDuration:delay animations:^{
                    [self.indicatorView setFrame:toIndicatorRect];
                } completion:nil];
            } else {
                selectedBtn.selected = YES;
                [self.indicatorView setFrame:toIndicatorRect];
            }
            if (self.scrollsToSelectedSegment) {
                CGSize frameSize = self.scrollView.frame.size;
                CGSize contentSize = self.scrollView.contentSize;
                if (contentSize.width - btnRect.origin.x < frameSize.width) {
                    CGFloat bottomOffset = contentSize.width - frameSize.width;
                    if (bottomOffset >= 0) {
                        [self.scrollView setContentOffset:CGPointMake(bottomOffset, 0) animated:animated];
                    }
                }
                else {
                    [self.scrollView setContentOffset:btnRect.origin animated:animated];
                }
            }
        }
        _selectedSegmentIndex = selectedSegmentIndex;
    }
    
- (void)setSegments:(NSArray *)segments {
    [self.items removeAllObjects];
    [self.items addObjectsFromArray:segments];
    _selectedSegmentIndex = 0;
    [self updateItems];
}
    
#pragma mark - Draw

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 0.5);
    [self.dividerColor setStroke];
    
    CGPoint aps[2];
    aps[0] = CGPointMake(0, rect.size.height);
    aps[1] = CGPointMake(rect.size.width, rect.size.height);
    
    CGContextAddLines(ctx, aps, 2);
    CGContextDrawPath(ctx, kCGPathStroke);
}
    
#pragma mark - Actions
    
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}
    
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}
    
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
}
    
- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
}
    
- (void)segmentedButtonTapped:(XXTESegmentedButton *)sender {
    NSUInteger selectedIndex = [self.buttons indexOfObject:sender];
    if (selectedIndex != NSNotFound && selectedIndex != _selectedSegmentIndex) {
        [self setSelectedSegmentIndex:selectedIndex];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
    
#pragma mark - Helpers
    
- (CGRect)indicatorRectForPageAtIndex:(NSUInteger)idx {
    if (idx >= self.buttons.count)
    return CGRectZero;
    XXTESegmentedButton *selectedBtn = self.buttons[idx];
    CGRect btnRect = selectedBtn.frame;
    UIEdgeInsets insets = self.segmentInsets;
    CGRect indicatorRect = CGRectMake(btnRect.origin.x + insets.left, 0, btnRect.size.width - (insets.left + insets.right), self.indicatorHeight);
    return indicatorRect;
}
    
#pragma mark - UIScrollViewDelegate
    
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView) {
        if (scrollView.isDragging) {
            CGPoint outTrans = [scrollView.panGestureRecognizer translationInView:scrollView];
            
            CGFloat outPageIndex = floor(( scrollView.contentOffset.x ) / CGRectGetWidth( scrollView.frame ));
            CGFloat outProgress = ( scrollView.contentOffset.x - outPageIndex * CGRectGetWidth( scrollView.frame ) ) / CGRectGetWidth( scrollView.frame );
            if (outProgress <= 0.0 || outProgress >= 1.0) return;
            
            NSUInteger inPrevPageIndex = (outTrans.x < 0) ? outPageIndex : outPageIndex + 1;
            NSUInteger inNextPageIndex = (outTrans.x < 0) ? outPageIndex + 1 : outPageIndex;
            CGFloat inProgress = (outTrans.x < 0) ? outProgress : 1.0 - outProgress;
            
            CGRect inPrev = [self indicatorRectForPageAtIndex:inPrevPageIndex];
            CGRect inNext = [self indicatorRectForPageAtIndex:inNextPageIndex];
            if (CGRectEqualToRect(inPrev, CGRectZero) || CGRectEqualToRect(inNext, CGRectZero)) return;
            CGFloat inTransX =  ( CGRectGetMinX(inNext) - CGRectGetMinX(inPrev) ) * inProgress;
            CGFloat inW = CGRectGetWidth(inPrev) + (CGRectGetWidth(inNext) - CGRectGetWidth(inPrev)) * inProgress;
            
            CGRect inTransFrame = CGRectMake(CGRectGetMinX(inPrev) + inTransX, 0.0, inW, self.indicatorHeight);
            [self.indicatorView setFrame:inTransFrame];
        }
    }
}
    
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView) {
        NSUInteger currentPage = (NSUInteger)((scrollView.contentOffset.x) / CGRectGetWidth(scrollView.frame));
        [self setSelectedSegmentIndex:currentPage animated:YES];
    }
}
    
@end
