//
//  XXTPixelImage.m
//  XXTPixelImage
//
//  Created by 苏泽 on 16/8/1.
//  Copyright © 2016年 苏泽. All rights reserved.
//

#import "XXTPixelImage.h"

#import <CoreGraphics/CoreGraphics.h>

#include <stdlib.h>

typedef uint8_t SZ_BOOL;
typedef union SZ_COLOR SZ_COLOR;
typedef struct SZ_POS SZ_POS;

/* Color Struct */
union SZ_COLOR {
    uint32_t the_color; /* the_color is name of color value */
    struct { /* RGB struct */
        uint8_t blue;
        uint8_t green;
        uint8_t red;
        uint8_t alpha;
    };
};

struct SZ_IMAGE {
    uint8_t orientation;
    int width;
    int height;
    SZ_COLOR *pixels;
    SZ_BOOL is_destroyed;
};

/* Pos Struct */
struct SZ_POS {
    int32_t x;
    int32_t y;
    union {
        uint32_t the_color; /* the_color is name of color value */
        struct { /* RGB struct */
            uint8_t blue;
            uint8_t green;
            uint8_t red;
            uint8_t alpha;
        };
    };
    int8_t sim;
    SZ_COLOR color_offset;
};

static inline SZ_IMAGE *create_pixels_image_with_uiimage(UIImage *img) {
    SZ_IMAGE *pixels_image = NULL;
    @autoreleasepool {
        CGSize size = [img size];
        int width = size.width;
        int height = size.height;
        pixels_image = (SZ_IMAGE *) malloc(sizeof(SZ_IMAGE));
        memset(pixels_image, 0, sizeof(SZ_IMAGE));
        pixels_image->width = width;
        pixels_image->height = height;
        SZ_COLOR *pixels = (SZ_COLOR *) malloc(width * height * sizeof(SZ_COLOR));
        memset(pixels, 0, width * height * sizeof(SZ_COLOR));
        pixels_image->pixels = pixels;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(SZ_COLOR), colorSpace,
                kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), [img CGImage]);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return pixels_image;
}

#define SHIFT_XY_BY_ORIEN_NOM1(X, Y, W, H, O) \
{\
switch (O) {\
int Z;\
case 0:\
break;\
case 1:\
(Z) = (X);\
(X) = (W) - (Y);\
(Y) = (Z);\
break;\
case 2:\
(Z) = (Y);\
(Y) = (H) - (X);\
(X) = (Z);\
break;\
case 3:\
(X) = (W) - (X);\
(Y) = (H) - (Y);\
break;\
}\
}

#define SHIFT_XY_BY_ORIEN(X, Y, W, H, O) SHIFT_XY_BY_ORIEN_NOM1((X), (Y), ((W)-1), ((H)-1), (O))

#define UNSHIFT_XY_BY_ORIEN_NOM1(X, Y, W, H, O) \
{\
switch (O) {\
int Z;\
case 0:\
break;\
case 1:\
(Z) = (Y);\
(Y) = (W) - (X);\
(X) = (Z);\
break;\
case 2:\
(Z) = (X);\
(X) = (H) - (Y);\
(Y) = (Z);\
break;\
case 3:\
(X) = (W) - (X);\
(Y) = (H) - (Y);\
break;\
}\
}

#define UNSHIFT_XY_BY_ORIEN(X, Y, W, H, O) UNSHIFT_XY_BY_ORIEN_NOM1((X), (Y), ((W)-1), ((H)-1), (O))

#define SHIFT_RECT_BY_ORIEN_NOM1(X1, Y1, X2, Y2, W, H, O) \
{\
int Z;\
SHIFT_XY_BY_ORIEN_NOM1((X1), (Y1), (W), (H), (O));\
SHIFT_XY_BY_ORIEN_NOM1((X2), (Y2), (W), (H), (O));\
if ((X1) > (X2)){\
(Z) = (X1);\
(X1) = (X2);\
(X2) = (Z);\
}\
if ((Y1) > (Y2)){\
(Z) = (Y1);\
(Y1) = (Y2);\
(Y2) = (Z);\
}\
}

#define SHIFT_RECT_BY_ORIEN(X1, Y1, X2, Y2, W, H, O) SHIFT_RECT_BY_ORIEN_NOM1((X1), (Y1), (X2), (Y2), (W-1), (H-1), (O))

#define UNSHIFT_RECT_BY_ORIEN_NOM1(X1, Y1, X2, Y2, W, H, O) \
{\
int Z;\
UNSHIFT_XY_BY_ORIEN_NOM1((X1), (Y1), (W), (H), (O));\
UNSHIFT_XY_BY_ORIEN_NOM1((X2), (Y2), (W), (H), (O));\
if ((X1) > (X2)){\
(Z) = (X1);\
(X1) = (X2);\
(X2) = (Z);\
}\
if ((Y1) > (Y2)){\
(Z) = (Y1);\
(Y1) = (Y2);\
(Y2) = (Z);\
}\
}

#define UNSHIFT_RECT_BY_ORIEN(X1, Y1, X2, Y2, W, H, O) UNSHIFT_RECT_BY_ORIEN_NOM1((X1), (Y1), (X2), (Y2), (W-1), (H-1), (O))

