//
//  XXTETerminalDelegate.h
//  XXTExplorer
//
//  Created by MMM on 8/14/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#ifndef XXTETerminalDelegate_h
#define XXTETerminalDelegate_h

#import <Foundation/Foundation.h>

static NSString *kTerminalErrorLineNumberKey = @"kTerminalErrorLineNumberKey";  // integer, line number
static NSString *kTerminalErrorDescriptionKey = @"kTerminalErrorDescriptionKey";  // string, detailed info
static NSString *kTerminalErrorLevelKey = @"kTerminalErrorLevelKey";  // enum

typedef enum : NSUInteger {
    XXTETerminalErrorLevelInfo = 0,
    XXTETerminalErrorLevelWarning,
    XXTETerminalErrorLevelError,
} XXTETerminalErrorLevel;


@protocol XXTETerminalViewControllerDelegate <NSObject>
@optional
- (void)terminalDidTerminateWithSuccess:(UIViewController *)sender;
- (void)terminalDidTerminate:(UIViewController *)sender withError:(NSError *)error;

@end

#endif /* XXTETerminalDelegate_h */
