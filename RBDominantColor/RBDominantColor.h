//
//  RBDominantColor.h
//  Created by Rob Brackett
//

#import <UIKit/UIKit.h>

@interface RBDominantColor : NSObject

//
// Step 0: RBDominantColor *dc = [[RBDominantColor alloc] init];
//

//
// Step 1: Set an image
//
@property (nonatomic) UIImage *image;

//
// Step 1a (optional): Set the max pixels to use in analysis.
// Setting it higher causes the algorithm to take longer to run, but might give better results.
//
@property (nonatomic) int maxPixels;

//
// Step 2: Mark areas as belonging to foreground
//
// Note: You must call either markRect:, markDefaultArea, or markPoint:withRadius:isForeground:
// at least once, otherwise the entire image will be considered background.
//
// markFace is a special case. Calling markFace will call the opencv face detection algorithm.
// This is done in order to determine skin colors, which are *removed* from the foreground
// before domainant colors are calculated.
//
- (BOOL)markFace;
- (BOOL)markRect:(CGRect)rect;
- (BOOL)markDefaultArea;
- (void)markPoint:(CGPoint)point withRadius:(int)radius isForeground:(BOOL)isForeground;

//
// Step 3: Remove the background
//
- (void)grabCut;

//
// Step 4: Reduce colors in the foreground to a manageable number
//
- (void)kMeans:(int)colors;

//
// Step 5 (optional): Further reduce colors by eliminating colors that are close to one another
// Color distance should lie between 0 and 116 (116 = CIE94 distance between black and white)
//
- (void)minimizeColorsWithDistanceThreshold:(CGFloat)distance;

//
// Step 6: The resulting list of UIColors is stored in colorArray
//
@property (nonatomic, readonly) NSArray *colorArray;

//
// DEBUG: Creates a UIImage with background and removed foreground (skin) colors marked with a given color,
// along with the colorArray colors being put into the image with alpha transparency.
//
- (UIImage *)getImageWithBackgroundColor:(UIColor *)bgColor andRemovedColor:(UIColor *)removedColor andSwatchColorAlpha:(CGFloat)alpha;

//
// DEBUG: Provide a UIView, and it will empty out the UIView of subviews
// and add new subviews for each color.
//
- (void)populateColorsIntoView:(UIView *)v;

@end