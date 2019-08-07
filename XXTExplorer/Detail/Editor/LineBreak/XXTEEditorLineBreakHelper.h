//
//  XXTEEditorLineBreakHelper.h
//  XXTExplorer
//
//  Created by Darwin on 8/3/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXTEEditorTextProperties.h"

NS_ASSUME_NONNULL_BEGIN

@interface XXTEEditorLineBreakHelper : NSObject
+ (NSString *)lineBreakNameForType:(NSStringLineBreakType)type;
+ (NSString *)lineBreakStringForType:(NSStringLineBreakType)type;

@end

NS_ASSUME_NONNULL_END
