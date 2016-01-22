function plotGrav_scriptRun(in_script)
%PLOTGRAV_SCRIPTRUN Run scripts for plotGrav
% This function reads the input script and runs all commands
% chronologically. 
% 
% Input:
%   in_script   ... full file name of plotGrav script
%
%
%                                                   M.Mikolaj, 24.09.2015

% Open log file
[ty,tm,td,th,tmm] = datevec(now);                                           % get current time for logfile
tic;                                                                        % start measuring time for logfile
try
    fid_log = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % try to get the logfile name
catch
    fid_log = fopen('plotGrav_LOG_FILE.log','a');                               % otherwise use default logfile name
end
set(findobj('Tag','plotGrav_text_status'),'String','Running script...');drawnow; % status
fprintf(fid_log,'Running script: %s (%04d/%02d/%02d %02d:%02d)\n',in_script,ty,tm,td,th,tmm); % will be overwritten in case script contains 'LOAD_DATA' command. 'load_all_data' uses 'o' permission!
pause(1);
count = 0;                                                                  % to count number of read lines
% % First, check if plotGrav runs - not working
% check_open_window = get(findobj('Tag','plotGrav_check_legend'),'Value');    % only checks if uicontrol with such 'Tag' exists
% if isempty(check_open_window)                                               % start plotGrav if not already running
%     plotGrav                                                                % start plotGrav if not opened
%     drawnow;pause(10);                                                       % wait for plotGrav
% else

