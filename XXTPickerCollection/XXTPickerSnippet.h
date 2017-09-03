//
//  XXTPickerSnippet.h
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTBasePicker.h"

@interface XXTPickerSnippet : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray <NSDictionary *> *flags;

- (instancetype)initWithContentsOfFile:(NSString *)path;
- (NSString *)generateWithError:(NSError **)error;

- (void)addResult:(id)result;
- (UIViewController <XXTBasePicker> *)nextPicker;
- (BOOL)taskFinished;
- (float)currentProgress;

- (NSUInteger)currentStep;
- (NSUInteger)totalStep;

@end
