//
//  RMCloudExpandable.h
//  XXTExplorer
//
//  Created by Zheng on 16/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RMCloudExpandable <NSObject>
@property (weak, nonatomic) UILabel *titleTextLabel;
@property (weak, nonatomic) UILabel *valueTextLabel;
@property (weak, nonatomic) UIView *topSepatator;
@property (weak, nonatomic) UIView *bottomSepatator;

@end
