//
//  RMProject.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMProject.h"

@implementation RMProjectDownloadModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"url": @"url",
                                                                  @"path": @"path"
                                                                  }];
}

@end

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
                                                                  @"trialType": @"TrialType",
                                                                  @"contactString": @"Contact",
                                                                  @"applicationID": @"AppID",
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
    @"trialType",
    @"contactString",
    @"applicationID",
    ];
    if ([optionalProperty containsObject:propertyName])
        return YES;
    return NO;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName
{
    NSArray <NSString *> *ignoredProperty =
    @[
      @"localizedTrialDescription",
      @"createdAtNSDate",
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
    return [self promiseGETRequest:RMApiUrl(RMApiActionFindScript, args)];
}

+ (PMKPromise *)filteredListWithKeyword:(NSString *)kw atPage:(NSUInteger)idx itemsPerPage:(NSUInteger)ipp
{
    if (!kw) return nil;
    NSDictionary *args =
    @{ @"sort": @"1",
       @"pindex": [NSString stringWithFormat:@"%lu", idx],
       @"pagesize": [NSString stringWithFormat:@"%lu", ipp],
       @"fit": @"0.5",
       @"word": kw,
     };
    return [self promiseGETRequest:RMApiUrl(RMApiActionFindScript, args)];
}

+ (PMKPromise *)projectWithID:(NSUInteger)projectID {
    if (!projectID) return nil;
    NSDictionary *args =
    @{ @"projectid": [NSString stringWithFormat:@"%lu", projectID],
       };
    return [self promiseGETRequest:RMApiUrl(RMApiActionScriptDetails, args)];
}

- (PMKPromise *)downloadURL {
    NSUInteger projectID = self.projectID;
    if (!projectID) return nil;
    NSDictionary *args =
    @{ @"projectid": [NSString stringWithFormat:@"%lu", projectID],
       };
    return [[RMProjectDownloadModel class] promiseGETRequest:RMApiUrl(RMApiActionGetScriptUrl, args)];
}

- (NSString *)localizedTrialDescription {
    if (self.trialType == 0) {
        return NSLocalizedString(@"No", nil);
    } else {
        return NSLocalizedString(@"Yes", nil);
    }
}

+ (NSDateFormatter *)sharedFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[NSLocale localeWithLocaleIdentifier:XXTE_STANDARD_LOCALE]];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
        }
    });
    return formatter;
}

- (NSDate *)createdAtNSDate {
    if (!self.createdAt) {
        return nil;
    }
    return [[[self class] sharedFormatter] dateFromString:self.createdAt];
}

@end