#define GET_ROTATE_ROTATE(OO, FO, OUTO) \
{\
switch (FO) {\
case 1:\
switch (OO){\
case 0:\
(OUTO) = 1;\
break;\
case 1:\
(OUTO) = 3;\
break;\
case 2:\
(OUTO) = 0;\
break;\
case 3:\
(OUTO) = 2;\
break;\
}\
break;\
case 2:\
switch (OO){\
case 0:\
(OUTO) = 2;\
break;\
case 1:\
(OUTO) = 0;\
break;\
case 2:\
(OUTO) = 3;\
break;\
case 3:\
(OUTO) = 1;\
break;\
}\
break;\
case 3:\
switch (OO){\
case 0:\
(OUTO) = 3;\
break;\
case 1:\
(OUTO) = 2;\
break;\
case 2:\
(OUTO) = 1;\
break;\
case 3:\
(OUTO) = 0;\
break;\
}\
break;\
case 0:\
(OUTO) = OO;\
}\
}

#define GET_ROTATE_ROTATE2(OO, FO) GET_ROTATE_ROTATE((OO), (FO), (OO))

#define GET_ROTATE_ROTATE3 GET_ROTATE_ROTATE

static inline void get_color_in_pixels_image_safe(SZ_IMAGE *pixels_image, int x, int y, SZ_COLOR *color_of_point) {
    SHIFT_XY_BY_ORIEN(x, y, pixels_image->width, pixels_image->height, pixels_image->orientation);
    if (x < pixels_image->width &&
            y < pixels_image->height) {
        color_of_point->the_color = pixels_image->pixels[y * pixels_image->width + x].the_color;
        color_of_point->red = pixels_image->pixels[y * pixels_image->width + x].blue;
        color_of_point->blue = pixels_image->pixels[y * pixels_image->width + x].red;
        return;
    }
    color_of_point->the_color = 0;
}

static inline void set_color_in_pixels_image_safe(SZ_IMAGE *pixels_image, int x, int y, SZ_COLOR *color_of_point) {
    SHIFT_XY_BY_ORIEN(x, y, pixels_image->width, pixels_image->height, pixels_image->orientation);
    if (x < pixels_image->width &&
            y < pixels_image->height) {
        pixels_image->pixels[y * pixels_image->width + x].the_color = color_of_point->the_color;
        pixels_image->pixels[y * pixels_image->width + x].red = color_of_point->blue;
        pixels_image->pixels[y * pixels_image->width + x].blue = color_of_point->red;
    }
}

static inline void get_color_in_pixels_image_notran(SZ_IMAGE *pixels_image, int x, int y, SZ_COLOR *color_of_point) {
    SHIFT_XY_BY_ORIEN(x, y, pixels_image->width, pixels_image->height, pixels_image->orientation);
    color_of_point->the_color = pixels_image->pixels[y * pixels_image->width + x].the_color;
}

static inline CGImageRef create_cgimage_with_pixels_image(SZ_IMAGE *pixels_image, SZ_COLOR **ppixels_data) /* 这个函数产生的返回值需要释放，第二个参数如果有产出，也需要释放 */
{
    int W, H;
    *ppixels_data = NULL; /* 先把需要产出的这里置空，函数完毕之后需要通过这里判断是否需要释放 */
    SZ_COLOR *pixels_buffer = pixels_image->pixels;
    switch (pixels_image->orientation) {
        case 1:
        case 2:
            H = pixels_image->width;
            W = pixels_image->height;
            break;
        default:
            W = pixels_image->width;
            H = pixels_image->height;
            break;
    }
    if (0 != pixels_image->orientation) {
        pixels_buffer = (SZ_COLOR *) malloc(W * H * 4); /* 通过第二个参数 ppixels_data 延迟释放，一定要记住 */
        *ppixels_data = pixels_buffer;
        uint64_t big_count_offset = 0;
        SZ_COLOR color_of_point;
        for (int y = 0; y < H; ++y) {
            for (int x = 0; x < W; ++x) {
                get_color_in_pixels_image_notran(pixels_image, x, y, &color_of_point);
                pixels_buffer[big_count_offset++].the_color = color_of_point.the_color;
            }
        }
    }
    CGDataProviderRef provider = CGDataProviderCreateWithData(
            NULL, pixels_buffer, (4 * W * H), NULL);
    CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wenum-conversion"
    CGImageRef img = CGImageCreate(W, H, 8, (8 * 4), (4 * W), cspace,
            kCGImageAlphaPremultipliedLast,
            provider, NULL, true, kCGRenderingIntentDefault);
#pragma clang diagnostic pop
    CFRelease(cspace);
    CFRelease(provider);
    return img;
}

