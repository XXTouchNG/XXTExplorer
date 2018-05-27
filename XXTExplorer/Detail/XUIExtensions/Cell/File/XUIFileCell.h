//
//  XUIFileCell.h
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIBaseCell.h"

static CGFloat const XUIFileCellHeight = 68.f;

@interface XUIFileCell : XUIBaseCell

@property (nonatomic, strong) NSNumber *xui_isFile;
@property (nonatomic, strong) NSString *xui_initialPath;
@property (nonatomic, strong) NSArray <NSString *> *xui_allowedExtensions;
@property (nonatomic, strong) NSString *xui_footerText;

@end
