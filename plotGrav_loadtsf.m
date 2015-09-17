function [time,data,channels,units,undetval,increment,countinfo] = plotGrav_loadtsf(input_tsf)
%LOADTSF load tsf outputs to matlab
% Input:
%  input_tsf    ...     full file name 
%
% Output:
%   time        ...     matlab time (vector)
%   data        ...     data matrix (for all channels)
%   channels    ...     channels info (cell array)
%   units       ...     units for each channel (cell array)
%   undetval    ...     undefined values (scalar)
%   increment   ...     time step in seconds (scalar)
%   countinfo   ...     total number of observations (scalar)
% 
% Example:
%   [time,data] = plotGrav_loadtsf('VI_gravity.tsf');
% 
%                                                   M.Mikolaj, 21.7.2015
%                                                   mikolaj@gfz-potsdam.de

%% Initialize
time = [];
data = [];
channels = [];
units = [];
undetval = [];
increment = [];
countinfo = [];

%% Get undetval
try
    cr = 0;
    num_chan = 1;
    fid = fopen(input_tsf);
    row = fgetl(fid);cr = cr+1;
catch
    error('plotGrav_loadtsf:FOF','Fail to open the file. File not found');
end
% Get UNDETVAL
while ischar(row)
    if length(row) >= 6
        if strcmp(row(1:6),'[UNDET')
            undetval = str2double(row(11:end));
            break;
        elseif strcmp(row(1:6),'[DATA]')
            break;
        end
    end
    row = fgetl(fid);
    cr = cr+1;
end
fclose(fid);
fid = fopen(input_tsf);
row = fgetl(fid);cr = cr+1;
% Get INCREMENT
while ischar(row)
    if length(row) >= 6
        if strcmp(row(1:6),'[INCRE')
            increment = str2double(row(12:end));
            break;
        elseif strcmp(row(1:6),'[DATA]')
            break;
        end
    end
    row = fgetl(fid);cr = cr+1;
end
fclose(fid);
fid = fopen(input_tsf);
row = fgetl(fid);cr = 1;
% Get CHANNELS
while ischar(row)
    if length(row) >= 6
        if strcmp(row(1:6),'[CHANN')
            row = fgetl(fid);cr = cr+1;
            while ~strcmp(row(1),'[')
                channels{num_chan,1} = row;num_chan = num_chan+1;
                row = fgetl(fid);cr = cr+1;
                if isempty(row)
                    row = '[';
                end
            end
            break;
        elseif strcmp(row(1:6),'[DATA]')
            break;
        end
    end
    row = fgetl(fid);cr = cr+1;
end
fclose(fid);
fid = fopen(input_tsf);
row = fgetl(fid);cr = 1;
% Get UNITS
while ischar(row)
    if length(row) >= 6
        if strcmp(row(1:6),'[UNITS')
            num_mm = 1;
            row = fgetl(fid);cr = cr+1;
            while ~strcmp(row(1),'[')
                units{num_mm,1} = row;num_mm = num_mm+1;
                row = fgetl(fid);cr = cr+1;
                if isempty(row)
                    row = '[';
                end
            end
            break;
        elseif strcmp(row(1:6),'[DATA]')
            break;
        end
    end
    row = fgetl(fid);cr = cr+1;
end
fclose(fid);
fid = fopen(input_tsf);
row = fgetl(fid);cr = 1;
% Get COUNT
while ischar(row)
    if length(row) >= 6
        if strcmp(row(1:6),'[COUNT')
                countinfo = str2double(row(12:end));
                break;
        elseif strcmp(row(1:6),'[DATA]')
            break;
        end
    end
    row = fgetl(fid);cr = cr+1;
end
fclose(fid);
fid = fopen(input_tsf);
row = fgetl(fid);cr = 1;
% Get DATA (stop)
while ischar(row)
    if length(row) >= 6
        if strcmp(row(1:6),'[DATA]')
            data_start = cr;
            break;
        end
    end
    row = fgetl(fid);cr = cr+1;
end
fclose(fid);
% create format specification
formatSpec = '%d%d%d%d%d%d';
for i = 1:length(channels);
   formatSpec = [formatSpec,'%f'];
end
try 
    % Get Data
    try                                                                     % assumed, file contains COUNTINFO 
        fid = fopen(input_tsf,'r');
        for i = 1:data_start
            row = fgetl(fid);
        end
        if isempty(countinfo)
            count = 0;
            row = fgetl(fid);
            if isempty(row)
                while isempty(row)
                    row = fgetl(fid);
                    data_start = data_start + 1;
                end
            end
            while ischar(row)
                row = fgetl(fid);
                count = count + 1;
            end
            fclose(fid);
            fid = fopen(input_tsf,'r');
            countinfo = count;
            for i = 1:data_start
                row = fgetl(fid);
            end
        end
        dataArray = textscan(fid, formatSpec, countinfo);
        time = datenum(double(dataArray{1,1}),double(dataArray{1,2}),double(dataArray{1,3}),double(dataArray{1,4}),double(dataArray{1,5}),double(dataArray{1,6}));
        data = cell2mat(dataArray(7:end));
        if ~isempty(undetval)
            data(data == undetval) = NaN;
        end
        fclose(fid);
    catch
        fclose(fid);
        data_start = 1;
        dataArray = dlmread(input_tsf,'',data_start,0); % warning no footer info are allowed
        time = datenum(dataArray(:,1:6));
        data = dataArray(:,7:end);
        if ~isempty(undetval)
            data(data == undetval) = NaN;
        end
        error('plotGrav_loadtsf:FRH','Fail to read header');
    end
        
%     % Get footer info
%     row = fgetl(fid);
%     while ischar(row)
%         if length(row) >= 5
%         end
%         row = fgetl(fid);
%     end
catch
    fclose('all');
    error('plotGrav_loadtsf:FRD','Fail to read data');
%     fprintf('Could not load the required file. Checkt the format (file must contain: COUNTINFO, CHANNEL, UNITS, UNDETVAL)\n');
end
end