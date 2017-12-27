//
//  XXTEAutoLabel.m
//  XXTExplorer
//
//  Created by Zheng on 27/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEAutoLabel.h"

@implementation XXTEAutoLabel

- (void)setBounds:(CGRect)bounds {
    if (bounds.size.width != self.bounds.size.width) {
        [self setNeedsUpdateConstraints];
    }
    [super setBounds:bounds];
}

- (void)updateConstraints {
    if (self.preferredMaxLayoutWidth != self.bounds.size.width) {
        self.preferredMaxLayoutWidth = self.bounds.size.width;
    }
    [super updateConstraints];
}

@end
