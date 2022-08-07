//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEUpdatePackage.h"

@implementation XXTEUpdatePackage

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:
            @{
        
        @"latestVersion": @"version_string",
        @"updateDescription": @"version_description",
        @"cydiaURLString": @"cydia_url",
        
        @"templateURLString": @"template_url",
        @"aptURLString": @"apt_url",
        @"packageID": @"package_id",
        
        @"downloadURLString": @"download_url",
        @"downloadPath": @"download_path",
        @"downloadSHA256": @"version_checksum",
        
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    NSArray <NSString *> *optionalKeys =
    @[
        @"cydiaURLString",
        
        @"templateURLString",
        @"aptURLString",
        @"packageID",
        
        @"downloadURLString",
        @"downloadPath",
        @"downloadSHA256",
    ];
    if ([optionalKeys containsObject:propertyName]) {
        return YES;
    }
    return NO;
}

@end
