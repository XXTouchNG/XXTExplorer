//
//  XXTEAppDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEAppDelegate : UIResponder <UIApplicationDelegate>

+ (NSDictionary *)appDefines;
+ (NSUserDefaults *)userDefaults;
+ (NSDictionary *)builtInDefaults;
+ (NSString *)sharedRootPath;

@property (strong, nonatomic) UIWindow *window;
- (void)reloadWorkspace;

@end

