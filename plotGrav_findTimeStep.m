function [timeout,dataout,id_out,id_in] = plotGrav_findTimeStep(time,data,orig_step)
%PLOTGRAV_FINDTIMESTEP Function for identifying steps and filling them with NaN
% Warning: this function calculates with one second accuracy. Therefore, do
% not use this function for time series sampled with higher time
% resolution!
% 
% Input:
%   time        ...     input time vector
%   data        ...     input data vector
%   orig_step   ...     sampling rate in days (datenum), e.g. 1/24 for 1
%                       hour sampling
% 
% Output:       
%   timeout     ...     output time (equally spaced with given 'orig_step' 
%                       sampling)
%   dataout     ...     output data (equally spaced with given 'orig_step' 
%                       sampling)
%   id_in       ...     id matrix (Nx2) with starting and ending rows of
%                       input time/data
%   id_out      ...     id matrix (Nx2) with starting and ending rows of
%                       output timeout/dataout
% 
% Example:
%   [tout,dout,id_out] = plotGrav_findTimeStep(tin,din,1/86400)
% 
%                                                    M.Mikolaj, 21.1.2016
%                                                    mikolaj@gfz-potsdam.de


% Sort data (in case not already sorted)
[time,inde] = sort(time);
data = data(inde,:);
% Remove redundant data
[time,inde] = unique(time);
data = data(inde,:);
clear inde
% Remove possible time NaNs
data(isnan(time),:) = [];
time(isnan(time),:) = [];
% Create output time vector.
timeout = transpose(time(1):orig_step:time(end));
% Check the time resolution precision (either in
% seconds or milliseconds. If latter, use 0.01 sec precision)
if round(orig_step*86400) ~= orig_step*86400
    convert_switch = 'msecond';    
else
    convert_switch = 'second';
    % Round to seconds also the output vector (the creation in 38th row is
    % limited to double precision)
    timeout_mat = datevec(timeout); 
    timeout_mat(:,end) = round(timeout_mat(:,end));
    timeout = datenum(timeout_mat); 
    clear timeout_mat;
end
timepattern = time2pattern(timeout,convert_switch);
timeID = time2pattern(time,convert_switch);
% Declare output variables
dataout(1:length(timeout),1:size(data,2)) = NaN;
% Aux variables to count indices
j = 1;id_in = 1;id_out = [1 1];
% Run loop comparing regular and actual time
for i = 1:length(timepattern)
    if timepattern(i) == timeID(j)
        dataout(i,:) = data(j,:);
        j = j + 1;
        if (id_out(end,2) ~= i-1) && i ~= 1;
           id_out(end+1,1) = i;
        end
        id_out(end,2) = i;
        
    else
        if id_in(end) ~= j
           id_in = vertcat(id_in,j);
        end
    end
end
if length(id_in)>1
    id_in(:,2) = vertcat(id_in(2:end,1)-1,size(data,1));
else
    id_in(1,2) = size(data,1);
end

end

function time_out = time2pattern(time_in,resol)
	%TIME2PATTERN convert input time vector to time patter (e.g. yyyymmdd)
	%
	% Input:
	%   time_in     ... time vector (datenum) or time matrix
	%   resol       ... string switch for output precission:
	%                   'day':      yyyymmdd
	%                   'hour':     yyyymmddhh
	%                   'minute':   yyyymmddhhmm
	%                   'second':   yyyymmddhhmmss
	%                   'msecond':   yyyymmddhhmmssmm
	%
	% Output:
	%   time_out    ... time pattern (see 'resol' input)
	%
	% Example:
	%   time_out = time2pattern(time_vec,'hour');
	%
	% M. Mikolaj, mikolaj@gfz-potsdam.de, 10.12.2016
	%
	%% Check input (vector or matrix)
	% Convert to datevec format if necessary
	if size(time_in,2) == 1
		time_in = datevec(time_in);
	end

	%% Convert
	% Switch between required output precision
	if strcmp(resol,'day')
		multiplier = [10000, 100];
	elseif strcmp(resol,'hour')
		multiplier = [1000000,10000,100];
	elseif strcmp(resol,'minute')
		multiplier = [100000000,1000000,10000,100];
	elseif strcmp(resol,'second')
		multiplier = [10000000000,100000000,1000000,10000,100];
		time_in(:,6) = round(time_in(:,6));
	elseif strcmp(resol,'msecond')
		multiplier = [1000000000000,10000000000,100000000,1000000,10000,100];
	else
		multiplier = 0;
	end
	% Create pattern
	time_out = 0;
	for i = 1:length(multiplier)
		time_out = time_out + time_in(:,i)*multiplier(i);
	end
	if ~strcmp(resol,'msecond')
		time_out = time_out + time_in(:,i+1);
	end

end

