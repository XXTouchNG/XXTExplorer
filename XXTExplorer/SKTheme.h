//
//  SKTheme.h
//  XXTExplorer
//
//  Represents a TextMate theme file (.tmTheme). Currently only supports the
//  foreground text color attribute on a local scope.
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NSDictionary <NSString *, id> * SKAttributes;

@interface SKTheme : NSObject

// MARK: - Properties
@property (nonatomic, strong, readonly) NSUUID *uuid;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, SKAttributes> *attributes;

// MARK: - Global Scope
@property (nonatomic, strong, readonly, getter=getBackgroundColor) UIColor *backgroundColor;
@property (nonatomic, strong, readonly, getter=getForegroundColor) UIColor *foregroundColor;
@property (nonatomic, strong, readonly, getter=getCaretColor) UIColor *caretColor;
@property (nonatomic, strong, readonly, getter=getSelectionColor) UIColor *selectionColor;

// MARK: - Initializers
- (instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dictionary font:(UIFont *)font;

@end
