//
//  UIDevice+IPAddress.h
//  XXTExplorer
//
//  Created by Zheng on 2018/5/28.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (IPAddress)

- (NSArray <NSDictionary *> *)getIPAddresses;

@end
