# Demonstration | approximately two minutes

1. Open a terminal in the project folder and run python run_experiment.py.
   Show the live run briefly, then use the completed results to avoid a long wait.
   “My question is whether combining three harmonic tracks improves estimates
   of speed, closest distance and pass-by time from a stationary microphone.”
2. Show model(), extract() and fit() in the code. Play results/clean_passby.wav
   and results/noisy_passby_0dB.wav briefly.
   “The simulator models propagation delay. The received tones rise in
   frequency during approach and fall during recession. The two methods
   receive the same test signal. One follows only the fundamental, while the
   other estimates three fundamental-equivalent tracks. I compare a fixed weighted average with a framewise median.”
3. Open results/errors.png and results/summary.csv.
   “I tested twelve noise realisations per condition. At a 4096-sample window
   and 10 dB, fusion reduced ridge error from 0.135 to 0.060 Hz. At 0 dB
   the error rose from 0.427 to 9.853 Hz. Incorrect peaks in the weaker
   harmonics can distort the fit. Better ridge error does not consistently
   translate to better motion estimates. The trial-spread plot shows whether the median reduces those large errors.”
4. Show results/tracks.png and the report conclusion.
   “These are controlled simulations with known emitted frequencies.
   I would next reject inconsistent peaks and validate with a measured
   pass-by recording.”

Upload the recording to Canvas. Add the shareable video URL to the
GitHub project site and the report before final submission.

