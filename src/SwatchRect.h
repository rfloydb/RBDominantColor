//
//  SwatchRect.h
//  Created by Rob Brackett
//

// this is the target image size to analyze after removing the irrelevant parts
static const int workingImageMaxPixels = 30000;

// this is how big the border around our marked areas should be
static const CGFloat maskBorderPercent = 0.03;

@interface SwatchRect : NSObject

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
