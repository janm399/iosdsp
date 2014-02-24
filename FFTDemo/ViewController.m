#import "ViewController.h"
#import "FourierTransform.h"

@interface ViewController ()

@end

@implementation ViewController {
    FourierTransform *fft;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    fft = [[FourierTransform alloc] initWithSampleSize:4];
    // This four is important, because we'll be        ^
    // sending samples containing 2^4 elements         |
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/** 
 Depending on the UI selector, returns the appropriate 1D signal
 @return ``NSArray`` containing ``NSFloat``s
 */
- (NSArray *)oneDimSignal {
    switch (self.oneDimSignalSegmentedControl.selectedSegmentIndex) {
        /* Square signal with nice sharp edges.
          1.0  _   _   _
          0.5   | | | | |
          0.0   | | | | |  ...
         -0.5   | | | | |
         -1.0   |_| |_| |_
        */
        case 0: return @[@1.0f, @-1.0f, @1.0f, @-1.0f,
                         @1.0f, @-1.0f, @1.0f, @-1.0f,
                         @1.0f, @-1.0f, @1.0f, @-1.0f,
                         @1.0f, @-1.0f, @1.0f, @-1.0f];
        /* Half-amplitude triangle signal
         1.0  _       _
         0.5   |_   _| |_   ...
         0.0     |_|     |_
         
         */
        case 1: return @[@1.0f, @0.5f, @0.0f, @0.5f,
                         @1.0f, @0.5f, @0.0f, @0.5f,
                         @1.0f, @0.5f, @0.0f, @0.5f,
                         @1.0f, @0.5f, @0.0f, @0.5f];
        /* DC signal (not good!)
          1.0
          0.5
          0.0  ______________ ....
         -0.5
         -1.0
         
         */
        case 2: return @[@0.0f, @0.0f, @0.0f, @0.0f,
                         @0.0f, @0.0f, @0.0f, @0.0f,
                         @0.0f, @0.0f, @0.0f, @0.0f,
                         @0.0f, @0.0f, @0.0f, @0.0f];
    }
    @throw @"Bad selector";
}

- (IBAction)oneDimFFT:(id)sender
{
    NSArray* output;
    NSError* error;
    [fft transform1D:[self oneDimSignal] to:&output withError:&error];
    [self.resultTextView setText:[NSString stringWithFormat:@"%@", output]];
}

- (IBAction)twoDimFFT:(id)sender
{
    // Ponies & unicorns
}

@end

