//
//  XXTENotificationCenterDefines.h
//  XXTExplorer
//
//  Created by Zheng on 01/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTENotificationCenterDefines_h
#define XXTENotificationCenterDefines_h

static NSString * const XXTENotificationEvent = @"XXTENotificationEvent";
static NSString * const XXTENotificationShortcut = @"XXTENotificationShortcut";

// XXTENotificationEvent

static NSString * const XXTENotificationEventType = @"XXTENotificationEventType";
static NSString * const XXTENotificationDetailDisplayMode = @"XXTENotificationDetailDisplayMode"; // NSNumber

// Global - XXTENotificationEventType
static NSString * const XXTENotificationEventTypeInbox = @"XXTENotificationEventTypeInbox";
static NSString * const XXTENotificationEventTypeInboxMoved = @"XXTENotificationEventTypeInboxMoved";
static NSString * const XXTENotificationEventTypeApplicationDidBecomeActive = @"XXTENotificationEventTypeApplicationDidBecomeActive";
static NSString * const XXTENotificationEventTypeApplicationDidExtractResource = @"XXTENotificationEventTypeApplicationDidExtractResource";
static NSString * const XXTENotificationEventTypeApplicationDidEnterBackground = @"XXTENotificationEventTypeApplicationDidEnterBackground";

static NSString * const XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode = @"XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode";

static NSString * const XXTENotificationEventTypeFormSheetDismissed = @"XXTENotificationEventTypeFormSheetDismissed";

static NSString * const XXTENotificationEventTypeSelectedScriptPathChanged = @"XXTENotificationEventTypeSelectedScriptPathChanged";

// XXTENotificationShortcut
static NSString * const XXTENotificationShortcutInterface = @"XXTENotificationShortcutInterface";
static NSString * const XXTENotificationShortcutInterfaceScan = @"XXTENotificationShortcutInterfaceScan";
static NSString * const XXTENotificationShortcutInterfaceLicense = @"XXTENotificationShortcutInterfaceLicense";
static NSString * const XXTENotificationShortcutInterfaceLauncher = @"XXTENotificationShortcutInterfaceLauncher";
static NSString * const XXTENotificationShortcutInterfaceDownload = @"XXTENotificationShortcutInterfaceDownload";

static NSString * const XXTENotificationShortcutUserData = @"XXTENotificationShortcutUserData";

#endif /* XXTENotificationCenterDefines_h */
