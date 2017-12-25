//
//  XXTKeyEventPicker.h
//  XXTPickerCollection
//
//  Created by Zheng on 30/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTBasePicker.h"

@interface XXTKeyEventPicker : UIViewController <XXTBasePicker>
@property (nonatomic, weak) XXTPickerFactory *pickerFactory;

@end
