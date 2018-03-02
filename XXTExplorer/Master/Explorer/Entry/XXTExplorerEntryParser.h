//
//  XXTExplorerEntryParser.h
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTExplorerEntry.h"

@interface XXTExplorerEntryParser : NSObject
- (XXTExplorerEntry *)entryOfPath:(NSString *)path withError:(NSError **)error;

@end
