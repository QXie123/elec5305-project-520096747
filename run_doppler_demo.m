%% ELEC5305: preliminary acoustic Doppler motion estimator
% Qirui Xie. AI-assisted preliminary implementation, October 2026.
% Base MATLAB only. Run this script; outputs are saved beside the script.
% MATLAB execution has not yet been verified in the authoring environment.
clear; close all; clc;
rng(7);
root = fileparts(mfilename('fullpath'));
out = fullfile(root, 'results');
if ~exist(out, 'dir'), mkdir(out); end

cfg.fs = 44100;
cfg.duration = 10;
cfg.f0 = 3000;
cfg.c = 343;
cfg.v = 10;
cfg.d = 5;
cfg.u0 = 5;              % emission time of closest approach, seconds
cfg.snrDb = Inf;         % noiseless baseline; try 20, 10, 5, 0 later
cfg.windowLength = 4096;
cfg.hop = 256;
cfg.nfft = 16384;        % zero padding interpolates the spectrum

t = (0:1/cfg.fs:cfg.duration-1/cfg.fs).';
[u, r, trueFreq] = doppler_model(t,cfg.v,cfg.d,cfg.u0,cfg.f0,cfg.c);
% Received phase is evaluated at emission time, NOT reception time.
% Relative inverse-distance amplitude is a simplified free-field model.
x = (cfg.d./r).*sin(2*pi*cfg.f0*u);
if isfinite(cfg.snrDb)
    noiseStd = sqrt(mean(x.^2)/10^(cfg.snrDb/10));
    x = x + noiseStd*randn(size(x));
end
audiowrite(fullfile(out,'received_signal.wav'),0.95*x/max(abs(x)),cfg.fs);

