function message_out = plotGrav_fitData(deg,start,stop,fid,varargin)
%PLOTGRAV_FITDATA estimate fit and compute residuals
% This function allow fitting data to polynomial up to degree 3, or use
% User's coefficient to compute the residuals.
%
% Input:
%   deg     ... polynomial degree. Scalar, e.g., 1. If 0, mean value will
%               be subtracted/fitted. If 9999, user coefficients are used
%               (expecting 5th input parameter, i.e., in vararin{1})
%   start   ... starting time, scalar in matlab datenum format. All time
%               records < start will be removed prior to the fitting.
%               Set to [] if no cutting required.
%   stop    ... ending time, scalar in matlab datenum format. All time
%               records > stop will be removed prior to the fitting.
%               Set to [] if no cutting required.
%   fid     ... logfile file ID, if [], default file will be used.
%   
%
% Output:
%   message_out ... Output message (string), e.g., 'Data fitted'.
%
%                                               M.Mikolaj, 22.09.2015


%% Open the logfile + get time and data matrix
if isempty(fid)
    try
        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
    catch
        fid = fopen('plotGrav_LOG_FILE.log','a');
    end
end
data = get(findobj('Tag','plotGrav_push_load'),'UserData');                 % load all data 
time = get(findobj('Tag','plotGrav_text_status'),'UserData');               % load time vectors

%% Get ui-table, channel names and units. These variables will be used to
% find selected channels and to create new channel names and untis
% Get iGrav data
data_table.igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data');      % get the iGrav ui-table. For finding selected/checked time series + to update the ui-table
units.igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
channels.igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
% Get TRiLOGi
data_table.trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data');  % get the TRiLOGi ui-table. 
units.trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
channels.trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)      
% Get Other1
data_table.other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data');    % get the Other1 table
units.other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
channels.other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
% Get Other2
data_table.other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data');    % get the Other2 table
units.other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
channels.other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)


