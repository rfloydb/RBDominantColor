//
//  RBDominantColor.m
//  Created by Rob Brackett
//

#import "RBDominantColor.h"
#import "RBSwatchColor.h"
#import "RBSwatchRect.h"
#import "opencv2/highgui/ios.h"
#import "UIColor+Distance.h"

//
// This is the target image size to analyze after removing the irrelevant parts.
// Smaller number means faster analysis.
//
static const int workingImageMaxPixelsDefault = 30000;

//
// These are percentages of the smaller dimension of the original image.
//
// Example: If minFacePercent = 0.1 and maxFacePercent = 0.5, it means
// a face should be 10-50% the width of a portrait-oriented image.
//
static const CGFloat minFacePercent = 0.05;
static const CGFloat maxFacePercent = 0.25;

//
// This shrinks the face area to try to avoid getting hair in there for color analysis.
//
static const CGFloat faceGrowPercent = -0.25;

//
// These are thresholds of colors to remove.
//
// Example: If faceColorRemovalPercent = 0.5, it means it will remove the top 50% of colors
// found in the face, by pixel count (after kMeans has run).
//
// Example: If faceColorRemovalStep2Distance = 10.0, it will remove any colors which have
// a distance of 10 or less to a face color
//
static const CGFloat faceColorRemovalPercent = 1.0;
static const CGFloat faceColorRemovalStep2Distance = 0.0;

static const NSUInteger swatchStatusInit = 0;
static const NSUInteger swatchStatusImageSet = 1;
static const NSUInteger swatchStatusGrabCut = 2;
static const NSUInteger swatchStatusKMeans = 3;

@implementation RBDominantColor {
    cv::CascadeClassifier faceDetector;
    
    NSMutableArray *colors;
    NSMutableArray *marked;
    
    NSUInteger status;
    
    cv::Mat kMeansColorIndexes;
}

- (id)init
{
    self = [super init];
    if (self) {
        status = swatchStatusInit;
        self.maxPixels = workingImageMaxPixelsDefault;
    }
    return self;
}

#pragma mark - Step 1 - Set Image

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    marked = [NSMutableArray array];
    
    status = swatchStatusImageSet;
}

#pragma mark - Step 2 - Create potential foreground areas

