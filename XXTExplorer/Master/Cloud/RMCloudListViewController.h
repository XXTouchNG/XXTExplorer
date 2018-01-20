//
//  RMCloudListViewController.h
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMProject.h"

@interface RMCloudListViewController : UIViewController
@property (nonatomic, assign) RMApiActionSortBy sortBy;
@property (nonatomic, copy) NSString *searchWord;

@end
