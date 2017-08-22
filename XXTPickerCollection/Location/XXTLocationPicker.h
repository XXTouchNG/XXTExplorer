//
//  XXTLocationPicker.h
//  XXTLocationPicker
//
//  Created by Zheng on 15/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "XXTBasePicker.h"

@interface XXTLocationPicker : UIViewController <XXTBasePicker>
@property (nonatomic, weak) XXTPickerFactory *pickerFactory;

@end
