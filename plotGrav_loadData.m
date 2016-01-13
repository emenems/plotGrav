function [time,data,channels,units,uitable_data] = plotGrav_loadData(file_name_in,format_switch,start_time,end_time,fid,panel_name,varargin)
%PLOTGRAV_LOADDATA load plotGrav supported file formats
% Read data stored as:
%   *.tsf   ... tsoft file format including header (calls 
%               plotGrav_loadtsf.m)
%   *.mat   ... load matlab files containing array: *.data = data
%               matrix/vector.  *.time = time vector (matlab datenum) or
%               time matrix [year,month,day,hour,minute,second].
%               *.channels channel names related to *.data columns as cell
%               array, e.g., {'Gravity','Pressure'};
%               *.units channel units related to *.data columns as cell
%               array, e.g., {'nm/s^2','hPa'};
%   *.dat   ... load (Wettzell) Soil Moisture cluster data, i.e., call the
%               plotGrav_readcsv.m function.
%
% Input:
%   file_name_in    ... full file name of the input file 
%                       e.g., 'F:\data\InputFile.tsf'
%   format_switch   ... switch between supported file formats, i.e.,
%                       1 = tsoft file
%                       2 = mat file
%                       3 = dat soil moisture cluster data
%   start_time      ... time scalar in matlab datenum format. This input
%                       will be used to remove all data points recored before 
%                       this date. If [], no cutting.
%                       e.g., 736225
%                       e.g., []
%   end_time        ... time scalar in matlab datenum format. This input
%                       will be used to remove all data points recored after 
%                       this date. If [], no cutting.
%                       e.g., 736226
%                       e.g., []
%   fid             ... output/logfile file ID (get using fopen). If [], no
%                       logfile writing.
%   panel_name      ... string used as prefix to write in logfile. This
%                       string should describe the input file. Will not be
%                       used if fid is empty.
%                       e.g., 'iGrav'

