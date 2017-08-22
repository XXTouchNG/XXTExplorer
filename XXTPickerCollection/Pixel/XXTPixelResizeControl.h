//
//  XXTPixelResizeControl.h
//  XXTouchApp
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@protocol XXTPixelResizeControlViewDelegate;

@interface XXTPixelResizeControl : UIView

@property(nonatomic, weak) id <XXTPixelResizeControlViewDelegate> delegate;
@property(nonatomic, readonly) CGPoint translation;

@end

@protocol XXTPixelResizeControlViewDelegate <NSObject>

- (void)resizeControlViewDidBeginResizing:(XXTPixelResizeControl *)resizeControlView;

- (void)resizeControlViewDidResize:(XXTPixelResizeControl *)resizeControlView;

- (void)resizeControlViewDidEndResizing:(XXTPixelResizeControl *)resizeControlView;

@end
