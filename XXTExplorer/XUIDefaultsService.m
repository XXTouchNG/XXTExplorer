//
//  XUIDefaultsService.m
//  XXTExplorer
//
//  Created by Zheng on 02/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIDefaultsService.h"
#import "XUIBaseCell.h"
#import "XXTEAppDefines.h"

@interface XUIDefaultsService ()

@property (nonatomic, strong, readonly) NSString *defaultsPath;

@end

@implementation XUIDefaultsService

- (instancetype)init {
    if (self = [super init]) {
        _defaultsPath = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:@"uicfg"];
    }
    return self;
}

- (void)saveDefaultsFromCell:(XUIBaseCell *)cell {
    NSString *specComponent = nil;
    if (!specComponent) specComponent = cell.xui_defaults;
    if (!specComponent) return;
    assert([specComponent isKindOfClass:[NSString class]] && specComponent.length > 0);
    NSString *specPath = [self.defaultsPath stringByAppendingPathComponent:specComponent];
    NSString *specPathExt = [specPath stringByAppendingPathExtension:@"plist"];
    NSMutableDictionary *specDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:specPathExt];
    if (!specDictionary) specDictionary = [[NSMutableDictionary alloc] init];
    NSString *specKey = cell.xui_key;
    if (!specKey) return;
    assert ([specKey isKindOfClass:[NSString class]] && specKey.length > 0);
    id specValue = cell.xui_value;
    if (!specValue) return;
    specDictionary[specKey] = specValue;
    [specDictionary writeToFile:specPathExt atomically:YES];
}

- (void)readDefaultsToCell:(XUIBaseCell *)cell {
    NSString *specComponent = nil;
    if (!specComponent) specComponent = cell.xui_defaults;
    if (!specComponent) return;
    assert([specComponent isKindOfClass:[NSString class]] && specComponent.length > 0);
    NSString *specPath = [self.defaultsPath stringByAppendingPathComponent:specComponent];
    NSString *specPathExt = [specPath stringByAppendingPathExtension:@"plist"];
    NSDictionary *specDictionary = [[NSDictionary alloc] initWithContentsOfFile:specPathExt];
    if (!specDictionary) specDictionary = [[NSDictionary alloc] init];
    NSString *specKey = cell.xui_key;
    if (!specKey) return;
    assert ([specKey isKindOfClass:[NSString class]] && specKey.length > 0);
    id specValue = specDictionary[specKey];
    id defaultValue = cell.xui_default;
    if (specValue) {
        cell.xui_value = specValue;
    }
    else if (defaultValue) {
        cell.xui_value = defaultValue;
    }
}

@end