%% Tsoft file format
switch format_switch
    case 1                                                                  % TSF file format
        try                                                                 % use try/catch to avoid program crash. 
            [time,data,channels,units] = plotGrav_loadtsf(file_name_in);    % used default function for tsf data loading.
            for i = 1:length(channels)                                      % run this for for all channels of the input file in order to extract the channel names (channel correct)
                temp = strsplit(char(channels(i)),':');                     % split string using :, i.e., tsf standard for separating Location:Intrument:Measurement. See plotGrav_loadtsf functions
                channels(i) = temp(end);                                    % get the last string, i.e., 'Measurement' == channel name
                % Now, after extracting channels name, create an ui-table. 
                uitable_data(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels(i)),char(units(i))),false,false,false}; % update table
                clear temp                                                  % remove temp variable
            end
            if length(find(isnan(data))) ~= numel(data)                     % check if loaded data contains numeric values, otherwise set data and time = [], i.e., default output for no data loaded 
                if ~isempty(start_time) && ~isempty(end_time)               % cut the time series only if some input
                    data(time<datenum(start_time) | time>datenum(end_time),:) = []; % remove time epochs out of requested range (i.e. starting and ending time)
                    time(time<datenum(start_time) | time>datenum(end_time),:) = []; % do the same for time vector. The order is important. First data and then time (otherwise, the modified time vector woud not fit data dimension)
                end
                if ~isempty(fid)
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data loaded: %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                end
            else
                data = [];                                                  % otherwise empty. [] means that the ui-table will be empty and no ploting will be possible.
                time = [];
                if ~isempty(fid)
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No data in %s input file (in selected time interval): %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                end
            end
        catch error_message                                                 % Catch possible errors during data loading
            data = [];                                                      % same as if no data loaded
            time = [];
            channels = [];
            units = [];
            uitable_data = {false,false,false,'NotAvailable',false,false,false}; % default ui-table
            if ~isempty(fid)
                if strcmp(error_message.identifier,'plotGrav_loadtsf:FOF')  % switch between error IDs. See plotGrav_loadtsf.m function for error handling
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRH')
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s could NOT read header (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRD')
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s could NOT read data (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                else
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s loaded but NOT processed. Error = %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,error_message.identifier,ty,tm,td,th,tmm); % Write message to logfile
                end
            end
        end
    case 2                                                                  % MAT file format
        try
            temp = importdata(file_name_in);                                % store the data to temporary variable (use importdata not load to overcome possible naming issues)
            time = datenum(double(temp.time));temp.time = [];               % convert to matlab time format. Does not affect the result if data already in such format. Convert to double in case input is stored in single precision.
            data = double(temp.data);temp.data = [];                        % convert the input data to double precision and remove temp.data variable to clear some memory
            channels = temp.channels;                                       % get channel names. It is assumed the temp.channels stores the data in the same file format as plotGrav, e.g., {'Gravity','Pressure};
            units = temp.units;                                             % get channel units. -- || --
            clear temp                                                      % remove the temporary variable
            for i = 1:length(channels)                                % run for all channels to prepare the date for ui-table
                uitable_data(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels(i)),char(units(i))),false,false,false}; % just names and units. Check/uncheck will be updated later.
            end
            if length(find(isnan(data))) ~= numel(data)                     % check if loaded data contains numeric values
                if ~isempty(start_time) && ~isempty(end_time)               % cut the time series only if some input
                    data(time<datenum(start_time) | time>datenum(end_time),:) = []; % remove time epochs out of requested range (i.e. starting and ending time)
                    time(time<datenum(start_time) | time>datenum(end_time),:) = []; % do the same for time vector. The order is important. First data and then time (otherwise, the modified time vector woud not fit data dimension)
                end
                if ~isempty(fid)
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data loaded: %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                end
            else
                data = [];                                            % otherwise empty, i.e. will not be visible for plotting
                time = [];
                if ~isempty(fid)
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No data in %s input file (in selected time interval): %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                end
            end
        catch error_message                                                 % Catch possible errors during data loading
            data = [];                                                      % same as if no data loaded
            time = [];
            channels = [];
            units = [];
            uitable_data = {false,false,false,'NotAvailable',false,false,false}; % default ui-table
            if strcmp(error_message.identifier,'MATLAB:FileIO:InvalidFid')
                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
            else
                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s loaded but NOT processed. Check format and required layers (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
            end
        end
    case 3                                                                  % DAT file format = Wettzell Soil moisture clusters
        try 
            [time,data,temp] = plotGrav_readcsv(file_name_in,4,',',1,'"yyyy-mm-dd HH:MM:SS"','All'); % fixed for SM cluster: 4 = number of header lines, ',' = delimiter, 1 = first column == time, fixed time format, 'All' = load all columns
            channels = temp(2,2:end);                                       % extract channel name (see plotGrav_readcsv.m function for outputs)
            units = temp(3,2:end);                                          % extract channel units
            cut = [];                                                       % auxiliary variable to count/identify channel names with no string = redundant (will be used to update channels and units variables)
            for i = 1:length(channels)                                      % run for loop to create the ui-table and to remove channels with no name (will not affect DATA, only channel Names and Units)
                if ~isempty(channels{i})                                    % 
                    uitable_data(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels(i)),char(units(i))),false,false,false};
                else
                    cut = vertcat(cut,i);                                   % count all redundant channel names
                end
                clear temp
            end
            channels(cut) = [];                                             % remove redundant channel names
            units(cut) = [];
            clear cut
            if length(find(isnan(data))) ~= numel(data)                     % check if loaded data contains numeric values
                if ~isempty(start_time) && ~isempty(end_time)               % cut the time series only if some input
                    data(time<datenum(start_time) | time>datenum(end_time),:) = []; % remove time epochs out of requested range (i.e. starting and ending time)
                    time(time<datenum(start_time) | time>datenum(end_time),:) = []; % do the same for time vector. The order is important. First data and then time (otherwise, the modified time vector woud not fit data dimension)
                end
                if ~isempty(fid)
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data loaded: %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                end
            else
                data = [];                                            % otherwise empty, i.e. will not be visible for plotting
                time = [];
                if ~isempty(fid)
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No data in %s input file (in selected time interval): %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
                end
            end
        catch error_message
            data = [];                                                      % same as if no data loaded
            time = [];
            channels = [];
            units = [];
            uitable_data = {false,false,false,'NotAvailable',false,false,false}; % default ui-table
            if strcmp(error_message.identifier,'MATLAB:FileIO:InvalidFid')
                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
            else
                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s file: %s loaded but NOT processed. Check format (%04d/%02d/%02d %02d:%02d)\n',panel_name,file_name_in,ty,tm,td,th,tmm); % Write message to logfile
            end
        end
end % Switch END

end % Function END