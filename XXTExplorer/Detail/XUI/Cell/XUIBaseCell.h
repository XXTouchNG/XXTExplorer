//
// Created by Zheng on 28/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XUIAdapter.h"
#import "XUITheme.h"

@class XUIAdapter;

extern NSString * XUIBaseCellReuseIdentifier;

extern NSString * XUIOptionCellTitleKey;
extern NSString * XUIOptionCellShortTitleKey;
extern NSString * XUIOptionCellValueKey;
extern NSString * XUIOptionCellIconKey;

@interface XUIBaseCell : UITableViewCell

@property (nonatomic, strong) NSString *xui_cell;
@property (nonatomic, strong) NSString *xui_label;
@property (nonatomic, strong) NSString *xui_defaults;
@property (nonatomic, strong) NSString *xui_key;
@property (nonatomic, strong) id xui_default;
@property (nonatomic, strong) NSString *xui_icon;
@property (nonatomic, strong) NSNumber *xui_readonly;
@property (nonatomic, strong) NSNumber *xui_height;
@property (nonatomic, strong) id xui_value;
@property (nonatomic, strong) XUIAdapter *adapter;

@property (nonatomic, strong) XUITheme *theme;
@property (nonatomic, assign) BOOL canEdit;

+ (BOOL)xibBasedLayout;
+ (BOOL)layoutNeedsTextLabel;
+ (BOOL)layoutNeedsImageView;
+ (BOOL)layoutRequiresDynamicRowHeight;
+ (NSDictionary <NSString *, Class> *)entryValueTypes;
+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error;

- (void)setupCell; // init cell

@end
