//
//  SwatchColor.m
//  Created by Rob Brackett
//

#import "SwatchColor.h"
#import "UIColor+Distance.h"

@implementation SwatchColor {
    uchar cachedRed;
    uchar cachedGreen;
    uchar cachedBlue;
    BOOL colorRGBCached;
    
    CGFloat cachedHue;
    CGFloat cachedSaturation;
    CGFloat cachedBrightness;
    BOOL colorHSBCached;
    
    CGFloat cached_L;
    CGFloat cached_a;
    CGFloat cached_b;
    BOOL colorLabCached;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"importance=%d, removed=%d, pixels=%d color(%d,%d,%d)", self.importance, self.removedColor, self.pixels, self.red, self.green, self.blue];
}

- (id)initWithColor:(UIColor *)color
{
    self = [super init];
    if (self) {
        self.color = color;
        self.pixels = 0;
        self.colorRemovalPixels = 0;
        self.removedColor = NO;
        colorRGBCached = NO;
        colorHSBCached = NO;
        colorLabCached = NO;
        self.importance = -1;
    }
    return self;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    colorRGBCached = NO;
    colorHSBCached = NO;
    colorLabCached = NO;
}

- (void)cacheRGB
{
    CGFloat r, g, b, a;
    [self.color getRed:&r green:&g blue:&b alpha:&a];
    
    cachedRed = r * 255;
    cachedGreen = g * 255;
    cachedBlue = b * 255;
    
    colorRGBCached = YES;
}

- (void)cacheHSB
{
    CGFloat a;
    [self.color getHue:&cachedHue saturation:&cachedSaturation brightness:&cachedBrightness alpha:&a];
    
    colorHSBCached = YES;
}

- (void)cacheLab
{
    [self.color getL:&cached_L a:&cached_a b:&cached_b];
    
    colorLabCached = YES;
}

- (uchar)red
{
    if (colorRGBCached) {
        return cachedRed;
    }
    
    [self cacheRGB];
    return cachedRed;
}

- (uchar)green
{
    if (colorRGBCached) {
        return cachedGreen;
    }
    
    [self cacheRGB];
    return cachedGreen;
}

- (uchar)blue
{
    if (colorRGBCached) {
        return cachedBlue;
    }
    
    [self cacheRGB];
    return cachedBlue;
}

- (CGFloat)hue
{
    if (colorHSBCached) {
        return cachedHue;
    }
    
    [self cacheHSB];
    return cachedHue;
}

- (CGFloat)saturation
{
    if (colorHSBCached) {
        return cachedSaturation;
    }
    
    [self cacheHSB];
    return cachedSaturation;
}

- (CGFloat)brightness
{
    if (colorHSBCached) {
        return cachedBrightness;
    }
    
    [self cacheHSB];
    return cachedBrightness;
}

- (CGFloat)lab_L
{
    if (colorLabCached) {
        return cached_L;
    }
    
    [self cacheLab];
    return cached_L;
}

- (CGFloat)lab_a
{
    if (colorLabCached) {
        return cached_a;
    }
    
    [self cacheLab];
    return cached_a;
}

- (CGFloat)lab_b
{
    if (colorLabCached) {
        return cached_b;
    }
    
    [self cacheLab];
    return cached_b;
}

@end