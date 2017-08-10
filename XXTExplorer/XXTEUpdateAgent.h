//
//  XXTEUpdateAgent.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEUpdateAgent;

@protocol XXTEUpdateAgentDelegate <NSObject>

@end

@interface XXTEUpdateAgent : NSObject

@property (nonatomic, weak) id <XXTEUpdateAgentDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier;

- (BOOL)shouldRemindWithVersion:(NSString *)version;
- (void)ignoreVersion:(NSString *)version;
- (void)ignoreThisDay;

@end
