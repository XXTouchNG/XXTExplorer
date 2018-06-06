//
//  XXTEDbTableContentViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEDbTableContentViewController.h"
#import "XXTEMultiColumnTableView.h"
#import "XXTEBaseObjectViewController.h"

@interface XXTEDbTableContentViewController () <XXTEMultiColumnTableViewDataSource, XXTEMultiColumnTableViewDelegate>

@property (nonatomic, strong) XXTEMultiColumnTableView *multiColumView;

@end

@implementation XXTEDbTableContentViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.multiColumView];
    if (@available(iOS 8.0, *)) {
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTopMargin multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          ];
        [self.view addConstraints:constraints];
    } else {
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.multiColumView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          ];
        [self.view addConstraints:constraints];
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.multiColumView reloadData];
}

#pragma mark -
#pragma mark UIView Getters

- (XXTEMultiColumnTableView *)multiColumView {
    if (!_multiColumView) {
        _multiColumView = [[XXTEMultiColumnTableView alloc] initWithFrame:self.view.bounds];
        _multiColumView.translatesAutoresizingMaskIntoConstraints = NO;
        _multiColumView.backgroundColor = [UIColor whiteColor];
        _multiColumView.dataSource = self;
        _multiColumView.delegate = self;
    }
    return _multiColumView;
}

#pragma mark -
#pragma mark MultiColumnTableView DataSource

- (NSInteger)numberOfColumnsInTableView:(XXTEMultiColumnTableView *)tableView
{
    return self.columnsArray.count;
}
- (NSInteger)numberOfRowsInTableView:(XXTEMultiColumnTableView *)tableView
{
    return self.contentsArray.count;
}


- (NSString *)columnNameInColumn:(NSInteger)column
{
    return self.columnsArray[column];
}


- (NSString *)rowNameInRow:(NSInteger)row
{
    return [NSString stringWithFormat:@"%ld",(long)row];
}

- (NSString *)contentAtColumn:(NSInteger)column row:(NSInteger)row
{
    if (self.contentsArray.count > row) {
        NSDictionary<NSString *, id> *dic = self.contentsArray[row];
        if (self.contentsArray.count > column) {
            return [NSString stringWithFormat:@"%@",[dic objectForKey:self.columnsArray[column]]];
        }
    }
    return @"";
}

- (NSArray *)contentAtRow:(NSInteger)row
{
    NSMutableArray *result = [NSMutableArray array];
    if (self.contentsArray.count > row) {
        NSDictionary<NSString *, id> *dic = self.contentsArray[row];
        for (int i = 0; i < self.columnsArray.count; i ++) {
            [result addObject:dic[self.columnsArray[i]]];
        }
        return result;
    }
    return nil;
}

- (CGFloat)multiColumnTableView:(XXTEMultiColumnTableView *)tableView
      heightForContentCellInRow:(NSInteger)row
{
    return 36.0;
}

- (CGFloat)multiColumnTableView:(XXTEMultiColumnTableView *)tableView
    widthForContentCellInColumn:(NSInteger)column
{
    return 120.0;
}

- (CGFloat)heightForTopHeaderInTableView:(XXTEMultiColumnTableView *)tableView
{
    return 36.0;
}

- (CGFloat)widthForLeftHeaderInTableView:(XXTEMultiColumnTableView *)tableView
{
    NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long)self.contentsArray.count];
    NSDictionary <NSString *, id> *attrs = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0]};
    CGSize size = [str boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 14)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:attrs context:nil].size;
    return size.width + 20;
}

#pragma mark -
#pragma mark MultiColumnTableView Delegate


- (void)multiColumnTableView:(XXTEMultiColumnTableView *)tableView didTapLabelWithText:(NSString *)text
{
    XXTEBaseObjectViewController *objectController = [[XXTEBaseObjectViewController alloc] initWithRootObject:text];
    objectController.title = NSLocalizedString(@"Value", nil);
    [self.navigationController pushViewController:objectController animated:YES];
}

- (void)multiColumnTableView:(XXTEMultiColumnTableView *)tableView didTapHeaderWithText:(NSString *)text sortType:(XXTEDbTableColumnHeaderSortType)sortType
{
    
    NSArray<NSDictionary<NSString *, id> *> *sortContentData = [self.contentsArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary<NSString *, id> * obj1, NSDictionary<NSString *, id> * obj2) {
        
        if ([obj1 objectForKey:text] == [NSNull null]) {
            return NSOrderedAscending;
        }
        if ([obj2 objectForKey:text] == [NSNull null]) {
            return NSOrderedDescending;
        }
        
        if (![[obj1 objectForKey:text] respondsToSelector:@selector(compare:)] && ![[obj2 objectForKey:text] respondsToSelector:@selector(compare:)]) {
            return NSOrderedSame;
        }
        
        NSComparisonResult result =  [[obj1 objectForKey:text] compare:[obj2 objectForKey:text]];
        
        return result;
    }];
    if (sortType == XXTEDbTableColumnHeaderSortTypeDesc) {
        NSEnumerator *contentReverseEvumerator = [sortContentData reverseObjectEnumerator];
        sortContentData = [NSArray arrayWithArray:[contentReverseEvumerator allObjects]];
    }
    
    self.contentsArray = sortContentData;
    [self.multiColumView reloadData];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEDbTableContentViewController dealloc]");
#endif
}


@end