- (cv::Rect)findFace
{
    cv::Mat gray;
    UIImageToMat(self.image, gray);
    cvtColor(gray, gray, CV_RGBA2GRAY);
    
    faceDetector.load([[[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"] UTF8String]);
    
    int minW = MAX(1, MIN(gray.cols, gray.rows) * minFacePercent);
    int minH = MAX(1, MIN(gray.cols, gray.rows) * minFacePercent);
    int maxW = MAX(1, MIN(gray.cols, gray.rows) * maxFacePercent);
    int maxH = MAX(1, MIN(gray.cols, gray.rows) * maxFacePercent);
    
    std::vector<cv::Rect> faces;
    faceDetector.detectMultiScale(gray, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(minW, minH), cv::Size(maxW, maxH));
    
    cv::Rect biggestFace(0, 0, 0, 0);
    
    for (unsigned int i = 0 ; i < faces.size() ; i++) {
        const cv::Rect &f = faces[i];
        
        if (f.width * f.height > biggestFace.width * biggestFace.height) {
            biggestFace = f;
        }
    }
    
    return biggestFace;
}

- (BOOL)markFace
{
    if (status == swatchStatusGrabCut) {
        NSLog(@"Can't adjust mask after grabCut has run.");
        return NO;
    }
    
    if (status == swatchStatusInit) {
        NSLog(@"Can't adjust mask before setting image.");
        return NO;
    }
    
    if (status >= swatchStatusKMeans) {
        NSLog(@"Can't adjust mask grabCut after kMeans.");
        return NO;
    }
    
    cv::Rect r = [self findFace];
    if (r.width * r.height > 0) {
        CGFloat growW = r.width * faceGrowPercent;
        CGFloat growH = r.height * faceGrowPercent;
        
        r.x = MAX(0, r.x - growW / 2);
        r.y = MAX(0, r.y - growH / 2);
        r.width = MIN(self.image.size.width - r.x, r.width + growW);
        r.height = MIN(self.image.size.height - r.y, r.height + growH);
        
        if (r.width * r.height > 0) {
            RBSwatchRect *mask = [[RBSwatchRect alloc] initWithImage:self.image];
            mask.rect = CGRectMake(r.x, r.y, r.width, r.height);
            mask.useForColorRemoval = YES;
            
            [marked addObject:mask];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)markRect:(CGRect)rect
{
    if (status == swatchStatusGrabCut) {
        NSLog(@"Can't adjust mask after grabCut has run.");
        return NO;
    }
    
    if (status == swatchStatusInit) {
        NSLog(@"Can't adjust mask before setting image.");
        return NO;
    }
    
    if (status >= swatchStatusKMeans) {
        NSLog(@"Can't adjust mask grabCut after kMeans.");
        return NO;
    }
    
    if (CGRectGetMinX(rect) < 0 || CGRectGetMinY(rect) < 0 || CGRectGetMaxX(rect) > self.image.size.width || CGRectGetMaxY(rect) > self.image.size.height) {
        return NO;
    }
    
    if (rect.size.width * rect.size.height > 0) {
        RBSwatchRect *mask = [[RBSwatchRect alloc] initWithImage:self.image];
        mask.rect = rect;
        
        [marked addObject:mask];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)markDefaultArea
{
    if (status == swatchStatusGrabCut) {
        NSLog(@"Can't adjust mask after grabCut has run.");
        return NO;
    }
    
    if (status == swatchStatusInit) {
        NSLog(@"Can't adjust mask before setting image.");
        return NO;
    }
    
    if (status >= swatchStatusKMeans) {
        NSLog(@"Can't adjust mask grabCut after kMeans.");
        return NO;
    }
    
    RBSwatchRect *mask = [[RBSwatchRect alloc] initWithImage:self.image];
    CGRect rect = CGRectMake(mask.borderSize, mask.borderSize, self.image.size.width - 2 * mask.borderSize, self.image.size.height - 2 * mask.borderSize);
    
    if (rect.size.width > 0 && rect.size.height > 0) {
        mask.rect = rect;
        
        [marked addObject:mask];
        
        return YES;
    }
    
    return NO;
}

- (void)markPoint:(CGPoint)point withRadius:(int)radius isForeground:(BOOL)isForeground
{
    if (status == swatchStatusGrabCut) {
        NSLog(@"Can't adjust mask after grabCut has run.");
        return;
    }
    
    if (status == swatchStatusInit) {
        NSLog(@"Can't adjust mask before setting image.");
        return;
    }
    
    if (status >= swatchStatusKMeans) {
        NSLog(@"Can't adjust mask grabCut after kMeans.");
        return;
    }
    
    CGRect rect = CGRectMake(point.x - radius, point.y - radius, point.x + radius, point.y + radius);
    
    RBSwatchRect *mask = [[RBSwatchRect alloc] initWithImage:self.image];
    mask.rect = rect;
    
    // if we are hardcoding this selection to foreground, then the entire rect should be foreground
    if (isForeground) {
        mask.forceForeground = YES;
        mask.forceForegroundRectPercent = 1.0;
    }
    
    [marked addObject:mask];
}

#pragma mark - Step 3 - Run grabCut

- (void)setReducePercentOnMarkedAreas
{
    NSArray *sorted = [marked sortedArrayUsingComparator:^NSComparisonResult(RBSwatchRect *obj1, RBSwatchRect *obj2) {
        if (obj1.pixels < obj2.pixels) {
            return NSOrderedAscending;
        } else if (obj1.pixels > obj2.pixels) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    int remainingPixels = self.maxPixels;
    
    for (int i = 0 ; i < sorted.count ; i++) {
        RBSwatchRect *s = sorted[i];
        
        int pixelTarget = remainingPixels / (sorted.count - i);
        
        if (s.pixels > pixelTarget) {
            s.reducePercent = sqrt((double)pixelTarget / (double)s.pixels);
        }
        
        remainingPixels -= s.pixels;
    }
}

- (void)grabCut
{
    if (status == swatchStatusGrabCut) {
        NSLog(@"grabCut can only run once.");
        return;
    }
    
    if (status == swatchStatusInit) {
        NSLog(@"Can't run grabCut before setting image.");
        return;
    }
    
    if (status >= swatchStatusKMeans) {
        NSLog(@"Can't run grabCut after kMeans.");
        return;
    }
    
    if (status == swatchStatusImageSet) {
        [self setReducePercentOnMarkedAreas];
    }
    
    status = swatchStatusGrabCut;
    
    for (RBSwatchRect *s in marked) {
        [s grabCut];
    }
}

#pragma mark - Step 4 - Run kMeans

- (void)processColors
{
    // initialize the colors
    
    for (RBSwatchRect *s in marked) {
        for (int i = 0 ; i < s.kMeansLength ; i++) {
            int colorIndex = kMeansColorIndexes.at<int>(s.kMeansStartIndex + i, 0);
            RBSwatchColor *c = colors[colorIndex];
            
            if (s.useForColorRemoval) {
                c.colorRemovalPixels++;
            } else {
                c.pixels++;
            }
        }
    }
    
    NSArray *sortedForRemoval = [colors sortedArrayUsingComparator:^NSComparisonResult(RBSwatchColor *obj1, RBSwatchColor *obj2) {
        if (obj1.colorRemovalPixels > obj2.colorRemovalPixels) {
            return NSOrderedAscending;
            
        } else if (obj1.colorRemovalPixels < obj2.colorRemovalPixels) {
            return NSOrderedDescending;
            
        } else if (obj1.pixels < obj2.pixels) {
            return NSOrderedAscending;
            
        } else if (obj1.pixels > obj2.pixels) {
            return NSOrderedDescending;
            
        } else {
            return NSOrderedSame;
        }
    }];
    
    NSMutableArray *removalColors = [NSMutableArray arrayWithCapacity:MAX(1, sortedForRemoval.count * faceColorRemovalPercent)];
    for (RBSwatchColor *c in [sortedForRemoval subarrayWithRange:NSMakeRange(0, MAX(1, sortedForRemoval.count * faceColorRemovalPercent))]) {
        if (c.colorRemovalPixels > 0) {
            [removalColors addObject:c.color];
        }
    }
    
    for (RBSwatchColor *c in colors) {
        CGFloat d = [c.color closestDistanceInPalette:removalColors];
        if (d <= faceColorRemovalStep2Distance) {
            c.removedColor = YES;
            c.importance = 0;
        }
    }
}

- (void)kMeans:(int)numColors
{
    if (status < swatchStatusGrabCut) {
        NSLog(@"Can't run kMeans until grabCut has run.");
        return;
    }
    
    status = swatchStatusKMeans;
    
    int pixels = 0;
    for (RBSwatchRect *s in marked) {
        s.kMeansStartIndex = -1;
        
        for (int y = 0 ; y < s.mask.rows ; y++ ) {
            for (int x = 0 ; x < s.mask.cols ; x++) {
                if (s.mask.at<uchar>(y, x) & 1) {
                    if (s.kMeansStartIndex == -1) {
                        s.kMeansStartIndex = pixels;
                    }
                    
                    pixels++;
                }
            }
        }
        
        s.kMeansLength = pixels - s.kMeansStartIndex;
    }
    
    // can't have less pixels than colors
    
    if (pixels < numColors) {
        numColors = pixels;
    }
    
    // generate the input for kmeans
    
    cv::Mat samples(pixels, 3, CV_32F);
    
    int pixel = 0;
    for (RBSwatchRect *s in marked) {
        for (int y = 0 ; y < s.mask.rows ; y++ ) {
            for (int x = 0 ; x < s.mask.cols ; x++) {
                if (s.mask.at<uchar>(y, x) & 1) {
                    for (int z = 0 ; z < 3 ; z++) {
                        samples.at<float>(pixel, z) = s.mat.at<cv::Vec3b>(y, x)[z];
                    }
                    
                    pixel++;
                }
            }
        }
    }
    
    // run kmeans
    
    cv::Mat labels;
    cv::Mat centers;
    int attempts = 5;
    int iterations = 30;
    kmeans(samples, numColors, labels, cv::TermCriteria(CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, iterations, 0.01), attempts, cv::KMEANS_PP_CENTERS, centers);
    
    kMeansColorIndexes = labels;
    
    colors = [NSMutableArray arrayWithCapacity:centers.rows];
    for (int i = 0 ; i < centers.rows ; i++) {
        colors[i] = [[RBSwatchColor alloc] initWithColor:[UIColor colorWithRed:centers.at<float>(i, 0) / 255 green:centers.at<float>(i, 1) / 255 blue:centers.at<float>(i, 2) / 255 alpha:1.0]];
    }
    
    [self processColors];
}

#pragma mark - Step 5 - Color Minimization

- (NSArray *)sortedColorArray
{
    return [colors sortedArrayUsingComparator:^NSComparisonResult(RBSwatchColor *obj1, RBSwatchColor *obj2) {
        if (obj1.removedColor < obj2.removedColor) {
            return NSOrderedAscending;
        } else if (obj1.removedColor > obj2.removedColor) {
            return NSOrderedDescending;
            
        } else if (obj1.importance > obj2.importance) {
            return NSOrderedAscending;
        } else if (obj1.importance < obj2.importance) {
            return NSOrderedDescending;
            
        } else if (obj1.pixels > obj2.pixels) {
            return NSOrderedAscending;
        } else if (obj1.pixels < obj2.pixels) {
            return NSOrderedDescending;
            
        } else {
            return NSOrderedSame;
        }
    }];
}

- (void)findMinDist:(NSUInteger)i
{
    RBSwatchColor *c = colors[i];
    
    if (c.importance != -1) {
        return;
    }
    
    CGFloat dist = MAXFLOAT;
    NSUInteger distI = colors.count;
    
    NSUInteger I = 0;
    while (I < colors.count) {
        RBSwatchColor *C = colors[I];
        
        if (C.importance == -1) {
            CGFloat d = [c.color distanceToColor:C.color];
            
            if (i != I && d < dist) {
                dist = d;
                distI = I;
            }
        }
        
        I++;
    }
    
    c.minDistIndex = distI;
    c.minDist = dist;
}

- (void)setColorImportance
{
    for (int iter = 0 ; iter < colors.count ; iter++) {
        for (int i = 0 ; i < colors.count ; i++) {
            [self findMinDist:i];
        }
        
        CGFloat minCost = -1;
        int minIndex = -1;
        for (int i = 0 ; i < colors.count ; i++) {
            RBSwatchColor *c = colors[i];
            
            if (c.importance == -1) {
                CGFloat cost = c.pixels * c.minDist;
                if (minCost == -1 || cost < minCost) {
                    minIndex = i;
                    minCost = cost;
                }
            }
        }
        
        if (minIndex > -1) {
            RBSwatchColor *c = colors[minIndex];
            c.importance = iter + 1; // zero is for removed colors
            
        } else {
            break;
        }
    }
}

- (CGFloat)colorPercent:(RBSwatchColor *)c minPercent:(CGFloat)minPercent
{
    int index = (int)[colors indexOfObject:c];
    int hist[colors.count];
    int pixels = 0;
    
    int i = 0;
    for (RBSwatchColor *c in colors) {
        if (!c.removedColor) {
            pixels += c.pixels;
            hist[i] = c.pixels;
        } else {
            hist[i] = 0;
        }
        i++;
    }
    
    if (pixels == 0) {
        return 0;
    }
    
    int minPixels = minPercent * pixels;
    if (minPixels > 0) {
        int pixelsToSteal = 0;
        int stealingPool = 0;
        
        int i = 0;
        for (RBSwatchColor *c in colors) {
            if (!c.removedColor) {
                if (c.pixels < minPixels) {
                    pixelsToSteal += minPixels - c.pixels;
                    hist[i] = minPixels;
                } else {
                    stealingPool += c.pixels - minPixels;
                }
            }
            i++;
        }
        
        if (pixelsToSteal > 0) {
            int i = 0;
            for (RBSwatchColor *c in colors) {
                if (!c.removedColor && c.pixels > minPixels) {
                    hist[i] -= (CGFloat)pixelsToSteal * (CGFloat)(hist[i] - minPixels) / (CGFloat)stealingPool;
                }
                i++;
            }
        }
    }
    
    return (CGFloat)hist[index] / (CGFloat)pixels;
}

- (void)minimizeColorsWithDistanceThreshold:(CGFloat)distance
{
    if (status != swatchStatusKMeans) {
        NSLog(@"Can't run minimizeColorsWithDistanceThreshold until kMeans has been run.");
        return;
    }
    
    BOOL didSomething;
    do {
        didSomething = NO;
        
        [self setColorImportance];
        NSArray *sorted = [self sortedColorArray];
        
        RBSwatchColor *colorToRemove;
        for (RBSwatchColor *c in sorted) {
            if (c.minDist > distance || c.removedColor) {
                continue;
            }
            
            colorToRemove = c;
            break;
        }
        
        if (colorToRemove) {
            didSomething = YES;
            
            RBSwatchColor *colorToKeep = colors[colorToRemove.minDistIndex];
            
            CGFloat L1, L2, a1, a2, b1, b2;
            [colorToKeep.color getL:&L1 a:&a1 b:&b1];
            [colorToRemove.color getL:&L2 a:&a2 b:&b2];
            
            CGFloat percent;
            if (colorToKeep.pixels + colorToRemove.pixels > 0) {
                percent = (CGFloat)colorToRemove.pixels / (CGFloat)(colorToKeep.pixels + colorToRemove.pixels);
            } else {
                percent = 0.5;
            }
            
            L1 += (L2 - L1) * percent;
            a1 += (a2 - a1) * percent;
            b1 += (b2 - b1) * percent;
            
            colorToKeep.color = [UIColor colorWithLightness:L1 A:a1 B:b1 alpha:1.0];
            colorToKeep.pixels += colorToRemove.pixels;
            colorToRemove.removedColor = YES;
            colorToRemove.mergedIntoColor = colorToKeep;
        }
        
    } while (didSomething);
}

#pragma mark - Step 6 - Read colorArray

- (NSArray *)colorArray
{
    NSArray *sorted = [self sortedColorArray];
    
    NSMutableArray *temp = [NSMutableArray array];
    for (RBSwatchColor *c in sorted) {
        if (c.removedColor) {
            continue;
        }
        
        [temp addObject:c.color];
    }
    
    return temp;
}

#pragma mark - Debug - Get Image

- (UIImage *)UIImageWithAlphaFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 // width
                                        cvMat.rows,                                 // height
                                        8,                                          // bits per component
                                        8 * cvMat.elemSize(),                       // bits per pixel
                                        cvMat.step[0],                              // bytesPerRow
                                        colorSpace,                                 // colorspace
                                        kCGImageAlphaLast | kCGBitmapByteOrderDefault,
                                        provider,                                   // CGDataProviderRef
                                        NULL,                                       // decode
                                        false,                                      // should interpolate
                                        kCGRenderingIntentDefault                   // intent
                                        );
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (UIImage *)getImageWithBackgroundColor:(UIColor *)bgColor andRemovedColor:(UIColor *)removedColor andSwatchColorAlpha:(CGFloat)alpha
{
    if (status < swatchStatusKMeans) {
        NSLog(@"Can't run getImage until kMeans has been run.");
        return nil;
    }
    
    CGFloat rF;
    CGFloat gF;
    CGFloat bF;
    CGFloat aF;
    [bgColor getRed:&rF green:&gF blue:&bF alpha:&aF];
    
    uchar bgRed = rF * 255;
    uchar bgGreen = gF * 255;
    uchar bgBlue = bF * 255;
    uchar bgAlpha = aF * 255;
    
    // pass one sets up the image and keeps track of the face colors
    
    cv::Mat newImage(self.image.size.height, self.image.size.width, CV_8UC4);
    for (int y = 0 ; y < self.image.size.height ; y++) {
        for (int x = 0 ; x < self.image.size.width ; x++) {
            newImage.at<cv::Vec4b>(y, x) = {bgRed, bgGreen, bgBlue, bgAlpha};
        }
    }
    
    for (RBSwatchRect *r in marked) {
        [r kMeansMat:kMeansColorIndexes intoMat:newImage withColors:colors andRemovedColor:removedColor andAlpha:alpha];
    }
    
    UIImage *returnedImage = [self UIImageWithAlphaFromCVMat:newImage];
    
    return returnedImage;
}

#pragma mark - DEBUG - Create a view with the dominant colors

- (void)populateColorsIntoView:(UIView *)v
{
    if (status != swatchStatusKMeans) {
        NSLog(@"Can't run populateColorsIntoView until kMeans has been run.");
        return;
    }
    
    for (UIView *sub in v.subviews) {
        [sub removeFromSuperview];
    }
    
    v.backgroundColor = [UIColor redColor];
    
    NSArray *sorted = [self sortedColorArray];
    
    int numColors = 0;
    for (RBSwatchColor *c in sorted) {
        if (c.removedColor) {
            continue;
        }
        
        numColors++;
    }
    
    if (numColors == 0) {
        return;
    }
    
    CGFloat progress = 0;
    for (RBSwatchColor *c in sorted) {
        if (c.removedColor) {
            continue;
        }
        
        UIView *bar = [[UIView alloc] init];
        bar.backgroundColor = c.color;
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        [v addSubview:bar];
        
        CGFloat percent = [self colorPercent:c minPercent:1.0 / numColors];
        
        [v addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bar]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bar)]];
        
        [v addConstraint:[NSLayoutConstraint constraintWithItem:bar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeRight multiplier:progress constant:0.0]];
        [v addConstraint:[NSLayoutConstraint constraintWithItem:bar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeWidth multiplier:percent constant:0.0]];
        
        if (c.removedColor) {
            UIView *bottomBar = [[UIView alloc] init];
            bottomBar.backgroundColor = [UIColor redColor];
            bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
            [v addSubview:bottomBar];
            
            [v addConstraint:[NSLayoutConstraint constraintWithItem:bottomBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeRight multiplier:progress constant:0.0]];
            [v addConstraint:[NSLayoutConstraint constraintWithItem:bottomBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeWidth multiplier:percent constant:0.0]];
            [v addConstraint:[NSLayoutConstraint constraintWithItem:bottomBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
            [v addConstraint:[NSLayoutConstraint constraintWithItem:bottomBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:v attribute:NSLayoutAttributeHeight multiplier:0.1 constant:0.0]];
        }
        
        progress += percent;
    }
}

@end