//
//  XXTExplorerItemDetailObjectViewController.h
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerItemDetailObjectViewController : UITableViewController

@property (nonatomic, strong) NSBundle *entryBundle;
@property (nonatomic, strong, readonly) id detailObject;
- (instancetype)initWithDetailObject:(id)detailObject;

@end
