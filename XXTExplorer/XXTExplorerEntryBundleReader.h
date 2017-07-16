//
//  XXTExplorerEntryBundleReader.h
//  XXTExplorer
//
//  Created by Zheng on 16/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTExplorerEntryBundleReader_h
#define XXTExplorerEntryBundleReader_h

#import "XXTExplorerEntryReader.h"

@protocol XXTExplorerEntryBundleReader <XXTExplorerEntryReader>

@property (nonatomic, assign, readonly) BOOL configurable;
+ (Class)configurationViewer;

@end

#endif /* XXTExplorerEntryBundleReader_h */
