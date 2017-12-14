//
//  XXTEEditorSearchController.h
//  XXTExplorer
//
//  Created by Zheng on 2017/11/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTESegmentedController.h"

@class XXTEEditorController;

@interface XXTEEditorSearchController : XXTESegmentedController

@property (nonatomic, weak) XXTEEditorController *editor;

@end
