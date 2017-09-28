//
//  XXTExplorerFooterView.h
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *XXTExplorerEntryFooterViewReuseIdentifier = @"XXTExplorerEntryFooterViewReuseIdentifier";

@interface XXTExplorerFooterView : UITableViewHeaderFooterView
@property (nonatomic, strong, readonly) UILabel *footerLabel;

@end
