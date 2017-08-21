//
//  SKHelper.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKHelperConfig;
@class SKAttributedParser;
@class SKLanguage;
@class SKTheme;

@interface SKHelper : NSObject

@property (nonatomic, strong, readonly) SKHelperConfig *config;
@property (nonatomic, strong, readonly) SKLanguage *language;
@property (nonatomic, strong, readonly) SKTheme *theme;

- (instancetype)initWithConfig:(SKHelperConfig *)config;
- (SKAttributedParser *)attributedParser;

@end
