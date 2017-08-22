//
//  UIImage+XXTCrop.h
//  XXTouchApp
//

#import <UIKit/UIKit.h>

@interface UIImage (XXTCrop)

- (UIImage *)rotatedImageWithtransform:(CGAffineTransform)rotation
                         croppedToRect:(CGRect)rect;

@end
