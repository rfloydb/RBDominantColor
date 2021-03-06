//
//  ViewController.m
//  RBDominantColorExample
//
//  Created by Rob Brackett on 3/12/15.
//
//

#import "ViewController.h"
#import "RBDominantColor.h"

@interface ViewController ()

@end

@implementation ViewController {
    UIImageView *imageView;
    UIImageView *resultImageView;
    UIImageView *resultImageViewBackground;
    UIView *colorView;
    UILabel *timeLabel;
    
    UILabel *imageViewLabel;
    UILabel *resultImageViewLabel;
    UILabel *resultImageViewHelpLabel;
    UIButton *startButton;

    UISlider *maxPixelsSlider;
    UISlider *kMeansColorsSlider;
    UISlider *minimizeColorsSlider;
    UILabel *paramsLabel;
    
    NSTimeInterval startTime;
    
    RBDominantColor *dominantColors;
}

#pragma mark - RBDominantColor Example

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    dominantColors = [[RBDominantColor alloc] init];

    [self setupView];
}

- (void)buttonPressed
{
    startButton.enabled = NO;
    
    startTime = [NSDate timeIntervalSinceReferenceDate];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [dominantColors setImage:[UIImage imageNamed:@"test-image.jpg"]];
        [dominantColors markFace];
        [dominantColors markDefaultArea];
        [dominantColors grabCut];
        [dominantColors kMeans:(int)kMeansColorsSlider.value];
        [dominantColors minimizeColorsWithDistanceThreshold:minimizeColorsSlider.value];
        
        [self performSelectorOnMainThread:@selector(setResultImage) withObject:nil waitUntilDone:NO];
    });
}

- (void)setResultImage
{
    timeLabel.text = [NSString stringWithFormat:@"Time Taken: %.3f secs", [NSDate timeIntervalSinceReferenceDate] - startTime];
    
    resultImageView.image = [dominantColors getImageWithBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.05] andRemovedColor:[UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.05] andSwatchColorAlpha:1.0];
    
    [dominantColors populateColorsIntoView:colorView];

    startButton.enabled = YES;
}

#pragma mark - User Interface

- (void)setParamsLabelText
{
    paramsLabel.text = [NSString stringWithFormat:@"maxPixels: %d\nkMeans Colors: %d\nminimizeColors Distance: %.1f", dominantColors.maxPixels, (int)kMeansColorsSlider.value, minimizeColorsSlider.value];;
}

- (void)maxPixelsChanged
{
    dominantColors.maxPixels = (int)powf(10.0, maxPixelsSlider.value);
    [self setParamsLabelText];
}

- (void)kMeansColorsChanged
{
    [self setParamsLabelText];
}

- (void)minimizeColorsChanged
{
    [self setParamsLabelText];
}

