function [outtime,outsig] = plotGrav_conv(timein,sig,imp,cut)
%PLOTGRAV_CONV Convolution including cutting to valid output signal
%
% Input:
%   timein  ...  input time in matlab format (vector)
%   sig     ...  signal to be filtered (vector)
%   imp     ...  filter = impulse response (vector)
%   cut     ...  cutting switch
% 
% Output:
%   outtime ...  output time (corrected for convolution effect, if
%               required). Vector in matlab time format
%   outsig  ...  filtered signal (vector)
% 
%                                                   M.Mikolaj, 19.3.2015

outsig = conv(sig,imp);                                                     % convolution using matlab function
d_imp = length(imp);                                                        % length of the filter
switch cut
    case 'valid'
        outsig = outsig(1+(d_imp-1)/2:end-(d_imp-1)/2);                     % remove phase shift
        outsig = outsig(1+(d_imp-1)/2:end-(d_imp-1)/2);                     % remove affected values (=> 2*0.5 filter length)
        outtime = timein(1+(d_imp-1)/2:end-(d_imp-1)/2);                    % update time output
    case 'phase'
        outtime = timein;
        outsig = outsig(1+(d_imp-1)/2:end-(d_imp-1)/2);                     % remove phase shift
    case 'nothing'
        outtime = timein;
    otherwise
        disp('Wrong switch')
end
end