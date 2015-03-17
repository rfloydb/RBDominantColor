//
//  SwatchColor.h
//  Created by Rob Brackett
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface RBSwatchColor : NSObject

- (id)initWithColor:(UIColor *)color;

@property (nonatomic) UIColor *color;
@property (nonatomic) int pixels;
@property (nonatomic) int colorRemovalPixels;
@property (nonatomic) BOOL removedColor;
@property (weak, nonatomic) RBSwatchColor *mergedIntoColor;

@property (nonatomic) int importance; // 0 == removed, -1 == not set
@property (nonatomic) NSUInteger minDistIndex;
@property (nonatomic) CGFloat minDist;

@property (nonatomic, readonly) uchar red;
@property (nonatomic, readonly) uchar green;
@property (nonatomic, readonly) uchar blue;

@property (nonatomic, readonly) CGFloat hue;
@property (nonatomic, readonly) CGFloat saturation;
@property (nonatomic, readonly) CGFloat brightness;

@property (nonatomic, readonly) CGFloat lab_L;
@property (nonatomic, readonly) CGFloat lab_a;
@property (nonatomic, readonly) CGFloat lab_b;

@end