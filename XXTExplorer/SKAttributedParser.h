//
//  SKAttributedParser.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKParser.h"
#import "SKTheme.h"

typedef void (^SKAttributedCallback)(NSString *scope, NSRange range, SKAttributes attributes);

@interface SKAttributedParser : SKParser

@property (nonatomic, strong, readonly) SKTheme *theme;
- (instancetype)initWithLanguage:(SKLanguage *)language theme:(SKTheme *)theme;
- (void)parseString:(NSString *)string matchCallback:(SKAttributedCallback)callback;
- (NSAttributedString *)parseString:(NSString *)string baseAttributes:(SKAttributes)baseAttributes;

@end
