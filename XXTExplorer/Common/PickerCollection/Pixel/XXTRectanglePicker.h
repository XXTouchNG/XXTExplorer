//
//  XXTRectanglePicker.h
//  XXTouchApp
//
//  Created by Zheng on 18/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTBasePicker.h"

typedef enum : NSUInteger {
    XXTPixelPickerTypeRect = 0,
    XXTPixelPickerTypePosition = 1,
    XXTPixelPickerTypeColor = 2,
    XXTPixelPickerTypePositionColor = 3,
    XXTPixelPickerTypeMultiplePositionColor = 4,
} XXTPixelPickerType;

@interface XXTRectanglePicker : UIViewController <XXTBasePicker>
@property (nonatomic, weak) XXTPickerFactory *pickerFactory;

+ (XXTPixelPickerType)cropViewType;

@end
