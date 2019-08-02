//
//  XXTEEditorEncodingHelper.h
//  XXTExplorer
//
//  Created by Darwin on 8/2/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XXTEEditorEncodingHelper : NSObject
+ (NSString *)encodingNameForEncoding:(CFStringEncoding)encoding;

@end

NS_ASSUME_NONNULL_END
