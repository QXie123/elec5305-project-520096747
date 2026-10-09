# Doppler-Based Motion Estimation Using Multi-Harmonic Time-Frequency Analysis


## Project Overview
This ELEC5305 project investigates acoustic Doppler-based motion estimation using MATLAB and Short-Time Fourier Transform (STFT).


The project aims to estimate the speed and closest-approach distance of a moving sound source from the frequency variations recorded by a stationary microphone.


## Project Objectives
- Simulate acoustic Doppler signals.
- Analyse Doppler frequency changes using STFT.
- Extract instantaneous-frequency trajectories.
- Estimate source motion parameters.
- Compare single-harmonic and multi-harmonic estimation.


## Project Progress — Feedback 2
This project has been revised following the initial teaching staff feedback. The research focus has been extended from forward Doppler simulation to inverse motion estimation.


A preliminary single-tone MATLAB implementation has been added in [run_doppler_demo.m](run_doppler_demo.m). It includes retarded-time Doppler simulation, STFT analysis, interpolated frequency-ridge extraction and nonlinear fitting of speed, closest distance and closest-approach emission time.

See [README_PRELIMINARY.md](README_PRELIMINARY.md) for the model, parameters, limitations and run instructions. The implementation is AI-assisted and requires student review. MATLAB execution and numerical results remain pending.


## Preliminary Results
MATLAB simulation results, spectrograms and frequency estimation plots will be added after validation.


## Future Work
- Run and validate the preliminary simulation, frequency tracker and motion estimator in MATLAB.
- Upload the generated spectrogram, frequency-fit figures and estimation-summary CSV.
- Evaluate performance under different SNR levels.
- Compare STFT window lengths and multi-harmonic methods.


## Software
MATLAB


## Course
ELEC5305 — Acoustics, Speech and Signal Processing



## Running the Preliminary Code

Download `run_doppler_demo.m`, open it in MATLAB R2024a and press Run. The script creates a `results` folder containing three figures, a WAV signal, CSV results and a MAT workspace. The baseline uses a 3,000 Hz tone, 10 m/s source speed and 5 m closest distance. These are simulation settings, not measured results.
