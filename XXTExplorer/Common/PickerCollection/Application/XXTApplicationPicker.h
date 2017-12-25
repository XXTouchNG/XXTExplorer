//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTBasePicker.h"

@interface XXTApplicationPicker : UIViewController <XXTBasePicker>
@property (nonatomic, weak) XXTPickerFactory *pickerFactory;
@property (nonatomic, assign) BOOL userApplicationOnly;

@end
