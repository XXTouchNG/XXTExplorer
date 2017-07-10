//
//  NSFileManager+DeepSize.h
//  XXTouchApp
//
//  Created by Zheng on 14/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (DeepSize)
- (NSArray *)listItemsInDirectoryAtPath:(NSString *)path deep:(BOOL)deep cancelFlag:(int *)cancelFlag;
- (NSNumber *)sizeOfDirectoryAtPath:(NSString *)path error:(NSError **)error cancelFlag:(int *)cancelFlag;
- (NSNumber *)sizeOfItemAtPath:(NSString *)path error:(NSError **)error;

@end
