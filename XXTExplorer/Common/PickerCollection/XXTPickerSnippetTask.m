//
//  XXTPickerSnippetTask.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/27.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTPickerSnippetTask.h"
#import "XXTPickerSnippet.h"

#import "XXTLocationPicker.h"
#import "XXTKeyEventPicker.h"
#import "XXTRectanglePicker.h"
#import "XXTPositionPicker.h"
#import "XXTColorPicker.h"
#import "XXTPositionColorPicker.h"
#import "XXTMultiplePositionColorPicker.h"
#import "XXTApplicationPicker.h"
#import "XXTMultipleApplicationPicker.h"

@interface XXTPickerSnippetTask ()

@property (nonatomic, strong) NSMutableArray *results;

@end

@implementation XXTPickerSnippetTask

+ (NSArray <Class> *)pickers {
    // Register Picker Here
    NSArray <Class> *availablePickers =
    @[
      [XXTLocationPicker class],
      [XXTKeyEventPicker class],
      [XXTRectanglePicker class],
      [XXTPositionPicker class],
      [XXTColorPicker class],
      [XXTPositionColorPicker class],
      [XXTMultiplePositionColorPicker class],
#ifndef APPSTORE
      [XXTApplicationPicker class],
      [XXTMultipleApplicationPicker class],
#endif
      ];
    return availablePickers;
}

- (UIViewController <XXTBasePicker> *)nextPicker {
    NSUInteger nextFlagIndex = self.results.count;
    if (nextFlagIndex >= self.snippet.flags.count) return nil;
    
    NSDictionary *nextFlagDictionary = self.snippet.flags[nextFlagIndex];
    NSString *nextFlag = nextFlagDictionary[@"type"];
    
    Class pickerClass;
    for (Class cls in self.class.pickers) {
        NSString *keyword = nil;
        if ([cls respondsToSelector:@selector(pickerKeyword)]) {
            keyword = [cls performSelector:@selector(pickerKeyword)];
        }
        if ([keyword isEqualToString:nextFlag]) {
            pickerClass = cls;
        }
    }
    
    UIViewController <XXTBasePicker> *picker = [[pickerClass alloc] init];
    picker.pickerMeta = nextFlagDictionary;
    
    return picker;
}

- (instancetype)initWithSnippet:(XXTPickerSnippet *)snippet {
    self = [super init];
    if (self) {
        _snippet = snippet;
        _results = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Generator

- (id)generateWithError:(NSError **)error {
    return [self.snippet generateWithResults:self.results Error:error];
}

- (void)addResult:(id)result {
    if (!result || self.results.count >= self.snippet.flags.count) return;
    [self.results addObject:result];
}

- (BOOL)taskFinished {
    return (self.results.count >= self.snippet.flags.count - 1);
}

- (float)currentProgress {
    return (float)self.results.count / self.snippet.flags.count;
}

- (NSUInteger)currentStep {
    return self.results.count + 1;
}

- (NSUInteger)totalStep {
    return self.snippet.flags.count;
}

#pragma mark - Getters

- (NSArray *)getResults {
    return [self.results copy];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    XXTPickerSnippetTask *newTask = [[XXTPickerSnippetTask allocWithZone:zone] initWithSnippet:self.snippet];
    newTask.results = [self.results mutableCopy];
    return newTask;
}

@end
