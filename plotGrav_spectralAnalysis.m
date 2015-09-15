function [f,amp,pha,y,h] = plotGrav_spectralAnalysis(signal,fs,win,lenFFT,ax_handle)
%PLOTGRAV_SPECTRALANALYSIS performe spectral analysis
% This function removes signal trend automatically.
% 
% Input:
%   signal  ...     input time series (vector)
%   fs      ...     frequency sampling (scalar, Hz)
%   win     ...     window function = 'none'|'hann'|'hamm'
%   lenFFT  ...     length of the FFT (scalar, if [] lenFFT = 
%                   2^nextpow2(length(signal)) or length of the input
%                   vector * 2.
%   ax_handle..     axes handle (for plotting)
% 
% Output:
%   f       ...     output FFT frequency (Hz)
%   amp     ...     computed FFT amplitudes
%   pha     ...     computed FFT phase
%   y       ...     scaled FFT output/length(signal) (complex numbers)
%   h       ...     line handle
% 
%                                                   M.Mikolaj, 21.3.2015
%   

if nargin == 2
    lenFFT = 2^nextpow2(length(signal));                                    % default length of FFT
    if lenFFT<length(signal)
       lenFFT = length(signal)*2;                                           % min. length = length of signal * 2
    end
    figure;                                                                 % open new window if not provided
    ax_handle = axes;
end
if isempty(ax_handle);
    figure;                                                                 % open new window if axes not provided
    ax_handle = axes;
end
if isempty(lenFFT)
    lenFFT = 2^nextpow2(length(signal));                                    % default length of FFT
    if lenFFT<length(signal)
       lenFFT = length(signal)*2;                                           % min. length = length of signal * 2
    end
end
signal = detrend(signal);                                                   % remove trend
switch win
    case 'hann'
        signal = signal.*hann(length(signal));                              % hanning window
    case 'hamm'           
        signal = signal.*hamming(length(signal));                           % hamming window   
end
y = fft(signal,lenFFT)/length(signal);                                      % compute FFT
amp = 2*abs(y);                                                             % Amplitudes
amp(1) = amp(1)/2;                                                          % correct first amplitude
pha = unwrap(angle(y));                                                     % compute phase
f = (0:length(y)-1)*(fs/length(y));                                         % output frequency

h = plot(ax_handle,(1./f)/86400,amp);                                       % plot period vs. amplitude
xmax = ((1/fs)*length(signal))/86400;                                       % max x limit (length of the signal in days)
xmin = (1/(fs/2))/86400;                                                    % min x limit (half of the freq. sampling)
set(ax_handle,'XLim',[xmin xmax]);                                          % set new x limits 
xlabel(ax_handle,'days','FontSize',8);                                      % xlabel
ylabel(ax_handle,'amplitude','FontSize',8);

end