% Open script for reading
try                                                                         % catch errors
    fid = fopen(in_script,'r'); 
    row = fgetl(fid);count = count + 1;                                     % Get first row (usualy comment). Count number of read lines
    while ischar(row)                                                       % continue reading whole file
        if ~strcmp(row(1),'%')                                              % run code only if not comment
            switch row                                                      % switch between commands depending on the Script switch.
                %% Setting file paths
                case 'FILE_IN_IGRAV'
                    row = fgetl(fid);count = count + 1;                     % Get next line/row. The plotGrav script are designed as follows: first the switch and next line the inputs
                    if strcmp(row,'[]')                                     % [] symbol means no input                           
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'String',row); % otherwise set the input file
                    end
                case 'FILE_IN_TRILOGI'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'String',row);
                    end
                case 'FILE_IN_OTHER1'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_edit_other1_path'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_other1_path'),'String',row);
                    end
                case 'FILE_IN_OTHER2'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_edit_other2_path'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_other2_path'),'String',row);
                    end
                case 'FILE_IN_TIDES'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_edit_tide_file'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_tide_file'),'String',row);
                    end
                case 'FILE_IN_FILTER'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_edit_filter_file'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_filter_file'),'String',row);
                    end
                case 'FILE_IN_UNZIP'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_menu_ftp'),'UserData','');  % unlike other inputs, unzip (7zip) exe full file name is stored in userdata container.
                    else
                        set(findobj('Tag','plotGrav_menu_ftp'),'UserData',row);
                    end
                case 'FILE_IN_WEBCAM'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_menu_webcam'),'UserData',''); % similarly to unzip exe, webcam path is stored in UserData
                    else
                        set(findobj('Tag','plotGrav_menu_webcam'),'UserData',row);
                    end
                case 'FILE_IN_LOGFILE'
                    row = fgetl(fid);count = count + 1; 
                    if strcmp(row,'[]')
                        set(findobj('Tag','plotGrav_edit_logfile_file'),'String','');
                    else
                        set(findobj('Tag','plotGrav_edit_logfile_file'),'String',row);
                    end
                %% Input time settings
                case 'TIME_START'                                           % Starting time
                    row = fgetl(fid);count = count + 1;                     % read the date
                    if ~strcmp(row,'[]')                                    % proceed/set only if required
                        date = strsplit(row,';');                           % By default multiple inputs are delimited by ;. If one input (with minus sign), then set to current time - input
                        if length(date) == 1
                            date = char(date);
                            if strcmp(date(1),'-');
                                temp = now;temp = datevec(temp+str2double(date)); % use + as input starts with minus sign!
                                set(findobj('Tag','plotGrav_edit_time_start_year'),'String',sprintf('%04d',temp(1))); % set year
                                set(findobj('Tag','plotGrav_edit_time_start_month'),'String',sprintf('%02d',temp(2))); % month
                                set(findobj('Tag','plotGrav_edit_time_start_day'),'String',sprintf('%02d',temp(3))); % day
                                set(findobj('Tag','plotGrav_edit_time_start_hour'),'String','00'); % Set hours to 0 if one input.
                            end
                        else
                            set(findobj('Tag','plotGrav_edit_time_start_year'),'String',char(date(1))); % first value must be a year
                            set(findobj('Tag','plotGrav_edit_time_start_month'),'String',char(date(2))); % second value must be month
                            set(findobj('Tag','plotGrav_edit_time_start_day'),'String',char(date(3))); % first value must be day
                            set(findobj('Tag','plotGrav_edit_time_start_hour'),'String',char(date(4))); % first value must be hour (no minutes and seconds on plotGrav input)
                        end
                    end
                case 'TIME_STOP'                                            % Stop time
                    row = fgetl(fid);count = count + 1;                     % read the date
                    if ~strcmp(row,'[]')                                    % proceed/set only if required
                        date = strsplit(row,';');                            % By default multiple inputs are delimited by ; If one input (with minus sign), then set to current time - input
                        if length(date) == 1
                            date = char(date);
                            if strcmp(date(1),'-');
                                temp = now;temp = datevec(temp+str2double(date));  % use + as input starts with minus sign!
                                set(findobj('Tag','plotGrav_edit_time_stop_year'),'String',sprintf('%04d',temp(1))); % set year
                                set(findobj('Tag','plotGrav_edit_time_stop_month'),'String',sprintf('%02d',temp(2))); % month
                                set(findobj('Tag','plotGrav_edit_time_stop_day'),'String',sprintf('%02d',temp(3))); % day
                                set(findobj('Tag','plotGrav_edit_time_stop_hour'),'String','00'); % Set hours to 0 if one input.
                            end
                        else
                            set(findobj('Tag','plotGrav_edit_time_stop_year'),'String',char(date(1))); % first value must be a year
                            set(findobj('Tag','plotGrav_edit_time_stop_month'),'String',char(date(2))); % second value must be month
                            set(findobj('Tag','plotGrav_edit_time_stop_day'),'String',char(date(3))); % first value must be day
                            set(findobj('Tag','plotGrav_edit_time_stop_hour'),'String',char(date(4))); % first value must be hour (no minutes and seconds on plotGrav input)
                        end
                    end
                %% iGrav/SG030 processing settings
                case 'CALIBRATION_FACTOR'
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(row,'[]')                                        % proceed/set only if required
                        set(findobj('Tag','plotGrav_edit_calb_factor'),'String',row);
                    end
                case 'CALIBRATION_DELAY'
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(row,'[]')                                        % proceed/set only if required
                        set(findobj('Tag','plotGrav_edit_calb_delay'),'String',row);
                    end
                case 'ADMITTANCE_FACTOR'
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(row,'[]')                                        % proceed/set only if required
                        set(findobj('Tag','plotGrav_edit_admit_factor'),'String',row);
                    end
                case 'RESAMPLE_IGRAV'
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(row,'[]')                                        % proceed/set only if required
                        set(findobj('Tag','plotGrav_edit_resample'),'String',row);
                    end
                case 'DRIFT_SWITCH'
                    row = fgetl(fid);count = count + 1;
                    coef = strsplit(row,';');                                % multiple input possible => split it (first=polynomial, second=possibly polynomial coefficients
                    if ~strcmp(char(coef),'[]')                             % proceed/set only if required
                        set(findobj('Tag','plotGrav_pupup_drift'),'Value',str2double(coef(1))); 
                        if strcmp(char(coef(1)),'6')                        % 6 = user defined polynomial ceoffients
                            set(findobj('Tag','plotGrav_edit_drift_manual'),'String',char(coef(2:end)));  % set coefficients
                            set(findobj('Tag','plotGrav_edit_drift_manual'),'Visible','on'); % turn on (by default off) editable field with polynomial coefficients
                        else
                            set(findobj('Tag','plotGrav_edit_drift_manual'),'Visible','off');
                        end
                    end
                %% Channels selection/checking
                case 'UITABLE_IGRAV_L'                                         % iGrav panel, LX axes (X=>for all left-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                  % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)) = {true};
                                else
                                    data_table(i,channel_numbers(1)) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end
                case 'UITABLE_IGRAV_R'                                         % iGrav panel, RX axes (X=>for all right-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                    % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                  % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)+4) = {true}; % +4 = first three are for Left axes, fourth is channel description.
                                else
                                    data_table(i,channel_numbers(1)+4) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end

                case 'UITABLE_TRILOGI_L'                                        % TRiLOGi panel, LX axes (X=>for all left-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                   % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)) = {true};
                                else
                                    data_table(i,channel_numbers(1)) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end
                case 'UITABLE_TRILOGI_R'                                        % TRiLOGi panel, RX axes (X=>for all right-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                   % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)+4) = {true}; % +4 = first three are for Left axes, fourth is channel description.
                                else
                                    data_table(i,channel_numbers(1)+4) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end

                case 'UITABLE_OTHER1_L'                                         % Other1 panel, LX axes (X=>for all left-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                   % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)) = {true};
                                else
                                    data_table(i,channel_numbers(1)) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end
                case 'UITABLE_OTHER1_R'                                         % Other1 panel, RX axes (X=>for all right-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                   % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)+4) = {true}; % +4 = first three are for Left axes, fourth is channel description.
                                else
                                    data_table(i,channel_numbers(1)+4) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end

                case 'UITABLE_OTHER2_L'                                         % Other2 panel, LX axes (X=>for all left-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                   % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)) = {true};
                                else
                                    data_table(i,channel_numbers(1)) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end
                case 'UITABLE_OTHER2_R'                                         % Other2 panel, RX axes (X=>for all right-axes)
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                                   % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                                 % proceed/set only if required
                        data_table = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the ui-table.
                        channel_numbers = str2double(chan);                     % convert to double. Keep in mind, that first value shows the axes!
                        if channel_numbers(1) >= 1 || channel_numbers(1) <= 3   % Proceed only if logical input (only 3 plots available)
                            for i = 1:size(data_table,1)                        % run for whole data table. Channels on stated on input will be turned off/unchecked
                                r = find(i == channel_numbers(2:end));          % just to check if current channel is on input
                                if ~isempty(r)                                  % check such channel
                                   data_table(i,channel_numbers(1)+4) = {true}; % +4 = first three are for Left axes, fourth is channel description.
                                else
                                    data_table(i,channel_numbers(1)+4) = {false}; % Otherwise, unchecked.
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_table); % update ui-table using 
                        plotGrav('uitable_push');                               % Re-plot data
                        pause(1);                                               % wait until plotting finished
                    end
                case 'UNCHECK_ALL'
                    plotGrav('uncheck_all');
                    row = fgetl(fid);count = count + 1;

                %% Print plots
                case 'PRINT_FIGURE'
                    row = fgetl(fid);count = count + 1;
                    in = strsplit(row,';');                                     % split: minimum 2 inputs required
                    if ~strcmp(char(in),'[]')                                   % proceed/set only if required
                        if length(in) == 2                                      % switch between number of inputs
                            plotGrav_printData(str2double(in(1)),char(in(2)),[],[]);   % no DPI and screen resolution on input
                        elseif length(in) == 3
                            plotGrav_printData(str2double(in(1)),char(in(2)),str2double(in(3)),[]) % no screen resolution on input
                        elseif length(in) == 4
                            plotGrav_printData(str2double(in(1)),char(in(2)),str2double(in(3)),str2num(char(in(4)))); % all inputs
                        end
                    end
                %% Export data
                case 'EXPORT_DATA'
                    row = fgetl(fid);count = count + 1;
                    in = strsplit(row,';');                                     % split: 3 inputs expected = panel switch; all/selected channels switch; and output file name
                    if ~strcmp(char(in(1)),'[]')                                % proceed/set only if required
                        if length(in) == 3
                            switch char(in(1))                                  % switch between panels
                                case '1'
                                    if strcmp(char(in(2)),'1')                  % switch between all/selected channels
                                        plotGrav('export_igrav_all',char(in(3)));
                                    elseif strcmp(char(in(2)),'2')
                                        plotGrav('export_igrav_sel',char(in(3)));
                                    end
                                case '2'
                                    if strcmp(char(in(2)),'1')                  % switch between all/selected channels
                                        plotGrav('export_trilogi_all',char(in(3)));
                                    elseif strcmp(char(in(2)),'2')
                                        plotGrav('export_trilogi_sel',char(in(3)));
                                    end
                                case '3'
                                    if strcmp(char(in(2)),'1')                  % switch between all/selected channels
                                        plotGrav('export_other1_all',char(in(3)));
                                    elseif strcmp(char(in(2)),'2')
                                        plotGrav('export_other1_sel',char(in(3)));
                                    end
                                case '4'
                                    if strcmp(char(in(2)),'1')                  % switch between all/selected channels
                                        plotGrav('export_other2_all',char(in(3)));
                                    elseif strcmp(char(in(2)),'2')
                                        plotGrav('export_other2_sel',char(in(3)));
                                    end
                            end
                        end
                    end
                %% Plar motion effect
                case 'GET_POLAR_MOTION'
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(char(row),'[]')
                       plotGrav('get_polar',char(row));                         % In this case 2 inputs for plotGrav function. First calls the function/section and second sets th additional input. This way, no ui input fields are required.
                    end
                %% Atmacs atmospheric effect
                case 'GET_ATMACS'
                    row = fgetl(fid);count = count + 1;
                    in = strsplit(row,';');                                     % two or three inputs expected
                    if ~strcmp(char(in(1)),'[]')
                        if length(in) == 2
                            plotGrav('get_atmacs',char(in(1)),char(in(2)),'');                         % In this case 2 inputs for plotGrav function. First calls the function/section and second sets th additional input. This way, no ui input fields are required.
                        elseif length(in) == 3
                            plotGrav('get_atmacs',char(in(1)),char(in(2)),char(in(3)));
                        end
                    end
                %% Correction file (apply or show)
                case 'CORRECTION_FILE'
                    row = fgetl(fid);count = count + 1;
                    in = strsplit(row,';');                                     % two inputs expected
                    if ~strcmp(char(in(1)),'[]')
                        if length(in) == 2                                      % two inputs expected = first is file name, second switch between correction apply, correction show
                            if strcmp(char(in(2)),'1')                          % 1 == apply correction
                                plotGrav('correction_file',char(in(1))); 
                            elseif strcmp(char(in(2)),'2')                      % 2 == show correctors
                                plotGrav('correction_file_show',char(in(1))); 
                            end
                        end
                    end
                %% Remove spikes
                case 'REMOVE_SPIKES'                                        % remove spikes using standard deviation*input as condition
                    row = fgetl(fid);count = count + 1;                     % only one input expected = number to multiply the standard deviation.
                    if ~strcmp(char(row),'[]')
                        plotGrav('remove_Xsd',char(row));
                    end
                %% Remove missing/NaN data
                case 'REMOVE_MISSING'   
                    row = fgetl(fid);count = count + 1;                     % only one input expected = maximum time interval in seconds.
                    if ~strcmp(char(row),'[]')
                        plotGrav('interpolate_interval_auto',char(row));
                    end
                %% Filter channels
                case 'FILTER_SELECTED'                                      % will filter selected channels
                    plotGrav('compute_filter_channel',char(row));                       % no input required
                    row = fgetl(fid);count = count + 1;   
                %% Introduce time shift
                case 'TIME_SHIFT'                                           % will affect only selected channels!
                    row = fgetl(fid);count = count + 1;                     % only one input expected = time shift in seconds
                    if ~strcmp(char(row),'[]')
                        plotGrav('compute_time_shift',char(row));           % call time shift function
                    end
                %% Resample all time series to new resolution
                case 'RESAMPLE_ALL'
                    row = fgetl(fid);count = count + 1;                     % only one input expected = time resolution in seconds
                    if ~strcmp(char(row),'[]')
                        plotGrav('compute_decimate',char(row));
                    end
                %% Channels algebra
                case 'CHANNELS_ALGEBRA'
                    row = fgetl(fid);count = count + 1;                     % only one input expected = mathematical expression
                    if ~strcmp(char(row),'[]')
                        plotGrav('simple_algebra',char(row));
                    end
                %% Regression analysis
                case 'REGRESSION'
                    row = fgetl(fid);count = count + 1;                     % only one input expected = mathematical expression (response = predictors)
                    if ~strcmp(char(row),'[]')
                        plotGrav('regression_simple',char(row));
                    end
                %% View: fonts, labels, legends, grid
                case 'SET_DATE_FORMAT'                                      % set date format = x tick labels
                    row = fgetl(fid);count = count + 1;                     % only one input expected = date format (e.g., yyyy)
                    if ~strcmp(char(row),'[]')
                        plotGrav('set_date_1',char(row));
                    end 
                case 'SET_FONT_SIZE'
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(char(row),'[]')
                        plotGrav('set_font_size',char(row));
                    end 
                case 'SET_PLOT_DATE'                                        % range for all x axes
                    row = fgetl(fid);count = count + 1;
                    in = strsplit(row,';');                                 % two inputs expected = starting and ending date
                    if ~strcmp(char(in(1)),'[]')                            % two inputs expected = starting and ending date
                        if length(strsplit(in{1},' ')) == 6                 % input = whole date (2x)
                            plotGrav('push_zoom_in_set',char(in(1)),char(in(2)));
                        elseif length(strsplit(in{1},' ')) == 1             % input is one number (with minus sign) that sets the date to curent-input
                            temp1 = now;temp1 = datevec(temp1+str2double(in(1)));  % Start. use + as input starts with minus sign!
                            temp2 = now;temp2 = datevec(temp2+str2double(in(2)));  % Stop. use + as input starts with minus sign!
                            plotGrav('push_zoom_in_set',sprintf('%4d %02d %02d 00 00 00',temp1(1),temp1(2),temp1(3)),... % do not set hours minutes and seconds.
                                                        sprintf('%4d %02d %02d 00 00 00',temp2(1),temp2(2),temp2(3)));
                        end
                    end 
                case 'SET_TICK_X'                                               % number of ticks on x axes
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(char(row),'[]')
                        plotGrav('set_num_of_ticks_x',char(row));
                    end 
                case 'SET_TICK_Y'                                               % number of ticks on y axes
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(char(row),'[]')
                        plotGrav('set_num_of_ticks_y',char(row));
                    end 
                case 'SET_PLOT_Y_RANGE'                                         % range for Y axes.
                    row = fgetl(fid);count = count + 1;                         % multiple one inputs expected = 6 y axis * 2 values (min max)
                    in = strsplit(row,';');
                    % L1
                    if ~strcmp(char(in(1)),'[]')
                        plotGrav('set_y_L1',char(in(1)));
                    end
                    % R1
                    if ~strcmp(char(in(2)),'[]')
                        plotGrav('set_y_R1',char(in(2)));
                    end
                    % L2
                    if ~strcmp(char(in(3)),'[]')
                        plotGrav('set_y_L2',char(in(3)));
                    end
                    % R2
                    if ~strcmp(char(in(4)),'[]')
                        plotGrav('set_y_R2',char(in(4)));
                    end
                    % L3
                    if ~strcmp(char(in(5)),'[]')
                        plotGrav('set_y_L3',char(in(5)));
                    end
                    % R3
                    if ~strcmp(char(in(6)),'[]')
                        plotGrav('set_y_R3',char(in(6)));
                    end
                case 'SHOW_GRID'
                    row = fgetl(fid);count = count + 1;                         % one inputs expected = 0== off, 1 == on.
                    if ~strcmp(char(row),'[]')
                        if strcmp(char(row),'0')
                            set(findobj('Tag','plotGrav_check_grid'),'Value',0);
                        elseif strcmp(char(row),'1')
                            set(findobj('Tag','plotGrav_check_grid'),'Value',1);
                        end
                        plotGrav('uitable_push');                               % Re-plot
                    end
                case 'SHOW_LABEL'
                    row = fgetl(fid);count = count + 1;                         % one inputs expected = 0== off, 1 == on.
                    if ~strcmp(char(row),'[]')
                        if strcmp(char(row),'0')
                            set(findobj('Tag','plotGrav_check_labels'),'Value',0);
                        elseif strcmp(char(row),'1')
                            set(findobj('Tag','plotGrav_check_labels'),'Value',1);
                        end
                        plotGrav('uitable_push');                               % Re-plot
                    end
                case 'SHOW_LEGEND'
                    row = fgetl(fid);count = count + 1;                         % one inputs expected = 0== off, 1 == on.
                    if ~strcmp(char(row),'[]')
                        if strcmp(char(row),'0')
                            set(findobj('Tag','plotGrav_check_legend'),'Value',0);
                        elseif strcmp(char(row),'1')
                            set(findobj('Tag','plotGrav_check_legend'),'Value',1);
                        end
                        plotGrav('uitable_push');                               % Re-plot
                    end
                %% Set Y labels
                case 'SET_LABEL_Y'                                              % set temporary y labels
                    row = fgetl(fid);count = count + 1;                         % multiple one inputs expected = 6 y axis
                    in = strsplit(row,';');
                    % L1
                    if ~strcmp(char(in(1)),'[]')
                        plotGrav('set_label_L1',char(in(1)));
                    end
                    % R1
                    if ~strcmp(char(in(2)),'[]')
                        plotGrav('set_label_R1',char(in(2)));
                    end
                    % L2
                    if ~strcmp(char(in(3)),'[]')
                        plotGrav('set_label_L2',char(in(3)));
                    end
                    % R2
                    if ~strcmp(char(in(4)),'[]')
                        plotGrav('set_label_R2',char(in(4)));
                    end
                    % L3
                    if ~strcmp(char(in(5)),'[]')
                        plotGrav('set_label_L3',char(in(5)));
                    end
                    % R3
                    if ~strcmp(char(in(6)),'[]')
                        plotGrav('set_label_R3',char(in(6)));
                    end
                %% Set legends
                case 'SET_LEGEND'                                               % set temporary legend
                    row = fgetl(fid);count = count + 1;                         % multiple one inputs expected = 6 y axis
                    in = strsplit(row,';');
                    % L1
                    if ~strcmp(char(in(1)),'[]')
                        plotGrav('set_legend_L1',char(in(1)));
                    end
                    % R1
                    if ~strcmp(char(in(2)),'[]')
                        plotGrav('set_legend_R1',char(in(2)));
                    end
                    % L2
                    if ~strcmp(char(in(3)),'[]')
                        plotGrav('set_legend_L2',char(in(3)));
                    end
                    % R2
                    if ~strcmp(char(in(4)),'[]')
                        plotGrav('set_legend_R2',char(in(4)));
                    end
                    % L3
                    if ~strcmp(char(in(5)),'[]')
                        plotGrav('set_legend_L3',char(in(5)));
                    end
                    % R3
                    if ~strcmp(char(in(6)),'[]')
                        plotGrav('set_legend_R3',char(in(6)));
                    end
                %% Set line width
                case 'SET_LINE_WIDTH'
                    row = fgetl(fid);count = count + 1;                         % one inputs expected = six numbers in one string
                    if ~strcmp(char(row),'[]')
                        plotGrav('set_line_width',char(row));
                    end 
                %% Set new channel names
                case 'SET_CHANNELS_IGRAV'                                       % sets new channel names and update the ui-table of iGrav
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_names_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_names_igrav',char(row));
                    end 
                case 'SET_CHANNELS_TRILOGI'                                       % sets new channel names and update the ui-table of TRiLOGi
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_names_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_names_trilogi',char(row));
                    end 
                case 'SET_CHANNELS_OTHER1'                                       % sets new channel names and update the ui-table of Other1
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_names_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_names_otehr2',char(row));
                    end 
                case 'SET_CHANNELS_OTHER2'                                       % sets new channel names and update the ui-table of Other2
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_names_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_names_other2',char(row));
                    end 
                %% Set new channel units
                case 'SET_UNITS_IGRAV'                                          % sets new channel units and update the ui-table of iGrav
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_names_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_units_igrav',char(row));
                    end 
                case 'SET_UNITS_TRILOGI'                                        % sets new channel units and update the ui-table of TRiLOGi
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_units_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_units_trilogi',char(row));
                    end 
                case 'SET_UNITS_OTHER1'                                         % sets new channel units and update the ui-table of Other1
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_units_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_units_otehr2',char(row));
                    end 
                case 'SET_UNITS_OTHER2'                                         % sets new channel units and update the ui-table of Other2
                    row = fgetl(fid);count = count + 1;                         % one inputs expected. The string splitting will be performed within plotGrav/'edit_channel_units_igrav'
                    if ~strcmp(char(row),'[]')
                        plotGrav('edit_channel_units_other2',char(row));
                    end 

                %% Load data
                case 'LOAD_DATA'
                    plotGrav('load_all_data')                                   % push load data button. No further input (now row) needed
                    row = fgetl(fid);count = count + 1;
                %% Remove data
                case 'REMOVE_DATA'                                              % this will remove all data and re-set ui tables. Settings, howerver, will not be affected!
                    plotGrav('reset_tables')                                    % No input expected => No further input (now row) needed
                    row = fgetl(fid);count = count + 1;
                %% Remove channels
                case 'REMOVE_CHANNEL'                                       % remove required channels
                    row = fgetl(fid);count = count + 1;
                    chan = strsplit(row,';');                               % multiple input possible = selected channels
                    if ~strcmp(char(chan),'[]')                             % proceed/set only if required
                        data_table_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the A ui-table.
                        data_table_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the B ui-table.
                        data_table_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the C ui-table.
                        data_table_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the D ui-table.
                        % First, uncheck all channels so channels selected
                        % prior to calling this part will NOT be deleted
                        for i = 1:size(data_table_igrav,1)
                            data_table_igrav(i,1) = {false};
                        end
                        for i = 1:size(data_table_trilogi,1)
                            data_table_trilogi(i,1) = {false};
                        end
                        for i = 1:size(data_table_other1,1)
                            data_table_other1(i,1) = {false};
                        end
                        for i = 1:size(data_table_other2,1)
                            data_table_other2(i,1) = {false};
                        end
                        
                        % Run for all input values
                        for i = 1:length(chan) 
                            if length(chan{i}) >= 2 % the input for each selection must be at least 2 character long (panel+channel number)
                                channel_number = str2double(char(chan{i}(2:end))); % get the channel number
                                switch char(chan{i}(1)) % switch between panels
                                    case 'A' % A == iGrav
                                        if channel_number <= size(data_table_igrav,1) % check if required channel exists
                                            data_table_igrav(str2double(chan{i}(2:end)),1) = {true}; % select the channel as given on input
                                        end
                                    case 'B' % B == trilogi
                                        if channel_number <= size(data_table_trilogi,1) % check if required channel exists
                                            data_table_trilogi(str2double(chan{i}(2:end)),1) = {true}; % select the channel as given on input
                                        end
                                    case 'C' % C == Other1
                                        if channel_number <= size(data_table_other1,1) % check if required channel exists
                                            data_table_other1(str2double(chan{i}(2:end)),1) = {true}; % select the channel as given on input
                                        end
                                    case 'D' % D == Other2
                                        if channel_number <= size(data_table_other2,1) % check if required channel exists
                                            data_table_other2(str2double(chan{i}(2:end)),1) = {true}; % select the channel as given on input
                                        end
                                end
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_table_igrav); % update ui-table
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_table_trilogi); % update ui-table 
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_table_other1); % update ui-table
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_table_other2); % update ui-table
                        % The plotGrav 'compute_remove_channel' removes 
                        % automatically all selected channels
                        plotGrav('compute_remove_channel');                 % Call removing function
                    end
                %% Pause
                case 'PAUSE'                                                % pauses the compuation for a required number of seconds
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(char(row),'[]')
                        pause(str2double(row));
                    end 
                case 'RESET_VIEW'                                           % zoom out to whole time series.
                    plotGrav('reset_view');                                 % no input.
                    row = fgetl(fid);count = count + 1;
                %% Show Earthquakes
                case 'SHOW_EARTHQUAKES'                                     % plot last 20 earthquakes
                    row = fgetl(fid);count = count + 1;
                    if ~strcmp(char(row),'[]')
                        plotGrav('plot_earthquake',row)
                    end 
                %% Visibility
                % Somethime is is preferable to do not show the plotGrav GUI
                % (like when running on server).
                case 'GUI_OFF'
                    set(findobj('Tag','plotGrav_main_menu'),'Visible','off');   % turn of visibility
                    row = fgetl(fid);
                case 'GUI_ON'
                    set(findobj('Tag','plotGrav_main_menu'),'Visible','on');    % turn of visibility
                    row = fgetl(fid);
                case 'SCRIPT_END'
                    break
                otherwise
                    row = fgetl(fid);count = count + 1; 
            end
        else
            row = fgetl(fid);count = count + 1; 
        end

    end
    pause(1);
    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');             % in case some command has forgotten to turn of the GUI input fields
    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
    set(findobj('Tag','plotGrav_text_status'),'String','Script finished.');
    t = toc;
    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid_log,'Script finished. Duration = %6.1f sec., input file: %s (%04d/%02d/%02d %02d:%02d)\n',t,in_script,ty,tm,td,th,tmm);
    fclose(fid);
    fclose(fid_log);
catch error_message
    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');             % in case some command has forgotten to turn of the GUI input fields
    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
    set(findobj('Tag','plotGrav_text_status'),'String',sprintf('An error at line %3.0f occured during script run.',count));
    t = toc;
    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid_log,'An error at line %3.0f occurred during script run: %s. Duration = %6.1f sec., input file: %s (%04d/%02d/%02d %02d:%02d)\n',count,char(error_message.message),t,in_script,ty,tm,td,th,tmm);
    fclose(fid);
    fclose(fid_log);
end

end % Function