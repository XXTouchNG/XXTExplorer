//
//  NSString+VersionValue.h
//  XXTExplorer
//
//  Created by Zheng on 25/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (VersionValue)

- (NSComparisonResult)compareVersion:(nonnull NSString *)version;

@end
