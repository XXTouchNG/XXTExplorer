//
//  XXTEScanLineAnimation.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEScanLineAnimation : UIImageView

@property (nonatomic, assign) BOOL isAnimating;

- (void)startAnimatingWithRect:(CGRect)animationRect
                    parentView:(UIView *)parentView;
- (void)stopAnimating;

@end
