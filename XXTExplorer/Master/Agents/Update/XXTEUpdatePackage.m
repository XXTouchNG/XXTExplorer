//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEUpdatePackage.h"

@implementation XXTEUpdatePackage

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:
            @{
              
              @"latestVersion": @"latest",
              @"updateDescription": @"description",
              @"cydiaURLString": @"cydia-url",
              
              @"templateURLString": @"template-url",
              @"aptURLString": @"apt-url",
              @"packageID": @"package-id",
              
              @"downloadURLString": @"url",
              @"downloadPath": @"path",
              @"downloadMD5": @"md5",
              @"downloadSHA1": @"sha1",
              @"downloadSHA256": @"sha256",
              @"downloadSHA512": @"sha512",
              
              }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    NSArray <NSString *> *optionalKeys =
  @[
    @"downloadURLString",
    @"downloadPath",
    @"downloadMD5",
    @"downloadSHA1",
    @"downloadSHA256",
    @"downloadSHA512",
    
    @"templateURLString",
    @"aptURLString",
    @"packageID",
    ];
    if ([optionalKeys containsObject:propertyName]) {
        return YES;
    }
    return NO;
}

@end
