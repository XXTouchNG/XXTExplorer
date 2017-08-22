//
//  XXTPickerTask.h
//  XXTPickerCollection
//
//  Created by Zheng on 29/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXTPickerTask : NSObject <NSCopying, NSMutableCopying, NSCoding>
@property (nonatomic, assign) NSUInteger currentStep;
@property (nonatomic, assign) NSUInteger totalStep;
@property (nonatomic, copy) NSString *udid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *code;

+ (instancetype)taskWithTitle:(NSString *)title code:(NSString *)code;
+ (instancetype)taskWithTitle:(NSString *)title code:(NSString *)code udid:(NSString *)udid;
- (Class)nextStepClass;
- (void)nextStep;
- (BOOL)taskFinished;
- (float)currentProgress;

@end
