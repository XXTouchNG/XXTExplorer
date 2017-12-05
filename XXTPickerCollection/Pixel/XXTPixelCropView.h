//
//  XXTPixelCropView.h
//  XXTouchApp
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    kXXTPixelCropViewTypeRect = 0,
    kXXTPixelCropViewTypePosition = 1,
    kXXTPixelCropViewTypeColor = 2,
    kXXTPixelCropViewTypePositionColor = 3,
    kXXTPixelCropViewTypeMultiplePositionColor = 4,
} kXXTPixelCropViewType;

@class XXTPixelCropView;

@protocol XXTPixelCropViewDelegate <NSObject>

- (void)cropView:(XXTPixelCropView *)crop selectValueUpdated:(id)selectedValue;

@end

@interface XXTPixelCropView : UIView

@property(nonatomic, assign) kXXTPixelCropViewType type;

@property(nonatomic) UIImage *image;
@property(nonatomic, readonly) UIImage *croppedImage;
@property(nonatomic, readonly) CGRect zoomedCropRect;
@property(nonatomic, readonly) CGAffineTransform rotation;
@property(nonatomic, readonly) BOOL userHasModifiedCropArea;

@property(nonatomic) BOOL allowsRotate;
@property(nonatomic) BOOL keepingCropAspectRatio;
@property(nonatomic) BOOL allowsOperation;
@property(nonatomic) CGFloat cropAspectRatio;

@property(nonatomic) CGRect cropRect;
@property(nonatomic) CGRect imageCropRect;
@property(nonatomic) CGFloat rotationAngle;

@property(nonatomic, weak) id <XXTPixelCropViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame andType:(kXXTPixelCropViewType)type;

- (void)resetCropRect;

- (void)resetCropRectAnimated:(BOOL)animated;

- (void)setRotationAngle:(CGFloat)rotationAngle snap:(BOOL)snap;

- (void)rotateLeft;

- (void)rotateRight;

@end
