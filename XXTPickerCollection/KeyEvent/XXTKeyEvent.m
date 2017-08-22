//
//  XXTKeyEvent.m
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTKeyEvent.h"

@implementation XXTKeyEvent

+ (instancetype)eventWithTitle:(NSString *)title command:(NSString *)command {
    XXTKeyEvent *newModel = [XXTKeyEvent new];
    newModel.title = title;
    newModel.command = command;
    return newModel;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _title = [aDecoder decodeObjectForKey:@"title"];
        _command = [aDecoder decodeObjectForKey:@"command"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.command forKey:@"command"];
}

#pragma mark - Copy

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    XXTKeyEvent *copy = (XXTKeyEvent *) [[[self class] allocWithZone:zone] init];
    copy.title = [self.title copyWithZone:zone];
    copy.command = [self.command copyWithZone:zone];
    return copy;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    XXTKeyEvent *copy = (XXTKeyEvent *) [[[self class] allocWithZone:zone] init];
    copy.title = [self.title mutableCopyWithZone:zone];
    copy.command = [self.command mutableCopyWithZone:zone];
    return copy;
}

@end
