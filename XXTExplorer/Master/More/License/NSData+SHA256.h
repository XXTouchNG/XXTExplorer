//
//  NSData+SHA256.h
//  XXTExplorer
//
//  Created by Zheng on 02/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SHA256)
- (NSString *)sha256String;
- (NSData *)sha256Data;

@end
