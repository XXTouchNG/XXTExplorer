//
//  XXTEEditorSearchHeaderView.m
//  XXTExplorer
//
//  Created by Zheng on 16/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchHeaderView.h"

@implementation XXTEEditorSearchHeaderView

- (instancetype)init {
    self = [super init];
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

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor colorWithWhite:0.99 alpha:1.0];
    self.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.layer.borderWidth = .5;
//    self.layer.shadowColor = [UIColor colorWithWhite:0.33 alpha:1.0].CGColor;
//    self.layer.shadowRadius = 6.0;
//    self.layer.shadowOpacity = 0.12;
//    self.layer.shadowOffset = CGSizeMake(4.0, 4.0);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
