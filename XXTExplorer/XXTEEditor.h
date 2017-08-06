//
//  XXTEEditor.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#ifndef XXTEEditor_h
#define XXTEEditor_h

#import <UIKit/UIKit.h>
#import "XXTEDetailViewController.h"

@protocol XXTEEditor <XXTEDetailViewController>

+ (NSString *)editorName;
+ (NSArray <NSString *> *)suggestedExtensions;

@property (nonatomic, copy, readonly) NSString *entryPath;
- (instancetype)initWithPath:(NSString *)path;

@end

#endif /* XXTEEditor_h */
