//
//  XXTETableContentHeaderCell.h
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XXTEDbTableColumnHeaderSortType) {
    XXTEDbTableColumnHeaderSortTypeNone = 0,
    XXTEDbTableColumnHeaderSortTypeAsc,
    XXTEDbTableColumnHeaderSortTypeDesc,
};

@interface XXTEDbTableColumnHeader : UIView

@property (nonatomic, strong) UILabel *label;

- (void)changeSortStatusWithType:(XXTEDbTableColumnHeaderSortType)type;

@end