static inline SZ_IMAGE *create_pixels_image_with_pixels_image_rect(SZ_IMAGE *pixels_image_, uint8_t orien, int x1, int y1, int x2, int y2) {
    SZ_IMAGE *pixels_image = NULL;
    @autoreleasepool {
        int old_W = pixels_image_->width;
        int new_W = x2 - x1;
        int new_H = y2 - y1;
        pixels_image = (SZ_IMAGE *) malloc(sizeof(SZ_IMAGE));
        memset(pixels_image, 0, sizeof(SZ_IMAGE));
        pixels_image->width = new_W;
        pixels_image->height = new_H;
        SZ_COLOR *pixels = (SZ_COLOR *) malloc(new_W * new_H * sizeof(SZ_COLOR));
        memset(pixels, 0, new_W * new_H * sizeof(SZ_COLOR));
        pixels_image->pixels = pixels;
        uint64_t big_count_offset = 0;
        for (int y = y1; y < y2; ++y) {
            for (int x = x1; x < x2; ++x) {
                pixels[big_count_offset++] = pixels_image_->pixels[y * old_W + x];
            }
        }
        GET_ROTATE_ROTATE3(pixels_image_->orientation, orien, pixels_image->orientation);
    }
    return pixels_image;
}

static inline void free_pixels_image(SZ_IMAGE *pixels_image) {
    if (!pixels_image->is_destroyed) {
        free(pixels_image->pixels);
        pixels_image->is_destroyed = 1;
    }
    free(pixels_image);
}

@implementation XXTPixelImage

+ (XXTPixelImage *)imageWithUIImage:(UIImage *)uiimage {
    return [[[XXTPixelImage alloc] autorelease] initWithUIImage:uiimage];
}

- (XXTPixelImage *)init {
    self = [super init];
    _pixel_image = NULL;
    return self;
}

- (XXTPixelImage *)initWithUIImage:(UIImage *)uiimage {
    self = [super init];
    if (self) {
        @autoreleasepool {
            _pixel_image = create_pixels_image_with_uiimage(uiimage);
        }
    }
    return self;
}

- (XXTPixelImage *)crop:(CGRect)rect {
    XXTPixelImage *rectImg = nil;
    @autoreleasepool {
        int x1 = rect.origin.x;
        int y1 = rect.origin.y;
        int x2 = rect.origin.x + rect.size.width;
        int y2 = rect.origin.y + rect.size.height;
        SHIFT_RECT_BY_ORIEN(x1, y1, x2, y2, _pixel_image->width, _pixel_image->height, _pixel_image->orientation);
        y2 = (y2 > _pixel_image->height) ? _pixel_image->height : y2;
        x2 = (x2 > _pixel_image->width) ? _pixel_image->width : x2;
        rectImg = [[XXTPixelImage alloc] init];
        rectImg->_pixel_image = create_pixels_image_with_pixels_image_rect(_pixel_image, 0, x1, y1, x2, y2);
    }
    return [rectImg autorelease];
}

- (CGSize)size {
    int W = 0, H = 0;
    switch (_pixel_image->orientation) {
        case 1:
        case 2:
            H = _pixel_image->width;
            W = _pixel_image->height;
            break;
        default:
            W = _pixel_image->width;
            H = _pixel_image->height;
            break;
    }
    return CGSizeMake(W, H);
}

- (XXTPixelColor *)getColorOfPoint:(CGPoint)point {
    SZ_COLOR color_of_point;
    get_color_in_pixels_image_safe(_pixel_image, point.x, point.y, &color_of_point);
    return [XXTPixelColor colorWithRed:color_of_point.red green:color_of_point.green blue:color_of_point.blue alpha:color_of_point.alpha];
}

- (NSString *)getColorHexOfPoint:(CGPoint)point {
    SZ_COLOR color_of_point;
    get_color_in_pixels_image_safe(_pixel_image, point.x, point.y, &color_of_point);
    return [[XXTPixelColor colorWithRed:color_of_point.red green:color_of_point.green blue:color_of_point.blue alpha:color_of_point.alpha] getColorHex];
}

- (void)setColor:(XXTPixelColor *)color ofPoint:(CGPoint)point {
    SZ_COLOR color_of_point;
    color_of_point.red = color.red;
    color_of_point.green = color.green;
    color_of_point.blue = color.blue;
    color_of_point.alpha = 0xff;
    set_color_in_pixels_image_safe(_pixel_image, point.x, point.y, &color_of_point);
}

- (UIImage *)getUIImage {
    SZ_COLOR *pixels_data = NULL;
    CGImageRef cgimg = create_cgimage_with_pixels_image(_pixel_image, &pixels_data);
    if (pixels_data) {
        NSData *imgData = nil;
        @autoreleasepool {
            UIImage *img0 = [UIImage imageWithCGImage:cgimg];
            CFRelease(cgimg);
            imgData = [UIImagePNGRepresentation(img0) retain];
        }
        UIImage *img = [UIImage imageWithData:imgData];
        [imgData release];
        free(pixels_data);
        return img;
    } else {
        UIImage *img0 = [UIImage imageWithCGImage:cgimg];
        CFRelease(cgimg);
        return img0;
    }
}

- (void)setOrient:(uint8_t)orient {
    _pixel_image->orientation = orient;
}

- (uint8_t)orient {
    return _pixel_image->orientation;
}

- (void)dealloc {
    free_pixels_image(_pixel_image);
    [super dealloc];
}

@end
