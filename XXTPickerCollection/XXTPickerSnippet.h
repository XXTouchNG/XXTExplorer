//
//  XXTPickerSnippet.h
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXTPickerSnippet : NSObject <NSCoding, NSCopying, NSMutableCopying>

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray <NSString *> *flags;

- (instancetype)initWithContentsOfFile:(NSString *)path;
- (NSString *)generateWithError:(NSError **)error;

- (void)addResult:(id)result;
- (Class)nextStepClass;
- (BOOL)taskFinished;
- (float)currentProgress;

- (NSUInteger)currentStep;
- (NSUInteger)totalStep;

@end
