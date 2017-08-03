//
//  XUIDefaultsService.h
//  XXTExplorer
//
//  Created by Zheng on 02/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XUIBaseCell;

@interface XUIDefaultsService : NSObject

- (void)saveDefaultsFromCell:(XUIBaseCell *)cell;
- (void)readDefaultsToCell:(XUIBaseCell *)cell;

@end
