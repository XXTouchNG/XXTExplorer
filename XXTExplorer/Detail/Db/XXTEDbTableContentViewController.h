//
//  XXTEDbTableContentViewController.h
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEDbTableContentViewController : UIViewController

@property (nonatomic, strong) NSArray<NSString *> *columnsArray;
@property (nonatomic, strong) NSArray<NSDictionary<NSString *, id> *> *contentsArray;

@end
