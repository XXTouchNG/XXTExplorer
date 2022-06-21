//
//  XXTEKeyboardButtonView.m
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEKeyboardButtonView.h"
#import "XXTEKeyboardButton.h"
#import "XXTETurtleBezierPath.h"

@interface XXTEKeyboardButtonView ()

@property(nonatomic, weak) XXTEKeyboardButton *button;
@property(nonatomic, assign) XXTEKeyboardButtonPosition expandedPosition;
@property(nonatomic, assign) XXTEKeyboardRowStyle colorStyle;

@end

@implementation XXTEKeyboardButtonView

#pragma mark - UIView

- (instancetype)initWithKeyboardButton:(XXTEKeyboardButton *)button {
    CGRect frame = [UIScreen mainScreen].bounds;
    
    XXTE_START_IGNORE_PARTIAL
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        frame = CGRectMake(0, 0, CGRectGetHeight(frame), CGRectGetWidth(frame));
    }
    XXTE_END_IGNORE_PARTIAL

    self = [super initWithFrame:frame];

    if (self) {
        _button = button;
        _colorStyle = button.colorStyle;

        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;

        if (button.position != XXTEKeyboardButtonPositionInner) {
            _expandedPosition = button.position;
        } else {
            // Determine the position
            CGFloat leftPadding = CGRectGetMinX(button.frame);
            CGFloat rightPadding = CGRectGetMaxX(button.superview.frame) - CGRectGetMaxX(button.frame);
            _expandedPosition = (leftPadding > rightPadding ? XXTEKeyboardButtonPositionLeft : XXTEKeyboardButtonPositionRight);
        }
    }

    return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [self drawInputView:rect];
}

- (void)drawInputView:(CGRect)rect {
    // Generate the overlay
    UIBezierPath *bezierPath = [self inputViewPath];
    NSString *inputString = self.button.output;

    // Position the overlay
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];

    CGContextRef context = UIGraphicsGetCurrentContext();

    // Overlay path & shadow
    {
        UIColor *fillColor = [self isDarkMode] ? [UIColor colorWithWhite:1.f alpha:.3f] : [UIColor whiteColor];
        //// Shadow Declarations
        UIColor *shadow = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        CGSize shadowOffset = CGSizeMake(0, 0.5);
        CGFloat shadowBlurRadius = 2;

        //// Rounded Rectangle Drawing
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [fillColor setFill];
        [bezierPath fill];
        CGContextRestoreGState(context);
    }

    // Draw the key shadow sliver
    {
        UIColor *shadowColor = [self isDarkMode] ? [UIColor clearColor] : [UIColor whiteColor];
        //// Color Declarations
        UIColor *color = shadowColor;

        //// Shadow Declarations
        UIColor *shadow = [self isDarkMode] ? [UIColor clearColor] : [UIColor colorWithRed:136.f / 255.f green:138.f / 255.f blue:142.f / 255.f alpha:1.f];
        CGSize shadowOffset = CGSizeMake(0.1, 1.1);
        CGFloat shadowBlurRadius = 0.0;

        //// Rounded Rectangle Drawing
        UIBezierPath *roundedRectanglePath =
                [UIBezierPath bezierPathWithRoundedRect:CGRectMake(keyRect.origin.x, keyRect.origin.y, keyRect.size.width, keyRect.size.height - 1.0) cornerRadius:4.0];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [color setFill];
        [roundedRectanglePath fill];

        CGContextRestoreGState(context);
    }

    // Text drawing
    {
        UIColor *fillColor = [self isDarkMode] ? [UIColor whiteColor] : [UIColor blackColor];
        
        UIColor *stringColor = nil;
        if (_button.selecting) {
            stringColor = XXTColorDanger();
        } else {
            stringColor = fillColor;
        }

        CGRect stringRect = bezierPath.bounds;
        NSMutableParagraphStyle *p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:inputString attributes:@{NSFontAttributeName: [self.button.font fontWithSize:44.0], NSForegroundColorAttributeName: stringColor, NSParagraphStyleAttributeName: p}];
        
        CGSize stringSize = attributedString.size;
        CGRect drawRect = CGRectMake(stringRect.origin.x + CGRectGetWidth(stringRect) / 2.0 - stringSize.width / 2.0, stringRect.origin.y + CGRectGetHeight(stringRect) / 2.0 - stringSize.height / 2.0 - 22.0, stringSize.width, stringSize.height);
        [attributedString drawInRect:drawRect];
    }
}

