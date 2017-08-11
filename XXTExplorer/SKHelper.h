//
//  SKHelper.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKHelper : NSObject

@property (nonatomic, strong, readonly) NSBundle *bundle;
- (instancetype)initWithBundle:(NSBundle *)bundle;
- (NSString *)fixtureWithName:(NSString *)name type:(NSString *)type;
- (SKLanguage *)languageWithName:(NSString *)name;
- (SKTheme *)themeWithName:(NSString *)name;
+ (NSAttributedString *)test:(NSString *)path;

@end
