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

static NSString * const XXTExplorerViewSectionHomeEnabledKey = @"XXTExplorerViewSectionHomeEnabledKey";
static NSString * const XXTExplorerViewEntryListSortFieldKey = @"XXTExplorerViewEntryListSortFieldKey";
static NSString * const XXTExplorerViewEntryListSortOrderKey = @"XXTExplorerViewEntryListSortOrderKey";
static NSString * const XXTExplorerViewEntryListHideDotItemKey = @"XXTExplorerViewEntryListHideDotItemKey";

// XXTExplorerViewEntryListSortOrderKey
typedef enum : NSUInteger {
    XXTExplorerViewEntryListSortOrderAsc = 0,
    XXTExplorerViewEntryListSortOrderDesc,
} XXTExplorerViewEntryListSortOrder;

// XXTExplorerViewEntryListSortFieldKey
static NSString * const XXTExplorerViewEntryListSortFieldName = @"XXTExplorerViewEntryListSortFieldName";
static NSString * const XXTExplorerViewEntryListSortFieldKind = @"XXTExplorerViewEntryListSortFieldKind";
static NSString * const XXTExplorerViewEntryListSortFieldDateModified = @"XXTExplorerViewEntryListSortFieldDateModified";
static NSString * const XXTExplorerViewEntryListSortFieldDateCreated = @"XXTExplorerViewEntryListSortFieldDateCreated";
static NSString * const XXTExplorerViewEntryListSortFieldSize = @"XXTExplorerViewEntryListSortFieldSize";

#pragma mark - Attributes

// XXTExplorerViewEntryAttribute
static NSString * const XXTExplorerViewEntryAttributeDisplayName = @"XXTExplorerViewEntryAttributeDisplayName";
static NSString * const XXTExplorerViewEntryAttributeName = @"XXTExplorerViewEntryAttributeName";
static NSString * const XXTExplorerViewEntryAttributePath = @"XXTExplorerViewEntryAttributePath";
static NSString * const XXTExplorerViewEntryAttributeRealPath = @"XXTExplorerViewEntryAttributeRealPath";
static NSString * const XXTExplorerViewEntryAttributeType = @"XXTExplorerViewEntryAttributeType";
static NSString * const XXTExplorerViewEntryAttributeRealType = @"XXTExplorerViewEntryAttributeRealType";
static NSString * const XXTExplorerViewEntryAttributeCreationDate = @"XXTExplorerViewEntryAttributeCreationDate";
static NSString * const XXTExplorerViewEntryAttributeModificationDate = @"XXTExplorerViewEntryAttributeModificationDate";
static NSString * const XXTExplorerViewEntryAttributeSize = @"XXTExplorerViewEntryAttributeSize";

// XXTExplorerViewEntryAttributeType
static NSString * const XXTExplorerViewEntryAttributeTypeUnsupported = @"XXTExplorerViewEntryAttributeTypeUnsupported";
static NSString * const XXTExplorerViewEntryAttributeTypeRegular = @"XXTExplorerViewEntryAttributeTypeRegular";
static NSString * const XXTExplorerViewEntryAttributeTypeDirectory = @"XXTExplorerViewEntryAttributeTypeDirectory";
static NSString * const XXTExplorerViewEntryAttributeTypeBundle = @"XXTExplorerViewEntryAttributeTypeBundle";
static NSString * const XXTExplorerViewEntryAttributeTypeSymlink = @"XXTExplorerViewEntryAttributeTypeSymlink";

#endif /* XXTExplorerDefaults_h */
