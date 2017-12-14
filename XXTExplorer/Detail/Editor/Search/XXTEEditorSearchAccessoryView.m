//
//  XXTEEditorSearchAccessoryView.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchAccessoryView.h"

@implementation XXTEEditorSearchAccessoryView

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.translucent = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIBarButtonItem *prevButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEEditorSearchBarPrevIcon"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(searchPreviousMatch)];
    UIBarButtonItem *nextButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEEditorSearchBarNextIcon"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(searchNextMatch)];
    
    prevButtonItem.tintColor = self.tintColor;
    nextButtonItem.tintColor = self.tintColor;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:16.0];
    countLabel.textAlignment = NSTextAlignmentRight;
    countLabel.textColor = self.tintColor;
    countLabel.text = NSLocalizedString(@"0/0", nil);
    [countLabel sizeToFit];
    _countLabel = countLabel;
    
    UIBarButtonItem *counter = [[UIBarButtonItem alloc] initWithCustomView:countLabel];
    [self setItems:@[prevButtonItem, nextButtonItem, flexibleSpace, counter]];
}

- (void)searchPreviousMatch {
    if ([_accessoryDelegate respondsToSelector:@selector(searchAccessoryViewShouldMatchPrev:)]) {
        [_accessoryDelegate searchAccessoryViewShouldMatchPrev:self];
    }
}

- (void)searchNextMatch {
    if ([_accessoryDelegate respondsToSelector:@selector(searchAccessoryViewShouldMatchNext:)]) {
        [_accessoryDelegate searchAccessoryViewShouldMatchNext:self];
    }
}

- (void)reloadItemTintColor {
    for (UIBarButtonItem *item in self.items) {
        item.tintColor = self.tintColor;
    }
    self.countLabel.textColor = self.tintColor;
}

@end
