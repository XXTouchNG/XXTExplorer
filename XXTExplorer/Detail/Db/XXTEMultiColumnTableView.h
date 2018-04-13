//
//  XXTEMultiColumnTableView.h
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEDbTableColumnHeader.h"

@class XXTEMultiColumnTableView;

@protocol XXTEMultiColumnTableViewDelegate <NSObject>

@required
- (void)multiColumnTableView:(XXTEMultiColumnTableView *)tableView didTapLabelWithText:(NSString *)text;
- (void)multiColumnTableView:(XXTEMultiColumnTableView *)tableView didTapHeaderWithText:(NSString *)text sortType:(XXTEDbTableColumnHeaderSortType)sortType;

@end

@protocol XXTEMultiColumnTableViewDataSource <NSObject>

@required

- (NSInteger)numberOfColumnsInTableView:(XXTEMultiColumnTableView *)tableView;
- (NSInteger)numberOfRowsInTableView:(XXTEMultiColumnTableView *)tableView;
- (NSString *)columnNameInColumn:(NSInteger)column;
- (NSString *)rowNameInRow:(NSInteger)row;
- (NSString *)contentAtColumn:(NSInteger)column row:(NSInteger)row;
- (NSArray *)contentAtRow:(NSInteger)row;

- (CGFloat)multiColumnTableView:(XXTEMultiColumnTableView *)tableView widthForContentCellInColumn:(NSInteger)column;
- (CGFloat)multiColumnTableView:(XXTEMultiColumnTableView *)tableView heightForContentCellInRow:(NSInteger)row;
- (CGFloat)heightForTopHeaderInTableView:(XXTEMultiColumnTableView *)tableView;
- (CGFloat)widthForLeftHeaderInTableView:(XXTEMultiColumnTableView *)tableView;

@end


@interface XXTEMultiColumnTableView : UIView

@property (nonatomic, weak) id<XXTEMultiColumnTableViewDataSource>dataSource;
@property (nonatomic, weak) id<XXTEMultiColumnTableViewDelegate>delegate;

- (void)reloadData;

@end
