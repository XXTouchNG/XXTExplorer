//
//  LSApplicationProxy.h
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bid;
- (NSData *)iconDataForVariant:(int)arg1;
- (NSString *)itemName;
- (NSString *)localizedName;
- (NSURL *)resourcesDirectoryURL;
- (NSURL *)containerURL;
- (NSURL *)dataContainerURL;

@property (nonatomic, readonly) NSString *applicationIdentifier;

@end
