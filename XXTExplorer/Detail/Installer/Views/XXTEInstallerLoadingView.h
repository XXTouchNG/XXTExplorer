//
//  XXTEInstallerLoadingView.h
//  XXTExplorer
//
//  Created by Zheng on 26/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat const XXTEInstallerLoadingViewHeight = 68.0;

@interface XXTEInstallerLoadingView : UIView
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end
