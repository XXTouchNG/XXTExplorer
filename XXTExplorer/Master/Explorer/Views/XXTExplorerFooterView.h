//
//  XXTExplorerFooterView.h
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *XXTExplorerEntryFooterViewReuseIdentifier = @"XXTExplorerEntryFooterViewReuseIdentifier";

@class XXTExplorerFooterView;

@protocol XXTExplorerFooterViewDelegate <NSObject>
- (void)footerView:(XXTExplorerFooterView *)view emptyButtonTapped:(UIButton *)sender;

@end

@interface XXTExplorerFooterView : UITableViewHeaderFooterView

@property (nonatomic, weak) id <XXTExplorerFooterViewDelegate> delegate;
@property (nonatomic, assign) BOOL emptyMode;
@property (nonatomic, strong, readonly) UILabel *footerLabel;

@end
