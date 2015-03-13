//
//  ViewController.m
//  RBDominantColorExample
//
//  Created by Rob Brackett on 3/12/15.
//
//

#import "ViewController.h"
#import "opencv2/highgui/ios.h"
#import "RBDominantColor.h"
#import "SwatchColor.h"
#import "UIImage+Resize.h"

@interface ViewController ()

@end

@implementation ViewController {
    UIImageView *imageView;
    UIImageView *overlayImageView;
    
    UIView *histView;
    
    NSTimeInterval startTime;
    UILabel *timeLabel;
    
    RBDominantColor *s;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    s = [[RBDominantColor alloc] init];
    
    imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView setImage:[UIImage imageNamed:@"test-image.jpg"]];
    
    overlayImageView = [[UIImageView alloc] init];
    overlayImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    histView = [[UIView alloc] init];
    histView.backgroundColor = [UIColor blackColor];
    
    timeLabel = [[UILabel alloc] init];
    timeLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    overlayImageView.translatesAutoresizingMaskIntoConstraints = NO;
    histView.translatesAutoresizingMaskIntoConstraints = NO;
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:imageView];
    [self.view addSubview:overlayImageView];
    [self.view addSubview:histView];
    [self.view addSubview:timeLabel];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[histView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(histView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-40-[timeLabel]-40-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(timeLabel)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[imageView]-10-[histView(30)]-10-[timeLabel(30)]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView, histView, timeLabel)]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:overlayImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:overlayImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:overlayImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:overlayImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];

    timeLabel.text = @"";
    startTime = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [s setImage:[UIImage imageNamed:@"test-image.jpg"]];
        [s markFace];
        [s markDefaultArea];
        [s grabCut];
        [s kMeans:16];
        
        [self performSelectorOnMainThread:@selector(setGrabCutImage) withObject:nil waitUntilDone:NO];
    });
}

- (void)setGrabCutImage
{
    timeLabel.text = [NSString stringWithFormat:@"%.3f secs", [NSDate timeIntervalSinceReferenceDate] - startTime];
    
    overlayImageView.image = [s getImageWithBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] andRemovedColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] andSwatchColorAlpha:0.0];
    
    [s minimizeColorsWithDistanceThreshold:20.0];
    
    [s populateColorsIntoView:histView];
}

@end
