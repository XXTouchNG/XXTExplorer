//
//  XXTECodeViewerController.h
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECommonWebViewController.h"
#import "XXTEViewer.h"

@interface XXTECodeViewerController : XXTECommonWebViewController <XXTEViewer>
@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, strong) UIColor *barTextColor;
@property (nonatomic, strong) UIColor *backgroundColor;
- (void)setNeedsRefreshNavigationBar;

@end
