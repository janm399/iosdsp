#import "FourierTransform.h"
#import <Accelerate/Accelerate.h>

@implementation FourierTransform {
    FFTSetup fftSetup;
    int logN;
    int n;
    int nHalf;
}

- (id)initWithSampleSize:(int)sampleSize {
    self = [super init];
    if (self) {
        logN = sampleSize;       // Typically this would be at least 10 (i.e. 2^logN = 1024pt FFTs).
        n = 1 << logN;
        nHalf = n / 2;
        
        // Set up a data structure with pre-calculated values for
        // doing a very fast FFT. The structure is opaque, but presumably
        // includes sin/cos twiddle factors, and a lookup table for converting
        // to/from bit-reversed ordering. Normally you'd create this once
        // in your application, then use it for many (hundreds! thousands!) of
        // forward and inverse FFTs.
        fftSetup = vDSP_create_fftsetup(logN, kFFTRadix2);
    }
    return self;
}

- (id)init {
    return [self initWithSampleSize:4];
}

- (bool)transform1D:(NSArray *)input to:(NSArray **)output withError:(NSError **)error {
    if (input.count > n) {
        if (error != nil) *error = [NSError errorWithDomain:@"FFT" code:kFourierTransformSampleTooBig userInfo:nil];
        return false;
    }
    if (output == nil) {
        if (error != nil) *error = [NSError errorWithDomain:@"FFT" code:kFourierTransformNoOutput userInfo:nil];
        return false;
    }

    // Buffers for real (time-domain) input and output signals.
    float *x = new float[n];
    
    // Initialize the input buffer with a sinusoid
    // int BIN = 5;
    for (int k = 0; k < n; k++) {
        if (input.count >= k) x[k] = [[input objectAtIndex:k] floatValue]; else x[k] = 0;
    }
    
    DSPSplitComplex tempSplitComplex;
    tempSplitComplex.realp = new float[nHalf];
    tempSplitComplex.imagp = new float[nHalf];
    
    // ----------------------------------------------------------------
    // Forward FFT
    
    // Scramble-pack the real data into complex buffer in just the way that's
    // required by the real-to-complex FFT function that follows.
    vDSP_ctoz((DSPComplex*)x, 2, &tempSplitComplex, 1, nHalf);
    
    // Do real->complex forward FFT
    vDSP_fft_zrip(fftSetup, &tempSplitComplex, 1, logN, kFFTDirection_Forward);
    
    // Print the complex spectrum. Note that since it's the FFT of a real signal,
    // the spectrum is conjugate symmetric, that is the negative frequency components
    // are complex conjugates of the positive frequencies. The real->complex FFT
    // therefore only gives us the positive half of the spectrum from bin 0 ("DC")
    // to bin N/2 (Nyquist frequency, i.e. half the sample rate). Typically with
    // audio code, you don't need to worry much about the DC and Nyquist values, as
    // they'll be very close to zero if you're doing everything else correctly.
    //
    // Bins 0 and N/2 both necessarily have zero phase, so in the packed format
    // only the real values are output, and these are stuffed into the real/imag components
    // of the first complex value (even though they are both in fact real values). Try
    // replacing BIN above with N/2 to see how sinusoid at Nyquist appears in the spectrum.
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:nHalf];
    for (int k = 0; k < nHalf; k++) {
        float re = tempSplitComplex.realp[k];
        float im = tempSplitComplex.imagp[k];
        // computer power in dB
        float pow = log2f(re * re + im * im);
        [result addObject:[NSNumber numberWithFloat:pow]];
    }
    *output = result;
    
    delete tempSplitComplex.realp;
    delete tempSplitComplex.imagp;
    
    return true;
}

