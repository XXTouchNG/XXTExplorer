//
//  XXTEInstallerLoadingView.m
//  XXTExplorer
//
//  Created by Zheng on 26/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEInstallerLoadingView.h"

@implementation XXTEInstallerLoadingView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.loadingLabel.text = NSLocalizedString(@"Loading...", nil);
}

@end
