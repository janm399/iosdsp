#import <Foundation/Foundation.h>

enum {
    kFourierTransformSampleTooBig = 401,
    kFourierTransformNoOutput = 402
} FastFourierTransformErrors;

@interface FourierTransform : NSObject
/**
 Constructs this instance with default values: sampleSize = 4
 */
- (id)init;

/**
 Constructs this instance and sets the ``sampleSize``. 
 The inputs to the 1D and 2D transforms should then contain [at most] ``2 ^ sampleSize`` values.

 @param sampleSize the sample size in powers of two.
 */
- (id)initWithSampleSize:(int)sampleSize;

/**
 Performs 2D forward FFT on the ``input`` containing no more than ``2 ^ sampleSize`` ``NSFloat`` elements.
 If successful, returns ``true`` and mutates the value in ``*output``; if unsuccessful, returns ``false`` and
 sets ``*error``, unless it is ``nil``.
 
 @see FastFourierTransformErrors
 @param input the input containing no more than ``2 ^ sampleSize`` ``NSFloat``s
 @param output the output that will receive the powers; never ``nil``.
 @param error value that can receive error details.
 @return ``true`` on success.
 */
- (bool)transform1D:(NSArray *)input to:(NSArray **)output withError:(NSError **)error;

@end
