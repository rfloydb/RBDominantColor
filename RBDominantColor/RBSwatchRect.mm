//
//  SwatchRect.m
//  Created by Rob Brackett
//

#import "RBSwatchRect.h"
#import "UIImage+Resize.h"
#import "opencv2/highgui/ios.h"
#import "RBSwatchColor.h"

@implementation RBSwatchRect {
    UIImage *bigImage;
    UIImage *adjustedImage;
    
    CGRect adjustedRectCached;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        bigImage = image;
        adjustedImage = nil;
        self.rect = CGRectZero;
        
        // how much does this rect need to be reduced to allow grabcut to run quickly
        self.reducePercent = 1.0;
        
        self.useForColorRemoval = NO;
        
        self.forceForeground = NO;
        
        // if, after grabcut, less than this percent of pixels is foreground
        // force foreground using forceForegroundRectPercent
        self.forceForegroundPixelPercent = 0.1;
        
        // if, after grabcut, we need to force foreground, then force this percent of the rect to foreground
        self.forceForegroundRectPercent = 0.4;
    }
    return self;
}

- (void)setRect:(CGRect)rect
{
    _rect = CGRectIntegral(rect);
    adjustedRectCached = CGRectZero;
}

- (void)setReducePercent:(CGFloat)reducePercent
{
    _reducePercent = reducePercent;
    adjustedRectCached = CGRectZero;
}

- (int)pixels
{
    return self.adjustedRect.size.width * self.adjustedRect.size.height;
}

- (int)borderSizeAtScale:(CGFloat)scale
{
    return MAX(1, MIN(bigImage.size.width * scale, bigImage.size.height * scale) * maskBorderPercent);
}

- (int)borderSize
{
    return [self borderSizeAtScale:1.0];
}

- (CGRect)adjustedRectAtScale:(CGFloat)scale
{
    CGFloat width = bigImage.size.width * scale;
    CGFloat height = bigImage.size.height * scale;
    
    int x = MAX(0, CGRectGetMinX(self.rect) * scale - [self borderSizeAtScale:scale]);
    int y = MAX(0, CGRectGetMinY(self.rect) * scale - [self borderSizeAtScale:scale]);
    int w = MIN(width - x, CGRectGetWidth(self.rect) * scale + 2 * [self borderSizeAtScale:scale]);
    int h = MIN(height - y, CGRectGetHeight(self.rect) * scale + 2 * [self borderSizeAtScale:scale]);
    
    return CGRectIntegral(CGRectMake(x, y, w, h));
}

- (CGRect)adjustedRect
{
    if (CGRectIsEmpty(adjustedRectCached)) {
        adjustedRectCached = [self adjustedRectAtScale:self.reducePercent];
    }
    
    return adjustedRectCached;
}

- (void)resetMask
{
    _mask.create(_mat.size(), CV_8UC1);
    _mask.setTo(cv::GC_BGD);
    
    cv::Point center((int)(CGRectGetMidX(self.adjustedRect) - CGRectGetMinX(self.adjustedRect)),
                     (int)(CGRectGetMidY(self.adjustedRect) - CGRectGetMinY(self.adjustedRect)));
    cv::Size size((int)(self.adjustedRect.size.width - [self borderSizeAtScale:self.reducePercent]),
                  (int)(self.adjustedRect.size.height - [self borderSizeAtScale:self.reducePercent]));
    
    ellipse(_mask, cv::RotatedRect(center, size, 0), cv::GC_PR_FGD, -1);
    
    if (self.forceForeground) {
        size.width *= self.forceForegroundRectPercent;
        size.height *= self.forceForegroundRectPercent;
        ellipse(_mask, cv::RotatedRect(center, size, 0), cv::GC_FGD, -1);
    }
}

