//
//  XXTEEditorLineMask.h
//  XXTExplorer
//
//  Created by MMM on 8/17/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    XXTEEditorLineMaskNone,
    XXTEEditorLineMaskInfo,
    XXTEEditorLineMaskWarning,
    XXTEEditorLineMaskError,
    XXTEEditorLineMaskSuccess
} XXTEEditorLineMaskType;

@interface XXTEEditorLineMask : NSObject

@property (nonatomic, assign) NSUInteger lineIndex;  // start from 0
@property (nonatomic, assign) XXTEEditorLineMaskType maskType;
@property (nonatomic, copy, nullable) NSString *maskDescription;
@property (nonatomic, strong, nullable) id relatedObject;

@end

NS_ASSUME_NONNULL_END
