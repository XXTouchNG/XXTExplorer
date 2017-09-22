//
//  SKAttributedRenderer.h
//  XXTExplorer
//
//  Created by Zheng on 13/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKParser.h"
#import "SKTheme.h"

@interface SKAttributedRenderer : SKParser

// MARK: - Properties

@property (nonatomic, strong, readonly) SKTheme *theme;

// MARK: - Initializers

- (instancetype)initWithLanguage:(SKLanguage *)language theme:(SKTheme *)theme;

// MARK: - Render

- (void)attributedRenderString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;

@end
