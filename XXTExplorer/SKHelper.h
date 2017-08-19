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

@interface SKHelper : NSObject

- (instancetype)initWithConfig:(SKHelperConfig *)config;
- (SKAttributedParser *)attributedParser;

@end
