//
//  LSApplicationProxy.h
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef LSApplicationProxy_h
#define LSApplicationProxy_h

#import <UIKit/UIKit.h>

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bid;
- (NSData *)iconDataForVariant:(int)arg1;
- (NSString *)itemName;
- (NSString *)localizedName;
- (NSURL *)resourcesDirectoryURL;
- (NSURL *)containerURL;
- (NSURL *)dataContainerURL;
- (BOOL)isSystemApplication;

@property (nonatomic, readonly) NSString *applicationIdentifier;

@end

#endif /* LSApplicationProxy_h */
