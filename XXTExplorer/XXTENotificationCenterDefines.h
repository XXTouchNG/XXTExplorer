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

// XXTENotificationEvent

static NSString * const XXTENotificationEventType = @"XXTENotificationEventType";
static NSString * const XXTENotificationDetailDisplayMode = @"XXTENotificationDetailDisplayMode"; // NSNumber

// Global - XXTENotificationEventType
static NSString * const XXTENotificationEventTypeInbox = @"XXTENotificationEventTypeInbox";
static NSString * const XXTENotificationEventTypeInboxMoved = @"XXTENotificationEventTypeInboxMoved";
static NSString * const XXTENotificationEventTypeApplicationDidBecomeActive = @"XXTENotificationEventTypeApplicationDidBecomeActive";
static NSString * const XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode = @"XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode";

#endif /* XXTENotificationCenterDefines_h */
