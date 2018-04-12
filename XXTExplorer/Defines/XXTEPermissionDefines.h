//
//  XXTEPermissionDefines.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/1/30.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#ifndef XXTEPermissionDefines_h
#define XXTEPermissionDefines_h

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    const char *add1s_binary(void);
    const char *installer_binary(void);
    int promiseFixPermission(NSString *path, BOOL resursive);
    
#ifdef __cplusplus
}
#endif

#endif /* __OBJC__ */

#endif /* XXTEPermissionDefines_h */
