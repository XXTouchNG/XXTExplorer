//
//  UIControl+BlockTarget.h
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^UIControlCompletionHandler)(UIControl *sender);

@interface UIControl (BlockTarget)

- (void)addActionforControlEvents:(UIControlEvents)controlEvents respond:(UIControlCompletionHandler)completion;

@end
