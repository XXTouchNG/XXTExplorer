//
//  XXTETextEditorTheme.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTETextEditorTheme : NSObject

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *foregroundColor;
@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, strong) UIColor *caretColor;
@property (nonatomic, strong, readonly) NSString *identifier;
- (instancetype)initWithIdentifier:(NSString *)identifier;

@end
