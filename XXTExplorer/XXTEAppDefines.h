//
//  XXTEAppDefines.h
//  XXTExplorer
//
//  Created by Zheng on 05/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEAppDefines_h
#define XXTEAppDefines_h

#import "XXTEAppDelegate.h"

static inline id uAppDefine(NSString *key) {
    return ((XXTEAppDelegate *)[[UIApplication sharedApplication] delegate]).appDefines[key];
}

#endif /* XXTEAppDefines_h */
