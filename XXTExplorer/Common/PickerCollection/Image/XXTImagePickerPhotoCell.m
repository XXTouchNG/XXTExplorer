//
//  XXTImagePickerPhotoCell.m
//  XXTPickerCollection
//

#import "XXTImagePickerPhotoCell.h"

@implementation XXTImagePickerPhotoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelectMode:(BOOL)bSelect {
    if (bSelect)
        _ivPhoto.alpha = 0.2;
    else
        _ivPhoto.alpha = 1.0;
}

@end
