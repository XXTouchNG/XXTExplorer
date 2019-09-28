//
//  XXTExplorerToolbarButtonItem.m
//  XXTExplorer
//
//  Created by MMM on 2019/9/28.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTExplorerToolbarButtonItem.h"

@implementation XXTExplorerToolbarButtonItem

- (instancetype)initWithName:(NSString *)name andActionReceiver:(id <XXTExplorerToolbarButtonItemDelegate>)actionReceiver {
    if (self = [super init]) {
        _name = name;
        _actionReceiver = actionReceiver;
        _status = XXTExplorerToolbarButtonItemStatusNormal;
        
        [self updateButtonStatus];
    }
    return self;
}

- (void)setStatus:(XXTExplorerToolbarButtonItemStatus *)status forTraitCollection:(UITraitCollection *)traitCollection {
    _status = status;
    [self updateButtonStatusForTraitCollection:traitCollection];
}

- (void)updateButtonStatus {
    [self updateButtonStatusForTraitCollection:nil];
}

- (void)updateButtonStatusForTraitCollection:(UITraitCollection *)traitCollection {
    UIImage *itemImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@", self.name, self.status] inBundle:nil compatibleWithTraitCollection:traitCollection];
    itemImage = [itemImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIButton *newButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 26.0, 26.0)];
    if ([self.actionReceiver respondsToSelector:@selector(toolbarButtonTapped:)]) {
        [newButton addTarget:self.actionReceiver action:@selector(toolbarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    [newButton setImage:itemImage forState:UIControlStateNormal];
    
    [self setCustomView:newButton];
}

@end
