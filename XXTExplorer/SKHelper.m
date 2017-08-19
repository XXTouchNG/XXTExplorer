//
//  SKHelper.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKHelper.h"
#import "SKHelperConfig.h"
#import "SKAttributedParser.h"
#import "SKBundleManager.h"

@interface SKHelper ()

@property (nonatomic, strong) SKLanguage *language;
@property (nonatomic, strong) SKTheme *theme;

@end

@implementation SKHelper

- (instancetype)initWithConfig:(SKHelperConfig *)config {
    self = [super init];
    if (self)
    {
        SKBundleManager *manager = [[SKBundleManager alloc] initWithCallback:^NSURL *(NSString *identifier, SKTextMateFileType kind) {
            NSArray <NSString *> *components = [identifier componentsSeparatedByString:@"."];
            NSURL *url = nil;
            if (kind == SKTextMateFileTypeLanguage && components.count > 1) {
                url = [config.bundle URLForResource:components[1] withExtension:@"tmLanguage"];
            }
            else if (kind == SKTextMateFileTypeTheme) {
                url = [config.bundle URLForResource:identifier withExtension:@"tmTheme"];
            }
            return url ? url : [NSURL fileURLWithPath:@""];
        }];
        _language = [manager languageWithIdentifier:config.languageIdentifier];
        _theme = [manager themeWithIdentifier:config.themeIdentifier font:config.font];
    }
    return self;
}

- (SKAttributedParser *)attributedParser {
    return [[SKAttributedParser alloc] initWithLanguage:self.language theme:self.theme];
}


@end
