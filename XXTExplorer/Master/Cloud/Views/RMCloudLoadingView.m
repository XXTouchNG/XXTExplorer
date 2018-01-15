//
//  RMCloudLoadingView.m
//  XXTExplorer
//
//  Created by Zheng on 15/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudLoadingView.h"

@interface RMCloudLoadingView ()

@end

@implementation RMCloudLoadingView {
    
}

- (instancetype)init {
    if (self = [super init])
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)setup {
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:[UIImage imageNamed:@"RMPaw"]];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.contentView = imageView;
    
    self.shimmeringSpeed = 25.;
    self.shimmeringAnimationOpacity = .4;
    self.shimmering = YES;
}

@end
