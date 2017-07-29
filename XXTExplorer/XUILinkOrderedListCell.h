//
//  XUILinkOrderedListCell.h
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIBaseCell.h"

@interface XUILinkOrderedListCell : XUIBaseCell

@property (nonatomic, strong) NSArray <NSString *> *xui_validTitles;
@property (nonatomic, strong) NSArray *xui_validValues;
@property (nonatomic, strong) NSString *xui_staticTextMessage;
@property (nonatomic, strong) NSNumber *xui_minCount;
@property (nonatomic, strong) NSNumber *xui_maxCount;

@end
