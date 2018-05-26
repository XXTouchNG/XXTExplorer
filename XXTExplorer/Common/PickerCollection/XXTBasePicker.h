//
//  XXTBasePicker.h
//  XXTLocationPicker
//
//  Created by Zheng on 15/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTBasePicker_h
#define XXTBasePicker_h

#import <Foundation/Foundation.h>

@class XXTPickerSnippetTask, XXTPickerFactory;

@protocol XXTBasePicker <NSObject>
@property (nonatomic, weak) XXTPickerFactory *pickerFactory;
@property (nonatomic, strong) XXTPickerSnippetTask *pickerTask;
@property (nonatomic, strong) NSDictionary *pickerMeta;

+ (NSString *)pickerKeyword;
- (id)pickerResult;

@optional
- (NSString *)pickerSubtitle;
- (NSAttributedString *)pickerAttributedSubtitle;

@end

#endif /* XXTBasePicker_h */
