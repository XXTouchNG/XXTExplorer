//
//  XUIAdapter.h
//  XXTExplorer
//
//  Created by Zheng on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XUIBaseCell;

@interface XUIAdapter : NSObject

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, strong, readonly) NSBundle *bundle;
- (instancetype)initWithXUIPath:(NSString *)path Bundle:(NSBundle *)bundle;

- (NSDictionary *)rootEntryWithError:(NSError **)error;

- (void)saveDefaultsFromCell:(XUIBaseCell *)cell;

- (id)objectForKey:(NSString *)key Defaults:(NSString *)identifier;
- (void)setObject:(id)obj forKey:(NSString *)key Defaults:(NSString *)identifier;

@end
