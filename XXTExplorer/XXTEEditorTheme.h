//
//  XXTEEditorTheme.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEEditorTheme : NSObject

@property (nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nonatomic, strong, readonly) UIColor *foregroundColor;
@property (nonatomic, strong, readonly) UIColor *selectionColor;
@property (nonatomic, strong, readonly) UIColor *invisibleColor;
@property (nonatomic, strong, readonly) UIColor *caretColor;
@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) UIFont *font;
- (instancetype)initWithIdentifier:(NSString *)identifier font:(UIFont *)font;
- (NSDictionary *)defaultAttributes;

@end
