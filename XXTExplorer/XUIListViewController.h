//
//  XUIListViewController.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIViewController.h"

@interface XUIListViewController : XUIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicatorView;
- (instancetype)initWithPath:(NSString *)path withBundlePath:(NSString *)bundlePath;

@end
