//
//  XXTPickerPreviewBar.h
//  XXTPickerCollection
//
//  Created by Zheng on 29/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTPickerPreviewBar : UIToolbar
- (void)setTitle:(NSString *)title;
- (void)setSubtitle:(NSString *)subtitle;
- (void)setAttributedSubtitle:(NSAttributedString *)subtitle;
- (void)setProgress:(float)progress;

@end
