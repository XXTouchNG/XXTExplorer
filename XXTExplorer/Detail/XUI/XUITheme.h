//
//  XUITheme.h
//  XXTExplorer
//
//  Created by Zheng Wu on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XUITheme : NSObject

@property (nonatomic, strong, readonly) UIColor *tintColor;
@property (nonatomic, strong, readonly) UIColor *dangerColor;
@property (nonatomic, strong, readonly) UIColor *warningColor;
@property (nonatomic, strong, readonly) UIColor *successColor;
@property (nonatomic, strong, readonly) UIColor *highlightColor;

@property (nonatomic, strong, readonly) UIColor *navigationBarColor;
@property (nonatomic, strong, readonly) UIColor *navigationTitleColor;

@property (nonatomic, strong, readonly) UIColor *labelColor;
@property (nonatomic, strong, readonly) UIColor *valueColor;

@property (nonatomic, assign, readonly, getter=isDarkMode) BOOL darkMode;

- (instancetype)initWithDictionary:(NSDictionary *)themeDictionary;

@end