- (void)setupView
{
    UIImage *testImage = [UIImage imageNamed:@"test-image.jpg"];
    
    imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView setImage:testImage];
    
    imageViewLabel = [[UILabel alloc] init];
    imageViewLabel.text = @"Reference Image";
    imageViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
    imageViewLabel.textAlignment = NSTextAlignmentCenter;
    
    resultImageViewBackground = [[UIImageView alloc] init];
    resultImageViewBackground.contentMode = UIViewContentModeScaleAspectFit;
    [resultImageViewBackground setImage:testImage];
    resultImageViewBackground.alpha = 0.1;

    resultImageView = [[UIImageView alloc] init];
    resultImageView.contentMode = UIViewContentModeScaleAspectFit;

    resultImageViewLabel = [[UILabel alloc] init];
    resultImageViewLabel.text = @"Foreground Isolated";
    resultImageViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
    resultImageViewLabel.textAlignment = NSTextAlignmentCenter;
    
    resultImageViewHelpLabel = [[UILabel alloc] init];
    resultImageViewHelpLabel.numberOfLines = 0;
    resultImageViewHelpLabel.lineBreakMode = NSLineBreakByWordWrapping;
    resultImageViewHelpLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
    resultImageViewHelpLabel.textColor = [UIColor grayColor];
    resultImageViewHelpLabel.text = @"RED - Background\nYELLOW - Foreground Removed by Skin Color Detection";
    resultImageViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
    
    startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startButton setTitle:@"Find Dominant Foreground Colors" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    colorView = [[UIView alloc] init];
    colorView.layer.borderColor = [UIColor blackColor].CGColor;
    colorView.layer.borderWidth = 0.5;
    colorView.layer.cornerRadius = 4.0;
    colorView.clipsToBounds = YES;
    
    timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.text = @"";
    
    maxPixelsSlider = [[UISlider alloc] init];
    maxPixelsSlider.maximumValue = log10f(3264 * 2448);
    maxPixelsSlider.minimumValue = log10f(64 * 64);
    maxPixelsSlider.value = log10f(dominantColors.maxPixels);
    [maxPixelsSlider addTarget:self action:@selector(maxPixelsChanged) forControlEvents:UIControlEventValueChanged];

    kMeansColorsSlider = [[UISlider alloc] init];
    kMeansColorsSlider.maximumValue = 128;
    kMeansColorsSlider.minimumValue = 2;
    kMeansColorsSlider.value = 16;
    [kMeansColorsSlider addTarget:self action:@selector(kMeansColorsChanged) forControlEvents:UIControlEventValueChanged];
    
    minimizeColorsSlider = [[UISlider alloc] init];
    minimizeColorsSlider.maximumValue = 116;
    minimizeColorsSlider.minimumValue = 0;
    minimizeColorsSlider.value = 20;
    [minimizeColorsSlider addTarget:self action:@selector(minimizeColorsChanged) forControlEvents:UIControlEventValueChanged];
    
    paramsLabel = [[UILabel alloc] init];
    paramsLabel.numberOfLines = 0;
    paramsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    paramsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
    paramsLabel.textColor = [UIColor grayColor];
    [self setParamsLabelText];
    paramsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.0];

    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageViewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    resultImageViewBackground.translatesAutoresizingMaskIntoConstraints = NO;
    resultImageView.translatesAutoresizingMaskIntoConstraints = NO;
    resultImageViewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    resultImageViewHelpLabel.translatesAutoresizingMaskIntoConstraints = NO;
    colorView.translatesAutoresizingMaskIntoConstraints = NO;
    startButton.translatesAutoresizingMaskIntoConstraints = NO;
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    maxPixelsSlider.translatesAutoresizingMaskIntoConstraints = NO;
    kMeansColorsSlider.translatesAutoresizingMaskIntoConstraints = NO;
    minimizeColorsSlider.translatesAutoresizingMaskIntoConstraints = NO;
    paramsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:imageView];
    [self.view addSubview:imageViewLabel];
    [self.view addSubview:resultImageViewBackground];
    [self.view addSubview:resultImageView];
    [self.view addSubview:resultImageViewLabel];
    [self.view addSubview:resultImageViewHelpLabel];
    [self.view addSubview:colorView];
    [self.view addSubview:startButton];
    [self.view addSubview:timeLabel];
    [self.view addSubview:maxPixelsSlider];
    [self.view addSubview:kMeansColorsSlider];
    [self.view addSubview:minimizeColorsSlider];
    [self.view addSubview:paramsLabel];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[imageView]-8-[resultImageView(==imageView)]-8-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(imageView, resultImageView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[imageViewLabel]-8-[resultImageViewLabel(==imageViewLabel)]-8-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(imageViewLabel, resultImageViewLabel)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[colorView]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(colorView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[startButton]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(startButton)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[timeLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(timeLabel)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[maxPixelsSlider]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(maxPixelsSlider)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[kMeansColorsSlider]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(kMeansColorsSlider)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[minimizeColorsSlider]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(minimizeColorsSlider)]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-24-[imageView]-4-[imageViewLabel]-4-[resultImageViewHelpLabel]-4-[maxPixelsSlider]-4-[kMeansColorsSlider]-4-[minimizeColorsSlider]-4-[startButton]-4-[colorView(30)]-4-[timeLabel]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView, imageViewLabel, resultImageViewHelpLabel, maxPixelsSlider, kMeansColorsSlider, minimizeColorsSlider, startButton, colorView, timeLabel)]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeWidth multiplier:testImage.size.height / testImage.size.width constant:0.0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageViewHelpLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:resultImageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageViewHelpLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:resultImageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:paramsLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:paramsLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:resultImageViewHelpLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:paramsLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageViewBackground attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:resultImageView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageViewBackground attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:resultImageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageViewBackground attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:resultImageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:resultImageViewBackground attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:resultImageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
}

@end
