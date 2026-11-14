"""Matched-signal comparison of fundamental and harmonic Doppler tracking."""
from pathlib import Path
import csv
import numpy as np
from scipy.optimize import least_squares
from scipy.io.wavfile import write
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

FS, F0, C = 44100, 3000, 343
TRUTH = np.array([10, 5, 5])
AMPS = np.array([1, .7, .5])
OUT = Path(__file__).resolve().parent / "results"

def model(t, v, d, u0):
    beta, T = v/C, t-u0
    e = (T-np.sqrt(beta**2*T**2+(1-beta**2)*(d/C)**2))/(1-beta**2)
    r = np.hypot(d, v*e)
    return u0+e, r, F0/(1+v**2*e/(r*C))

def extract(x, n):
    nfft = 16384
    starts = np.arange(0, len(x)-n+1, 512)
    centers = (starts+(n-1)/2)/FS
    frames = np.lib.stride_tricks.sliding_window_view(x,n)[starts]
    spec = np.abs(np.fft.rfft(frames*np.hanning(n),nfft))
    f = np.fft.rfftfreq(nfft,1/FS)
    rows = np.arange(len(starts))
    tracks = []
    for h in (1,2,3):
        band = np.flatnonzero((f>=.8*h*F0)&(f<=1.2*h*F0))
        b = band[spec[:,band].argmax(axis=1)]
        a,m,z = [np.log(np.maximum(spec[rows,b+j],1e-30)) for j in (-1,0,1)]
        den = a-2*m+z
        delta = np.clip(np.divide(.5*(a-z),den,out=np.zeros_like(den),where=abs(den)>1e-12),-.5,.5)
        tracks.append((b+delta)*FS/(nfft*h))
    return centers,np.array(tracks)

def fit(t, ridge):
    candidates = [least_squares(lambda p: model(t,*p)[2]-ridge,
                  [v,d,5],bounds=([.1,.1,0],[.3*C,100,10]))
                  for v,d in ((3,2),(8,8),(15,20),(25,8))]
    return min(candidates,key=lambda result:result.cost).x

def main():
    OUT.mkdir(exist_ok=True)
    t=np.arange(10*FS)/FS
    u,r,_=model(t,*TRUTH)
    x=sum(a*np.sin(2*np.pi*h*F0*u) for h,a in enumerate(AMPS,1))*TRUTH[1]/r
    rng=np.random.default_rng(520096747)
    rows=[]
    example=None
    for trial in range(12):
        noise=rng.normal(size=x.size)
        noise*=np.linalg.norm(x)/np.linalg.norm(noise)
        for snr in (20,10,5,0):
            y=x+noise*10**(-snr/20)
            for n in (2048,4096,8192):
                tf,tracks=extract(y,n)
                ft=model(tf,*TRUTH)[2]
                for method,ridge in (("Fundamental",tracks[0]),("Joint",np.average(tracks,axis=0,weights=AMPS**2*np.arange(1,4)**2)),("Median",np.median(tracks,axis=0))):
                    p=fit(tf,ridge)
                    err=abs(p-TRUTH)
                    rows.append([trial,snr,n,method,*p,*err,np.sqrt(np.mean((ridge-ft)**2))])
                if (trial,snr,n)==(0,0,4096):
                    example=(tf,ft,tracks)
                    for name,signal in (("clean_passby",x),("noisy_passby_0dB",y)):
                        write(OUT/(name+".wav"),FS,np.int16(signal/max(abs(y))*.95*32767))
    with (OUT/"trials.csv").open("w",newline="") as file:
        writer=csv.writer(file)
        writer.writerow(["trial","SNR_dB","window","method","speed_mps","distance_m","emission_time_s","speed_abs_error","distance_abs_error","time_abs_error","ridge_RMSE_Hz"])
        writer.writerows(rows)
    fig,axes=plt.subplots(2,2,figsize=(9,6),layout="constrained")

    for ax,k,label in zip(axes.flat,(7,8,9,10),("Speed MAE (m/s)","Distance MAE (m)","Emission time MAE (s)","Mean ridge RMSE (Hz)")):
        for method in ("Fundamental","Joint","Median"):
            v=[np.mean([r[k] for r in rows if r[1]==snr and r[2]==4096 and r[3]==method]) for snr in (0,5,10,20)]
            ax.plot((0,5,10,20),v,"o-",label=method)
        ax.set(xlabel="Input SNR (dB)",ylabel=label)
        ax.grid(alpha=.3)
    axes[0,0].legend()
    fig.savefig(OUT/"errors.png",dpi=160)
    plt.close(fig)
    tf,ft,tracks=example
    fig,ax=plt.subplots(figsize=(8,4),layout="constrained")
    for h,track in enumerate(tracks,1):
        ax.plot(tf,track,alpha=.55,label=f"Harmonic {h} / {h}")
    ax.plot(tf,ft,"k--",label="Theory")
    ax.set(xlabel="Reception time (s)",ylabel="Fundamental-equivalent frequency (Hz)")
    ax.legend()
    fig.savefig(OUT/"tracks.png",dpi=160)
    with (OUT/"summary.csv").open("w",newline="") as file:
        writer=csv.writer(file)
        writer.writerow(["SNR_dB","window","method","speed_MAE","distance_MAE","time_MAE","mean_ridge_RMSE"])
        for n in (2048,4096,8192):
            for snr in (0,5,10,20):
                for method in ("Fundamental","Joint","Median"):
                    writer.writerow([snr,n,method,*np.mean([r[7:] for r in rows if r[1]==snr and r[2]==n and r[3]==method],axis=0)])
    print(f"Completed {len(rows)} estimates. Results: {OUT}")

if __name__=="__main__":
    main()