- (void)setupImage
{
    UIImage *cropped = [bigImage croppedImage:[self adjustedRectAtScale:1.0]];
    adjustedImage = [cropped resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:self.adjustedRect.size interpolationQuality:kCGInterpolationHigh];
    UIImageToMat(adjustedImage, _mat);
    
    cvtColor(_mat, _mat, CV_RGBA2RGB);
}

- (void)grabCut
{
    cv::Rect notUsed;
    cv::Mat bgModel;
    cv::Mat fgModel;
    
    [self setupImage];
    [self resetMask];
    
    grabCut(_mat, _mask, notUsed, bgModel, fgModel, 1, cv::GC_INIT_WITH_MASK);
    
    if (!self.forceForeground) {
        int fgPixels = 0;
        int targetPixels = self.pixels * self.forceForegroundPixelPercent;
        
        for (int y = 0 ; y < _mask.rows ; y++ ) {
            for (int x = 0 ; x < _mask.cols ; x++) {
                if (_mask.at<uchar>(y, x) & 1) {
                    fgPixels++;
                }
            }
            
            if (fgPixels >= targetPixels) {
                break;
            }
        }
        
        if (fgPixels < targetPixels) {
            self.forceForeground = YES;
            [self resetMask];
            [self grabCut];
        }
    }
}

- (cv::Mat)kMeansMat:(cv::Mat)kMeansIndexes
{
    cv::Mat kMeansMat;
    kMeansMat.create(_mask.size(), CV_32S);
    kMeansMat.setTo(-1);
    
    int pixel = self.kMeansStartIndex;
    for (int y = 0 ; y < _mask.rows ; y++ ) {
        for (int x = 0 ; x < _mask.cols ; x++) {
            if (_mask.at<uchar>(y, x) & 1) {
                kMeansMat.at<int>(y, x) = kMeansIndexes.at<int>(pixel, 0);
                pixel++;
            }
        }
    }
    
    return kMeansMat;
}

- (void)kMeansMat:(cv::Mat)kMeansIndexes intoMat:(cv::Mat)imageMat withColors:(NSArray *)colors andRemovedColor:(UIColor *)removedColor andAlpha:(CGFloat)alpha
{
    cv::Mat smallMat = [self kMeansMat:kMeansIndexes];
    
    CGRect bigRect = [self adjustedRectAtScale:1.0];
    
    CGFloat r, g, b, a;
    [removedColor getRed:&r green:&g blue:&b alpha:&a];
    uchar rcR = 255 * r;
    uchar rcG = 255 * g;
    uchar rcB = 255 * b;
    uchar rcA = 255 * a;
    
    uchar alphaU = alpha * 255;
    
    int kX;
    int kY;
    for (int y = 0 ; y < bigRect.size.height ; y++) {
        for (int x = 0 ; x < bigRect.size.width ; x++) {
            if (bigRect.size.height > 1 && smallMat.rows > 0) {
                kY = round((smallMat.rows - 1) * y / (bigRect.size.height - 1));
            } else {
                kY = 0;
            }
            
            if (bigRect.size.width > 1 && smallMat.cols > 0) {
                kX = round((smallMat.cols - 1) * x / (bigRect.size.width - 1));
            } else {
                kX = 0;
            }
            
            int colorIndex = smallMat.at<int>(kY, kX);
            if (colorIndex >= 0) {
                RBSwatchColor *c = colors[colorIndex];
                if (c.mergedIntoColor) {
                    do {
                        c = c.mergedIntoColor;
                    } while (c.mergedIntoColor);

                    imageMat.at<cv::Vec4b>(bigRect.origin.y + y, bigRect.origin.x + x) = {c.red, c.green, c.blue, alphaU};

                } else if (c.removedColor) {
                    imageMat.at<cv::Vec4b>(bigRect.origin.y + y, bigRect.origin.x + x) = {rcR, rcG, rcB, rcA};
                } else {
                    imageMat.at<cv::Vec4b>(bigRect.origin.y + y, bigRect.origin.x + x) = {c.red, c.green, c.blue, alphaU};
                }
            }
        }
    }
}

@end