try
    %% Find selected channles
    % Set panel 'official' names. To reduce the code length, use a for loop for
    % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
    % filling the structure arrays.
    panels = {'igrav','trilogi','other1','other2'};  
    % First find all selected channels
    for i = 1:length(panels)
        plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
    end
    %% Fit data
    for i = 1:length(panels)
        % First check if iGrav data selected        & loaded                    & only one channel selected (function does not work if more than one channel selected for fitting)
        if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i)))) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
            channel_number = size(data.(char(panels(i))),2)+1;                  % get current number of channels. Two new channels will be appended (first = fit, second = input-fit)
            if ~isempty(start) && ~isempty(stop)                                % Check if starting and ending time has been inserted
                data.(char(panels(i)))(time.(char(panels(i)))<start | time.(char(panels(i)))>stop,:) = []; % remove data outside required time interval
                time.(char(panels(i)))(time.(char(panels(i)))<start | time.(char(panels(i)))>stop,:) = [];              
            end
            switch deg
                case 0
                    [out_par,~,out_fit,out_res] = plotGrav_fit(time.(char(panels(i))),data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))),'poly0');
                case 1
                    [out_par,~,out_fit,out_res] = plotGrav_fit(time.(char(panels(i))),data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))),'poly1');
                case 2
                    [out_par,~,out_fit,out_res] = plotGrav_fit(time.(char(panels(i))),data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))),'poly2');
                case 3
                    [out_par,~,out_fit,out_res] = plotGrav_fit(time.(char(panels(i))),data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))),'poly3');
                case 9999
                    out_par = varargin{1};                                  % get user input (varargin = variable number of arguments on input {1} = first input after defined ones)
                    out_fit = polyval(out_par,time.(char(panels(i))));      % evaluate the polynomial coefficients
					out_res = data.igrav(:,plot_axesL1.(char(panels(i)))) - out_fit;
            end
            % Two channels will be added/appended, first = fit result, second = residuals
            units.(char(panels(i)))(channel_number) = units.(char(panels(i)))(plot_axesL1.(char(panels(i)))); % append/duplicate units = fit result
            units.(char(panels(i)))(channel_number+1) = units.(char(panels(i)))(plot_axesL1.(char(panels(i)))); % append/duplicate units = fit residuals
            channels.(char(panels(i)))(channel_number) = {sprintf('%s_fit_p%1d',char(channels.(char(panels(i)))(plot_axesL1.(char(panels(i))))),deg)}; % add channel name = fit result
            channels.(char(panels(i)))(channel_number+1) = {sprintf('%s_fitRes_p%1d',char(channels.(char(panels(i)))(plot_axesL1.(char(panels(i))))),deg)}; % add channel name = fit residuals
            data_table.(char(panels(i)))(channel_number,1:7) = {false,false,false,...  % add/append to ui-table = fit result
                                    sprintf('[%2d] %s (%s)',channel_number,char(channels.(char(panels(i)))(channel_number)),char(units.(char(panels(i)))(channel_number))),false,false,false};
            data_table.(char(panels(i)))(channel_number+1,1:7) = {false,false,false,...% add/append to ui-table = fit residuals
                                    sprintf('[%2d] %s (%s)',channel_number+1,char(channels.(char(panels(i)))(channel_number+1)),char(units.(char(panels(i)))(channel_number+1))),false,false,false};
            data.(char(panels(i)))(:,channel_number) = out_fit;                 % add data = fit
            data.(char(panels(i)))(:,channel_number+1) = out_res;               % add residuals (see plotGrav_fit.m function for outputs)
            % Write to logfile. Due to variable number of estimated
            % parameters (depends on 'deg'), the message is written to
            % logfile in three steps: 1. main message, 2. estimated
            % coefficients, 3. message ending = date of computation.
            [ty,tm,td,th,tmm] = datevec(now);                                       % Time for logfile
            fprintf(fid,'iGrav channel %d pol%1d fitted = %2.0f, estim. coefficients = ',... % Main massage
                    plot_axesL1.(char(panels(i))),deg,channel_number);
            for c = 1:length(out_par)
                fprintf(fid,'%10.8f, ',out_par(c));                         % Estimated coefficients
            end
            fprintf(fid,'(%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);    % date of compuation
            % Add comment about the new channel with residuals
            fprintf(fid,'iGrav channel %d pol%1d residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                    plot_axesL1.(char(panels(i))),deg,channel_number+1,ty,tm,td,th,tmm);
            clear out_par out_sig out_fit out_res
            clear time_resolution                     % remove variables
        end
    end
    %% Store data
    % This part cannot be in the 'panels' for loop because of the way how the
    % data is stored in uicontrol's UserData containers, e.g.,'Tag','plotGrav_uitable_igrav_data'
    if isempty(start) && isempty(stop)                                      % store data only if no cutting options (start/stop) on input
        set(findobj('Tag','plotGrav_push_load'),'UserData',data);           % store the data matrices
        % iGrav
        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_table.igrav); % update table
        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units.igrav);   % update iGrav units
        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels.igrav); % update iGrav channels (names)
        % TRiLOGi
        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_table.trilogi); 
        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units.trilogi);
        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels.trilogi); 
        % Other1
        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_table.other1);
        set(findobj('Tag','plotGrav_text_other1'),'UserData',units.other1);
        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels.other1);
        % Other2
        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_table.other2); 
        set(findobj('Tag','plotGrav_text_other2'),'UserData',units.other2);
        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels.other2); 
    end
    message_out = 'Data fitted (providing one channle was selected).';
    fclose(fid);
catch error_message
    if strcmp(error_message.identifier,'MATLAB:license:checkouterror')
        message_out = 'Upps, no licence (Fitting Toolbox?)';
    else
        message_out = 'An (unkonwn) error occur during fitting.';
    end
    fclose(fid);
end

end % Function
