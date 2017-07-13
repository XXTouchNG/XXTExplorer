//
//  XXTExplorerDefaults.h
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTExplorerDefaults_h
#define XXTExplorerDefaults_h

#pragma mark - Application Bundle

static NSString * const XXTExplorerDefaults = @"XXTExplorerDefaults";

#pragma mark - Defaults

//static NSUInteger const XXTExplorerMaximumEntryCount = 1000;

static NSString * const XXTExplorerViewInitialPath = @"XXTExplorerViewInitialPath";

static NSString * const XXTExplorerViewSectionHomeEnabledKey = @"XXTExplorerViewSectionHomeEnabledKey";
static NSString * const XXTExplorerViewSectionHomeSeriesKey = @"XXTExplorerViewSectionHomeSeriesKey";
static NSString * const XXTExplorerViewEntryListSortFieldKey = @"XXTExplorerViewEntryListSortFieldKey";
static NSString * const XXTExplorerViewEntryListSortOrderKey = @"XXTExplorerViewEntryListSortOrderKey";
static NSString * const XXTExplorerViewEntryListHideDotItemKey = @"XXTExplorerViewEntryListHideDotItemKey";
static NSString * const XXTExplorerViewSelectedScriptPathKey = @"XXTExplorerViewSelectedScriptPathKey";
static NSString * const XXTExplorerViewSelectLaunchedScriptKey = @"XXTExplorerViewSelectLaunchedScriptKey";

// XXTExplorerViewEntryListSortOrderKey
typedef enum : NSUInteger {
    XXTExplorerViewEntryListSortOrderAsc = 0,
    XXTExplorerViewEntryListSortOrderDesc,
} XXTExplorerViewEntryListSortOrder;

// XXTExplorerViewSectionHomeSeriesKey
static NSString * const XXTExplorerViewSectionHomeSeriesDetailTitleKey = @"XXTExplorerViewSectionHomeSeriesDetailTitleKey";
static NSString * const XXTExplorerViewSectionHomeSeriesDetailSubtitleKey = @"XXTExplorerViewSectionHomeSeriesDetailSubtitleKey";
static NSString * const XXTExplorerViewSectionHomeSeriesDetailIconKey = @"XXTExplorerViewSectionHomeSeriesDetailIconKey";
static NSString * const XXTExplorerViewSectionHomeSeriesDetailPathKey = @"XXTExplorerViewSectionHomeSeriesDetailPathKey";

#pragma mark - Attributes

// XXTExplorerViewEntryAttribute
static NSString * const XXTExplorerViewEntryAttributeIconImage = @"XXTExplorerViewEntryAttributeIconImage"; // UIImage
static NSString * const XXTExplorerViewEntryAttributeDisplayName = @"XXTExplorerViewEntryAttributeDisplayName"; // NSString - Name
static NSString * const XXTExplorerViewEntryAttributeName = @"XXTExplorerViewEntryAttributeName"; // NSString - Name
static NSString * const XXTExplorerViewEntryAttributePath = @"XXTExplorerViewEntryAttributePath"; // NSString - Full Path
static NSString * const XXTExplorerViewEntryAttributeExtension = @"XXTExplorerViewEntryAttributeExtension"; // NSString - Real Extension
static NSString * const XXTExplorerViewEntryAttributeInternalExtension = @"XXTExplorerViewEntryAttributeInternalExtension"; // NSString - Internal Type
static NSString * const XXTExplorerViewEntryAttributeType = @"XXTExplorerViewEntryAttributeType"; // NSString - Mask Type
static NSString * const XXTExplorerViewEntryAttributeMaskType = @"XXTExplorerViewEntryAttributeMaskType"; // NSString - Mask Type
static NSString * const XXTExplorerViewEntryAttributeCreationDate = @"XXTExplorerViewEntryAttributeCreationDate"; // NSDate
static NSString * const XXTExplorerViewEntryAttributeModificationDate = @"XXTExplorerViewEntryAttributeModificationDate"; // NSDate
static NSString * const XXTExplorerViewEntryAttributeSize = @"XXTExplorerViewEntryAttributeSize"; // NSNumber
static NSString * const XXTExplorerViewEntryAttributePermission = @"XXTExplorerViewEntryAttributePermission"; // Dictionary

