# RBDominantColor

iOS tool for selecting the dominant colors in the foreground of an image using [opencv](http://opencv.org).

It was developed as part of [kloz.it](http://kloz.it), for determining the color of clothing from photos.

## Getting Started

Drag the src directory into your project. This should include the opencv framework, the RBDominantColor code, and the xml file used for face detection.

**Please Note:** RBDominantColor makes use of Objective C++, so you will need to change your build settings to compile your sources as Objective C++. This can be found under *Build Settings* -> *Apple LLVM - Language* -> *Compile Sources As*.

*TODO:* Make this work using the default option (Compile Sources As = According to File Type).

## Usage

```objective-c

- (void)findDominantColors
{
	dominantColors = [[RBDominantColor alloc] init];

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[dominantColors setImage:[UIImage imageNamed:@"test-image.jpg"]];

		// OPTIONAL: Ignore Skin
		[dominantColors markFace];

		// Use this OR markRect: OR markPoint:withRadius:isForeground: if you know where the foreground is already
		[dominantColors markDefaultArea];

		// Remove Background
		[dominantColors grabCut];

		// Reduce Colors
		[dominantColors kMeans:int(kMeansColorsSlider.value)];

		// Eliminate Similar Colors
		[dominantColors minimizeColorsWithDistanceThreshold:minimizeColorsSlider.value];

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
    
    // DEBUG - Display the colorArray in a pre-existing view.
    // The view will be emptied out and repopulated with a subview for each element in colorArray
    [dominantColors populateColorsIntoView:colorView];
}

```