#pragma mark - Internal

- (UIBezierPath *)inputViewPath {
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];

    UIEdgeInsets insets = UIEdgeInsetsMake(7, 13, 7, 13);
    CGFloat upperWidth = CGRectGetWidth(_button.frame) + insets.left + insets.right;
    CGFloat lowerWidth = CGRectGetWidth(_button.frame);
    CGFloat majorRadius = 10.f;
    CGFloat minorRadius = 4.f;

    XXTETurtleBezierPath *path = [XXTETurtleBezierPath new];
    [path home];
    path.lineWidth = 0;
    path.lineCapStyle = kCGLineCapRound;

    switch (self.button.position) {
        case XXTEKeyboardButtonPositionInner: {
            [path rightArc:majorRadius turn:90]; // #1
            [path forward:upperWidth - 2 * majorRadius]; // #2 top
            [path rightArc:majorRadius turn:90]; // #3
            [path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom]; // #4 right big
            [path rightArc:majorRadius turn:48]; // #5
            [path forward:8.5f];
            [path leftArc:majorRadius turn:48]; // #6
            [path forward:CGRectGetHeight(keyRect) - 8.5f + 1];
            [path rightArc:minorRadius turn:90];
            [path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
            [path rightArc:minorRadius turn:90];
            [path forward:CGRectGetHeight(keyRect) - 2 * minorRadius];
            [path leftArc:majorRadius turn:48];
            [path forward:8.5f];
            [path rightArc:majorRadius turn:48];

            CGFloat offsetX = 0, offsetY = 0;
            CGRect pathBoundingBox = path.bounds;

            offsetX = CGRectGetMidX(keyRect) - CGRectGetMidX(path.bounds);
            offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) + 10;

            [path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
        }
            break;

        case XXTEKeyboardButtonPositionLeft: {
            [path rightArc:majorRadius turn:90]; // #1
            [path forward:upperWidth - 2 * majorRadius]; // #2 top
            [path rightArc:majorRadius turn:90]; // #3
            [path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom]; // #4 right big
            [path rightArc:majorRadius turn:45]; // #5
            [path forward:28]; // 6
            [path leftArc:majorRadius turn:45]; // #7
            [path forward:CGRectGetHeight(keyRect) - 26 + (insets.left + insets.right) / 4]; // #8
            [path rightArc:minorRadius turn:90]; // 9
            [path forward:path.currentPoint.x - minorRadius]; // 10
            [path rightArc:minorRadius turn:90]; // 11


            CGFloat offsetX = 0, offsetY = 0;
            CGRect pathBoundingBox = path.bounds;

            offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(path.bounds);
            offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) - CGRectGetMinY(path.bounds);

            [path applyTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), -offsetX - CGRectGetWidth(path.bounds), offsetY)];
        }
            break;

        case XXTEKeyboardButtonPositionRight: {
            [path rightArc:majorRadius turn:90]; // #1
            [path forward:upperWidth - 2 * majorRadius]; // #2 top
            [path rightArc:majorRadius turn:90]; // #3
            [path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom]; // #4 right big
            [path rightArc:majorRadius turn:45]; // #5
            [path forward:28]; // 6
            [path leftArc:majorRadius turn:45]; // #7
            [path forward:CGRectGetHeight(keyRect) - 26 + (insets.left + insets.right) / 4]; // #8
            [path rightArc:minorRadius turn:90]; // 9
            [path forward:path.currentPoint.x - minorRadius]; // 10
            [path rightArc:minorRadius turn:90]; // 11

            CGFloat offsetX = 0, offsetY = 0;
            CGRect pathBoundingBox = path.bounds;

            offsetX = CGRectGetMinX(keyRect);
            offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) - CGRectGetMinY(path.bounds);

            [path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
        }
            break;
        default:
            break;
    }
    return path;
}

- (BOOL)isDarkMode {
    return (self.colorStyle == XXTEKeyboardRowStyleDark);
}

@end