- (void)demo {
    // Buffers for real (time-domain) input and output signals.
    float *x = new float[n];
    float *y = new float[n];
    
    // Initialize the input buffer with a sinusoid
    int BIN = 5;
    for (int k = 0; k < n; k++) x[k] = cos(2 * M_PI * BIN * k / n);
    
    // We need complex buffers in two different formats!
    DSPComplex *tempComplex = new DSPComplex[nHalf];
    
    DSPSplitComplex tempSplitComplex;
    tempSplitComplex.realp = new float[nHalf];
    tempSplitComplex.imagp = new float[nHalf];
    
    // For polar coordinates
    float *mag = new float[nHalf];
    float *phase = new float[nHalf];
    
    // ----------------------------------------------------------------
    // Forward FFT
    
    // Scramble-pack the real data into complex buffer in just the way that's
    // required by the real-to-complex FFT function that follows.
    vDSP_ctoz((DSPComplex*)x, 2, &tempSplitComplex, 1, nHalf);
    
    // Do real->complex forward FFT
    vDSP_fft_zrip(fftSetup, &tempSplitComplex, 1, logN, kFFTDirection_Forward);
    
    // Print the complex spectrum. Note that since it's the FFT of a real signal,
    // the spectrum is conjugate symmetric, that is the negative frequency components
    // are complex conjugates of the positive frequencies. The real->complex FFT
    // therefore only gives us the positive half of the spectrum from bin 0 ("DC")
    // to bin N/2 (Nyquist frequency, i.e. half the sample rate). Typically with
    // audio code, you don't need to worry much about the DC and Nyquist values, as
    // they'll be very close to zero if you're doing everything else correctly.
    //
    // Bins 0 and N/2 both necessarily have zero phase, so in the packed format
    // only the real values are output, and these are stuffed into the real/imag components
    // of the first complex value (even though they are both in fact real values). Try
    // replacing BIN above with N/2 to see how sinusoid at Nyquist appears in the spectrum.
    printf("\nSpectrum:\n");
    for (int k = 0; k < nHalf; k++) {
        printf("%3d\t%6.2f\t%6.2f\n", k, tempSplitComplex.realp[k], tempSplitComplex.imagp[k]);
    }
    
    // ----------------------------------------------------------------
    // Convert from complex/rectangular (real, imaginary) coordinates
    // to polar (magnitude and phase) coordinates.
    
    // Compute magnitude and phase. Can also be done using vDSP_polar.
    // Note that when printing out the values below, we ignore bin zero, as the
    // real/complex values for bin zero in tempSplitComplex actually both correspond
    // to real spectrum values for bins 0 (DC) and N/2 (Nyquist) respectively.
    vDSP_zvabs(&tempSplitComplex, 1, mag, 1, nHalf);
    vDSP_zvphas(&tempSplitComplex, 1, phase, 1, nHalf);
    
    printf("\nMag / Phase:\n");
    for (int k = 1; k < nHalf; k++) {
        printf("%3d\t%6.2f\t%6.2f\n", k, mag[k], phase[k]);
    }
    
    // ----------------------------------------------------------------
    // Convert from polar coordinates back to rectangular coordinates.
    
    tempSplitComplex.realp = mag;
    tempSplitComplex.imagp = phase;
    
    vDSP_ztoc(&tempSplitComplex, 1, tempComplex, 2, nHalf);
    vDSP_rect((float*)tempComplex, 2, (float*)tempComplex, 2, nHalf);
    vDSP_ctoz(tempComplex, 2, &tempSplitComplex, 1, nHalf);
    
    // ----------------------------------------------------------------
    // Do Inverse FFT
    
    // Do complex->real inverse FFT.
    vDSP_fft_zrip(fftSetup, &tempSplitComplex, 1, logN, kFFTDirection_Inverse);
    
    // This leaves result in packed format. Here we unpack it into a real vector.
    vDSP_ztoc(&tempSplitComplex, 1, (DSPComplex*)y, 2, nHalf);
    
    // Neither the forward nor inverse FFT does any scaling. Here we compensate for that.
    float scale = 0.5 / n;
    vDSP_vsmul(y, 1, &scale, y, 1, n);
    
    // Assuming it's all correct, the input x and output y vectors will have identical values
    printf("\nInput & output:\n");
    for (int k = 0; k < n; k++) {
        printf("%3d\t%6.2f\t%6.2f\n", k, x[k], y[k]);
    }
}

@end
