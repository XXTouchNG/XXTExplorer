//
//  XXTPickerTask.m
//  XXTPickerCollection
//
//  Created by Zheng on 29/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerTask.h"
#import "XXTLocationPicker.h"
#import "XXTKeyEventPicker.h"
#import "XXTRectanglePicker.h"
#import "XXTPositionPicker.h"
#import "XXTColorPicker.h"
#import "XXTPositionColorPicker.h"
#import "XXTMultiplePositionColorPicker.h"
#import "XXTApplicationPicker.h"
#import "XXTMultipleApplicationPicker.h"

@implementation XXTPickerTask

+ (NSArray <Class> *)pickers {
    // Register Picker Here
    NSArray <Class> *availablePickers =
            @[
            [XXTLocationPicker class], [XXTKeyEventPicker class], [XXTRectanglePicker class],
            [XXTPositionPicker class], [XXTColorPicker class], [XXTPositionColorPicker class],
            [XXTMultiplePositionColorPicker class], [XXTApplicationPicker class], [XXTMultipleApplicationPicker class]
            ];
    for (Class cls in availablePickers) {
        NSString *errorMessage = [NSString stringWithFormat:@"Class %@ type mismatch!", NSStringFromClass(cls)];
        NSAssert([cls isSubclassOfClass:[UIViewController class]], errorMessage);
    }
    return availablePickers;
}

+ (instancetype)taskWithTitle:(NSString *)title code:(NSString *)code {
    return [self taskWithTitle:title code:code udid:nil];
}

+ (instancetype)taskWithTitle:(NSString *)title code:(NSString *)code udid:(NSString *)udid {
    
    XXTPickerTask *newModel = [XXTPickerTask new];
    newModel.title = [title mutableCopy];
    newModel.code = [code mutableCopy];
    newModel.udid = [udid mutableCopy];
    newModel.currentStep = 0;
    
    NSString *inputString = [code mutableCopy];
    
    NSUInteger keywordCount = 0;
    
    for (Class cls in [[self class] pickers]) {
        NSString *keyword = nil;
        if ([cls respondsToSelector:@selector(pickerKeyword)]) {
            keyword = [cls performSelector:@selector(pickerKeyword)];
        }
        if (([inputString rangeOfString:keyword].location) != NSNotFound) {
            const char *substr = [keyword cStringUsingEncoding:NSUTF8StringEncoding];
            const char *selfstr = [inputString cStringUsingEncoding:NSUTF8StringEncoding];
            unsigned long substrlen = strlen(substr);
            NSUInteger count = 0;
            char * ptr = (char *)selfstr;
            while ((ptr = strstr(ptr, substr)) != NULL && substr != '\0') {
                count++;
                ptr += substrlen;
            }
            keywordCount += count;
        }
    }
    
    newModel.totalStep = keywordCount;
    return newModel;
}

- (NSString *)udid {
    if (!_udid) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        _udid = (__bridge_transfer NSString *)string;
    }
    return _udid;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _udid = [aDecoder decodeObjectForKey:@"udid"];
        _title = [aDecoder decodeObjectForKey:@"title"];
        _code = [aDecoder decodeObjectForKey:@"code"];
        _currentStep = [[aDecoder decodeObjectForKey:@"currentStep"] unsignedIntegerValue];
        _totalStep = [[aDecoder decodeObjectForKey:@"totalStep"] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.udid forKey:@"udid"];
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.code forKey:@"code"];
    [aCoder encodeObject:@(self.currentStep) forKey:@"currentStep"];
    [aCoder encodeObject:@(self.totalStep) forKey:@"totalStep"];
}

#pragma mark - Copy

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    XXTPickerTask *copy = (XXTPickerTask *) [[[self class] allocWithZone:zone] init];
    copy.udid = [self.udid copyWithZone:zone];
    copy.title = [self.title copyWithZone:zone];
    copy.code = [self.code copyWithZone:zone];
    copy.currentStep = self.currentStep;
    copy.totalStep = self.totalStep;
    return copy;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    XXTPickerTask *copy = (XXTPickerTask *) [[[self class] allocWithZone:zone] init];
    copy.udid = [self.udid mutableCopyWithZone:zone];
    copy.title = [self.title mutableCopyWithZone:zone];
    copy.code = [self.code mutableCopyWithZone:zone];
    copy.currentStep = self.currentStep;
    copy.totalStep = self.totalStep;
    return copy;
}

#pragma mark - Next step generator

- (Class)nextStepClass {
    NSString *inputString = self.code;
    
    NSUInteger location = 0;
    NSUInteger oldLocation = NSNotFound;
    
    Class pickerClass;
    
    for (Class cls in [[self class] pickers]) {
        NSString *keyword = nil;
        if ([cls respondsToSelector:@selector(pickerKeyword)]) {
            keyword = [cls performSelector:@selector(pickerKeyword)];
        }
        if ((location = [inputString rangeOfString:keyword].location) != NSNotFound) {
            if (location <= oldLocation) {
                oldLocation = location;
                pickerClass = cls;
            }
        }
    }
    
    return pickerClass;
}

- (void)nextStep {
    self.currentStep++;
}

- (BOOL)taskFinished {
    return (self.currentStep >= self.totalStep);
}

- (float)currentProgress {
    return (float)self.currentStep / self.totalStep;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTPickerTask dealloc]");
#endif
}

@end