%% Windowed FFT and single-tone ridge extraction
N = cfg.windowLength;
assert(cfg.nfft >= N && cfg.hop > 0 && N <= numel(x));
w = 0.5-0.5*cos(2*pi*(0:N-1).'/(N-1)); % symmetric Hann window
starts = 1:cfg.hop:numel(x)-N+1;
frameTime = ((starts-1)+(N-1)/2).'/cfg.fs;
F = (0:floor(cfg.nfft/2)).'*cfg.fs/cfg.nfft;
% Broad prior band for the known tone. No true speed is used for tracking.
band = find(F >= 0.8*cfg.f0 & F <= 1.2*cfg.f0);
mag = zeros(numel(band),numel(starts));
tracked = zeros(numel(starts),1);
for k = 1:numel(starts)
    frame = x(starts(k):starts(k)+N-1).*w;
    spec = abs(fft(frame,cfg.nfft));
    mag(:,k) = spec(band);
    [~, idx] = max(spec(band));
    b = band(idx);
    delta = 0;
    if b > 1 && b < floor(cfg.nfft/2)+1
        y = log(max(spec(b-1:b+1),realmin));
        denominator = y(1)-2*y(2)+y(3);
        if abs(denominator) > 1e-12
            delta = max(-0.5,min(0.5,0.5*(y(1)-y(3))/denominator));
        end
    end
    tracked(k) = (b-1+delta)*cfg.fs/cfg.nfft;
end
[~,~,frameTruth] = doppler_model(frameTime,cfg.v,cfg.d,cfg.u0,cfg.f0,cfg.c);

%% Fit speed, closest distance, and emission-time closest approach
% Log parameters keep v and d positive. Multiple starts reduce local minima.
options = optimset('Display','off','MaxIter',3000,'MaxFunEvals',6000,...
    'TolX',1e-8,'TolFun',1e-10);
bestLoss = Inf;
for initialSpeed = [3 8 15 25]
    for initialDistance = [2 8 20]
        p0 = [log(initialSpeed),log(initialDistance),median(frameTime)];
        [p,loss] = fminsearch(@(p) fit_loss(p,frameTime,tracked,cfg),p0,options);
        if isfinite(loss) && loss < bestLoss
            bestLoss = loss; bestP = p;
        end
    end
end
assert(isfinite(bestLoss),'No valid fit found. Check ridge or search bounds.');
vHat = exp(bestP(1)); dHat = exp(bestP(2)); u0Hat = bestP(3);
[~,~,fitted] = doppler_model(frameTime,vHat,dHat,u0Hat,cfg.f0,cfg.c);
frequencyRMSE = sqrt(mean((tracked-frameTruth).^2));
frequencyBias = mean(tracked-frameTruth);
fitRMSE = sqrt(mean((tracked-fitted).^2));

summary = table(cfg.v,vHat,abs(vHat-cfg.v),cfg.d,dHat,abs(dHat-cfg.d),...
    cfg.u0,u0Hat,abs(u0Hat-cfg.u0),frequencyRMSE,frequencyBias,fitRMSE,...
    'VariableNames',{'TrueSpeed_mps','EstimatedSpeed_mps','SpeedError_mps',...
    'TrueDistance_m','EstimatedDistance_m','DistanceError_m',...
    'TrueClosestEmissionTime_s','EstimatedClosestEmissionTime_s',...
    'ClosestEmissionTimeError_s','FrequencyRMSE_Hz','FrequencyBias_Hz','FitRMSE_Hz'});
disp(summary);
writetable(summary,fullfile(out,'estimation_summary.csv'));
writetable(table(frameTime,frameTruth,tracked,fitted),fullfile(out,'frequency_tracks.csv'));
save(fullfile(out,'demo_workspace.mat'),'cfg','summary','frameTime','tracked','fitted');

%% Figures generated from this run
fig = figure('Color','w');
plot(t,x); xlabel('Reception time (s)'); ylabel('Relative amplitude');
title('Simulated received signal'); grid on;
exportgraphics(fig,fullfile(out,'figure1_waveform.png'),'Resolution',180);

fig = figure('Color','w');
imagesc(frameTime,F(band),20*log10(max(mag/max(mag(:)),1e-6)));
axis xy; caxis([-60 0]); colorbar; hold on;
plot(frameTime,frameTruth,'w--','LineWidth',1.5);
plot(frameTime,tracked,'r','LineWidth',1);
xlabel('Reception time (s)'); ylabel('Frequency (Hz)');
title('STFT magnitude (dB), theoretical curve and extracted ridge');
legend('Theoretical frequency','Extracted ridge','Location','best');
exportgraphics(fig,fullfile(out,'figure2_spectrogram.png'),'Resolution',180);

fig = figure('Color','w');
plot(frameTime,frameTruth,'k--',frameTime,tracked,'b',frameTime,fitted,'r','LineWidth',1.2);
xlabel('Reception time (s)'); ylabel('Frequency (Hz)'); grid on;
legend('Theoretical','Extracted','Fitted','Location','best');
title(sprintf('Estimated speed %.3f m/s; distance %.3f m',vHat,dHat));
exportgraphics(fig,fullfile(out,'figure3_frequency_fit.png'),'Resolution',180);
fprintf('Outputs saved to: %s\n',out);

function loss = fit_loss(p,t,observed,cfg)
    v = exp(p(1)); d = exp(p(2)); u0 = p(3);
    if ~all(isfinite([v d u0])) || v < 0.1 || v > 0.3*cfg.c || ...
            d < 0.1 || d > 100 || u0 < min(t)-5 || u0 > max(t)+5
        loss = 1e12; return;
    end
    [~,~,prediction] = doppler_model(t,v,d,u0,cfg.f0,cfg.c);
    loss = mean((prediction-observed).^2);
end

function [u,r,f] = doppler_model(t,v,d,u0,f0,c)
    % Exact subsonic inversion of t = u + r(u)/c.
    beta = v/c;
    T = t-u0;
    e = (T-sqrt(beta^2*T.^2+(1-beta^2)*(d/c)^2))/(1-beta^2);
    u = u0+e;
    r = sqrt(d^2+v^2*e.^2);
    radialVelocity = v^2*e./r;
    f = f0./(1+radialVelocity/c);
end
