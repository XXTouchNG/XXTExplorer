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
static NSString * const XXTExplorerViewEntryAttributeIconImage = @"XXTExplorerViewEntryAttributeIconImage";
static NSString * const XXTExplorerViewEntryAttributeDisplayName = @"XXTExplorerViewEntryAttributeDisplayName";
static NSString * const XXTExplorerViewEntryAttributeName = @"XXTExplorerViewEntryAttributeName";
static NSString * const XXTExplorerViewEntryAttributePath = @"XXTExplorerViewEntryAttributePath";
static NSString * const XXTExplorerViewEntryAttributeExtension = @"XXTExplorerViewEntryAttributeExtension";
static NSString * const XXTExplorerViewEntryAttributeInternalExtension = @"XXTExplorerViewEntryAttributeInternalExtension";
static NSString * const XXTExplorerViewEntryAttributeType = @"XXTExplorerViewEntryAttributeType";
static NSString * const XXTExplorerViewEntryAttributeMaskType = @"XXTExplorerViewEntryAttributeMaskType";
static NSString * const XXTExplorerViewEntryAttributeCreationDate = @"XXTExplorerViewEntryAttributeCreationDate";
static NSString * const XXTExplorerViewEntryAttributeModificationDate = @"XXTExplorerViewEntryAttributeModificationDate";
static NSString * const XXTExplorerViewEntryAttributeSize = @"XXTExplorerViewEntryAttributeSize";
static NSString * const XXTExplorerViewEntryAttributePermission = @"XXTExplorerViewEntryAttributePermission"; // Dictionary
static NSString * const XXTExplorerViewEntryAttributeKind = @"XXTExplorerViewEntryAttributeKind";
static NSString * const XXTExplorerViewEntryAttributeViewer = @"XXTExplorerViewEntryAttributeViewer";

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

#pragma mark - Pasteboard

// XXTExplorerPasteboard
static NSString * const XXTExplorerPasteboardName = @"XXTExplorerPasteboardName";

#pragma mark - Notifications

#endif /* XXTExplorerDefaults_h */
