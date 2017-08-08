//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEAPTPackage.h"


@implementation XXTEAPTPackage {

}
+ (XXTEAPTPackage *)packageWithDictionary:(NSDictionary *)dictionary {
    return [[XXTEAPTPackage alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (![[self class] verifyDictionary:dictionary]) {
        return nil;
    }
    if (self = [super init]) {
        _apt_Package = dictionary[@"Package"];
        _apt_Version = dictionary[@"Version"];
        _apt_Architecture = dictionary[@"Architecture"];
        _apt_Filename = dictionary[@"Filename"];
        _apt_Size = dictionary[@"Size"];
        _apt_MD5sum = dictionary[@"MD5sum"];
        _apt_Name = dictionary[@"Name"];
    }
    return self;
}

+ (BOOL)verifyDictionary:(NSDictionary *)dictionary {
    if (!dictionary[@"Package"] || !dictionary[@"Version"] || !dictionary[@"Architecture"] ||
            !dictionary[@"Filename"] || !dictionary[@"Size"] || !dictionary[@"MD5sum"] ||
            !dictionary[@"Name"])
    {
        return NO;
    }
    return [dictionary[@"Architecture"] isEqualToString:@"iphoneos-arm"];
}

@end