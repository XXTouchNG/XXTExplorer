//
//  XXTEViewer.h
//  XXTExplorer
//
//  Created by Zheng on 13/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEViewer_h
#define XXTEViewer_h

@protocol XXTEViewer <NSObject>

+ (NSString *)viewerName;
+ (NSArray <NSString *> *)suggestedExtensions;

@property (nonatomic, copy, readonly) NSString *entryPath;
- (instancetype)initWithPath:(NSString *)path;

@end

#endif /* XXTEViewer_h */
