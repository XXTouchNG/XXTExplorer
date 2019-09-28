//
//  XXTExplorerDefaults.h
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTExplorerDefaults_h
#define XXTExplorerDefaults_h

#import <Foundation/Foundation.h>

#pragma mark - Application Bundle

#pragma mark - Defaults

static NSString * const XXTExplorerViewBuiltInitialPath = @"EXPLORER_INITIAL_PATH";
static NSString * const XXTExplorerViewBuiltHistoryPath = @"EXPLORER_HISTORY_PATH";
static NSString * const XXTExplorerViewBuiltHomeSeries = @"EXPLORER_HOME_SERIES";

static NSString * const XXTExplorerViewEntryHomeEnabledKey = @"XXTExplorerViewEntryHomeEnabledKey";
static NSString * const XXTExplorerViewEntryListSortFieldKey = @"XXTExplorerViewEntryListSortFieldKey";
static NSString * const XXTExplorerViewEntryListSortOrderKey = @"XXTExplorerViewEntryListSortOrderKey";
static NSString * const XXTExplorerViewEntryListHideDotItemKey = @"XXTExplorerViewEntryListHideDotItemKey";
static NSString * const XXTExplorerViewEntrySelectedScriptPathKey = @"XXTExplorerViewEntrySelectedScriptPathKey";
static NSString * const XXTExplorerViewEntrySelectLaunchedScriptKey = @"XXTExplorerViewEntrySelectLaunchedScriptKey";
static NSString * const XXTExplorerViewEntryHideCommonFileExtensionsEnabledKey = @"XXTExplorerViewEntryHideCommonFileExtensionsEnabledKey";
static NSString * const XXTExplorerAllowOpenMethodKey = @"XXTExplorerAllowOpenMethodKey";
static NSString * const XXTExplorerAllowEditingFileOwnerKey = @"XXTExplorerAllowEditingFileOwnerKey";
static NSString * const XXTExplorerViewEntryHideOperationLabelKey = @"XXTExplorerViewEntryHideOperationLabelKey";
static NSString * const XXTExplorerPasteboardDetectOnActiveKey = @"XXTExplorerPasteboardDetectOnActiveKey";
static NSString * const XXTExplorerAllowsImportFromAlbum = @"XXTExplorerAllowsImportFromAlbum";
static NSString * const XXTExplorerFixFileOwnerAutomaticallyKey = @"XXTExplorerFixFileOwnerAutomaticallyKey";
static NSString * const XXTExplorerHistoryStoreLimit = @"XXTExplorerHistoryStoreLimit";

#pragma mark - Templates

static NSString * const XXTExplorerCreateItemTemplatePathKey = @"XXTExplorerCreateItemTemplatePathKey";

#pragma mark - Viewer Defaults

static NSString * const XXTExplorerDefaultEncodingKey = @"XXTExplorerDefaultEncodingKey";
static NSString * const XXTExplorerViewerRegexSearch = @"XXTExplorerViewerRegexSearch";
static NSString * const XXTExplorerViewerCaseSensitiveSearch = @"XXTExplorerViewerCaseSensitiveSearch";
static NSString * const XXTExplorerTerminalSaveLogs = @"XXTExplorerTerminalSaveLogs";
static NSString * const XXTExplorerTerminalLogStoreLimit = @"XXTExplorerTerminalLogStoreLimit";

#pragma mark - Editor Defaults

static NSString * const XXTExplorerTerminalPresentationStyle = @"XXTExplorerTerminalPresentationStyle";

typedef enum : NSUInteger {
    XXTETerminalPresentationStylePush = 0,
    XXTETerminalPresentationStylePresentInModal,
    XXTETerminalPresentationStylePresentAsPopover,
} XXTETerminalPresentationStyle;

#pragma mark - Item Picker Defaults

static NSString * const XXTExplorerViewItemPickerSortFieldKey = @"XXTExplorerViewItemPickerSortFieldKey";
static NSString * const XXTExplorerViewItemPickerSortOrderKey = @"XXTExplorerViewItemPickerSortOrderKey";

typedef enum : NSUInteger {
    XXTExplorerViewEntryListSortOrderAsc = 0,
    XXTExplorerViewEntryListSortOrderDesc,
} XXTExplorerViewEntryListSortOrder;

NS_INLINE NSString * const XXTELocalizedNameForSortOrder(XXTExplorerViewEntryListSortOrder sortOrder)
{
    NSUInteger sortOrderIdx = sortOrder;
    NSString *sortOrderTitie = (sortOrderIdx == XXTExplorerViewEntryListSortOrderAsc) ? NSLocalizedString(@"Ascend", nil) : NSLocalizedString(@"Descend", nil);
    return sortOrderTitie;
}

typedef enum : NSUInteger {
    XXTExplorerViewEntryListSortFieldCreationDate = 0,
    XXTExplorerViewEntryListSortFieldModificationDate,
    XXTExplorerViewEntryListSortFieldDisplayName,
    XXTExplorerViewEntryListSortFieldItemType,
    XXTExplorerViewEntryListSortFieldItemSize
} XXTExplorerViewEntryListSortField;

NS_INLINE NSArray <NSString *> * const XXTELocalizedNamesForAllSortFields()
{
    return @[
        NSLocalizedString(@"Created At", nil),
        NSLocalizedString(@"Modified At", nil),
        NSLocalizedString(@"Name", nil),
        NSLocalizedString(@"Type", nil),
        NSLocalizedString(@"Size", nil),
    ];
}

NS_INLINE NSString * const XXTELocalizedNameForSortField(XXTExplorerViewEntryListSortField sortField)
{
    NSArray <NSString *> *sortTitles = XXTELocalizedNamesForAllSortFields();
    NSUInteger sortFieldIdx = sortField;
    if (sortFieldIdx >= sortTitles.count) {
        sortFieldIdx = XXTExplorerViewEntryListSortFieldModificationDate;
    }
    NSString *sortFieldTitle = sortTitles[sortFieldIdx];
    return sortFieldTitle;
}

typedef enum : NSUInteger {
    XXTExplorerPasteboardDetectTypeNone = 0,
    XXTExplorerPasteboardDetectTypeURL,
    XXTExplorerPasteboardDetectTypeLicense,
    XXTExplorerPasteboardDetectTypeAll
} XXTExplorerPasteboardDetectType;

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

#pragma mark - Pasteboard

// XXTExplorerPasteboard
static NSString * const XXTExplorerPasteboardName = @"XXTExplorerPasteboardName";

#pragma mark - Bindings

static NSString * const XXTExplorerViewEntryBindingKey = @"XXTExplorerViewEntryBindingKey";

#pragma mark - Tutorials

static NSString * const XXTExplorerSwipeTutorialKey = @"XXTExplorerSwipeTutorialKey";

#endif /* XXTExplorerDefaults_h */
