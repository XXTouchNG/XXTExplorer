//
//  XXTExplorerDefaults.h
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTExplorerDefaults_h
#define XXTExplorerDefaults_h

#pragma mark - Defaults

static NSString * const XXTExplorerViewInitialPath = @"XXTExplorerViewInitialPath";

static NSString * const XXTExplorerViewSectionHomeEnabledKey = @"XXTExplorerViewSectionHomeEnabledKey";
static NSString * const XXTExplorerViewSectionHomeSeriesKey = @"XXTExplorerViewSectionHomeSeriesKey";
static NSString * const XXTExplorerViewEntryListSortFieldKey = @"XXTExplorerViewEntryListSortFieldKey";
static NSString * const XXTExplorerViewEntryListSortOrderKey = @"XXTExplorerViewEntryListSortOrderKey";
static NSString * const XXTExplorerViewEntryListHideDotItemKey = @"XXTExplorerViewEntryListHideDotItemKey";

// XXTExplorerViewEntryListSortOrderKey
typedef enum : NSUInteger {
    XXTExplorerViewEntryListSortOrderAsc = 0,
    XXTExplorerViewEntryListSortOrderDesc,
} XXTExplorerViewEntryListSortOrder;

#pragma mark - Attributes

// XXTExplorerViewEntryAttribute
static NSString * const XXTExplorerViewEntryAttributeIconImage = @"XXTExplorerViewEntryAttributeIconImage";
static NSString * const XXTExplorerViewEntryAttributeDisplayName = @"XXTExplorerViewEntryAttributeDisplayName";
static NSString * const XXTExplorerViewEntryAttributeName = @"XXTExplorerViewEntryAttributeName";
static NSString * const XXTExplorerViewEntryAttributePath = @"XXTExplorerViewEntryAttributePath";
static NSString * const XXTExplorerViewEntryAttributeExtension = @"XXTExplorerViewEntryAttributeExtension";
//static NSString * const XXTExplorerViewEntryAttributeRealPath = @"XXTExplorerViewEntryAttributeRealPath";
static NSString * const XXTExplorerViewEntryAttributeType = @"XXTExplorerViewEntryAttributeType";
static NSString * const XXTExplorerViewEntryAttributeMaskType = @"XXTExplorerViewEntryAttributeMaskType";
static NSString * const XXTExplorerViewEntryAttributeCreationDate = @"XXTExplorerViewEntryAttributeCreationDate";
static NSString * const XXTExplorerViewEntryAttributeModificationDate = @"XXTExplorerViewEntryAttributeModificationDate";
static NSString * const XXTExplorerViewEntryAttributeSize = @"XXTExplorerViewEntryAttributeSize";
static NSString * const XXTExplorerViewEntryAttributePermission = @"XXTExplorerViewEntryAttributePermission"; // Dictionary

// XXTExplorerViewEntryAttributeType
static NSString * const XXTExplorerViewEntryAttributeTypeUnsupported = @"XXTExplorerViewEntryAttributeTypeUnsupported";
static NSString * const XXTExplorerViewEntryAttributeTypeRegular = @"XXTExplorerViewEntryAttributeTypeRegular";
static NSString * const XXTExplorerViewEntryAttributeTypeDirectory = @"XXTExplorerViewEntryAttributeTypeDirectory";
static NSString * const XXTExplorerViewEntryAttributeTypeBundle = @"XXTExplorerViewEntryAttributeTypeBundle";
static NSString * const XXTExplorerViewEntryAttributeTypeSymlink = @"XXTExplorerViewEntryAttributeTypeSymlink";

// XXTExplorerViewSectionHomeSeries
static NSString * const XXTExplorerViewSectionHomeSeriesDetailTitleKey = @"XXTExplorerViewSectionHomeSeriesDetailTitleKey";
static NSString * const XXTExplorerViewSectionHomeSeriesDetailSubtitleKey = @"XXTExplorerViewSectionHomeSeriesDetailSubtitleKey";
static NSString * const XXTExplorerViewSectionHomeSeriesDetailIconKey = @"XXTExplorerViewSectionHomeSeriesDetailIconKey";
static NSString * const XXTExplorerViewSectionHomeSeriesDetailPathKey = @"XXTExplorerViewSectionHomeSeriesDetailPathKey";

static NSString * const XXTExplorerViewEntryAttributePermissionViewable = @"XXTExplorerViewEntryAttributePermissionViewable";
static NSString * const XXTExplorerViewEntryAttributePermissionEditable = @"XXTExplorerViewEntryAttributePermissionEditable";
static NSString * const XXTExplorerViewEntryAttributePermissionExecuteable = @"XXTExplorerViewEntryAttributePermissionExecuteable";

#pragma mark - Notifications

#endif /* XXTExplorerDefaults_h */
