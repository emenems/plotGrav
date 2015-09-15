function [time,data,header] = plotGrav_readcsv(input_file,head,delim,date_column,date_format,data_column)
%PLOTGRAV_READCSV read csv file
%
% Input:
%   input_file  ...     input file name, i.e., full file name (string)
%   head        ...     number of header lines (double)
%   delim       ...     csv delimiter (string or cell)
%   date_column ...     date column (double)
%   date_format ...     date string
%                       Example: '"yyyy-dd-mm HH:MM:SS"'
%                                'yyyy/mm/dd HH:MM:SS'
%   data_column ...     data column
%                       Example: 5 = load fifth column (in csv)
%                                2:10 = load all columns between 2 and 10
%                                (including 2 and 10)
%                                'All' = all data columns except time
% 
% Output:
%   time        ...     time vector (in matlab datenum format)
%   data        ...     selected data columns
%   header      ...     header info
% 
% Example:
%   input_file = 'Wettzell_Hang_Mux21.dat';
%   head = 3;
%   delim = {','};
%   date_column = 1;
%   date_format = '"yyyy-mm-dd HH:MM:SS"';
%   data_column = 'All';
% [time,data,header] =  plotGrav_readcsv(input_file,head,delim,date_column,date_format,data_column);
% 
%                                                   M.Mikolaj, 20.05.2015


%% Get header
fid = fopen(input_file,'r');                                                % open file
if head > 0                                                                 % read header only if 'head' variable > 0
    row = fgetl(fid);                                                       % read line
    header = strsplit(row,delim);                                           % split header using given delimiter(s)
    if head > 1                                                             % continue reading header if required
        for i = 1:head-1
            row = fgetl(fid);
            temp = strsplit(row,delim);
            header(i+1,1:length(temp)) = temp;
        end
    end
    clear temp
else
    row = 'No header';                                                      % if no header data
    header = [];
end

%% Get data
count = 1;                                                                  % data row number
data = [];                                                                  % prepare variable
row = fgetl(fid);                                                       % read line
while ischar(row)                                                           % continue until end of file
    split = strsplit(row,delim);                                            % split row using given delimiter(s)
    time(count,1) = datenum(split(date_column),date_format);                % get time info
    if ischar(data_column)
        data = vertcat(data,str2double(split(date_column+1:end)));          % read all columns except data
    else
        data = vertcat(data,str2double(split(data_column)));                % read selected data columns
    end
    count = count+1;                                                        % increase row number
    row = fgetl(fid);                                                       % read line
end

fclose(fid);                                                                % close file

end
