//
//  XXTEUpdateReminder.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEUpdateReminder;

@protocol XXTEUpdateReminderDelegate <NSObject>



@end

@interface XXTEUpdateReminder : NSObject

@property (nonatomic, weak) id <XXTEUpdateReminderDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier;

- (BOOL)shouldRemindWithVersion:(NSString *)version;
- (void)ignoreVersion:(NSString *)version;
- (void)ignoreThisDay;

@end
