//
//  XXTEPermissionDefines.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/1/30.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#ifndef XXTEPermissionDefines_h
#define XXTEPermissionDefines_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    const char *add1s_binary(void);
    int promiseFixPermission(NSString *path, BOOL resursive);
    
#ifdef __cplusplus
}
#endif

#endif /* XXTEPermissionDefines_h */
