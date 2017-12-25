//
//  UIImage+XXTCrop.h
//  XXTouchApp
//

#import <UIKit/UIKit.h>

@interface UIImage (XXTCrop)

- (UIImage *)rotatedImageWithTransform:(CGAffineTransform)rotation
                         croppedToRect:(CGRect)rect;

@end
