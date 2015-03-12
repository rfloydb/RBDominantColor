//
//  RBDominantColor.h
//  Created by Rob Brackett
//

#import "SwatchColor.h"

@interface Swatch : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic, readonly) NSArray *colorArray;

- (BOOL)markFace;
- (BOOL)markRect:(CGRect)rect;
- (BOOL)markDefaultArea;
- (void)markPoint:(CGPoint)point withRadius:(int)radius isForeground:(BOOL)isForeground;

- (void)grabCut;

- (void)kMeans:(int)colors;

- (UIImage *)getImageWithBackgroundColor:(UIColor *)bgColor andRemovedColor:(UIColor *)removedColor andSwatchColorAlpha:(CGFloat)alpha;

- (void)minimizeColorsWithDistanceThreshold:(CGFloat)distance;

- (void)populateColorsIntoView:(UIView *)v;

@end