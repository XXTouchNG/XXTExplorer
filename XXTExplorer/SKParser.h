//
//  SKParser.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKLanguage;

typedef void (^SKCallback)(NSString *scope, NSRange range);

@interface SKParser : NSObject

@property (nonatomic, strong, readonly) SKLanguage *language;
- (instancetype)initWithLanguage:(SKLanguage *)language;
- (void)parseString:(NSString *)string matchCallback:(SKCallback)callback;

@end
