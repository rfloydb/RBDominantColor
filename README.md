# RBDominantColor

iOS tool for selecting the dominant colors in the foreground of an image using [opencv](http://opencv.org).

It was developed as part of [kloz.it](http://kloz.it), for determining the color of clothing from photos. It should be considered alpha code at this point, inasmuch as it only hits the mark about 60-80% of the time. There are many potential areas to optimize this algorithm to make it smarter.

## Getting Started

Drag the RBDominantColor directory into your project. The RBDominantColor directory includes the opencv framework, the RBDominantColor code, and the xml file used for face detection. Your project probably already uses UIKit, but if it doesn't, you will need to add it as well.

## Usage

```objective-c

#import "RBDominantColor.h"

RBDominantColor *dominantColors;

- (void)findDominantColors
{
    dominantColors = [[RBDominantColor alloc] init];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Provide RBDominantColors with an image
        UIImage *image = [UIImage imageNamed:@"test-image.jpg"];
        if (image) {
            [dominantColors setImage:image];
        } else {
            NSLog(@"Make sure to provide RBDominantColors with an image.");
            exit(-1);
        }
        
        // OPTIONAL: Call this to ignore skin in the foreground
        [dominantColors markFace];
        
        // Use markDefaultArea if you don't know where the foreground is in the image
        // Use markRect: or markPoint:withRadius:isForeground: if you know where the foreground is already
        [dominantColors markDefaultArea];
        
        // Remove Background
        [dominantColors grabCut];
        
        // Reduce colors to 16
        [dominantColors kMeans:16];
        
        // Eliminate similar colors
        [dominantColors minimizeColorsWithDistanceThreshold:20.0];
        
        [self performSelectorOnMainThread:@selector(dominantColorsDone) withObject:nil waitUntilDone:NO];
    });
}

- (void)dominantColorsDone
{
    // colorArray is an array of UIColors representing the dominant colors
    NSLog(@"%@", dominantColors.colorArray);
    
    // DEBUG - Create an image or image overlay that shows where the background is,
    // and where the dominant colors came from
    UIImage *debugImage = [dominantColors getImageWithBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.05] andRemovedColor:[UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.05] andSwatchColorAlpha:1.0];
    
    NSLog(@"%.0fx%.0f", debugImage.size.width, debugImage.size.height);
    
    UIView *colorView = [[UIView alloc] init];
    
    // DEBUG - Display the colorArray in a pre-existing view.
    // The view will be emptied out and repopulated with a subview for each element in colorArray
    [dominantColors populateColorsIntoView:colorView];
}

```
