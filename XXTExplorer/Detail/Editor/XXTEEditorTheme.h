//
//  XXTEEditorTheme.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKTheme;

@interface XXTEEditorTheme : NSObject

@property (nonatomic, strong, readonly) SKTheme *rawTheme;

@property (nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nonatomic, strong, readonly) UIColor *foregroundColor;
@property (nonatomic, strong, readonly) UIColor *selectionColor;
@property (nonatomic, strong, readonly) UIColor *invisibleColor;
@property (nonatomic, strong, readonly) UIColor *caretColor;

@property (nonatomic, strong, readonly) UIColor *barTintColor;
@property (nonatomic, strong, readonly) UIColor *barTextColor;

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) UIFont *font;

@property (nonatomic, assign) CGFloat tabWidth;

- (instancetype)initWithName:(NSString *)name baseFont:(UIFont *)font;
- (NSDictionary *)defaultAttributes;

@end
