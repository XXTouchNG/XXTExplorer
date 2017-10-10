//
//  XXTEUIViewController+SharedInstance.h
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"

@interface XXTEUIViewController (SharedInstance)

+ (XXTExplorerEntryParser *)entryParser;
+ (XXTExplorerEntryService *)entryService;

@end
