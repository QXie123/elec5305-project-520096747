# ELEC5305: preliminary acoustic Doppler motion estimator

Author: Qirui Xie · GitHub: qxie123

Project site: https://qxie123.github.io/elec5305-project-520096747/

## Purpose

This preliminary code implements a controlled single-tone pass-by simulation,
windowed FFT analysis, frequency-ridge tracking and nonlinear least-squares
motion estimation. It is intended for Project Feedback 2 and responds to the
suggestion to move from Doppler visualisation to inverse motion estimation.

## How to run

1. Download `run_doppler_demo.m` and open it in MATLAB R2024a.
2. Press **Run**. The script uses base MATLAB functions; no optimisation or
   signal-processing toolbox is required.
3. Read the printed estimates and inspect the generated `results` folder.

Outputs: three PNG figures, a received-signal WAV file, estimated-parameter CSV,
frequency-track CSV, and a MAT workspace. Upload the generated figures and CSV
to GitHub after running and reviewing them.

## Model

Emission time `u` and reception time `t` are distinguished explicitly:

```
r(u) = sqrt(d^2 + v^2*(u-u0)^2)
t = u + r(u)/c
x(t) = (d/r(u))*sin(2*pi*f0*u)
f_received(t) = f0/(1 + r_prime(u)/c)
```

`u0` is the emission time of closest approach. Its signal reaches the receiver
at `u0 + d/c`; these two times must not be confused. The retarded-time relation
is inverted analytically for subsonic motion. Amplitude attenuation is a
simplified inverse-distance assumption, not a full moving-source radiation model.

## Baseline settings

| Setting | Value |
|---|---:|
| Sampling rate | 44,100 Hz |
| Duration | 10 s |
| Emitted frequency | 3,000 Hz |
| Sound speed | 343 m/s |
| Source speed | 10 m/s |
| Closest distance | 5 m |
| Closest-approach emission time | 5 s |
| Noise | None (`Inf` dB SNR) |
| Hann window length | 4,096 samples |
| Hop | 256 samples |
| FFT length | 16,384 samples |

Zero padding makes spectral interpolation finer; it does not improve the
physical frequency resolution set by the window duration.

## What the estimator does

- Finds the dominant spectral peak in a fixed band around the known tone.
- Uses a three-point log-magnitude interpolation for sub-bin frequencies.
- Fits speed, distance and closest-approach emission time with `fminsearch`.
- Uses multiple initial guesses and bounded admissible parameter ranges.
- Reports frequency RMSE, frequency bias, fitting residual RMSE and absolute
  parameter errors against the known simulation settings.

The estimator does not use the true speed or distance as fitting initial values.
The simulation and fit share a physical model, so this is an ideal-model baseline,
not independent real-world validation. The noisy variant uses global waveform
power to define SNR; local SNR varies with inverse-distance amplitude.

## Current status and limitations

The preliminary implementation has been written. MATLAB execution has not yet
been verified in the authoring environment. Do not report numerical MATLAB
results until the script has actually been run and inspected. No measured
recording or multi-harmonic comparison is included. Basic peak tracking has no
outlier rejection and may fail at low SNR. Short observations may poorly
constrain closest distance; a low fitting residual is not proof of identifiability.

## Next experiments

1. Run and validate the noiseless baseline against the known parameters.
2. Compare window lengths 2,048, 4,096 and 8,192 samples.
3. Test SNR values 20, 10, 5 and 0 dB over several random seeds.
4. Add multi-harmonic tracking and compare estimation errors with this baseline.
5. Validate against a controlled recording with independently measured speed.

## Attribution

This is AI-assisted preliminary code prepared for review and adaptation by the
student. Standard MATLAB FFT, optimisation, audio and plotting functions are
used; no third-party code has been copied. The student should understand,
validate and document changes in accordance with the course requirements.

Technical documentation:
- https://www.mathworks.com/help/matlab/ref/fft.html
- https://www.mathworks.com/help/matlab/ref/fminsearch.html

## Upload to the existing GitHub project

Keep the existing project website and README. Upload the MATLAB file and this
document without replacing existing files. After MATLAB execution, add the
`results` figures and summary CSV and link this document from the existing README.
