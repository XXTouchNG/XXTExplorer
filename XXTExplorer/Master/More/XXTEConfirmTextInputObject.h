//
//  XXTEConfirmTextInputObject.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/8.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface XXTEConfirmTextInputObject : NSObject

@property (nonatomic, strong) UITextField *textInput;
@property (nonatomic, copy) NSString *confirmString;
@property (nonatomic, copy) void (^confirmHandler)(UITextField *textInput);

@end
