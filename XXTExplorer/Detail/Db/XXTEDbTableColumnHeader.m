//
//  XXTETableContentHeaderCell.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEDbTableColumnHeader.h"

@implementation XXTEDbTableColumnHeader
{
    UILabel *_arrowLabel;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, frame.size.width - 25, frame.size.height)];
        label.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:label];
        self.label = label;
        
        
        _arrowLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 20, 0, 20, frame.size.height)];
        _arrowLabel.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:_arrowLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 0.6, 0, 0.6, frame.size.height)];
        line.backgroundColor = [UIColor colorWithWhite:0.803 alpha:0.850];
        [self addSubview:line];
        
    }
    return self;
}

- (void)changeSortStatusWithType:(XXTEDbTableColumnHeaderSortType)type
{
    switch (type) {
        case XXTEDbTableColumnHeaderSortTypeNone:
            _arrowLabel.text = @"";
            break;
        case XXTEDbTableColumnHeaderSortTypeAsc:
            _arrowLabel.text = @"+";
            break;
        case XXTEDbTableColumnHeaderSortTypeDesc:
            _arrowLabel.text = @"-";
            break;
    }
}

@end
