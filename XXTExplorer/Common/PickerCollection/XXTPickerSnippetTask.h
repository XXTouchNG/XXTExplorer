//
//  XXTPickerSnippetTask.h
//  XXTExplorer
//
//  Created by Zheng on 2018/5/27.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXTBasePicker.h"


@class XXTPickerSnippet;

@interface XXTPickerSnippetTask : NSObject <NSCopying>

@property (nonatomic, strong, readonly) XXTPickerSnippet *snippet;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSnippet:(XXTPickerSnippet *)snippet;

- (UIViewController <XXTBasePicker> *)nextPicker;
- (id)generateWithError:(NSError **)error;

- (void)addResult:(id)result;
- (BOOL)taskFinished;
- (float)currentProgress;

- (NSUInteger)currentStep;
- (NSUInteger)totalStep;

- (NSArray *)getResults;

@end
