//
//  XXTImagePickerPhotoCell.h
//  XXTPickerCollection
//

#import <UIKit/UIKit.h>

@interface XXTImagePickerPhotoCell : UICollectionViewCell

@property(weak, nonatomic) IBOutlet UIImageView *ivPhoto;
@property(weak, nonatomic) IBOutlet UIView *vSelect;

- (void)setSelectMode:(BOOL)bSelect;

@end
