//
//  XXTEProcessDelegateObject.h
//  XXTExplorer
//
//  Created by Zheng on 2018/4/14.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXTEProcessDelegateObject : NSObject

- (NSArray <NSValue *> *)processOpen:(const char **)arglist pidPointer:(pid_t *)pid_p;
- (int)processClose:(NSArray <NSValue *> *)fpArr pidPointer:(pid_t *)pid_p;

@end
