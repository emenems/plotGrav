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

%% Get ui-table, channel names and units. 
% These variables will be used to find selected channels and to create new
% channel names and untis 

% Set panel 'official' panel names. To reduce the code length, use a for loop for
% all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
% filling the structure arrays.
panels = {'igrav','trilogi','other1','other2'};  
% First get all channel names, units and data tables + find selected channels
for i = 1:length(panels)
     % Get units. Will be used for output/plot
    units.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_text_%s',panels{i})),'UserData');
    % get channels names. Will be used for output/plot
    channels.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{i})),'UserData');
    % Get UI tables
    data_table.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data'); 
    % Get selected channels (L1) for each panel
    plot_axesL1.(panels{i}) = find(cell2mat(data_table.(panels{i})(:,1))==1); 
end

try
    %% Fit data
    for i = 1:length(panels)
        % First check if any data selected        & loaded               
        if ~isempty(plot_axesL1.(panels{i})) && ~isempty(data.(panels{i}))
            % Run for all selected channels
            for j = 1:length(plot_axesL1.(panels{i}))
                % get current number of channels. New channels will be appended (first = fit, second = input-fit)
                channel_number = size(data.(panels{i}),2)+1;                % the side of data.(panels{i}) updates with each run (j)                  
                % Check if starting and ending time has been inserted. This
                % feature (local fitting) works, however, only if exact one
                % channel is selected
                if ~isempty(start) && ~isempty(stop) && length(plot_axesL1.(panels{i})) == 1                     
                    data.(panels{i})(time.(panels{i})<start | time.(panels{i})>stop,plot_axesL1.(panels{i})(j)) = []; % remove data outside required time interval
                    time.(panels{i})(time.(panels{i})<start | time.(panels{i})>stop,:) = [];              
                end
                % Depending on polynomial degree, fit the data
                switch deg
                    case 0
                        [out_par,~,out_fit,out_res] = plotGrav_fit(time.(panels{i}),data.(panels{i})(:,plot_axesL1.(panels{i})(j)),'poly0');
                    case 1
                        [out_par,~,out_fit,out_res] = plotGrav_fit(time.(panels{i}),data.(panels{i})(:,plot_axesL1.(panels{i})(j)),'poly1');
                    case 2
                        [out_par,~,out_fit,out_res] = plotGrav_fit(time.(panels{i}),data.(panels{i})(:,plot_axesL1.(panels{i})(j)),'poly2');
                    case 3
                        [out_par,~,out_fit,out_res] = plotGrav_fit(time.(panels{i}),data.(panels{i})(:,plot_axesL1.(panels{i})(j)),'poly3');
                    case 9999                                               % user sets the polynomial coefficients
                        out_par = varargin{1};                              % get user input (varargin = variable number of arguments on input {1} = first input after defined ones)
                        out_fit = polyval(out_par,time.(panels{i}));        % evaluate the polynomial coefficients
                        out_res = data.(panels{i})(:,plot_axesL1.(panels{i})(j)) - out_fit;
                end
                % Two channels will be added/appended, first = fit result, second = residuals
                units.(panels{i})(channel_number) = units.(panels{i})(plot_axesL1.(panels{i})(j)); % append/duplicate units = fit result
                units.(panels{i})(channel_number+1) = units.(panels{i})(plot_axesL1.(panels{i})(j)); % append/duplicate units = fit residuals
                channels.(panels{i})(channel_number) = {sprintf('%s_fit_p%1d',char(channels.(panels{i})(plot_axesL1.(panels{i})(j))),deg)}; % add channel name = fit result
                channels.(panels{i})(channel_number+1) = {sprintf('%s_fitRes_p%1d',char(channels.(panels{i})(plot_axesL1.(panels{i})(j))),deg)}; % add channel name = fit residuals
                data_table.(panels{i})(channel_number,1:7) = {false,false,false,...  % add/append to ui-table = fit result
                                    sprintf('[%2d] %s (%s)',channel_number,char(channels.(panels{i})(channel_number)),char(units.(panels{i})(channel_number))),false,false,false};
                data_table.(panels{i})(channel_number+1,1:7) = {false,false,false,...% add/append to ui-table = fit residuals
                                    sprintf('[%2d] %s (%s)',channel_number+1,char(channels.(panels{i})(channel_number+1)),char(units.(panels{i})(channel_number+1))),false,false,false};
                data.(panels{i})(:,channel_number) = out_fit;               % add data = fit
                data.(panels{i})(:,channel_number+1) = out_res;             % add residuals (see plotGrav_fit.m function for outputs)
                
                % Write to logfile. Due to variable number of estimated
                % parameters (depends on 'deg'), the message is written to
                % logfile in three steps: 1. main message, 2. estimated
                % coefficients, 3. message ending = date of computation.
                [ty,tm,td,th,tmm] = datevec(now);                                       % Time for logfile
                fprintf(fid,'%s channel %d pol%1d fitted = %2.0f, estim. coefficients = ',... % Main massage
                        panels{i},plot_axesL1.(panels{i})(j),deg,channel_number);
                for c = 1:length(out_par)
                    fprintf(fid,'%10.8f, ',out_par(c));                         % Estimated coefficients
                end
                fprintf(fid,'(%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);    % date of compuation
                % Add comment about the new channel with residuals
                fprintf(fid,'%s channel %d pol%1d residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                        panels{i},plot_axesL1.(panels{i})(j),deg,channel_number+1,ty,tm,td,th,tmm);
                clear out_par out_sig out_fit out_res
                clear time_resolution                     % remove variables
            
                % Store data only if no cutting options (start/stop) on
                % input + only once at the end of each panel run
                if (isempty(start) && isempty(stop)) &&   j == length(plot_axesL1.(panels{i}))                                    
                    % Store copied channel names, units and data table
                    set(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data',data_table.(panels{i})); 
                    set(findobj('Tag',sprintf('plotGrav_text_%s',panels{i})),'UserData',units.(panels{i})); 
                    set(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{i})),'UserData',channels.(panels{i})); 
                    % Store data
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);
                end
            end
        end
    end
    message_out = 'Data fitted.';
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
