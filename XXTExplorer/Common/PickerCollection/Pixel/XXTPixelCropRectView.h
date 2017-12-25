//
//  XXTPixelCropRectView.h
//  XXTouchApp
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kXXTResizeControlPositionTopLeft = 0,
    kXXTResizeControlPositionTopRight,
    kXXTResizeControlPositionBottomLeft,
    kXXTResizeControlPositionBottomRight
} kXXTResizeControlPosition;

@protocol XXTCropRectViewDelegate;

@interface XXTPixelCropRectView : UIView

@property(nonatomic, weak) id <XXTCropRectViewDelegate> delegate;
@property(nonatomic, assign) BOOL showsGridMajor;
@property(nonatomic, assign) BOOL showsGridMinor;
@property(nonatomic, assign) kXXTResizeControlPosition resizeControlPosition;

@property(nonatomic, assign) BOOL keepingAspectRatio;

@end

@protocol XXTCropRectViewDelegate <NSObject>

- (void)cropRectViewDidBeginEditing:(XXTPixelCropRectView *)cropRectView;

- (void)cropRectViewEditingChanged:(XXTPixelCropRectView *)cropRectView;

- (void)cropRectViewDidEndEditing:(XXTPixelCropRectView *)cropRectView;

@end

