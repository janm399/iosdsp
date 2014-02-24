#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction)oneDimFFT:(id)sender;
- (IBAction)twoDimFFT:(id)sender;
@property UISegmentedControl IBOutlet *oneDimSignalSegmentedControl;
@property UITextView IBOutlet *resultTextView;

@end
