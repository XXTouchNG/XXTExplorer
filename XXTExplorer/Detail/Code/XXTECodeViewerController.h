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

@property (nonatomic, assign, getter=isLockedState) BOOL lockedState;
@property (nonatomic, assign) CFStringEncoding currentEncoding;

@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, strong) UIColor *barTextColor;
@property (nonatomic, strong) UIColor *backgroundColor;

- (void)setNeedsRefreshNavigationBar;

@end
