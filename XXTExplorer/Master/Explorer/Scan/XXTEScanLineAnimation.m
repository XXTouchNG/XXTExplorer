//
//  XXTEScanLineAnimation.m
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEScanLineAnimation.h"

@interface XXTEScanLineAnimation ()

@end

@implementation XXTEScanLineAnimation

- (void)stepAnimation {
    if (!self.isAnimating) {
        return;
    }
    
    CGFloat leftX = self.animationRect.origin.x + 5;
    CGFloat width = self.animationRect.size.width - 10;
    
    self.frame = CGRectMake(leftX, self.animationRect.origin.y + 8, width, 8);
    self.alpha = 0.f;
    self.hidden = NO;
    
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:.5f animations:^{
        weakSelf.alpha = 1.0;
    } completion:nil];
    
    [UIView animateWithDuration:2.4f animations:^{
        CGFloat leftX = self->_animationRect.origin.x + 5;
        CGFloat width = self->_animationRect.size.width - 10;
        weakSelf.frame = CGRectMake(leftX, self->_animationRect.origin.y + self->_animationRect.size.height - 8, width, 4);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [weakSelf performSelector:@selector(stepAnimation) withObject:nil afterDelay:0.3];
    }];
}


- (void)startAnimatingWithRect:(CGRect)animationRect parentView:(UIView *)parentView {
    if (self.isAnimating) {
        return;
    }
    self.isAnimating = YES;
    self.animationRect = animationRect;
    
    [parentView addSubview:self];
    [self startAnimating_UIViewAnimation];
}

- (void)startAnimating_UIViewAnimation {
    [self stepAnimation];
}

- (void)stopAnimating {
    if (self.isAnimating) {
        self.isAnimating = NO;
        [self removeFromSuperview];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dealloc {
    [self stopAnimating];
}

@end
