# ELEC5305 | Acoustic Doppler Motion Estimation

Qirui Xie · 520096747

[Report](ELEC5305_Doppler_Final_Report.pdf) · [Project site](https://qxie123.github.io/elec5305-project-520096747/)

## Run

Install Python dependencies with `python -m pip install -r requirements.txt`.
Run `python run_experiment.py` from this folder. The script writes 432
parameter estimates, aggregated metrics, figures and two simulated WAV
examples into `results/`. The original MATLAB single-tone baseline is
`run_doppler_demo.m`. Run that script separately in MATLAB to reproduce
the preliminary example. It creates its own files under `results/`.

## Example results

At 4096 samples and 0 dB, mean ridge RMSE is 0.427 Hz for the
fundamental and 9.853 Hz for fixed harmonic fusion. At 10 dB, it is
0.135 Hz and 0.060 Hz respectively. See the report for motion errors.

The three comparators are fundamental-only tracking, fixed weighted harmonic fusion, and framewise median fusion. The packaged trial_spread.png compares the paired trials at 0 dB.

## Demonstration

See [recording notes](DEMO_SCRIPT.md). 



[Watch the project demonstration](https://drive.google.com/file/d/1GYqKhLjZ_48jbnXYytBexktqN6X0FGxq/view?usp=sharing)
