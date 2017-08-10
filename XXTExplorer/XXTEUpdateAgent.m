//
//  XXTEUpdateAgent.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEUpdateAgent.h"

#import "XXTEAppDefines.h"
#import <sys/stat.h>

static NSString * const XXTEUpdateAgentIgnoreVersionPrefix = @"Version %@"; // +versionString
static NSString * const XXTEUpdateAgentIgnoreDatePrefix = @"Date %@"; // +dateString

@interface XXTEUpdateAgent ()

@property (nonatomic, strong, readonly) NSString *configPath;
@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@end

@implementation XXTEUpdateAgent

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier {
    if (self = [super init]) {
        _bundleIdentifier = bundleIdentifier;
        NSString *temporarilyLocation = [[[sharedDelegate() sharedRootPath] stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"_XXTEUpdateAgent"];
        struct stat temporarilyLocationStat;
        if (0 != lstat([temporarilyLocation UTF8String], &temporarilyLocationStat))
            if (0 != mkdir([temporarilyLocation UTF8String], 0755))
                NSLog(@"%@", [NSString stringWithFormat:@"Cannot create temporarily directory \"%@\".", temporarilyLocation]); // just log
        _configPath = [temporarilyLocation stringByAppendingPathComponent:@"update_ignore.plist"];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter = dateFormatter;
    }
    return self;
}

- (BOOL)shouldRemindWithVersion:(NSString *)version {
    NSMutableDictionary *ignoreConfigDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:self.configPath];
    if (!ignoreConfigDictionary) {
        ignoreConfigDictionary = [@{} mutableCopy];
    }
    NSString *ignKey1 = [NSString stringWithFormat:XXTEUpdateAgentIgnoreVersionPrefix, version];
    if (ignoreConfigDictionary[ignKey1]) {
        return NO;
    }
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *ignKey2 = [NSString stringWithFormat:XXTEUpdateAgentIgnoreDatePrefix, dateString];
    if (ignoreConfigDictionary[ignKey2]) {
        return NO;
    }
    return YES;
}

- (void)ignoreVersion:(NSString *)version {
    NSMutableDictionary *ignoreConfigDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:self.configPath];
    if (!ignoreConfigDictionary) {
        ignoreConfigDictionary = [@{} mutableCopy];
    }
    NSString *ignKey = [NSString stringWithFormat:XXTEUpdateAgentIgnoreVersionPrefix, version];
    ignoreConfigDictionary[ignKey] = @(YES);
    [ignoreConfigDictionary writeToFile:self.configPath atomically:YES];
}

- (void)ignoreThisDay {
    NSMutableDictionary *ignoreConfigDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:self.configPath];
    if (!ignoreConfigDictionary) {
        ignoreConfigDictionary = [@{} mutableCopy];
    }
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *ignKey = [NSString stringWithFormat:XXTEUpdateAgentIgnoreDatePrefix, dateString];
    ignoreConfigDictionary[ignKey] = @(YES);
    [ignoreConfigDictionary writeToFile:self.configPath atomically:YES];
}

@end
