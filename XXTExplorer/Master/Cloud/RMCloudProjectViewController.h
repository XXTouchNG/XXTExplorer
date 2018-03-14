//
//  RMCloudProjectViewController.h
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEDetailViewController.h"

@interface RMCloudProjectViewController : UIViewController <XXTEDetailViewController>

@property (nonatomic, assign) NSUInteger projectID;
- (instancetype)initWithProjectID:(NSUInteger)projectID;

@end
