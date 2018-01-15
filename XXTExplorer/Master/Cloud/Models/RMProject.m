//
//  RMProject.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMProject.h"

@implementation RMProject

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"projectID": @"ProjectID",
                                                                  @"projectName": @"ProjectName",
                                                                  @"projectLogo": @"ProjectLogo",
                                                                  @"authorName": @"Author",
                                                                  @"projectVersion": @"Version",
                                                                  @"createdAt": @"CreateDate",
                                                                  @"deviceCount": @"Devices",
                                                                  @"averageRating": @"AvgScore",
                                                                  @"downloadTimes": @"Download",
                                                                  @"projectRemark": @"Remark",
                                                                  @"trailType": @"TrailType",
                                                                  @"contactString": @"Contact",
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    NSArray <NSString *> *optionalProperty =
  @[
    @"authorName",
    @"projectLogo",
    @"deviceCount",
    @"averageRating",
    @"downloadTimes",
    @"projectRemark",
    @"trailType",
    @"contactString",
    ];
    if ([optionalProperty containsObject:propertyName])
        return YES;
    return NO;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName
{
    NSArray <NSString *> *ignoredProperty =
    @[
      @"localizedTrailDescription",
      ];
    if ([ignoredProperty containsObject:propertyName])
        return YES;
    return NO;
}

+ (PMKPromise *)sortedList:(RMApiActionSortBy)sortBy atPage:(NSUInteger)idx itemsPerPage:(NSUInteger)ipp {
    NSDictionary *args =
    @{ @"sort": [NSString stringWithFormat:@"%lu", sortBy],
       @"pindex": [NSString stringWithFormat:@"%lu", idx],
       @"pagesize": [NSString stringWithFormat:@"%lu", ipp],
       };
    return [self promiseGETRequest:RMApiUrl(@"FindScript", args)];
}

+ (PMKPromise *)filteredListWithKeyword:(NSString *)kw atPage:(NSUInteger)idx itemsPerPage:(NSUInteger)ipp
{
    if (!kw) return nil;
    NSDictionary *args =
    @{ @"sort": @"1",
       @"pindex": [NSString stringWithFormat:@"%lu", idx],
       @"pagesize": [NSString stringWithFormat:@"%lu", ipp],
       @"fit": @"0.3",
       @"word": kw,
     };
    return [self promiseGETRequest:RMApiUrl(@"FindScript", args)];
}

+ (PMKPromise *)projectWithID:(NSUInteger)projectID {
    if (!projectID) return nil;
    NSDictionary *args =
    @{ @"projectid": [NSString stringWithFormat:@"%lu", projectID],
       };
    return [self promiseGETRequest:RMApiUrl(@"ScriptDetails", args)];
}

- (NSString *)localizedTrailDescription {
    if (self.trailType == 0) {
        return NSLocalizedString(@"No", nil);
    } else {
        return NSLocalizedString(@"Yes", nil);
    }
}

@end
