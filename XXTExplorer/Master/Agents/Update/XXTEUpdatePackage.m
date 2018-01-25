//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEUpdatePackage.h"

@implementation XXTEUpdatePackage

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:
            @{@"latestVersion": @"latest",
              @"updateDescription": @"description",
              @"downloadURLString": @"url",
              @"downloadPath": @"path",
              @"cydiaURL": @"cydia-url",
              }];
}

@end
