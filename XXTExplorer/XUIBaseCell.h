//
// Created by Zheng on 28/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XUIBaseCellReuseIdentifier = @"XUIBaseCellReuseIdentifier";

@interface XUIBaseCell : UITableViewCell

@property (nonatomic, strong) NSString *xui_cell;
@property (nonatomic, strong) NSString *xui_label;
@property (nonatomic, strong) NSString *xui_defaults;
@property (nonatomic, strong) NSString *xui_key;
@property (nonatomic, strong) id xui_default;
@property (nonatomic, strong) NSString *xui_icon;
@property (nonatomic, assign) NSNumber *xui_enabled;
@property (nonatomic, assign) NSNumber *xui_height;
// @property (nonatomic, strong) NSString *xui_detail;
@property (nonatomic, strong) id xui_value;

@property (nonatomic, strong) NSBundle *bundle;

+ (BOOL)xibBasedLayout;
+ (BOOL)layoutNeedsTextLabel;
+ (BOOL)layoutNeedsImageView;
+ (BOOL)layoutRequiresDynamicRowHeight;
+ (NSDictionary <NSString *, Class> *)entryValueTypes;
+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error;

- (void)setupCell; // init cell

@end
