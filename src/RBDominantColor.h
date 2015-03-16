//
//  RBDominantColor.h
//  Created by Rob Brackett
//

@interface RBDominantColor : NSObject

//
// Step 0: RBDominantColor *dc = [[RBDominantColor alloc] init];
//

//
// Step 1: Set an image
//
@property (nonatomic) UIImage *image;

//
// Step 2: Mark areas as belonging to foreground
//
// Note: You must call either markRect:, markDefaultArea, or markPoint:withRadius:isForeground:
// at least once, otherwise the entire image will be considered background.
// markFace is a special case. Calling markFace will call the opencv face detection algorithm.
// This is done in order to determine skin colors, which are *removed* from the foreground.
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
// Step 5: Further reduce colors by eliminating colors that are close to one another
// Color distance should lie between 0 and 116 (116 = CIE94 distance between black and white)
//
- (void)minimizeColorsWithDistanceThreshold:(CGFloat)distance;

//
// Step 6: The resulting list of colors is stored in colorArray
//
// Note: Each item is a SwatchColor. SwatchColor has a "color" property that is a UIColor.
//
@property (nonatomic, readonly) NSArray *colorArray;

//
// DEBUG: Creates a UIImage with background and removed foreground (skin) colors marked with a given color, along with the colorArray colors being put into the image with alpha transparency.
//
- (UIImage *)getImageWithBackgroundColor:(UIColor *)bgColor andRemovedColor:(UIColor *)removedColor andSwatchColorAlpha:(CGFloat)alpha;

//
// DEBUG: Provide a UIView, and it will empty out the UIView of subviews and add new subviews for each color.
//
- (void)populateColorsIntoView:(UIView *)v;

@end