//
//  XXTExplorerHeaderView.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *XXTExplorerEntryHeaderViewReuseIdentifier = @"XXTExplorerEntryHeaderViewReuseIdentifier";

@interface XXTExplorerHeaderView : UITableViewHeaderFooterView
@property (nonatomic, strong, readonly) UILabel *headerLabel;

@end
