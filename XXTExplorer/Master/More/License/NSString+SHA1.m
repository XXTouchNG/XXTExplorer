//
//  NSString+SHA1.m
//  XXTExplorer
//
//  Created by Zheng on 02/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "NSString+SHA1.h"
#import "NSData+SHA1.h"

@implementation NSString (SHA1)

- (NSString *)sha1String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] sha1String];
}

@end
