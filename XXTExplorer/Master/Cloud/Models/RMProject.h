//
//  RMProject.h
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMModel.h"
#import "RMHandler.h"

static RMApiAction const RMApiActionFindScript = @"FindScript";
typedef enum : NSUInteger {
    RMApiActionSortByCreatedAtDesc = 1,
    RMApiActionSortByDownloadTimesDesc = 2,
    RMApiActionSortByRatingDesc = 3,
} RMApiActionSortBy;

@interface RMProject : RMModel

@property (nonatomic, assign) NSUInteger projectID;
@property (nonatomic, copy) NSString *projectName;
@property (nonatomic, copy) NSString *projectLogo;
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, assign) float projectVersion;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, assign) NSUInteger deviceCount;
@property (nonatomic, assign) float averageRating;
@property (nonatomic, assign) NSUInteger downloadTimes;
@property (nonatomic, copy) NSString *projectRemark;
@property (nonatomic, assign) NSUInteger trailType;
@property (nonatomic, copy) NSString *contactString;
@property (nonatomic, copy) NSString *localizedTrailDescription;

// NSArray <RMProject *> *models
+ (PMKPromise *)sortedList:(RMApiActionSortBy)sortBy atPage:(NSUInteger)idx itemsPerPage:(NSUInteger)ipp;
+ (PMKPromise *)filteredListWithKeyword:(NSString *)kw atPage:(NSUInteger)idx itemsPerPage:(NSUInteger)ipp;

// RMProject *model
+ (PMKPromise *)projectWithID:(NSUInteger)projectID;

// NSString *downloadURL
- (PMKPromise *)downloadURL;

@end