static NSString * const XXTExplorerViewEntryAttributeDescription = @"XXTExplorerViewEntryAttributeDescription";
static NSString * const XXTExplorerViewEntryAttributeExtensionDescription = @"XXTExplorerViewEntryAttributeExtensionDescription"; // NSString - Description
static NSString * const XXTExplorerViewEntryAttributeViewerDescription = @"XXTExplorerViewEntryAttributeViewerDescription";
static NSString * const XXTExplorerViewEntryAttributeMetaKeys = @"XXTExplorerViewEntryAttributeMetaKeys";
static NSString * const XXTExplorerViewEntryAttributeMetaDictionary = @"XXTExplorerViewEntryAttributeMetaDictionary";

// XXTExplorerViewEntryAttributeType
static NSString * const XXTExplorerViewEntryAttributeTypeUnsupported = @"XXTExplorerViewEntryAttributeTypeUnsupported";
static NSString * const XXTExplorerViewEntryAttributeTypeRegular = @"XXTExplorerViewEntryAttributeTypeRegular";
static NSString * const XXTExplorerViewEntryAttributeTypeDirectory = @"XXTExplorerViewEntryAttributeTypeDirectory";
static NSString * const XXTExplorerViewEntryAttributeTypeSymlink = @"XXTExplorerViewEntryAttributeTypeSymlink";

static NSString * const XXTExplorerViewEntryAttributeMaskTypeBundle = @"XXTExplorerViewEntryAttributeMaskTypeBundle";
static NSString * const XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink = @"XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink";

// XXTExplorerViewEntryAttributeExtension
static NSString * const XXTExplorerViewEntryAttributeInternalExtensionExecutable = @"XXTExplorerViewEntryAttributeInternalExtensionExecutable";
static NSString * const XXTExplorerViewEntryAttributeInternalExtensionArchive = @"XXTExplorerViewEntryAttributeInternalExtensionArchive";

// XXTExplorerViewEntryAttributePermission
static NSString * const XXTExplorerViewEntryAttributePermissionViewable = @"XXTExplorerViewEntryAttributePermissionViewable";
static NSString * const XXTExplorerViewEntryAttributePermissionEditable = @"XXTExplorerViewEntryAttributePermissionEditable";
static NSString * const XXTExplorerViewEntryAttributePermissionExecuteable = @"XXTExplorerViewEntryAttributePermissionExecuteable";

#pragma mark - AlertView Actions

// XXTExplorerAlertViewAction
static NSString * const XXTExplorerAlertViewAction = @"XXTExplorerAlertViewAction";
static NSString * const XXTExplorerAlertViewActionPasteboardImport = @"XXTExplorerAlertViewActionPasteboardImport";
static NSString * const XXTExplorerAlertViewActionPasteboardExport = @"XXTExplorerAlertViewActionPasteboardExport";
static NSString * const XXTExplorerAlertViewActionPasteboardExportCut = @"XXTExplorerAlertViewActionPasteboardExportCut";
static NSString * const XXTExplorerAlertViewActionPasteboardExportCopy = @"XXTExplorerAlertViewActionPasteboardExportCopy";
static NSString * const XXTExplorerAlertViewActionPasteboardExportLink = @"XXTExplorerAlertViewActionPasteboardExportLink";
static NSString * const XXTExplorerAlertViewActionPasteboardExportPaste = @"XXTExplorerAlertViewActionPasteboardExportPaste";
static NSString * const XXTExplorerAlertViewContext = @"XXTExplorerAlertViewContext";

// XXTExplorerActionIcon
static NSString * const XXTExplorerActionIconLaunch = @"XXTExplorerActionIconLaunch";
static NSString * const XXTExplorerActionIconEdit = @"XXTExplorerActionIconEdit";
static NSString * const XXTExplorerActionIconProperty = @"XXTExplorerActionIconProperty";
static NSString * const XXTExplorerActionIconTrash = @"XXTExplorerActionIconTrash";
static NSString * const XXTExplorerActionIconInside = @"XXTExplorerActionIconInside";
static NSString * const XXTExplorerActionIconConfigure = @"XXTExplorerActionIconConfigure";

#pragma mark - Pasteboard

// XXTExplorerPasteboard
static NSString * const XXTExplorerPasteboardName = @"XXTExplorerPasteboardName";

#pragma mark - Notifications

#endif /* XXTExplorerDefaults_h */
