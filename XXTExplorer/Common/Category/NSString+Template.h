//
//  NSString+Template.h
//  XXTExplorer
//
//  Created by Zheng on 2018/5/12.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Template)

- (NSString *)stringByReplacingTagsInDictionary:(NSDictionary *)dictionary;

@end
