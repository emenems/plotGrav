function plotGrav_exportData(time,data,channels,units,select,fid,panel_name,output_file,varargin)
%PLOTGRAV_EXPORTDATA Export loaded plodGrav data to supported format
% Export data sotred temporary in plotGrav memory
%
% Input:
%   time    ... time vector in matlab format (datenum)
%   data    ... data matrix (columns correspond to time series)
%   channels... time series names (columns of data matrix). Stored in
%               cell arrray,e.g., {'Gravity','Pressure'}.
%   unints  ... Units related to 'channels' stored in cell arrray,
%               e.g., {'nm/s^2','mbar'}.
%   select  ... channels to be exported (column numbers). Set to [] if all
%               columns should be exported.
%   fid     ... output/logfile file ID (get using fopen). If [], no
%                       logfile writing.
%   panel_name. string used as prefix to write in logfile. This
%               string should describe the input file. Will not be
%               used if fid is empty. e.g., 'iGrav'
%   output_file full file name of output file. If [], will open a dialog
%               window for selection.
%

% Prepare logfile
if isempty(fid)                                         
    try
        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % try to get the logfile name
    catch
        fid = fopen('plotGrav_LOG_FILE.log','a');                           % otherwise use default logfile name
    end
end
[ty,tm,td,th,tmm] = datevec(now);                                           % get current time for logfile
                    
if isempty(data) || isempty(time)
    set(findobj('Tag','plotGrav_text_status'),'String',sprintf('No data in %s',panel_name));drawnow % continue only if some data has been loaded
else
    if isempty(output_file)                                                 % if no input
        [name,path,file_switch] = uiputfile({'*.tsf';'*.mat'},sprintf('Select your %s output file',panel_name)); % get output file. Store also 'file_switch' = tsf or mat
        output_file = fullfile(path,name);
    else
        name = 1;
        switch output_file(end-3:end)
            case '.tsf'
                file_switch = 1;
            case '.mat'
                file_switch = 2;
            otherwise
                file_switch = 9999;
        end
    end
    if name == 0                                                            % If cancelled-> no output/do not continue
        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file!');drawnow % send to status bar
    else
        set(findobj('Tag','plotGrav_text_status'),'String',sprintf('Writing %s data...',panel_name));drawnow % status
        if isempty(select)                                                  % [] => export all columns
            try
                switch file_switch                                          % switch between supported export file formats
                    case 1                                                  % TSF export (3 decimal places)
                        dataout = [datevec(time),data];                     % standard input for plotGrav_writetsf function
                        for i = 1:length(units)
                            comment(i,1:4) = {'plotGrav',panel_name,char(channels(i)),char(units(i))};  % create tsf header (input for plotGrav_writetsf function)
                        end
                        plotGrav_writetsf(dataout,comment,output_file,3);       % write to tsf 
                        set(findobj('Tag','plotGrav_text_status'),'String',sprintf('%s data have been written to selected file.',panel_name));drawnow % status
                        fprintf(fid,'%s data written to %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,output_file,ty,tm,td,th,tmm);
                    case 2                                                      % MAT export (double precision)
                        dataout.time = time;
                        dataout.data = data;
                        dataout.channels = channels;
                        dataout.units = units;
                        save(output_file,'dataout','-v7.3');
                        clear dataout
                        set(findobj('Tag','plotGrav_text_status'),'String',sprintf('%s data have been written to selected file.',panel_name));drawnow % status
                        fprintf(fid,'%s data written to %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,output_file,ty,tm,td,th,tmm);
                    otherwise
                        set(findobj('Tag','plotGrav_text_status'),'String','You have selected not supported file format!');drawnow % send to status bar
                end
                fclose(fid);
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Time series NOT exported!');drawnow % send to status bar
                fclose('all');
            end
        else                                                                % => export only selected chennels/columns.
            try
                switch  file_switch                                         % switch between supported export file formats
                    case 1                                                  % TSF export (3 decimal places)
                        dataout = [datevec(time),data(:,select)]; % standard input for plotGrav_writetsf function + use only selected channels
                        channels = channels(select);
                        units = units(select);
                        for i = 1:length(units)
                            comment(i,1:4) = {'plotGrav',panel_name,char(channels(i)),char(units(i))};  % create tsf header (input for plotGrav_writetsf function)
                        end
                        plotGrav_writetsf(dataout,comment,output_file,3);       % write to tsf 
                        set(findobj('Tag','plotGrav_text_status'),'String',sprintf('%s data have been written to selected file.',panel_name));drawnow % status
                        fprintf(fid,'%s data written to %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,output_file,ty,tm,td,th,tmm);
                    case 2                                                      % MAT export (double precision)
                        dataout.time = time;
                        dataout.data = data(:,select);
                        dataout.channels = channels(:,select);
                        dataout.units = units(:,select);
                        save(output_file,'dataout','-v7.3');
                        clear dataout
                        set(findobj('Tag','plotGrav_text_status'),'String',sprintf('%s data have been written to selected file.',panel_name));drawnow % status
                        fprintf(fid,'%s data written to %s (%04d/%02d/%02d %02d:%02d)\n',panel_name,output_file,ty,tm,td,th,tmm);
                    otherwise
                        set(findobj('Tag','plotGrav_text_status'),'String','You have selected not supported file format!');drawnow % send to status bar
                end
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Selected time series NOT exported!');drawnow % send to status bar
                fclose('all');
            end
            
        end
        
    end
end
					
					


end