//
//  XXTPickerDefine.h
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTPickerDefine_h
#define XXTPickerDefine_h

#define XXTP_START_IGNORE_PARTIAL _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wpartial-availability\"")
#define XXTP_END_IGNORE_PARTIAL _Pragma("clang diagnostic pop")

#define XXTP_SYSTEM_9 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_0)
#define XXTP_SYSTEM_8 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_0)
#define XXTP_PICKER_FRONT_COLOR ([UIColor colorWithRed:52.f/255.f green:152.f/255.f blue:219.f/255.f alpha:1.f])

#endif /* XXTPickerInternalDefine_h */
