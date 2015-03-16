//
//  UIColor+Distance.m
//  Created by Rob Brackett
//  Based on MTColorDistance (https://github.com/mysterioustrousers/MTColorDistance)
//

#import "UIColor+Distance.h"

#define K_L 1
#define K_1 0.045f
#define K_2 0.015f
#define X_REF 95.047f
#define Y_REF 100.0f
#define Z_REF 108.883f

// Coordinate bounds for device and whitepoint
#define REFMIN_L 0.0
#define REFMAX_L 100.0
#define REFMIN_A_02_D65 -86.184593
#define REFMAX_A_02_D65 98.254173
#define REFMIN_B_02_D65 -107.863632
#define REFMAX_B_02_D65 94.482437

@implementation UIColor (Distance)

- (void)getL:(CGFloat *)L a:(CGFloat *)a b:(CGFloat *)b
{
    // Don't allow grayscale colors.
    if (CGColorGetNumberOfComponents(self.CGColor) != 4) {
        return;
    }
    
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CGFloat x, y, z;
    [UIColor rgbToXYZr:red g:green b:blue x:&x y:&y z:&z];
    
    [UIColor xyzToLabx:x y:y z:z L:L a:a b:b];
}

- (CGFloat)distanceToColor:(UIColor *)color
{
    return [self distanceToColorLAB:color];
}

- (CGFloat)distanceToColorRGB:(UIColor *)color
{
    CGFloat r1, g1, b1, a1;
    [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    
    CGFloat r2, g2, b2, a2;
    [color getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    CGFloat dist = sqrtf(powf(r1 - r2, 2) + powf(g1 - g2, 2) + powf(b1 - b2, 2));
    
    return 100 * dist / sqrtf(3);
}

- (CGFloat)distanceToColorLAB:(UIColor *)color
{
    // CIE94
    
    CGFloat lab1L, lab1a, lab1b;
    [self getL:&lab1L a:&lab1a b:&lab1b];
    CGFloat C1 = sqrtf(lab1a * lab1a + lab1b * lab1b);
    
    CGFloat lab2L, lab2a, lab2b;
    [color getL:&lab2L a:&lab2a b:&lab2b];
    CGFloat C2 = sqrtf(lab2a * lab2a + lab2b * lab2b);
    
    CGFloat deltaL = lab1L - lab2L;
    CGFloat deltaC = C1 - C2;
    CGFloat deltaA = lab1a - lab2a;
    CGFloat deltaB = lab1b - lab2b;
    CGFloat deltaH = sqrtf(deltaA * deltaA + deltaB * deltaB - deltaC * deltaC);
    
    CGFloat CX = (C1 + C2) / 2;
    
    CGFloat deltaE = sqrtf(powf(deltaL / K_L, 2) + powf(deltaC / (1 + K_1 * CX), 2) + powf(deltaH / (1 + K_2 * CX), 2));
    
    return deltaE;
}

- (UIColor *)closestColorInPalette:(NSArray *)palette {
    CGFloat bestDifference = MAXFLOAT;
    UIColor *bestColor = nil;
    
    for (UIColor *color in palette) {
        CGFloat deltaE = [self distanceToColor:color];
        if (deltaE < bestDifference) {
            bestColor = color;
            bestDifference = deltaE;
        }
    }
    
    return bestColor;
}

- (CGFloat)closestDistanceInPalette:(NSArray *)palette {
    CGFloat bestDifference = MAXFLOAT;
    UIColor *bestColor = nil;
    
    for (UIColor *color in palette) {
        CGFloat deltaE = [self distanceToColor:color];
        if (deltaE < bestDifference) {
            bestColor = color;
            bestDifference = deltaE;
        }
    }
    
    return bestDifference;
}

+ (UIColor *)colorWithLightness:(CGFloat)lightness A:(CGFloat)A B:(CGFloat)B alpha:(CGFloat)alpha
{
    CGFloat x,y,z;
    [UIColor labToXYZL:lightness A:A B:B X:&x Y:&y Z:&z];
    
    CGFloat r,g,b;
    [UIColor xyzToRGBx:x y:y z:z r:&r g:&g b:&b];
    
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

+ (CGFloat)xyzToLab1:(CGFloat)component
{
    if (component > 0.008856) {
        component = powf(component, 0.333f);
    } else {
        component = (7.787 * component) + (16 / 116);
    }
    
    return component;
}

+ (void)xyzToLabx:(CGFloat)x y:(CGFloat)y z:(CGFloat)z L:(CGFloat *)L a:(CGFloat *)a b:(CGFloat *)b
{
    x /= X_REF;
    y /= Y_REF;
    z /= Z_REF;
    
    x = [UIColor xyzToLab1:x];
    y = [UIColor xyzToLab1:y];
    z = [UIColor xyzToLab1:z];
    
    *L = (116 * y) - 16;
    *a = 500 * (x - y);
    *b = 200 * (y - z);
}

+ (CGFloat)labToXYZ1:(CGFloat)component
{
    if (pow(component, 3.0) > 0.008856) {
        component = pow(component, 3.0);
    } else {
        component = (component - 16.0/116.0) / 7.787;
    }
    
    return component;
}

+ (void)labToXYZL:(CGFloat)L A:(CGFloat)A B:(CGFloat)B X:(CGFloat *)outX Y:(CGFloat *)outY Z:(CGFloat *)outZ
{
    CGFloat x,y,z;
    y = (L + 16.0) / 116.0;
    x = A / 500.0 + y;
    z = y - B / 200.0;
    
    x = [UIColor labToXYZ1:x];
    y = [UIColor labToXYZ1:y];
    z = [UIColor labToXYZ1:z];
    
    *outX = X_REF * x;
    *outY = Y_REF * y;
    *outZ = Z_REF * z;
}

+ (CGFloat)rgbXYZ1:(CGFloat)component
{
    if (component > 0.04045f) {
        component = powf((component + 0.055f) / 1.055f, 2.4f);
    } else {
        component = component / 12.92f;
    }
    
    return component;
}

+ (void)rgbToXYZr:(CGFloat)r g:(CGFloat)g b:(CGFloat)b x:(CGFloat *)x y:(CGFloat *)y z:(CGFloat *)z
{
    r = [UIColor rgbXYZ1:r] * 100.0f;
    g = [UIColor rgbXYZ1:g] * 100.0f;
    b = [UIColor rgbXYZ1:b] * 100.0f;
    
    *x = (r * 0.4124f) + (g * 0.3576f) + (b * 0.1805f);
    *y = (r * 0.2126f) + (g * 0.7152f) + (b * 0.0722f);
    *z = (r * 0.0193f) + (g * 0.1192f) + (b * 0.9505f);
}

+ (CGFloat)xyzToRGB1:(CGFloat)component
{
    if (component > 0.0031308) {
        component = 1.055 * pow(component, (1 / 2.4)) - 0.055;
    } else {
        component = 12.92 * component;
    }
    
    return component;
}

+ (void) xyzToRGBx:(CGFloat)x y:(CGFloat)y z:(CGFloat)z r:(CGFloat *)outR g:(CGFloat *)outG b:(CGFloat *)outB
{
    x /= 100.0;
    y /= 100.0;
    z /= 100.0;
    
    CGFloat r,g,b;
    
    r = x * 3.2406 + y * -1.5372 + z * -0.4986;
    g = x * -0.9689 + y * 1.8758 + z * 0.0415;
    b = x * 0.0557 + y * -0.2040 + z * 1.0570;
    
    *outR = [UIColor xyzToRGB1:r];
    *outG = [UIColor xyzToRGB1:g];
    *outB = [UIColor xyzToRGB1:b];
}

@end
