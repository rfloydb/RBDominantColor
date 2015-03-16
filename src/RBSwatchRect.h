//
//  SwatchRect.h
//  Created by Rob Brackett
//

//
// This is how big the border around our marked areas should be.
// Meaning, when you mark a rectangle, the rectangle *grows* by this percent,
// and the outer border will be marked as background.
//
static const CGFloat maskBorderPercent = 0.03;

@interface RBSwatchRect : NSObject

- (id)initWithImage:(UIImage *)image;
- (void)grabCut;
- (void)kMeansMat:(cv::Mat)kMeansIndexes intoMat:(cv::Mat)imageMat withColors:(NSArray *)colors andRemovedColor:(UIColor *)removedColor andAlpha:(CGFloat)alpha;

@property (nonatomic) CGRect rect;
@property (nonatomic) CGFloat reducePercent;

@property (nonatomic) BOOL useForColorRemoval;
@property (nonatomic) int kMeansStartIndex;
@property (nonatomic) int kMeansLength;

@property (nonatomic) BOOL forceForeground;
@property (nonatomic) CGFloat forceForegroundRectPercent;
@property (nonatomic) CGFloat forceForegroundPixelPercent;

@property (nonatomic, readonly) int pixels;
@property (nonatomic, readonly) int borderSize;
@property (nonatomic, readonly) CGRect adjustedRect;

@property (nonatomic, readonly) cv::Mat mat;
@property (nonatomic, readonly) cv::Mat mask;

@end
