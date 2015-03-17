//
//  UIColor+Distance.h
//  Created by Rob Brackett
//  Based on MTColorDistance (https://github.com/mysterioustrousers/MTColorDistance)
//

#import <UIKit/UIKit.h>

@interface UIColor (Distance)

- (void)getL:(CGFloat *)L a:(CGFloat *)a b:(CGFloat *)b;

- (CGFloat)distanceToColor:(UIColor *)color;
- (UIColor *)closestColorInPalette:(NSArray *)palette;
- (CGFloat)closestDistanceInPalette:(NSArray *)palette;

+ (UIColor *)colorWithLightness:(CGFloat)lightness A:(CGFloat)A B:(CGFloat)B alpha:(CGFloat)alpha;

@end
