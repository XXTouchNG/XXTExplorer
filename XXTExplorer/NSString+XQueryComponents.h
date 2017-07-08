//
//  NSString+XQueryComponents.h
//  XXTouchApp
//
//  Created by Zheng on 9/14/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (XQueryComponents)
- (NSString *)stringByDecodingURLFormat;
- (NSString *)stringByEncodingURLFormat;
- (NSMutableDictionary *)dictionaryFromQueryComponents;
@end

@interface NSURL (XQueryComponents)
- (NSMutableDictionary *)queryComponents;
@end

@interface NSDictionary (XQueryComponents)
- (NSString *)stringFromQueryComponents;
@end
