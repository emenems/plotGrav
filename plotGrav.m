function plotGrav(in_switch,varargin)
%PLOTGRAV visualize gravity and hydrological time series
% This GUI is designed for iGrav006. Additionally, user can load SG030 and
% other time series, provided these are in supported file format. 
% The aim of this function is to visualize time series recorded by iGrav 
% as well as iGFE (field enclosure) together with other hydrological and 
% gravity time series. This function generates the GUI. Run this function in
% order to use plotGrav.
% 
% Required functions:
%   plotGrav_Atmacs_and_EOP.m
%   plotGrav_conv.m
%   plotGrav_findTimeStep.m
%   plotGrav_fit.m
%   plotGrav_fitData.m
%   plotGrav_FTP.m
%   plotGrav_loadData.m
%   plotGrav_loadtsf.m
%   plotGrav_exportData.m
%   plotGrav_plotData.m
%   plotGrav_printData.m
%   plotGrav_readcsv.m
%   plotGrav_scriptRun.m
%   plotGrav_spectralAnalysis.m
%   plotGrav_writetsf.m
% These functions must be stored in the same folder as plotGrav.m
% 
% Some comments/system requirements:
% - it is allowed to run only one window per Matlab.
% - this function was tested using Matlab r2013a + statistical toolbox + 
%   curve fitting + signal processing toolbox.
% - should work also using Matlab r2014b. Works not with Octave due to missing
%	uitable function.
% - the loading of all data (especially second iGrav/SG030) takes some time!
%
% iGrav/SG030 visualisation procedure:
%	First select either path with iGrav data (root folder, i.e.,
% - after loading, the function adds 7 new channels to the iGrav tsf. These
%   are the filtered and corrected gravity values (provided filter and
%   tides are set correctly). The filtered values are obtained after
%   convolution corrected for phase shift and interpolated to original time
%   resolution.
% - the spectral analysis can be computed for the longest interval without
%   interruption or for re-interpolated time series.
% - prior to the spectral anlysis, a linear trend is removed.
% - TRiLOGi files contain many errors. Therefore, check the code if new
%   TRiLOGi version is available.
% - It is not recommended to compute spectral analysis for TRiLOGi data
%   (see the two comments above).
% - any change of: drift, calib.factor, admittance, time interval or input
%   files requires new loading of data.
% - any change of: grid, legend, labels require a re-plot, i.e. select
%   another channel or press Reset view.
% - the GUI is designed to fit the screen,i.e., uses normalized uints.
% - All tsf output files are written with 3 decimal places.
% - EOF/PCA results are automatically shown in plot 2 (L2)
% 
% 
%                                                   M.Mikolaj, 23.9.2015
%                                                   mikolaj@gfz-potsdam.de

% In the following, the comments are either on the right side
% of the code or befor the actual code that is commented.
% Start code. 
if nargin == 0																% Standard start for GUI function, i.e. no function input (nargin == 0) => create GUI. Otherwise use Switch/case to run required code sections
    check_open_window = get(findobj('Tag','plotGrav_check_legend'),'Value'); % check if no other plotGrav window is open (works only with one window per Matlab)
    if numel(check_open_window)>0											% do not continue if some window already open
        fprintf('Please use only one app window in Matlab\n')               % send message to command window
    else																	% Otherwise, continue with GUI generating
%%%%%%%%%%%%%%%%%%%%%%%%%%%% G U I %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Generate GUI
        % Set default values before reading init file
        path_data_a = '';                                                    % ROOT file path to data_a data, i.e., without year, month and day information. 
        path_data_b = '';                                                  % Folder with TRiLOGi data (this folder should contain all TRiLOGi files in *.tsf format).
		file_data_c = '';                                                   % Full file name for Other1 time series. If empty ('', or []) not loaded.
        file_data_d = '';                                                   % Full file name for Other2 time series. If empty ('', or []) not loaded.
        file_tides = '';                                                    % File in *.tsf format with Tidal effect (first channel). This file will be used only if data_a or SG030 data are loaded.
        file_filter = '';                                                   % File with filter coefficients in modified ETERNA format (just comment the header). This file will be used only if data_a or SG030 data are loaded.
        file_logfile = 'plotGrav_LOG_FILE.log';								% Full file name for Log-file with all important information
        path_webcam = '';                                                   % Path to Webcam Snapshots
        earthquake_web = 'http://geofon.gfz-potsdam.de/eqinfo/list.php';	% URL to webpage with earthquake information. This parameter CANNOT be changed within GUI
        earthquake_data = 'http://geofon.gfz-potsdam.de/eqinfo/list.php?latmin=&latmax=&lonmin=&lonmax=&magmin='; % SQL data with list of last earthquakes. This parameter CANNOT be changed within GUI
		set_admittance = '-3.0';                                            % admittance factor
        set_calib_factor = '1';                                             % calibration factor = multiplicator (for data_a only)
        set_calib_phase = '0';                                              % phase delay in seconds (for data_a only)
        set_resample_a = '60';                                              % resampling intraval in second (for data_a only)
        set_start = datevec(now-7);                                         % starting time
        set_stop = datevec(now-1);                                          % end time
        data_a_prefix = 'iGrav006';                                          % Instrument name for data_a panel data reading
        % Read initial setting file
        try
            count = 0; % count lines to point to possible error
            % Open file for reading (one row after another)
            fid = fopen('plotGrav.ini','r'); 
            row = fgetl(fid);                                                   % Get first row (usualy comment).
            while ischar(row)                                                   % continue reading whole file
                if ~strcmp(row(1),'%')                                          % run code only if not comment
                    switch row                                                  % switch between commands depending on the Script switch.
                        %% Set time interval
                        case 'TIME_START'                                           % Starting time
                            row = fgetl(fid);count = count + 1;                     % read the date
                            if ~strcmp(row,'[]')                                    % proceed/set only if required
                                date = strsplit(row,';');                           % By default multiple inputs are delimited by ;. If one input (with minus sign), then set to current time - input
                                if length(date) == 1
                                    date = char(date);
                                    if strcmp(date(1),'-');
                                        temp = now;
                                        set_start = datevec(temp+str2double(date)); % use + as input starts with minus sign!
                                        set_start(4) = 00;
                                    end
                                else
                                    for i = 1:4
                                        set_start(i) = str2double(date{i});
                                    end
                                end
                            end
                        case 'TIME_STOP'                                            % Stop time
                            row = fgetl(fid);count = count + 1;                     % read the date
                            if ~strcmp(row,'[]')                                    % proceed/set only if required
                                date = strsplit(row,';');                            % By default multiple inputs are delimited by ; If one input (with minus sign), then set to current time - input
                                if length(date) == 1
                                    date = char(date);
                                    if strcmp(date(1),'-');
                                        temp = now;
                                        set_stop = datevec(temp+str2double(date)); % use + as input starts with minus sign!
                                        set_stop(4) = 24;
                                    end
                                else
                                    for i = 1:4
                                        set_stop(i) = str2double(date{i});
                                    end
                                end
                            end
                        case 'RESAMPLE_A' % affect only data_a panel and only if data_a original data is loaded!
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                set_resample_a = 1; % no resampling for resolution < 2 seconds
                            else
                                set_resample_a = row;
                            end
                        %% Setting file paths
                        case 'FILE_IN_DATA_A'
                            row = fgetl(fid);count = count + 1;                 % Get next line/row. The plotGrav script are designed as follows: first the switch and next line the inputs
                            if strcmp(row,'[]')                                 % [] symbol means no input                           
                                path_data_a = '';
                            else
                                path_data_a = row;                               % otherwise set the input file
                            end
                        case 'FILE_IN_DATA_B'
                            row = fgetl(fid);count = count + 1;                 % Get next line/row. The plotGrav script are designed as follows: first the switch and next line the inputs
                            if strcmp(row,'[]')                                 % [] symbol means no input                           
                                path_data_b = '';
                            else
                                path_data_b = row;                             % otherwise set the input file
                            end
                        case 'FILE_IN_DATA_C'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                file_data_c = '';
                            else
                                file_data_c = row;
                            end
                        case 'FILE_IN_DATA_D'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                file_data_d = '';
                            else
                                file_data_d = row;
                            end
                        case 'FILE_IN_TIDES'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                file_tides = '';
                            else
                                file_tides = row;
                            end
                        case 'FILE_IN_FILTER'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                file_filter = '';
                            else
                                file_filter = row;
                            end
                        case 'FILE_IN_WEBCAM'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                path_webcam = ''; 
                            else
                                path_webcam = row;
                            end
                        case 'FILE_IN_LOGFILE'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                file_logfile = '';
                            else
                                file_logfile = row;
                            end
                        %% File naming
                        case 'DATA_A_PREFIX_NAME'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                data_a_prefix = 'iGrav006';
                            else
                                data_a_prefix = row;
                            end
                        
                        %% Set admittance & calibration & Drift (data_a panel)
                        case 'ADMITTANCE_FACTOR'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                set_admittance = '0';
                            else
                                set_admittance = row;
                            end
                        case 'CALIBRATION_FACTOR'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                set_calib_factor = '1';
                            else
                                set_calib_factor = row;
                            end
                        case 'CALIBRATION_DELAY'
                            row = fgetl(fid);count = count + 1; 
                            if strcmp(row,'[]')
                                set_calib_phase = '1';
                            else
                                set_calib_phase = row;
                            end
                        case 'DRIFT_SWITCH'
                            row = fgetl(fid);count = count + 1;
                            coef = strsplit(row,';');                       % multiple input possible => split it (first=polynomial, second=possibly polynomial coefficients
                            if ~strcmp(char(coef),'[]')                     % proceed/set only if required
                                set_drift_switch = str2double(coef(1));
                                if strcmp(char(coef(1)),'6')                % 6 = user defined polynomial ceoffients
                                    set_drift_val = char(coef(2:end));
                                else
                                    set_drift_val = [];
                                end
                            end
                    otherwise
                        row = fgetl(fid);count = count + 1; 
                    end
                else
                    row = fgetl(fid);count = count + 1; 
                end
            end
            fclose(fid);
        catch err_mess
            if count == 0
                errordlg('Could not read plotGrav.ini file');
            else
                errordlg(sprintf('Error at %d line: \n%s',count,err_mess.message));
                fclose(fid);
            end
        end
        
        % Get screen-resolution for future GUI window, i.e., the window is ALWAYS fitted to current monitor resolution.
        scrs = get(0,'screensize');			
		% Start creating GUI
		F1 = figure('Position',[50 50 scrs(3)-50*2, scrs(4)-50*3],...       % create main window
                    'Tag','plotGrav_main_menu','Resize','on','Menubar','none','ToolBar','none',...
                    'NumberTitle','off','Color',[0.941 0.941 0.941],...
                    'Name','plotGrav: plot gravity time series');
					
        % Start creating interface menu
		% Main FILE menu (selection of files: inputs and outputs)
        m1 	 = 	uimenu('Label','File');
			% Sub-FILE menu
			m10  = 	uimenu(m1,'Label','Select');
				% Sub-Sub-FILE menu
				m101 = 	uimenu(m10,'Label','Data A');
					uimenu(m101,'Label','Path','CallBack','plotGrav select_data_a');
					uimenu(m101,'Label','File','CallBack','plotGrav select_data_a_file',...
                        'Tag','plotGrav_menu_data_a_file','UserData',data_a_prefix);
				m102 = 	uimenu(m10,'Label','TRiLOGi');
					uimenu(m102,'Label','Path','CallBack','plotGrav select_data_b');
					uimenu(m102,'Label','File','CallBack','plotGrav select_data_b_file');
            m15 = uimenu(m1,'Label','Append channels');
                uimenu(m15,'Label','to DATA A','CallBack','plotGrav append_channels data_a');
                uimenu(m15,'Label','to DATA B','CallBack','plotGrav append_channels data_b');
                uimenu(m15,'Label','to DATA C','CallBack','plotGrav append_channels data_c');
                uimenu(m15,'Label','to DATA D','CallBack','plotGrav append_channels data_d');
            m12  = 	uimenu(m1,'Label','Export');
				uimenu(m10,'Label','Other1 file','CallBack','plotGrav select_data_c');
				uimenu(m10,'Label','Other2 file','CallBack','plotGrav select_data_d');
				uimenu(m10,'Label','Tides tsf file','CallBack','plotGrav select_tides');
				uimenu(m10,'Label','Filter file','CallBack','plotGrav select_filter');
				uimenu(m10,'Label','Webcam path','CallBack','plotGrav select_webcam');
				uimenu(m10,'Label','7zip exe','CallBack','plotGrav select_unzip');
				uimenu(m10,'Label','Log File','CallBack','plotGrav select_logfile');
				m121 = 	uimenu(m12,'Label','DATA A');
					uimenu(m121,'Label','All channels','Callback','plotGrav export_data_a_all');
					uimenu(m121,'Label','Selected channels (L1)','Callback','plotGrav export_data_a_sel');
				m122  = uimenu(m12,'Label','TRiLOGi data');
					uimenu(m122,'Label','All channels','Callback','plotGrav export_data_b_all');
					uimenu(m122,'Label','Selected channels (L1)','Callback','plotGrav export_data_b_sel');
				m123 = 	uimenu(m12,'Label','Other1 data');
					uimenu(m123,'Label','All channels','Callback','plotGrav export_data_c_all');
					uimenu(m123,'Label','Selected channels (L1)','Callback','plotGrav export_data_c_sel');
				m124  = uimenu(m12,'Label','Other2 data');
					uimenu(m124,'Label','All channels','Callback','plotGrav export_data_d_all');
					uimenu(m124,'Label','Selected channels (L1)','Callback','plotGrav export_data_d_sel');
			m13 = 	uimenu(m1,'Label','Print');
				uimenu(m13,'Label','All plots','CallBack','plotGrav print_all',...	
					'Tag','plotGrav_menu_print_all','UserData',[]); 		% this uimenu will be used to store file name for printing output (plot all)
				uimenu(m13,'Label','L1+R1','CallBack','plotGrav print_one',...
					'Tag','plotGrav_menu_print_one','UserData',[]); 		% this uimenu will be used to store file name for printing output (first plot)
				uimenu(m13,'Label','L1+R1+L2+R2','CallBack','plotGrav print_two',...
					'Tag','plotGrav_menu_print_two','UserData',[]);			% this uimenu will be used to store file name for printing output (first and second plot)
				uimenu(m13,'Label','Editable figure','CallBack','plotGrav print_three',...
					'Tag','plotGrav_menu_print_three','UserData',[]);		% this uimenu will be used to store file name for printing output (Plot 1 + 2 + 3)
            m14 = uimenu(m1,'Label','Correction file');
			uimenu(m14,'Label','Apply (read channel)','CallBack','plotGrav correction_file','Tag',...
					'plotGrav_menu_correction_file','UserData',[]);			% this uimenu will be used to store file name with correction file name
            uimenu(m14,'Label','Apply to selected','CallBack','plotGrav correction_file_selected');
            uimenu(m14,'Label','Show','CallBack','plotGrav correction_file_show');
			uimenu(m1,'Label','Script file','CallBack','plotGrav script_run');
				
        % Main VIEW menu (change the plot appearance or show additional information)
        m2 = uimenu('Label','View');
            % uimenu(m2,'Label','Convert/Update date','Callback','plotGrav push_date'); % use for setting exact X limits
			% Sub-VIEW menu
            uimenu(m2,'Label','Data points','CallBack','plotGrav set_data_points','UserData',1,...
                    'Tag','plotGrav_menu_set_data_points');
			uimenu(m2,'Label','Font Size','CallBack','plotGrav set_font_size','UserData',9,...
                    'Tag','plotGrav_menu_set_font_size');
            uimenu(m2,'Label','Grid On/Off','Callback','plotGrav show_grid');
			m22 = uimenu(m2,'Label','Label');
				uimenu(m22,'Label','On/Off','Callback','plotGrav show_label');
				m221 = uimenu(m22,'Label','Set');
                    uimenu(m221,'Label','L1','Callback','plotGrav set_label_L1');
                    uimenu(m221,'Label','R1','Callback','plotGrav set_label_R1');
                    uimenu(m221,'Label','L2','Callback','plotGrav set_label_L2');
                    uimenu(m221,'Label','R2','Callback','plotGrav set_label_R2');
                    uimenu(m221,'Label','L3','Callback','plotGrav set_label_L3');
                    uimenu(m221,'Label','R3','Callback','plotGrav set_label_R3');
            m23 = uimenu(m2,'Label','Legend');
				uimenu(m23,'Label','On/Off','Callback','plotGrav show_legend');
				m231 = uimenu(m23,'Label','Set');
                    uimenu(m231,'Label','L1','Callback','plotGrav set_legend_L1');
                    uimenu(m231,'Label','R1','Callback','plotGrav set_legend_R1');
                    uimenu(m231,'Label','L2','Callback','plotGrav set_legend_L2');
                    uimenu(m231,'Label','R2','Callback','plotGrav set_legend_R2');
                    uimenu(m231,'Label','L3','Callback','plotGrav set_legend_L3');
                    uimenu(m231,'Label','R3','Callback','plotGrav set_legend_R3');
            uimenu(m2,'Label','Line width','Callback','plotGrav set_line_width','Tag','plotGrav_menu_line_width',...
                        'UserData',[0.5 0.5 0.5 0.5 0.5 0.5]);              % Store line width
            m24 = uimenu(m2,'Label','X axis');
                m241 = uimenu(m24,'Label','Range');
                    uimenu(m241,'Label','Select (zoom in)','Callback','plotGrav push_zoom_in');
                    uimenu(m241,'Label','Set (date)','Callback','plotGrav push_zoom_in_set');
                    uimenu(m24,'Label','Num. of ticks','Tag','plotGrav_menu_num_of_ticks_x','UserData',9,...
                        'CallBack','plotGrav set_num_of_ticks_x');
                    m2411 = uimenu(m24,'Label','Date format','Tag','plotGrav_menu_date_format','UserData','dd/mm/yyyy HH:MM');
                        uimenu(m2411,'Label','Set','CallBack','plotGrav set_date_1');
                        uimenu(m2411,'Label','Help','CallBack','plotGrav set_date_2');
			m21 = uimenu(m2,'Label','Y axis');
                uimenu(m21,'Label','Num. of ticks','Tag','plotGrav_menu_num_of_ticks_y','UserData',5,...
                        'CallBack','plotGrav set_num_of_ticks_y');
                m211 = uimenu(m21,'Label','Reverse');
                    uimenu(m211,'Label','L1','Callback','plotGrav reverse_l1','UserData',1,... % UserData is used as information for reversions (1 == normal, 0 == reverse)
                        'Tag','plotGrav_menu_reverse_l1');
                    uimenu(m211,'Label','R1','Callback','plotGrav reverse_r1','UserData',1,... % UserData is used as information for reversions (1 == normal, 0 == reverse)
                        'Tag','plotGrav_menu_reverse_r1');
                    uimenu(m211,'Label','L2','Callback','plotGrav reverse_l2','UserData',1,... % UserData is used as information for reversions (1 == normal, 0 == reverse)
                        'Tag','plotGrav_menu_reverse_l2');
                    uimenu(m211,'Label','R2','Callback','plotGrav reverse_r2','UserData',1,... % UserData is used as information for reversions (1 == normal, 0 == reverse)
                        'Tag','plotGrav_menu_reverse_r2');
                    uimenu(m211,'Label','L3','Callback','plotGrav reverse_l3','UserData',1,... % UserData is used as information for reversions (1 == normal, 0 == reverse)
                        'Tag','plotGrav_menu_reverse_l3');
                    uimenu(m211,'Label','R3','Callback','plotGrav reverse_r3','UserData',1,... % UserData is used as information for reversions (1 == normal, 0 == reverse)
                        'Tag','plotGrav_menu_reverse_r3');
                m212 = uimenu(m21,'Label','Range');
                    m2121 = uimenu(m212,'Label','Set');
                        uimenu(m2121,'Label','L1','Callback','plotGrav set_y_L1');
                        uimenu(m2121,'Label','R1','Callback','plotGrav set_y_R1');
                        uimenu(m2121,'Label','L2','Callback','plotGrav set_y_L2');
                        uimenu(m2121,'Label','R2','Callback','plotGrav set_y_R2');
                        uimenu(m2121,'Label','L3','Callback','plotGrav set_y_L3');
                        uimenu(m2121,'Label','R3','Callback','plotGrav set_y_R3');
                    uimenu(m212,'Label','Select','Callback','plotGrav push_zoom_y');
                uimenu(m2,'Label','Plot type','Tag','plotGrav_view_plot_type','UserData',[1 1 1 1 1 1],'Callback','plotGrav set_plot_type');
                uimenu(m2,'Label','Reset view','Callback','plotGrav reset_view');
        % Main SHOW menu (plot/show additional informations)
        m3 = uimenu('Label','Show');
            % Sub-SHOW menu
			m30 = uimenu(m3,'Label','Earthquakes');
				% Sub-Sub-VIEW meanu
				uimenu(m30,'Label','List','CallBack','plotGrav show_earthquake',... % this uimenu contains link to earthquake web page
					'UserData',earthquake_web,'Tag','plotGrav_menu_show_earthquake');
				uimenu(m30,'Label','Plot (last 20)','CallBack','plotGrav plot_earthquake',... % contains link to earthquake data
					'Tag','plotGrav_menu_plot_earthquake','UserData',earthquake_data);
			uimenu(m3,'Label','File paths','CallBack','plotGrav show_paths');
			uimenu(m3,'Label','Filter','CallBack','plotGrav show_filter');
            uimenu(m3,'Label','Webcam','Callback','plotGrav push_webcam',...
					'Tag','plotGrav_menu_webcam','UserData',path_webcam); 	% Store file path with webcam snapshot
        % Main COMPUTE menu (perform analysis on visualized time series)
        m4 = uimenu('Label','Compute');
			% Sub-COMPUTE menu
			uimenu(m4,'Label','Algebra','CallBack','plotGrav simple_algebra'); 
			uimenu(m4,'Label','Atmacs','CallBack','plotGrav get_atmacs'); 	% the Atmacs URL will be set by user via string input
			m40 = uimenu(m4,'Label','Correlation');
				uimenu(m40,'Label','Simple all','CallBack','plotGrav correlation_matrix');
				uimenu(m40,'Label','Simple select','CallBack','plotGrav correlation_matrix_select');
				uimenu(m40,'Label','Cross','CallBack','plotGrav correlation_cross');
			m45 = uimenu(m4,'Label','Derivative');
                uimenu(m45,'Label','Difference','CallBack','plotGrav compute_derivative');
                uimenu(m45,'Label','Cumulative sum','CallBack','plotGrav compute_cumsum');
			m42 = uimenu(m4,'Label','EOF/PCA (beta)'); 						% EOF/PCA in beta version
				uimenu(m42,'Label','Compute','CallBack','plotGrav compute_eof',...
					'Tag','plotGrav_menu_compute_eof','UserData',[]); 		% UserData container will be used to store EOF results
% 				uimenu(m42,'Label','Export PCs','CallBack','plotGrav export_pcs');
% 				uimenu(m42,'Label','Export reconstructed time.series','CallBack','plotGrav export_rec_time_series');
				uimenu(m42,'Label','Export EOF/PCs','CallBack','plotGrav export_eof_pcs');
			uimenu(m4,'Label','Filter channel','CallBack','plotGrav compute_filter_channel');
			m43 = uimenu(m4,'Label','Fit');
				uimenu(m43,'Label','Subtract mean','CallBack','plotGrav fit_constant');
				uimenu(m43,'Label','Linear','CallBack','plotGrav fit_linear');
				uimenu(m43,'Label','Quadratic','CallBack','plotGrav fit_quadratic');
				uimenu(m43,'Label','Cubic','CallBack','plotGrav fit_cubic');
				uimenu(m43,'Label','Set coefficients','CallBack','plotGrav fit_user_set');
                uimenu(m43,'Label','Fit locally','CallBack','plotGrav fit_local');
%        		m431 = uimenu(m43,'Label','Sine');
%               	uimenu(m431,'Label','One','CallBack','plotGrav fit_sine1');
            uimenu(m4,'Label','Pol+LOD','CallBack','plotGrav get_polar');
			uimenu(m4,'Label','Regression','CallBack','plotGrav regression_simple');
			m45 = uimenu(m4,'Label','Re-sample');
                uimenu(m45,'Label','All','CallBack','plotGrav compute_decimate');
                uimenu(m45,'Label','DATA A','CallBack','plotGrav compute_decimate_select data_a');
                uimenu(m45,'Label','DATA B','CallBack','plotGrav compute_decimate_select data_b');
                uimenu(m45,'Label','DATA C','CallBack','plotGrav compute_decimate_select data_c');
                uimenu(m45,'Label','DATA D','CallBack','plotGrav compute_decimate_select data_d');
			m41 =  uimenu(m4,'Label','Spectral analysis');
				uimenu(m41,'Label','Max valid interval','Callback','plotGrav compute_spectral_valid');
				uimenu(m41,'Label','Ignore NaNs (interpolate)','Callback','plotGrav compute_spectral_interp');
				uimenu(m41,'Label','Spectrogram','Callback','plotGrav compute_spectral_evolution');
            m44 = uimenu(m4,'Label','Select');
                uimenu(m44,'Label','One point','Callback','plotGrav select_point');
                uimenu(m44,'Label','Difference','CallBack','plotGrav compute_difference');
            uimenu(m4,'Label','Statistics','Callback','plotGrav compute_statistics');
            uimenu(m4,'Label','Time shift','Callback','plotGrav compute_time_shift');
			
		% Main EDIT menu (add/remove features to time series/plot)
        m5  = uimenu('Label','Edit');
			% Sub-Menu EDIT
			m52  = uimenu(m5,'Label','Insert');
				% Sub-Sub-EDIT menu
                uimenu(m52,'Label','Copy channel','CallBack','plotGrav compute_copy_channel');
                m521 = uimenu(m52,'Label','Channel names');
                    uimenu(m521,'Label','DATA A','CallBack','plotGrav edit_channel_names_data_a');
                    uimenu(m521,'Label','DATA B','CallBack','plotGrav edit_channel_names_data_b');
                    uimenu(m521,'Label','DATA C','CallBack','plotGrav edit_channel_names_data_c');
                    uimenu(m521,'Label','DATA D','CallBack','plotGrav edit_channel_names_data_d');
                m523 = uimenu(m52,'Label','Channel units');
                    uimenu(m523,'Label','DATA A','CallBack','plotGrav edit_channel_units_data_a');
                    uimenu(m523,'Label','DATA B','CallBack','plotGrav edit_channel_units_data_b');
                    uimenu(m523,'Label','DATA C','CallBack','plotGrav edit_channel_units_data_c');
                    uimenu(m523,'Label','DATA D','CallBack','plotGrav edit_channel_units_data_d');
                m522 = uimenu(m52,'Label','Object');
                    uimenu(m522,'Label','Ellipse','CallBack','plotGrav insert_circle',...
                        'Tag','plotGrav_insert_circle','UserData',[]); 			% UserData will be used to store references to inserted circles (to have the option to delete them)
                    uimenu(m522,'Label','Line','CallBack','plotGrav insert_line',...
                        'Tag','plotGrav_insert_line','UserData',[]); 			% UserData will be used to store references to inserted lines (to have the option to delete them)
                    uimenu(m522,'Label','Text','CallBack','plotGrav insert_text',...
                        'Tag','plotGrav_insert_text','UserData',[]);			% UserData will be used to store references to inserted text (to have the option to delete it)
                    uimenu(m522,'Label','Rectangle','CallBack','plotGrav insert_rectangle',...
                        'Tag','plotGrav_insert_rectangle','UserData',[]); 		% UserData will be used to store references to inserted rectangles (to have the option to delete them)
			m51 = uimenu(m5,'Label','Remove');
                m511 = uimenu(m51,'Label','Ambiguities');
                    uimenu(m511,'Label','DATA A','CallBack','plotGrav compute_remove_ambiguities data_a');
                    uimenu(m511,'Label','DATA B','CallBack','plotGrav compute_remove_ambiguities data_b');
                    uimenu(m511,'Label','DATA C','CallBack','plotGrav compute_remove_ambiguities data_c');
                    uimenu(m511,'Label','DATA D','CallBack','plotGrav compute_remove_ambiguities data_d');
				uimenu(m51,'Label','Channel','CallBack','plotGrav compute_remove_channel');
					% Sub-Sub-Sub EDIT menu
				m514 = uimenu(m51,'Label','Inserted');
					m5141 = uimenu(m514,'Label','Ellipse');
						% Sub-Sub-Sub-SUB EDIT menu
						uimenu(m5141,'Label','All','CallBack','plotGrav remove_circle');
						uimenu(m5141,'Label','Last','CallBack','plotGrav remove_circle_last');
					m5142 = uimenu(m514,'Label','Line');
						uimenu(m5142,'Label','All','CallBack','plotGrav remove_line');
						uimenu(m5142,'Label','Last','CallBack','plotGrav remove_line_last');
					m5143 = uimenu(m514,'Label','Rectangles');
						uimenu(m5143,'Label','All','CallBack','plotGrav remove_rectangle');
						uimenu(m5143,'Label','Last','CallBack','plotGrav remove_rectangle_last');
					m5144 = uimenu(m514,'Label','Text');
						uimenu(m5144,'Label','All','CallBack','plotGrav remove_text');
						uimenu(m5144,'Label','Last','CallBack','plotGrav remove_text_last');
			uimenu(m51,'Label','Interval','CallBack','plotGrav remove_interval_selected');
			m515 = uimenu(m51,'Label','Spikes');
                  uimenu(m515,'Label','> X SD','CallBack','plotGrav remove_Xsd');
                  uimenu(m515,'Label','Set range','CallBack','plotGrav remove_set');
			uimenu(m51,'Label','Step','CallBack','plotGrav remove_step_selected');
            m53  = uimenu(m5,'Label','Replace');
                m524 = uimenu(m53,'Label','Interp. interval');
                    uimenu(m524,'Label','Select','CallBack','plotGrav interpolate_interval_linear');
                    uimenu(m524,'Label','Auto','CallBack','plotGrav interpolate_interval_auto');
                	uimenu(m53,'Label','Out of range','CallBack','plotGrav replace_range_by');
            
        % (UI) Panels for selecting time series. Each row of such
        % ui-table referes to a matrix column. The loaded time series are
        % store namely in matrices (one matrix per input/file/panel). The
        % columns refer to plotting axes, i.e., left 1 to 3 and right 1 to
        % 3. Checking or unchecking of ui-table checkboxes evokes
        % automatically the plotting section.
		p3 = uipanel(F1,'Units','normalized','Position',[0.01,0.76,0.265,0.33-0.10],... % Settings panel (uppermost panel)
				'Title','Settings','FontSize',9,'Tag','plotGrav_setting_panel');
        p1 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','A','R1','R2','R3'},... % first A panel 
				'Position',[0.01,0.25,0.13,0.50],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
				'Tag','plotGrav_uitable_data_a_data','Visible','on','FontSize',9,'RowName',[],'ButtonDownFcn','plotGrav select_data_a_file',...
				'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],...
				'CellEditCallback','plotGrav uitable_push','UserData',[]);			% UserData container will be used to store check/unchecked fields for this panel (use as switch to plot selected time series)
        p2 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','B','R1','R2','R3'},...% second panel for TRiLOGi data (upper right)
				'Position',[0.145,0.25,0.13,0.50],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
				'Tag','plotGrav_uitable_data_b_data','Visible','on','FontSize',9,'RowName',[],'ButtonDownFcn','plotGrav select_data_b_file',...
				'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],...
				'CellEditCallback','plotGrav uitable_push','UserData',[]);		% UserData container will be used to store check/unchecked fields for this panel (use as switch to plot selected time series)
        p4 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','C','R1','R2','R3'},... % Third panel for Other1 data (lower left)
				'Position',[0.01,0.02,0.13,0.22],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
				'Tag','plotGrav_uitable_data_c_data','Visible','on','FontSize',9,'RowName',[],'UserData',[],'ButtonDownFcn','plotGrav select_data_c',... % UserData will be used to store check/unchecked fields for this panel (use as switch to plot selected time series)
				'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],'CellEditCallback','plotGrav uitable_push');
        p5 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','D','R1','R2','R3'},...
				'Position',[0.145,0.02,0.13,0.22],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
				'Tag','plotGrav_uitable_data_d_data','Visible','on','FontSize',9,'RowName',[],'UserData',[],'ButtonDownFcn','plotGrav select_data_d',... % UserData will be used to store check/unchecked fields for this panel (use as switch to plot selected time series)
				'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],'CellEditCallback','plotGrav uitable_push');
        
		% Settings panel: Time
        uicontrol(p3,'Style','Text','String','Time min.:','units','normalized',...
                  'Position',[0.02,0.56+0.27,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Text','String','Time max.:','units','normalized',...
                  'Position',[0.02,0.44+0.27,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');   
        uicontrol(p3,'Style','Text','String','year','units','normalized',...
                  'Position',[0.16,0.61+0.30,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Text','String','month','units','normalized',...
                  'Position',[0.26,0.61+0.30,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Text','String','day','units','normalized',...
                  'Position',[0.345,0.61+0.30,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Text','String','hour','units','normalized',...
                  'Position',[0.44,0.61+0.30,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Edit','String',sprintf('%04d',set_start(1)),'units','normalized',...
                  'Position',[0.17,0.565+0.27,0.09,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_year');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',set_start(2)),'units','normalized',...
                  'Position',[0.27,0.565+0.27,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_month');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',set_start(3)),'units','normalized',...
                  'Position',[0.36,0.565+0.27,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_day');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',set_start(4)),'units','normalized',...
                  'Position',[0.45,0.565+0.27,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_hour');
        uicontrol(p3,'Style','Edit','String',sprintf('%04d',set_stop(1)),'units','normalized',...
                  'Position',[0.17,0.445+0.27,0.09,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_year');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',set_stop(2)),'units','normalized',...
                  'Position',[0.27,0.445+0.27,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_month');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',set_stop(3)),'units','normalized',...
                  'Position',[0.36,0.445+0.27,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_day');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',set_stop(4)),'units','normalized',...
                  'Position',[0.45,0.445+0.27,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_hour');
				  
		% Settings panel: calibration and admittance
        uicontrol(p3,'Style','Text','String','Calibration:','units','normalized',...
                  'Position',[0.54,0.565+0.27,0.15,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String',set_calib_factor,'units','normalized',...	% default calibration factor
                  'Position',[0.70,0.565+0.27,0.12,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_calb_factor');
        uicontrol(p3,'Style','Edit','String',set_calib_phase,'units','normalized',...	% default phase delay	
                  'Position',[0.83,0.565+0.27,0.12,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_calb_delay');
        uicontrol(p3,'Style','Text','String','nm/s^2 / V','units','normalized',...
                  'Position',[0.705,0.630+0.30,0.12,0.07],'FontSize',8,'HorizontalAlignment','left',...
                  'Tag','plotGrav_text_nms2','UserData',[]);
        uicontrol(p3,'Style','Text','String','seconds','units','normalized',...
                  'Position',[0.845,0.630+0.30,0.12,0.07],'FontSize',8,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Text','String','Admittance:','units','normalized',...
                  'Position',[0.54,0.44+0.27,0.15,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String',set_admittance,'units','normalized',...	% default single admittance factor			
                  'Position',[0.70,0.445+0.28,0.12,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_admit_factor');
        uicontrol(p3,'Style','Text','String','nm/s^2 / hPa','units','normalized',...
                  'Position',[0.83,0.44+0.27,0.16,0.09],'FontSize',9,'HorizontalAlignment','left');
				  
		% Settings: Drift + Re-sampling
        uicontrol(p3,'Style','Text','String','Drift fit:','units','normalized',...
                  'Position',[0.02,0.59,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Popupmenu','String','none|constant value|linear|quadratic|cubic|set','units','normalized',...
                  'Position',[0.17,0.65,0.18,0.05],'FontSize',9,'Tag','plotGrav_pupup_drift','backgroundcolor','w',...
                  'Value',set_drift_switch,'Callback','plotGrav set_manual_drift');		% default drift = none (zero)
        temp = uicontrol(p3,'Style','Edit','String','0.41 0','units','normalized',...	% default user drift setting			
                  'Position',[0.36,0.59,0.17,0.10],'FontSize',9,'BackgroundColor','w',...
                  'Tag','plotGrav_edit_drift_manual','visible','off');
        if ~isempty(set_drift_val)
            set(temp,'visible','on');
        end
        uicontrol(p3,'Style','Text','String','Re-sample:','units','normalized',...
                  'Position',[0.54,0.59,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String',set_resample_a,'units','normalized',...		% default re-sampling interval (of DATA A). Will not be used for TRiLOGi, Other1 and Other2 time series
                  'Position',[0.7,0.595,0.12,0.09],'FontSize',9,'Tag','plotGrav_edit_resample','backgroundcolor','w');
        uicontrol(p3,'Style','Text','String','seconds','units','normalized',...
                  'Position',[0.83,0.59,0.16,0.09],'FontSize',9,'HorizontalAlignment','left');
				  
		% Settings: legend/grid
        uicontrol(p3,'Style','Checkbox','String','Grid','units','normalized',...
                  'Position',[0.02,0.45,0.13,0.09],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_check_grid','Value',1,'Visible','off','UserData',[]); % by default, grid in on. UserData used to store Axes handles L1 and R1 (firs plot)!
        uicontrol(p3,'Style','Checkbox','String','Legend','units','normalized',...
                  'Position',[0.02,0.32,0.13,0.09],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_check_legend','Value',1,'Visible','off'); 	% by default, legend is on. UserData used to store Axes handles L2 and R2 (second plot)!
        uicontrol(p3,'Style','Checkbox','String','Labels','units','normalized',...
                  'Position',[0.02,0.20,0.13,0.09],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_check_labels','Value',1,'Visible','off');		% by default, y label is on. UserData used to store Axes handles L3 and R3 (third plot)!
        uicontrol(p3,'Style','Pushbutton','String','Rem. interval','units','normalized',...
                  'Position',[0.17,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'CallBack','plotGrav remove_interval_selected');
        uicontrol(p3,'Style','Pushbutton','String','Zoom in','units','normalized',...
                  'Position',[0.37,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_zoom_in','CallBack','plotGrav push_zoom_in',...
                  'UserData',[]);												% UserData will be used to store user selected zoom range
        uicontrol(p3,'Style','Pushbutton','String','Reset view','units','normalized',...
                  'Position',[0.57,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_reset_view','CallBack','plotGrav reset_view',...
                  'UserData',[0 0 0]);											% UserData will be used for Plot switch, 1 == 0, 0 == 0, first column = first plot,...
        uicontrol(p3,'Style','Pushbutton','String','Uncheck all','units','normalized',...
                  'Position',[0.77,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_push_uncheck_all','CallBack','plotGrav uncheck_all');
        uicontrol(p3,'Style','Pushbutton','String','Select point','units','normalized',...
                  'Position',[0.17,0.27,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'CallBack','plotGrav select_point');
        uicontrol(p3,'Style','Pushbutton','String','Compute diff.','units','normalized',...
                  'Position',[0.37,0.27,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'CallBack','plotGrav compute_difference');
        uicontrol(p3,'Style','Pushbutton','String','Webcam','units','normalized',...
                  'Position',[0.57,0.27,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'CallBack','plotGrav push_webcam');
        uicontrol(p3,'Style','Pushbutton','String','Earthquakes','units','normalized',...
                  'Position',[0.77,0.27,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'CallBack','plotGrav show_earthquake');
              
		% Settings: User Text input (only visible for certain functions)
        uicontrol(p3,'Style','Text','String','User input:','units','normalized',...
                  'Tag','plotGrav_text_input','Visible','off',...
                  'Position',[0.02,0.15,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String','','units','normalized','Visible','off',...
                  'Position',[0.17,0.16,0.62,0.09],'FontSize',9,'BackgroundColor','w',...
                  'Tag','plotGrav_edit_text_input','HorizontalAlignment','left');
        uicontrol(p3,'Style','pushbutton','String','Confirm','units','normalized',...
                  'Position',[0.80,0.16,0.18,0.10],'FontSize',9,'Tag',...
                  'plotGrav_push_confirm','Visible','off','CallBack','set(findobj(''Tag'',''plotGrav_push_confirm''),''Visible'',''off'')');
				  
        % Settings Load + status
        uicontrol(p3,'Style','pushbutton','String','Load data','units','normalized',...
                  'Position',[0.80,0.02,0.18,0.13],'FontSize',9,'FontWeight','bold','Tag',...
                  'plotGrav_push_load','CallBack','plotGrav load_all_data','UserData',[]); % UserData used to store ALL loaded time series (not time vectors, only data)
        uicontrol(p3,'units','normalized','Position',[0.02,0.030,0.73,0.09],'Style','Text',...
				  'FontSize',9,'FontAngle','italic','String','Check the settings and press Load data ->',...
				  'Tag','plotGrav_text_status','UserData',[]);							% UserData used to store ALL loaded time vectors (not data values)	
              
		% Auxiliary Panel with Paths/files (invisible). A window with the same content will be shown after pressing 'View->File paths'
        p30 = uipanel(F1,'Units','normalized','Position',[0.01,0.76,0.265,0.33-0.10],...
                     'Title','Settings','FontSize',9,'Visible','off');
		uicontrol(p30,'Style','Text','String','DATA A path:','units','normalized',...
                  'Tag','plotGrav_text_data_a','UserData',[],...								% Use UseData to store data_a units
                  'Position',[0.02,0.89,0.13,0.06],'FontSize',9,'HorizontalAlignment','left');
		uicontrol(p30,'Style','Edit','String',path_data_a,'units','normalized',...			% set default data_a path
				  'Position',[0.17,0.90,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_data_a_path','HorizontalAlignment','left','UserData',[]);
		uicontrol(p30,'Style','Text','String','TRiLOGi:','units','normalized',...
				  'Tag','plotGrav_text_data_b','UserData',[],...							% Use UseData to store TRiLOGi units
				  'Position',[0.02,0.82,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
		uicontrol(p30,'Style','Edit','String',path_data_b,'units','normalized',...			% set default TRiLOGi path
				  'Position',[0.17,0.83,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_data_b_path','HorizontalAlignment','left','UserData',[]);
		uicontrol(p30,'Style','Text','String','Other1 file:','units','normalized','UserData',[],...
				  'Position',[0.02,0.75,0.145,0.06],'FontSize',9,'HorizontalAlignment','left',...
				  'Tag','plotGrav_text_data_c','UserData',[]);								% Use UseData to store Ohter1 units
		uicontrol(p30,'Style','Edit','String',file_data_c,'units','normalized','UserData',[],...% set default data_c file name
				  'Position',[0.17,0.76,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_data_c_path','HorizontalAlignment','left','UserData',[]);
		uicontrol(p30,'Style','Text','String','Other2 file:','units','normalized',...
				  'Position',[0.02,0.68,0.145,0.06],'FontSize',9,'HorizontalAlignment','left',...
				  'Tag','plotGrav_text_data_d','UserData',[]);								% Use UseData to store Ohter2 units
		uicontrol(p30,'Style','Edit','String',file_data_d,'units','normalized','UserData',[],...% set default Other2 file name
				  'Position',[0.17,0.69,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_data_d_path','HorizontalAlignment','left');
		uicontrol(p30,'Style','Text','String','Tide/Pol file:','units','normalized',...
				  'Position',[0.02,0.61,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
		uicontrol(p30,'Style','Edit','String',file_tides,'units','normalized',...			% set default tides file
				  'Position',[0.17,0.62,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_tide_file','HorizontalAlignment','left');
		uicontrol(p30,'Style','Text','String','Filter file:','units','normalized',...
				  'Position',[0.02,0.54,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
		uicontrol(p30,'Style','Edit','String',file_filter,'units','normalized',...			% set default filter file
				  'Position',[0.17,0.55,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_filter_file','HorizontalAlignment','left');
		uicontrol(p30,'Style','Text','String','Webcam file:','units','normalized',...
				  'Position',[0.02,0.54-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
		uicontrol(p30,'Style','Edit','String',path_webcam,'units','normalized',...			% set default webcam path
				  'Position',[0.17,0.55-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_webcam_path','HorizontalAlignment','left');
		uicontrol(p30,'Style','Text','String','Logfile:','units','normalized',...
				  'Position',[0.02,0.47-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
		uicontrol(p30,'Style','Edit','String',file_logfile,'units','normalized',...			% set default logfile file name
				  'Position',[0.17,0.48-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
				  'Tag','plotGrav_edit_logfile_file','HorizontalAlignment','left');
                       
        % AXES: set axes for future plots
        aL1 = axes('units','normalized','Position',[0.33,0.71,0.63,0.26],'Tag','axesL1','FontSize',9);	% First axes = L1 (plot one, left)
        aR1 = axes('units','normalized','Position',[0.33,0.71,0.63,0.26],'Tag','axesR1',...				% Second axes = R1 (plot one, right)
					'color','none','YAxisLocation','right','FontSize',9);								%               set transparency (color = none)
        ylabel(aL1,'L1');ylabel(aR1,'R1');																% set to show user which axes corresponds to L1 and R1. Will be shown only until some time series is loaded.
        set(findobj('Tag','plotGrav_check_grid'),'UserData',[aL1,aR1]);									% Store the axes handles for future calling	
        aL2 = axes('units','normalized','Position',[0.33,0.39,0.63,0.26],'Tag','axesL2','FontSize',9);	% Third axes = L2 (plot two, left)
        aR2 = axes('units','normalized','Position',[0.33,0.39,0.63,0.26],'Tag','axesR2','FontSize',9,...% Fourth axes = R2 (plot two, right)
					'color','none','YAxisLocation','right');											% 				Must be transparent. Otherwise, L2 invisible (overlay)
        ylabel(aL2,'L2');ylabel(aR2,'R2');																% set to show user which axes corresponds to L2 and R3
        set(findobj('Tag','plotGrav_check_legend'),'UserData',[aL2,aR2]);								% Store the axes handles for future calling. Each plot is stored separately.
        aL3 = axes('units','normalized','Position',[0.33,0.06,0.63,0.26],'Tag','axesL3','FontSize',9);	% Fifth axes = L3 (plot three, left)
        aR3 = axes('units','normalized','Position',[0.33,0.06,0.63,0.26],'Tag','axesR3','FontSize',9,...% Sixth axes = R3 (plot three, right)
					'color','none','YAxisLocation','right');											% 				Must be transparent. Otherwise, L3 invisible (overlay)
        ylabel(aL3,'L3');ylabel(aR3,'R3');																% set to show user which axes corresponds to L3 and R3.
        set(findobj('Tag','plotGrav_check_labels'),'UserData',[aL3,aR3]);								% Store the axes handles for future calling. Each plot is stored separately.
        
		% Define colors for lines (all plots). Do not use Matlab's default colorscale.
        color_scale = [1 0 0;0 1 0;0 0 1;0 0 0;1 1 0;0 0.5 0;0.5 0.5 0.5;0.6 0.2 0.0;0.75 0.75 0.75;0.85 0.16 0;0.53 0.32 0.32;0.2 0.2 0.2]; % crate colours (for plots)
        color_scale(length(color_scale)+1:100,1) = 1;                       % If more than 12 time series are selected, use red color. It will be difficult to resolve the different lines so or so.
        set(findobj('Tag','plotGrav_text_nms2'),'UserData',color_scale);	% Store the defined color scale. It will be loaded within plotGrav_plotData.m function
        
		% Set default ui-tables (what should be checked and what not). Same after each plotGrav start and 'Load data' button is pressed.
		% Nevertheless, the ui-tables will be automatically updated after loading some time series.
        plotGrav('reset_tables');
    end 																	% numel(check_open_window)>0 => check if some plotGrav window already open.    
else																		% nargin ~= 0 => Use Switch/Case to run selected code blocks (first part, i.e., nargin == 0, create GUI window)
	warning('off','all');                                                   % turn off warning (especially for polynomial fitting)
    switch in_switch														% Switch between code blocs
%%%%%%%%%%%%%%%%%%% L O A D I N G   D A T A %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		case 'load_all_data'												% Start loading data. This part starts after pressing 'Load data' button.			
			plotGrav('reset_tables');	                                   	% reset all tables. Set all uitables (data_a,data_b,data_c,data_d) to default values. The tables will be updated after loading data.
			%% Get user inputs
			set(findobj('Tag','plotGrav_text_status'),'String','Starting...');drawnow % Send message to status bar (for user). drawnow = right now
			% Time
			start_time = [str2double(get(findobj('Tag','plotGrav_edit_time_start_year'),'String')),... % Get starting date and covert it to double. The conversion to datenum will be done later. This row = year
						str2double(get(findobj('Tag','plotGrav_edit_time_start_month'),'String')),... % month
						str2double(get(findobj('Tag','plotGrav_edit_time_start_day'),'String')),...   % day
						str2double(get(findobj('Tag','plotGrav_edit_time_start_hour'),'String')),0,0];% hour (minutes and seconds == 0)  
			end_time = [str2double(get(findobj('Tag','plotGrav_edit_time_stop_year'),'String')),... % Get date of end + convert to double. Conversion to datenum/matlab time format will done later.
						str2double(get(findobj('Tag','plotGrav_edit_time_stop_month'),'String')),... % month
						str2double(get(findobj('Tag','plotGrav_edit_time_stop_day'),'String')),...   % day
						str2double(get(findobj('Tag','plotGrav_edit_time_stop_hour'),'String')),0,0];% hour (minutes and seconds == 0)  
			% File paths/names
			file_path_data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'String'); 		% data_a path (stored in GUI UserData). The files will be loaded later.
			file_path_data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'String'); 	% get TRiLOGi path
			file_path_data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'String'); 	% get Ohter1 path
			file_path_data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'String'); 	% get Other2 path
			tide_file = get(findobj('Tag','plotGrav_edit_tide_file'),'String'); 			% get tidal effect file
			filter_file = get(findobj('Tag','plotGrav_edit_filter_file'),'String'); 		% get filter file
			% Calibration factor, admittance and drift approximation. Get values only. Will be used later.
			calib_factor = str2double(get(findobj('Tag','plotGrav_edit_calb_factor'),'String'));  	% get calibration factor (will be use for iGrav or SG030, but only if these are selected to be loaded, i.e., will not be used if *.mat is selected)
			calib_delay = str2double(get(findobj('Tag','plotGrav_edit_calb_delay'),'String'));  	% get phase delay (same as for 'calibration factor)
			admittance_factor = str2double(get(findobj('Tag','plotGrav_edit_admit_factor'),'String')); % get admittance factor (same as for 'calibration factor', In addition, will be used when calling plotGrav_Atmacs_and_EOP.m function)
			drift_fit = get(findobj('Tag','plotGrav_pupup_drift'),'Value');  				% get drift switch,1 = none, 2 = linear,... (same as for 'calibration factor')
			% Additional variables
			data_a_prefix = get(findobj('Tag','plotGrav_menu_data_a_file'),'UserData'); % DATA A file prefix (used during data loading). No prefix for SG030, the selected input file (file_path_data_a) will be used also for file prefix.
			data_b_suffix = '_ENC12345.tsf';                               % data_b file suffix (except 001, 002,...)
			data_b_channels = 40;                                          % number of data_b channels
			data_a_channels = 21;                                            % number of DATA A channels (original file)
			data_a_time_resolution = 1;                                      % DATA A time sampling in seconds (fixed, iGrav and SG030 measure with 1 second resolutin => do no use for 10 second data)
			time_in(:,7) = [datenum(start_time):1:datenum(end_time)]';      % Convert the input starting time and ending time to matlab format and create a time vector. Time step is ONE day = one file per day written by iGrav or SG
			time_in(:,1:6) = datevec(time_in(:,7));                         % crate input time matrix (calendar date + time), e.g., [2015,3,1,0,0,0,736024]. These information will be used to create file name to be loaded.            
			leap_second = [2015 06 30 23 59 59];                            % excact data for of leap seconds. These values will be used to find the leap second and to REMOVE it (otherwise redundant data permiting filterin = non-monotonic time vector)
            % Open the log file.
            try
				fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'w'); % use user file name
			catch
				fid = fopen('plotGrav_LOG_FILE.log','w');                   % use default file name if not existing/possible to open.
            end
            % Write initial message to logfile
			fprintf(fid,'plotGrav LogFile: recording since pressing Load Data button\nLoading data between: %04d/%02d/%02d %02d  - %04d/%02d/%02d %02d\n',...
				time_in(1,1),time_in(1,2),time_in(1,3),time_in(1,4),time_in(end,1),time_in(end,2),time_in(end,3),time_in(end,4));
            
			%% Load DATA A data
			if ~isempty(file_path_data_a)                                    % start following code only if data_a/SG file path/name is selected. Otherwise set data_a/SG data to []
				time.data_a = [];                                            % prepare variable (time.data_a will store time in matlab format). The variable name '.data_a' is used also for SG data or other data loaded with iGrav time series loader.
				data.data_a = [];                                            % prepare variable (data.data_a will store all tsoft channels/observed time series)
				data_a_loaded = 0;                                           % aux. variable to check if at least one file has been loaded. 
                                                                            % This switch will be used for further time series correction. 0 == no file loaded, 1 = at least one iGrav file (to be corrected), 2 = 'ready' file that does not need any further correction, 3 = SG030 file (to be corrected) 
				if strcmp(file_path_data_a(end-3:end),'.tsf')                % switch between file/folder input
                    % LOAD Tsoft file: the time series will not be
                    % corrected for tide or filtered. 'Just loading, no
                    % stacking'
					set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav/tsf data...');drawnow % send message to status bar
                    [time.data_a,data.data_a,channels_data_a,units_data_a,uitable_data] = plotGrav_loadData(file_path_data_a,1,start_time,end_time,fid,'iGrav');
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',...
                            uitable_data,'UserData',uitable_data); % store the updated ui-table.
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units_data_a); % store the loaded channel units 
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels_data_a); % store channel names
                    if ~isempty(data.data_a)
                        data_a_loaded = 2;                                   % set the switch to 2 = no further correction will be applied to data.data_a
                    end
				elseif strcmp(file_path_data_a(end-3:end),'.mat')                            
                    % LOAD MAT file, i.e. in plotGrav supported file format (array): containing following layers: 
                    % *.data (vector or matrix), *.time (matlab format or civil calender format), *.channels (cell array), *.units (cell array). 
                    % File may contain other channels, but the above stated are mandatory. 'Just loading, no stacking'
					set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav/mat data...');drawnow % send message to status bar
                    [time.data_a,data.data_a,channels_data_a,units_data_a,uitable_data] = plotGrav_loadData(file_path_data_a,2,start_time,end_time,fid,'iGrav');
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',... % update the ui-table / store the ui-table data (not time series)
                            uitable_data,'UserData',uitable_data);
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units_data_a); % store loaded units
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels_data_a); % store channel names
                    if ~isempty(data.data_a)
                        data_a_loaded = 2;                               % set the switch to 2 = no further correction will be applied to data.data_a
                    end
                elseif strcmp(file_path_data_a(end-3:end),'.dat')
                    % LOAD DAT file, i.e., soil moisture cluste data stored
                    % in csv format. This howerver, requred fixed header (4
                    % rows) and delimiter (','). 'Loading, no stacking'
                    set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav/dat data...');drawnow % send message to status bar
                    [time.data_a,data.data_a,channels_data_a,units_data_a,uitable_data] = plotGrav_loadData(file_path_data_a,3,start_time,end_time,fid,'iGrav');
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',... % update the ui-table / store the ui-table data (not time series)
                            uitable_data,'UserData',uitable_data);
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units_data_a); % store loaded units
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels_data_a); % store channel names
                    if ~isempty(data.data_a)
                        data_a_loaded = 2;                                   % set the switch to 2 = no further correction will be applied to data.data_a
                    end
                elseif strcmp(file_path_data_a(end-3:end),'.csv')
                    % LOAD CSV file, i.e., data in Dygraph csv format.
                    % Requres fixed header (1 rows) and delimiter (','). 
                    % 'Loading, no stacking'
                    set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav/csv data...');drawnow % send message to status bar
                    [time.data_a,data.data_a,channels_data_a,units_data_a,uitable_data] = plotGrav_loadData(file_path_data_a,4,start_time,end_time,fid,'iGrav');
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',... % update the ui-table / store the ui-table data (not time series)
                            uitable_data,'UserData',uitable_data);
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units_data_a); % store loaded units
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels_data_a); % store channel names
                    if ~isempty(data.data_a)
                        data_a_loaded = 2;                                   % set the switch to 2 = no further correction will be applied to data.data_a
                    end
				elseif strcmp(file_path_data_a(end-3:end-2),'.0') 
                    % LOAD SG0XX files, i.e. SG0XX data stored in tsf format
                    % file_path_data_a = full file name of one of the files with SG0XX data. Not Path, but file!
                    % In this case, plotGrav will load all files with file names within selected range (starting point - ending point)
                    % These time series will be stacked, filtered and calibrated (only lower sensor)
                    % Additionaly, these time series will be corrected for tides, atmosphere and drift (if selected so). 'Loading, and stacking'
					set(findobj('Tag','plotGrav_text_status'),'String','Loading SG0XX data...');drawnow % send (general) message to status bar
					for i = 1:length(time_in(:,7))                          % for loop for each day
						try  
							set(findobj('Tag','plotGrav_text_status'),'String',...
								sprintf('Loading SG0XX data...%04d/%02d/%02d',time_in(i,1),time_in(i,2),time_in(i,3)));drawnow % send (specific) message to status bar
							file_name = sprintf('%s%02d%02d%02d%s',file_path_data_a(1:end-10),abs(time_in(i,1)-2000),time_in(i,2),time_in(i,3),file_path_data_a(end-3:end)); % create file name: file path and file name = file_path_data_a. Last 10 characters specify the year, month and day of the file.
							[ttime,tdata] = plotGrav_loadtsf(file_name);    % load file and store to temporary variables. Do not read channel names and units, as these are known and constant.
                            % Now, check if the loaded time series contains non-constant sampling, i.e., missing data.
                            % If so, try to interpolate the missing intervals but only if the missing interval does not exceed 10 seconds!
                            % Steps longer than 10 seconds should not be interpolated due to the high nois of the data.
                            if max(abs(diff(ttime))) > 1.9/86400 && max(abs(diff(ttime))) <= 10/86400 
								ntime = [ttime(1):1/86400:ttime(end)]';     % new time vector with one second resolution (temporary variable)
								tdata = interp1(ttime,tdata,ntime,'linear');% interpolate value for new time vector (temporary variable)
								ttime = ntime;clear ntime;                  % remove the temporary time vector to clear memory. The temporary data matrix will be used in the following part.
								% It is important to write to the logfile that data has been interpolated
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0XX missing data interpolation (max 10 seconds):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
                            end
                            % Do the same as above for NaNs (missing data~= NaNs!)
							ntime = ttime;ndata = tdata;                    % temp. variables (see the comment above)
							ntime(isnan(sum(ndata(:,1:end),2))) = [];         % remove time samples where at least one data column is NaN (sum of [1 NaN 3] = NaN)
							ndata(isnan(sum(ndata(:,1:end),2)),:) = [];       % remove data samples where at least one column is NaN
							if max(abs(diff(ntime))) > 1.9/86400 && max(abs(diff(ntime))) <= 10/86400 % interpolate if max missing time interval is < 10 seconds (and >= 2 seconds)
								tdata = interp1(ntime,ndata,ttime,'linear');% interpolate value for new time vector
								clear ntime ndata;
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0XX NaNs interpolation (max 10 seconds):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
							end
							data_a_loaded = 3;                               % 3 => SG030 loaded time series will be corrected/calibrated/filtered. At least one of the inteded files must be loaded (it is not necesary to load all files)
                        catch error_message
							ttime = datenum(time_in(i,1:3));                % if data has not been loaded correctly, add a dummy for stacking (to make sure the missing files result in missing data!)
							tdata(1,1:3) = NaN;                             % insert NaNs (see comment above)
                            if strcmp(error_message.identifier,'plotGrav_loadtsf:FOF') % switch between error IDs. See plotGrav_loadtsf.m function for error handling
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0XX file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                            elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRH')
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0XX file: %s could NOT read header (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                            elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRD')
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0X file: %s could NOT read data (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                            else
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0XX file: %s loaded but NOT processed. Error %s (%04d/%02d/%02d %02d:%02d)\n',file_name,char(error_message.message),ty,tm,td,th,tmm); % Write message to logfile
                            end
						end
						time.data_a = vertcat(time.data_a,ttime);             % stack the temporary variable on already loaded ones (the time.data_a variable has been declared in the beginning of the iGrav section)
						data.data_a = vertcat(data.data_a,tdata);             % stack the temporary variable on already loaded ones (data)
						clear ttime tdata file_name                         % remove used variables    
					end
					if length(find(isnan(data.data_a))) ~= numel(data.data_a) % check if loaded data contains numeric values
						data.data_a(time.data_a<datenum(start_time) | time.data_a>datenum(end_time),:) = []; % remove time epochs out of requested range
						time.data_a(time.data_a<datenum(start_time) | time.data_a>datenum(end_time),:) = []; % do the same for time vector
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG0XX data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
					else
						data.data_a = [];                                    % otherwise empty
						time.data_a = [];
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No data in SG0XX input file (in selected time interval): %s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
					end
					set(findobj('Tag','plotGrav_uitable_data_a_data'),'data',... % update the ui-table
						get(findobj('Tag','plotGrav_uitable_data_a_data'),'UserData')); 
				else
                    % LOAD iGrav files, i.e. iGrav-006 data stored in tsf format
                    % file_path_data_a = file path (not name) to all input data
                    % In this case, plotGrav will load all files with file names within selected range (starting point - ending point)
                    % These time series will be stacked, filtered and calibrated
                    % Additionaly, these time series will be corrected for tides, atmosphere and drift (if selected so). 'Loading, and stacking'
					set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav data...');drawnow % send message to status bar
					for i = 1:length(time_in(:,7))                          % for loop for each day
						try  
                            % First find out if sub-folder with daily iGrav data exists, i.e. 
                            % if the data sent by iGrav has been unzipped. 
                            if exist(fullfile(file_path_data_a,...           % if folder /iGrav006_YYYY/DDMM/ does not exists, it is assumed the data is still unzipped
                                sprintf('%s_%04d',data_a_prefix,time_in(i,1)),sprintf('%02d%02d',time_in(i,2),time_in(i,3))),'dir') ~= 7 % exist function return 7 if such folder exists
                                file_in = fullfile(file_path_data_a,...      % create input file name = file path + file prefix + date + .zip
                                    sprintf('%s_%04d',data_a_prefix,time_in(i,1)),sprintf('%s_%04d%02d%02d.zip',data_a_prefix,time_in(i,1),time_in(i,2),time_in(i,3)));
                                file_out = fullfile(file_path_data_a,...     % create output PATH = file path + folder with year (iGrav are zipped in folders: /DDMM/
                                    sprintf('%s_%04d',data_a_prefix,time_in(i,1))); 
                                if exist(file_in,'file') == 2               % 2 = file exist
                                    set(findobj('Tag','plotGrav_text_status'),'String',... % send message to status bar
                                        sprintf('Unzipping %s data...%04d/%02d/%02d',time_in(i,1),data_a_prefix,time_in(i,2),time_in(i,3)));drawnow 
                                    unzip(file_in,file_out);                % unzip using built in matlab function
%                                 else
%                                     [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav file unzipping: %s does NOT exist (%04d/%02d/%02d %02d:%02d)\n',file_in,ty,tm,td,th,tmm); % write to logfile
                                end
                            end
                            % Start loading iGrav data
							set(findobj('Tag','plotGrav_text_status'),'String',... % send message to status bar
								sprintf('Loading iGrav data...%04d/%02d/%02d',time_in(i,1),time_in(i,2),time_in(i,3)));drawnow 
							file_name = fullfile(file_path_data_a,...        % create input (not zip) file name = file path + file prefix + date + .tsf
								sprintf('%s_%04d',data_a_prefix,time_in(i,1)),sprintf('%02d%02d',time_in(i,2),time_in(i,3)),sprintf('Data_%s_%02d%02d.tsf',data_a_prefix,time_in(i,2),time_in(i,3)));
							[ttime,tdata] = plotGrav_loadData(file_name,1,[],[],fid,'iGrav'); % load file and store to temporary variables (do not read channels and units as these are known and constant)
                            % Check if the loaded time series contains non-constant sampling, i.e., missing data (same as for SG030).
                            % If so, try to interpolate the missing intervals but only if the missing interval does not exceed 10 seconds!
                            % Steps longer than 10 seconds should not be interpolated due to the high noise of the data.
                            % First though, check if sampling > 0 (=no ambiguous time stemps)
                            if min(diff(ttime)) <= 0
                                tdata(vertcat(1,diff(ttime))<=0,:) = [];    % use vertcat as diff outputs vector with shorter length (see: help diff)
                                ttime(vertcat(1,diff(ttime))<=0) = [];
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav ambiguous data removed (e.g. non-increasing sampling):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
                            end
                            % Interpolate missing data (<10 seconds).
                            if max(abs(diff(ttime))) > 1.9/86400 && max(abs(diff(ttime))) <= 10/86400 
								ntime = [ttime(1):1/86400:ttime(end)]';     % new time vector with one second resolution (temporary variable)
								tdata = interp1(ttime,tdata,ntime,'linear');% interpolate value for new time vector (temporary variable)
								ttime = ntime;clear ntime;                  % remove the temporary time vector to clear memory. The temporary data matrix will be used in the following part.
								% It is important to write to the logfile that data has been interpolated
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav missing data interpolation (max 10 seconds):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
                            end
							data_a_loaded = 1;                               % 1 => iGrav time series will be corrected/calibrated filtered
                        catch error_message
							ttime = datenum(time_in(i,1:3));                % if data has not been loaded correctly, add a dummy to make sure the missig file results in missing data
							tdata(1,1:data_a_channels) = NaN;                % insert NaNs. Same as above.
							if strcmp(error_message.identifier,'plotGrav_loadtsf:FOF') % switch between error IDs. See plotGrav_loadtsf.m function for error handling
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                            elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRH')
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav file: %s could NOT read header (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                            elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRD')
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav file: %s could NOT read data (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                            else
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav file: %s loaded but NOT processed. Error %s (%04d/%02d/%02d %02d:%02d)\n',file_name,char(error_message.message),ty,tm,td,th,tmm); % Write message to logfile
                            end
						end
						time.data_a = vertcat(time.data_a,ttime);             % stack the temporary variable on already loaded ones (the time.data_a variable has been declared in the beginning of the iGrav section)
						data.data_a = vertcat(data.data_a,tdata);             % do the same for data matrices
						clear ttime tdata file_name                         % remove used variables    
					end
					if length(find(isnan(data.data_a))) ~= numel(data.data_a) % check if loaded data contains numeric values: for logfile 
						data.data_a(time.data_a<datenum(start_time) | time.data_a>datenum(end_time),:) = []; % remove time epochs out of requested range
						time.data_a(time.data_a<datenum(start_time) | time.data_a>datenum(end_time),:) = []; % do the same for time vector
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
					else
						data.data_a = [];                                    % otherwise empty
						time.data_a = [];
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No data in iGrav input file (in selected time interval): %s (%04d/%02d/%02d %02d:%02d)\n',file_path_data_a,ty,tm,td,th,tmm);
					end
					set(findobj('Tag','plotGrav_uitable_data_a_data'),'data',... % store the ui-table data
						get(findobj('Tag','plotGrav_uitable_data_a_data'),'UserData')); 
				end
            else                                                        
                % Only if file_path_igra == []; 
				data.data_a = [];                                            % if no iGrav paht selected, set time and data to []
				time.data_a = [];
				set(findobj('Tag','plotGrav_uitable_data_a_data'),'data',... % set ui-table to 'NotAvailable' (one row only)
					{false,false,false,'NotAvailable',false,false,false}); % update table
				data_a_loaded = 0;                                           % 0 => no further processing of iGrav time series
				[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data not selected/loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
			end
			
			%% Load TRiLOGi data
            data_b_loaded = 0;                                             % aux. variable to check if at least one file has been loaded
            % Switch beween file formats
            if isempty(file_path_data_b)
                fprintf(fid,'No TRiLOGi data loaded\n');                    % if no or empty TRiLOGi path has been selected
                time.data_b = [];
                data.data_b = [];
                set(findobj('Tag','plotGrav_uitable_data_b_data'),'data',...
                    {false,false,false,'NotAvailable',false,false,false});  % update ui-table
            elseif strcmp(file_path_data_b(end-3:end),'.tsf')                  %  Use last 4 characters to switch between formats
                % LOAD Tsoft file: the file contains the whole time series. 'Just loading, no stacking'
                % Only condition is, the file is stored in tsoft format
                % with standard header. The TRiLOGi data are NEVER corrected/calibrated/filtered!
                set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi/tsf data...');drawnow % send message to status bar
                [time.data_b,data.data_b,channels_data_b,units_data_b,uitable_data] = plotGrav_loadData(file_path_data_b,1,start_time,end_time,fid,'TRiLOGi');
                set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',... % update the ui-table
                        uitable_data,'UserData',uitable_data);
                set(findobj('Tag','plotGrav_text_data_b'),'UserData',units_data_b); % store data_b units (data and time vector will be save together with other time series at the end of Loading section)
                set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels_data_b); % store channel names. This data will be loaded when needed (e.g., exporting)
                if ~isempty(data.data_b)
                    data_b_loaded = 2;                                     % set the switch to 2 = no further correction will be applied to data.data_a
                end
			elseif strcmp(file_path_data_b(end-3:end),'.mat')              
                % LOAD MAT file, i.e. in plotGrav supported file format (array): containing following layers: 
                % *.data (vector or matrix), *.time (matlab format or civil calender format), *.channels (cell array), *.units (cell array). 
                % File may contain other channels, but the above stated are mandatory. 'Just loading, no stacking'
                set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi/mat data...');drawnow % send message to status bar
                [time.data_b,data.data_b,channels_data_b,units_data_b,uitable_data] = plotGrav_loadData(file_path_data_b,2,start_time,end_time,fid,'TRiLOGi');
                set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',... % update the ui-table
                        uitable_data,'UserData',uitable_data);
                set(findobj('Tag','plotGrav_text_data_b'),'UserData',units_data_b); % store data_b units (data and time vector will be save together with other time series at the end of Loading section)
                set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels_data_b); % store channel names. This data will be loaded when needed (e.g., exporting)
                if ~isempty(data.data_b)
                    data_b_loaded = 2;                                     % set the switch to 2 = no further correction will be applied to data.data_a
                end
            elseif strcmp(file_path_data_b(end-3:end),'.dat')              
                set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi/dat data...');drawnow % send message to status bar
                [time.data_b,data.data_b,channels_data_b,units_data_b,uitable_data] = plotGrav_loadData(file_path_data_b,3,start_time,end_time,fid,'TRiLOGi');
                set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',... % update the ui-table
                        uitable_data,'UserData',uitable_data);
                set(findobj('Tag','plotGrav_text_data_b'),'UserData',units_data_b); % store data_b units (data and time vector will be save together with other time series at the end of Loading section)
                set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels_data_b); % store channel names. This data will be loaded when needed (e.g., exporting)
                if ~isempty(data.data_b)
                    data_b_loaded = 2;                                     % set the switch to 2 = no further correction will be applied to data.data_a
                end
                elseif strcmp(file_path_data_b(end-3:end),'.csv')
                    set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi/csv data...');drawnow % send message to status bar
                    [time.data_b,data.data_b,channels_data_b,units_data_b,uitable_data] = plotGrav_loadData(file_path_data_b,4,start_time,end_time,fid,'TRiLOGi');
                    set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',... % update the ui-table
                        uitable_data,'UserData',uitable_data);
                    set(findobj('Tag','plotGrav_text_data_b'),'UserData',units_data_b); % store data_b units (data and time vector will be save together with other time series at the end of Loading section)
                    set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels_data_b); % store channel names. This data will be loaded when needed (e.g., exporting)
                    if ~isempty(data.data_b)
                        data_b_loaded = 2;                                     % set the switch to 2 = no further correction will be applied to data.data_a
                    end
            elseif ~isempty(file_path_data_b)
                % LOAD TRiLOGi controller files stored in tsf format
                % file_path_data_b = file path (not name) to all input data
                % In this case, plotGrav will load all files with file names within selected range (starting point - ending point)
                % These time series will be stacked. 'Loading and stacking'
                set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi data...');drawnow % send message to status bar
                time.data_b = [];                                          % prepare variable (time.data_b will store time in matlab format)
                data.data_b = [];                                          % prepare variable (data.data_b will store tsoft channels)
                for i = 1:length(time_in(:,7))                              % for loop for each day                            
                    condit_data_b = 10;fi = 0;                             % aux. variables, condit_data_b = minimum number of loaded rows (one TRiLOGi day can be stored in many files, plotGrav will use only that one with has at least condit_data_b rows)
                    try                                                     % use try/catch (many TRiLOGi files are not stored in proper format)
                        while condit_data_b <= 10                          % loop = repeat until the file with at least condit_data_b rows if found
                            fi = fi + 1;                                    % fi is the running number in the TRiLOGi file name
                            file_name = fullfile(file_path_data_b,...      % create file name = path + date + suffix
                                sprintf('%04d%02d%02d_%03d%s',time_in(i,1),time_in(i,2),time_in(i,3),fi,data_b_suffix));
                            [ttime,tdata] = plotGrav_loadData(file_name,1,[],[],fid,'TRiLOGi');
                            if isempty(ttime)                               % is impty if error occurs
                                condit_data_b = 20;                        % ends the while loop
                            elseif length(ttime) < 10                       % check how many rows does the file contain
                                condit_data_b = 0;
                            else
                                condit_data_b = 20;
                            end
                        end
                        [tyear,tmonth,~,thour,tmin,tsec] = datevec(ttime);  % convert back to civil time
                        tday = time_in(i,3);                                % make sure the current day is used (TRiLOGi writes sometime wrong day in first few rows). Still, this may result in a wrong data especially at the months transition.
                        ttime = datenum(tyear,tmonth,tday,thour,tmin,tsec); % convert to matlab time
                        data_b_loaded = 1;                                 % if ~= 0 => some data loaded. 1 = one file per day (TRiLOGi input)
                    catch error_message
                        ttime = datenum(time_in(i,1:3));                    % current file time (hours = 0)
                        tdata(1,1:data_b_channels) = NaN;                  % insert NaN
                        if strcmp(error_message.identifier,'plotGrav_loadtsf:FOF')  % switch between error IDs. See plotGrav_loadtsf.m function for error handling
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                        elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRH')
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi file: %s could NOT read header (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                        elseif strcmp(error_message.identifier,'plotGrav_loadtsf:FRD')
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi file: %s could NOT read data (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % Write message to logfile
                        else
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi file: %s loaded but NOT processed. Error %s (%04d/%02d/%02d %02d:%02d)\n',file_name,char(error_message.message),ty,tm,td,th,tmm); % Write message to logfile
                        end
                    end
                    time.data_b = vertcat(time.data_b,ttime);             % stack the temporary variable on already loaded ones (time)
                    data.data_b = vertcat(data.data_b,tdata);             % stack the temporary variable on already loaded ones (data)
                    clear ttime tdata file_name                             % remove used variables
                end
                if length(find(isnan(data.data_b))) ~= numel(data.data_b) % check if loaded data contains numeric values
                    data.data_b(time.data_b<datenum(start_time) | time.data_b>datenum(end_time),:) = []; % remove time epochs out of requested range
                    time.data_b(time.data_b<datenum(start_time) | time.data_b>datenum(end_time),:) = [];
                    try
                        r = find(diff(time.data_b) == 0);                  % find time epochs with wrong/zero increase (some TRiLOGi files contain duplicate/redundant values)
                        if ~isempty(r)
                           time.data_b(r+1) = time.data_b(r) + mode(diff(time.data_b)); % correct those time epochs (add one minute)
                        end
                        clear r                                             % clear the temporary variable
                    end
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                else
                    data.data_b = [];                                      % otherwise empty
                    time.data_b = [];
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No data TRiLOGi data in selected time interval (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                end
                if data_b_loaded == 0                                      % if no data loaded
                    set(findobj('Tag','plotGrav_uitable_data_b_data'),'data',...
                        {false,false,false,'NotAvailable',false,false,false}); % update table
                        time.data_b = [];
                        data.data_b = [];
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No TRiLOGi data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                end
            else
                fprintf(fid,'No TRiLOGi data loaded\n');                    % if no or empty TRiLOGi path has been selected
                time.data_b = [];
                data.data_b = [];
                set(findobj('Tag','plotGrav_uitable_data_b_data'),'data',...
                    {false,false,false,'NotAvailable',false,false,false});  % update ui-table
            end
			%% Load Other1 data
            % Unlike for iGrav and TRiLOGi panel, one file contains the
            % whole time series => 'Loading, no stacking'
			if ~isempty(file_path_data_c)                                   % continue only if user selected a file via GUI (by default [])
                % Switch between supported file formats
                switch file_path_data_c(end-3:end)                          % switch between supported file formats
                    case '.tsf'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other1/tsf data...');drawnow % send message to status bar
                        [time.data_c,data.data_c,channels_data_c,units_data_c,uitable_data] = plotGrav_loadData(file_path_data_c,1,start_time,end_time,fid,'Other1');
                    case '.mat'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other1/mat data...');drawnow % send message to status bar
                        [time.data_c,data.data_c,channels_data_c,units_data_c,uitable_data] = plotGrav_loadData(file_path_data_c,2,start_time,end_time,fid,'Other1');
                    case '.dat'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other1/dat data...');drawnow % send message to status bar
                        [time.data_c,data.data_c,channels_data_c,units_data_c,uitable_data] = plotGrav_loadData(file_path_data_c,3,start_time,end_time,fid,'Other1');
                    case '.csv'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other1/csv data...');drawnow % send message to status bar
                        [time.data_c,data.data_c,channels_data_c,units_data_c,uitable_data] = plotGrav_loadData(file_path_data_c,4,start_time,end_time,fid,'Other2');
                    otherwise
                        time.data_c = [];data.data_c = [];channels_data_c = [];units_data_c = [];
                        uitable_data = {false,false,false,'NotAvailable',false,false,false}; 
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Other1 data in not supported file format: %s (%04d/%02d/%02d %02d:%02d)\n',file_path_data_c,ty,tm,td,th,tmm);
                end
                % Regardless the input format, store the loaded data
                set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',... % update the ui-table
                    uitable_data,'UserData',uitable_data);
                set(findobj('Tag','plotGrav_text_data_c'),'UserData',units_data_c); % store channel units
                set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels_data_c); % store channel names
			else
				fprintf(fid,'No Other1 data loaded\n');
				time.data_c = [];
				data.data_c = [];
				set(findobj('Tag','plotGrav_uitable_data_c_data'),'data',...
					{false,false,false,'NotAvailable',false,false,false});  % update table = set to empty if  file input not selected
			end
			%% Load Other2 data
            % Unlike for iGrav and TRiLOGi panel, one file contains the
            % whole time series => 'Loading, no stacking'
			if ~isempty(file_path_data_d)                                   % continue only if user selected a file via GUI (by default [])
                % Switch between supported file formats
                switch file_path_data_d(end-3:end)                          % switch between supported file formats
                    case '.tsf'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other2/tsf data...');drawnow % send message to status bar
                        [time.data_d,data.data_d,channels_data_d,units_data_d,uitable_data] = plotGrav_loadData(file_path_data_d,1,start_time,end_time,fid,'Other2');
                    case '.mat'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other2/mat data...');drawnow % send message to status bar
                        [time.data_d,data.data_d,channels_data_d,units_data_d,uitable_data] = plotGrav_loadData(file_path_data_d,2,start_time,end_time,fid,'Other2');
                    case '.dat'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other2/dat data...');drawnow % send message to status bar
                        [time.data_d,data.data_d,channels_data_d,units_data_d,uitable_data] = plotGrav_loadData(file_path_data_d,3,start_time,end_time,fid,'Other2');
                    case '.csv'
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Other2/csv data...');drawnow % send message to status bar
                        [time.data_d,data.data_d,channels_data_d,units_data_d,uitable_data] = plotGrav_loadData(file_path_data_d,4,start_time,end_time,fid,'Other2');
                    otherwise
                        time.data_d = [];data.data_d = [];channels_data_d = [];units_data_d = [];
                        uitable_data = {false,false,false,'NotAvailable',false,false,false}; 
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Other2 data in not supported file format: %s (%04d/%02d/%02d %02d:%02d)\n',file_path_data_d,ty,tm,td,th,tmm);
                end
                % Regardless the input format, store the loaded data
                set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',... % update the ui-table
                    uitable_data,'UserData',uitable_data);
                set(findobj('Tag','plotGrav_text_data_d'),'UserData',units_data_d); % store channel units
                set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels_data_d); % store channel names
			else
				fprintf(fid,'No Other2 data loaded\n');
				time.data_d = [];
				data.data_d = [];
				set(findobj('Tag','plotGrav_uitable_data_d_data'),'data',...
					{false,false,false,'NotAvailable',false,false,false});  % update table = set to empty if  file input not selected
			end
			%% Load filter
			% Load filter file. Only loading, data will be filter in the
			% following section.
			if data_a_loaded == 1 || data_a_loaded == 3                       % load only if iGrav/SG030 data have been loaded
				try
					set(findobj('Tag','plotGrav_text_status'),'String','Loading Filter...');drawnow % send message to status bar
					if ~isempty(filter_file)                                % try to load the filter file/response if some string is given
                        switch filter_file(end-3:end)                       % switch between supported formats: mat = matlab output, otherwise, eterna modified format.
                            case '.mat'
                                Num = importdata(filter_file);              % Impulse response as created using Matlab's Filter design toolbox
                            otherwise
                                Num = load(filter_file);                    % load filter file = in ETERNA modified format (header must be commented using %)
                                Num = vertcat(Num(:,2),flipud(Num(1:end-1,2))); % stack the filter (ETERNA uses only one half of the repose = mirror the filter)
                        end
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Filter loaded: %s (%04d/%02d/%02d %02d:%02d)\n',filter_file,ty,tm,td,th,tmm);
					else
						Num = [];                                           % if not loaded, set to [] (empty)
					end
                catch error_message
                    if strcmp(error_message.identifier,'MATLAB:FileIO:InvalidFid')
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Filter file: %s NOT found (%04d/%02d/%02d %02d:%02d)\n',filter_file,ty,tm,td,th,tmm); % Write message to logfile
                    else
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not load filter file %s . Check format, error %s (%04d/%02d/%02d %02d:%02d)\n',filter_file,char(error_message.message),ty,tm,td,th,tmm); % Write message to logfile
                    end
					Num = [];                                               % if not loaded, set to [] (empty)
				end
			else
				Num = [];                                                   % if not loaded, set to [] (empty)
			end
			
			%% Filter data
            % After loading the filter and iGrav/SG030 filter fixed
            % channels, i.e., gravity.
			if (data_a_loaded == 1 || data_a_loaded == 3) && ~isempty(Num)    % filter only if at least one iGrav/SG030 file has been loaded + the filter file (previous section)
				set(findobj('Tag','plotGrav_text_status'),'String','Filtering...');drawnow % status
				data.filt = [];time.filt = [];                              % prepare variables (*.filt = filtered values)
                try
                    % Check for leap seconds + remove if present
                    for ls = 1:size(leap_second,1)                  
                        r = find(time.data_a == datenum(leap_second(ls,:)));
                        if ~isempty(r)                                      % continue only if loaded data contains given time epoch
                            if abs(time.data_a(r) - time.data_a(r+1)) < 0.9/86400 || abs(time.data_a(r) - time.data_a(r+1)) > 1.1/86400  % check if leap second indeed present in the data (might be removed manually)
                                time.data_a(r+1,:) = [];                     
                                data.data_a(r+1,:) = [];
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data: leap second %04d/%02d/%02d %02d:%02d:%02d removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    leap_second(ls,1),leap_second(ls,2),leap_second(ls,3),leap_second(ls,4),leap_second(ls,5),leap_second(ls,6),ty,tm,td,th,tmm);
                            end
                        end
                    end
                    clear r ls
                    for j = 1%:size(data.data_a,2)                           % set which channels should be filtered (1 = gravity observed, 1:size(data.data_a,2) = all channels)
                        [timeout,dataout,id] = plotGrav_findTimeStep(time.data_a,data.data_a(:,j),data_a_time_resolution/(24*60*60)); % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                        dout = [];                                          % aux. variable
                        for i = 1:size(id,1)                                % use for each time interval (filter between time steps that have been found using plotGrav_findTimeStep function) separately                 
                            if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough
                                [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv = Convolution function (outputs only valid time interval, see plotGrav_conv function for details)
                            else
                                ftime = timeout(id(i,1):id(i,2));           % if the interval is too short, set to NaN 
                                fgrav(1:length(ftime),1) = NaN;
                            end
                            dout = vertcat(dout,fgrav,NaN);                 % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                            if j == 1                                       % do only onece, i.e. for first channel
                                time.filt = vertcat(time.filt,ftime,...     % stack the aux. time only for first channel (same for all)
                                    ftime(end)+data_a_time_resolution/(2*24*60*60)); % this last part is for a NaN, see vertcat(dout above)   
                            end
                            clear ftime fgrav
                        end
                        data.filt = horzcat(data.filt,dout);                % stack the aux. data horizontally (all channels)
                    end
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data filtered (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                    time.filt(end) = [];                                    % remove last value (is equal NaN, see dout = vertcat(dout,fgrav,NaN))
                    data.filt(end) = [];
                catch error_message
                    data.filt = [];time.filt = [];                          % otherwise, set to empty + write to logfile
                    if strcmp(error_message.identifier,'MATLAB:griddedInterpolant:NonMonotonicCompVecsErrId')
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not filter gravity due to non-monotonic sampling of input data. Check for leap-seconds and data ambiguity (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                    else
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not filter gravity. Error %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),ty,tm,td,th,tmm);
                    end
                end
			else
				data.filt = [];                                             % otherwise, set to empty + write to logfile
				[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No iGrav data filtering (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
			end
			
			%% Tides
            % Load Tide effect file. The correction will be applied in the
            % following section. Do only if iGrav or SG030 (stacked) data
            % have been loaded.
            if data_a_loaded == 1 || data_a_loaded == 3                       % 1 => data_a, 3 => SG030
                set(findobj('Tag','plotGrav_text_status'),'String','Loading Tides...');drawnow % status
                if ~isempty(tide_file)                                      % load only if a file is given/selected
                    [time.tide,data.tide] = plotGrav_loadData(tide_file,1,[],[],fid,'Tides');
                else
                    time.tide = [];                                         % otherwise set to empty
                    data.tide = [];
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No Tide file selected (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                end
			else
				time.tide = [];                                             % set to empty => no correction will be applied.
				data.tide = [];
            end
            
%%%%%%%%%%%%%%%%%%%%%%% C O R R E C T I N G %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%% Correct time series
            % In this section, the loaded time series are corrected for
            % tides and atmosphere (pol effect optional, i.e., if tide
            % file contains second column with polar motion effect). The
            % correction are computed only if iGrav or SG030 'Loading and
            % stacking' data present. No correction for other inputs.
            if data_a_loaded == 1 || data_a_loaded == 3                       % iGrav or SG030 data loaded
                % the procedure of correction computation is identical for
                % both gravimeters, however, the input data differ with
                % respect to recorded column. Therefore, store the
                % corrections in different columns.
                switch data_a_loaded                                         
                    case 1
                        column_id = 0;                                      % will be added to default column numbering
                        column_g_id = 1;                                    % column with gravity variations
                        column_p_id = 2;                                    % column with pressure variations
                        gravi_string = 'iGrav';                                 % will be used for logfile
                    case 3
                        column_id = -18;                                    % will be added to default column numbering
                        column_g_id = 1;                                    % column with gravity variations (1 = lower sphere, 2 = upper sphere)
                        column_p_id = 3;                                    % column with pressure variations
                        % Adjust order in case single sphere SG loaded
                        if size(data.data_a,2) == 2
                            data.data_a(:,3) = data.data_a(:,2);
                            data.data_a(:,2) = 0;
                        end
                        gravi_string = 'SG0XX';                             % will be used for logfile
                        plotGrav('reset_tables_sg030');                     % Change the ui-table to SG030 (by default for iGrav)
                end
                try                   
					set(findobj('Tag','plotGrav_text_status'),'String','Computing corrections...');drawnow % status
                    % Calibrating time series: phase shift. Must be
                    % performed prior to correction introduction!
                    if calib_delay~=0                                       % introduce time shift if available
						data.data_a(:,column_g_id) = interp1(time.data_a+calib_delay/86400,data.data_a(:,column_g_id),time.data_a); % re-interpolate to new time sampling (shifted using calib_delay)
                        fprintf(fid,'%s phase shift introduced = %4.2f s (%04d/%02d/%02d %02d:%02d)\n',gravi_string,calib_delay,ty,tm,td,th,tmm);
						if ~isempty(data.filt) 
							data.filt(:,column_g_id) = interp1(time.filt+calib_delay/86400,data.filt(:,column_g_id),time.filt);
						end
                    end
                    % Computing atmospheric effect. Will be applied later.
					data.data_a(:,28+column_id) = (data.data_a(:,column_p_id) - mean(data.data_a(~isnan(data.data_a(:,column_p_id)),column_p_id)))*admittance_factor; % atmospheric effect - mean value (channel 28)
					[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data atmo correction = %4.2f nm/s^2/hPa (%04d/%02d/%02d %02d:%02d)\n',gravi_string,admittance_factor,ty,tm,td,th,tmm);
                    if ~isempty(data.filt)                                  % use filtered values only if filtering was successful
                        % Calibrating time series: amplitude factor
                        data.data_a(:,22+column_id) = data.data_a(:,column_g_id)*calib_factor;    % Calibrated gravity (stored in a new channel = 22)
						data.data_a(:,23+column_id) = interp1(time.filt,data.filt(:,column_g_id),time.data_a)*calib_factor; % Gravity: calibrated and filtered (data_a channel 23)
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data calibrated = %4.2f nm/s^2/V (%04d/%02d/%02d %02d:%02d)\n',gravi_string,calib_factor,ty,tm,td,th,tmm);
                        % Tide (optional Pol) correction
                        if ~isempty(data.tide)                              % correct for tide only if effect loaded 
							if size(data.tide) > 1                          % interpolated polar motion effect, if the tide tsf file contains more than one channel (assumed that this channel contains polar motion acceleration)
								data.data_a(:,27+column_id) = interp1(time.tide,data.tide(:,2),time.data_a); % polar motion effect (channel 27)
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data corrected for polar motion: %s (%04d/%02d/%02d %02d:%02d)\n',gravi_string,tide_file,ty,tm,td,th,tmm);
							else
								data.data_a(:,27+column_id) = 0;             % otherwise, polar motion effect equal 0 
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data not corrected for polar motion (%04d/%02d/%02d %02d:%02d)\n',gravi_string,ty,tm,td,th,tmm);
							end
							data.data_a(:,26+column_id) = interp1(time.tide,data.tide(:,1),time.data_a); % tide effect (channel 26). Tide effect must be in the first tsf channel!
							[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data corrected for tides: %s (%04d/%02d/%02d %02d:%02d)\n',gravi_string,tide_file,ty,tm,td,th,tmm);
						else
							data.data_a(:,26+column_id:27+column_id) = 0;    % if not loaded, set to zero 
							[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data not corrected for tides/polar motion. (%04d/%02d/%02d %02d:%02d)\n',gravi_string,ty,tm,td,th,tmm);
                        end
                        % corrected      =  filtered        - tides            - polar motion     - atmosphere
						data.data_a(:,24+column_id) = data.data_a(:,23+column_id) - data.data_a(:,26+column_id) - data.data_a(:,27+column_id) - data.data_a(:,28+column_id); % corrected (filtered and calibrated) gravity (channel 24)
                        % Correct for gravimeter drift (trend). Store the
                        % drift approximation in 29th channel. The
                        % corrected gravity (for tides,atmo,pol and drift
                        % in 25th channel)
						switch drift_fit                                    % select drift approximation
							case 1
								data.data_a(:,29+column_id) = 0;             % no drift estimated
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Instrumental drift removal: No drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
							case 2
                                out_par = mean(data.data_a(~isnan(data.data_a(:,24+column_id)),24+column_id)); % mean value
								data.data_a(:,29+column_id) = out_par;       % can use scalar because data.data_a is defined as matrix = will be used for all rows of 29th column.
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Instrumental drift removal: Constant: %6.2f (%04d/%02d/%02d %02d:%02d)\n',out_par,ty,tm,td,th,tmm);
							case 3
								[out_par,~,out_fit] = plotGrav_fit(time.data_a,data.data_a(:,24+column_id),'poly1');
								data.data_a(:,29+column_id) = out_fit;       % drift curve (channel 29)
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Instrumental drift removal: Linear coefficients: %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',out_par(1),out_par(2),ty,tm,td,th,tmm);
							case 4
								[out_par,~,out_fit] = plotGrav_fit(time.data_a,data.data_a(:,24+column_id),'poly2');
								data.data_a(:,29+column_id) = out_fit;       % drift curve (channel 29)
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Instrumental drift removal: Quadratic coefficients: %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',out_par(1),out_par(2),out_par(3),ty,tm,td,th,tmm);
							case 5
								[out_par,~,out_fit] = plotGrav_fit(time.data_a,data.data_a(:,24+column_id),'poly3');
								data.data_a(:,29+column_id) = out_fit;       % drift curve (channel 29)
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Instrumental drift removal: Cubic coefficients: %10.8f, %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',out_par(1),out_par(2),out_par(3),out_par(4),ty,tm,td,th,tmm);
                            case 6                                          % In this case, user defined coeficients are used.
                                out_par = get(findobj('Tag','plotGrav_edit_drift_manual'),'String'); % get iser input
                                out_par = str2double(strsplit(out_par,' ')); % split the sring and covert to double
								out_fit = polyval(out_par,time.data_a);     % compute the drift curve (will automatically depend on number of coefficients)
								data.data_a(:,29+column_id) = out_fit;       % drift curve (channel 29)
								[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Instrumental drift removal: User coefficients: %s (%04d/%02d/%02d %02d:%02d)\n',get(findobj('Tag','plotGrav_edit_drift_manual'),'String'),ty,tm,td,th,tmm);
						end
						data.data_a(:,25+column_id) = data.data_a(:,24+column_id) - data.data_a(:,29+column_id); % corrected gravity (filtered, calibrated, corrected, de-trended) (channel 25)
                    else
						data.data_a(:,[23,24,25,26,27,29]+column_id) = 0;              % set to zero if filtered data not available (except atmospheric effect)
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No Gravity data correction due to unseccessful filtering (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                    end
                catch error_message
                    if strcmp(error_message.identifier,'MATLAB:griddedInterpolant:NonMonotonicCompVecsErrId')
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not correct gravity due to non-monotonic sampling of input data. Check for leap-seconds and data ambiguity (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                    else
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not correct gravity. Error %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),ty,tm,td,th,tmm); % write to logfile
                    end
                    data.data_a(:,[23,24,25,26,27,29]+column_id) = 0;        % set to zero if filtered data not available (except atmospheric effect, if computed than do not overwrite)
                end
                data.tide = [];time.tide = [];                              % remove used variable that are not of interest for plotting (they have been copied do other variables or used in other way)
            end
            
			%% Resample
            % plotGrav allows direct resampling of loaded iGrav/SG030 time
            % series (only for 'Loading and stacking').
            if data_a_loaded == 1 || data_a_loaded == 3
				try
					resample = str2double(get(findobj('Tag','plotGrav_edit_resample'),'String')); % get resampling value
                    if resample >= 2                                        % resample data_a data only if required/userInput sampling > 1 second
						set(findobj('Tag','plotGrav_text_status'),'String','Resampling iGrav data...');drawnow % send message to status bar
						ntime = [time.data_a(1):resample/86400:time.data_a(end)]'; % create new time vector with future sampling
						dnew(1:length(ntime),1:size(data.data_a,2)) = 0;     % prepare new variable for future (resampled) data matrix.
                        for c = 1:size(data.data_a,2)                        % interpolate for each column
						   dnew(:,c) = interp1(time.data_a,data.data_a(:,c),ntime);
                        end
                        clear c
						time.data_a = ntime;clear ntime                      % update time vector and remove temporary variable
						data.data_a = dnew; clear dnew                       % update data matrix
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s data re-sampled to %4.1f sec (%04d/%02d/%02d %02d:%02d)\n',gravi_string,resample,ty,tm,td,th,tmm); % logfile
					else
						[ty,tm,td,th,tmm] = datevec(now); fprintf(fid,'No %s data re-sampling (%04d/%02d/%02d %02d:%02d)\n',gravi_string,ty,tm,td,th,tmm);
                    end
                catch error_message
                    if strcmp(error_message.identifier,'MATLAB:griddedInterpolant:NonMonotonicCompVecsErrId')
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not re-sample %s data due to non-monotonic sampling of input data. Check for leap-seconds and data ambiguity (%04d/%02d/%02d %02d:%02d)\n',gravi_string,ty,tm,td,th,tmm);
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String',sprintf('Could not re-sample %s input data.',gravi_string));drawnow % status
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not re-sample %s data. Error %s (%04d/%02d/%02d %02d:%02d)\n',gravi_string,char(error_message.message),ty,tm,td,th,tmm);
                    end
				end
				data.filt = [];time.filt = [];                              % remove used variable that are not of interest for plotting (they have been copied do other variables or used in other way)
				set(findobj('Tag','plotGrav_text_status'),'String','The requested files have been loaded.');drawnow % status
			elseif data_a_loaded == 2
				set(findobj('Tag','plotGrav_text_status'),'String','The selected file has been loaded.');drawnow % status
            else
				set(findobj('Tag','plotGrav_text_status'),'String','The selected files have been loaded.');drawnow % status
            end
            
            %% Save/store data
			% Store the all loaded/corrected/resampled data and time.
            % These data will be called for plotting/computing.
            set(findobj('Tag','plotGrav_text_status'),'UserData',time);     % store time vector 
            set(findobj('Tag','plotGrav_push_load'),'UserData',data);       % store data
            clear data time                                                 % remove variables	
            fclose(fid);                                                    % close logfile 
            plotGrav('uitable_push');                                       % visualize loaded data (see next section)

            %% CORRECTION FILE
            % After loading and correction the time series for tides, drift
            % atmosphere, user can select a correction file that contains
            % information about steps and anomalous intervals. This fille
            % is then used for correction these phenomena. Fixed file
            % structure must be used. See the header of the correction file
            % for details. In addition, used can simply visulize the
            % correction file to see applied steps ('correction_file_show')
		case 'correction_file'
            % Load and use the correction file:
			set(findobj('Tag','plotGrav_text_status'),'String','Select correction file.');drawnow % send instructions to status bar
            if nargin == 1                                                  % => no additional input
                [name,path] = uigetfile({'*.txt'},'Select Correction file');    % Select the file with correctors
                file_name = fullfile(path,name);
            else
                file_name = char(varargin{1});                              % read additional function input
                name = 1;
            end
            if name == 0                                                    % Continue only if some correction file selected (not important if valid or not at this stage)
				set(findobj('Tag','plotGrav_text_status'),'String','No correction file selected.');drawnow % status
            else                           
				data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data with all time series. 
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time vectors
				if ~isempty(data.data_a)                                     % continue only if some time series have been loaded. Keep in mind, corrections are applied only on iGrav time series.
					set(findobj('Tag','plotGrav_text_status'),'String','Correcting...');drawnow % status
					try
						fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Open logfile to document all applied corrections.
					catch
						fid = fopen('plotGrav_LOG_FILE.log','a');
					end
					try
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Loading correction file: %s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm);
                        fileid = fopen(file_name);
                        in_cell = textscan(fileid,'%d %d %d %d %d %d %d %d %d %d %d %d %d %d %f %f %s','CommentStyle','%','TreatAsEmpty',{'NaN'}); % load formated the correction file
						in = horzcat(double(cell2mat(in_cell(1:14))),double(cell2mat(in_cell(15:16)))); % convert cell aray (standard textscan output) to matrix with double precision
                        channel = in(:,2);                                  % Read channe indices (fixed file structure)
						x1 = datenum(in(:,3:8));                            % Read starting point/time of the correction + convert to matlab format (iGrav time is in such format) 
						x2 = datenum(in(:,9:14));                           % Read ending point/time of the correction
						y1 = in(:,15);                                      % Read staring point/Y Value of the correction (used especially for step correction). The value itself is no so important. Only the difference y2-y1 is used. 
						y2 = in(:,16);                                      % Read ending point/Y Value of the correction (used especially for step correction). 
                        for i = 1:size(in,1)                                % Run the correction algorithm for all correctors
                            switch in(i,1)                                  % switch between correction types (1 = steps, 2 = remove interval, >=3 = local fit). Switch is always stored in the first column of the correction file.
                                case 1                                      % Step removal. 
                                    if channel(i) <= size(data.data_a,2)     % continue only if such channel exists
                                        r = find(time.data_a >= x2(i));      % find points recorded after the step occur.
                                        if ~isempty(r)                      % continue only if some points have been found
                                            data.data_a(r,channel(i)) = data.data_a(r,channel(i)) - (y2(i)-y1(i)); % remove the step by SUBTRACTING the given difference.
                                            [ty,tm,td,th,tmm] = datevec(now); % Time for logfile.
                                            fprintf(fid,'iGrav step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                                channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),y1(i),...
                                                in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),y2(i),ty,tm,td,th,tmm);
                                        end
                                        clear r                             % remove temporary variable with indices. Same variable name will be used in next section.
                                    end
                                case 2                                      % Interval removal. Values between given dates will be removed (set to NaN)   
                                    r = find(time.data_a>x1(i) & time.data_a<x2(i)); % find points within the selected interval
                                    if ~isempty(r)                          % continue only if some points have been found
                                        data.data_a(r,channel(i)) = NaN;     % remove selected interval = set to NaN!
                                        [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                        fprintf(fid,'iGrav channel %d time interval removed: Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                            channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                            in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                    end
                                case 3                                      % Interpolate interval: Linearly. Values between given dates will be replaced with interpolated values
                                    r = find(time.data_a>x1(i) & time.data_a<x2(i)); % find points within the selected interval. 
                                    if ~isempty(r)                          % continue only if some points have been found
                                        ytemp = data.data_a(time.data_a<x1(i) | time.data_a>x2(i),channel(i));  % copy the affected channel to temporary variable. Directly remove the values within the interval. Will be used for interpolation. 
                                        xtemp = time.data_a(time.data_a<x1(i) | time.data_a>x2(i));             % get selected time interval 
                                        data.data_a(r,channel(i)) = interp1(xtemp,ytemp,time.data_a(r),'linear'); % Interpolate values for the affected interval only (use r as index)
                                        [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                        fprintf(fid,'iGrav channel %d time interval interpolated linearly: Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                            channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                            in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                    end
                                case 4                                      % Interpolate interval: Spline. Values between given dates will be replaced with interpolated values
                                    r = find(time.data_a>x1(i) & time.data_a<x2(i)); % find points within the selected interval. 
                                    if ~isempty(r)                          % continue only if some points have been found
                                        ytemp = data.data_a(time.data_a<x1(i) | time.data_a>x2(i),channel(i));  % copy the affected channel to temporary variable. Directly remove the values within the interval. Will be used for interpolation. 
                                        xtemp = time.data_a(time.data_a<x1(i) | time.data_a>x2(i));             % get selected time interval 
                                        data.data_a(r,channel(i)) = interp1(xtemp,ytemp,time.data_a(r),'spline'); % Interpolate values for the affected interval only (use r as index)
                                        [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                        fprintf(fid,'iGrav channel %d time interval interpolated (spline): Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                            channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                            in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                    end
                            end
                        end
						set(findobj('Tag','plotGrav_text_status'),'String','Data corrected.');drawnow % status
						set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated data
                        fclose(fid);
                        fclose(fileid);
                    catch error_message
						set(findobj('Tag','plotGrav_text_status'),'String','Data NOT corrected (see log file)');drawnow % status
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Correction file error: %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),ty,tm,td,th,tmm); % Write message to logfile
                        fclose(fid);
                        try
                            fclose(fileid);
                        end
					end
				end
            end
        case 'correction_file_selected'
            % Just like correction_file but instead of reading the channel
            % number from correction file, the corrections are apply to
            % selected channel only (regardless second column in correction
            % file). Unlike 'correction_file', this section allows to apply
            % correction to all panels ('correction_file' only for iGrav
            % panel)
            
            % First check if some (only one) channel is selected
            % To do so get required input data
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');      % get the TRiLOGi table. 
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');      % get the TRiLOGi table. 
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');        % get the Other1 table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');        % get the Other2 table
            panels = {'data_a','data_b','data_c','data_d'};
            % Run loop checking which channel is selected
            check_sum = 0;
            panel_use = '';
            for i = 1:length(panels)
                plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                % Get the name of selected panel
                if length(plot_axesL1.(char(panels(i)))) == 1
                    panel_use = char(panels(i));
                end
                check_sum = check_sum + length(plot_axesL1.(char(panels(i))));
            end
                   
            % Load the correction file:
			set(findobj('Tag','plotGrav_text_status'),'String','Select correction file.');drawnow % send instructions to status bar
            if nargin == 1                                                  % => no additional input
                [name,path] = uigetfile({'*.txt'},'Select Correction file');    % Select the file with correctors
                file_name = fullfile(path,name);
            else
                file_name = char(varargin{1});                              % read additional function input
                name = 1;
            end
			if name == 0                                                    % Continue only if some correction file selected (not important if valid or not at this stage)
				set(findobj('Tag','plotGrav_text_status'),'String','No correction file selected.');drawnow % status
            else                           
				data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data with all time series. 
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time vectors
				if ~isempty(data) && check_sum == 1                         % continue only if some time series have been loaded and exactly one channel is selected
					set(findobj('Tag','plotGrav_text_status'),'String','Correcting...');drawnow % status
					try
						fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Open logfile to document all applied corrections.
					catch
						fid = fopen('plotGrav_LOG_FILE.log','a');
					end
					try
						[ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Loading correction file: %s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm);
                        fileid = fopen(file_name);
                        in_cell = textscan(fileid,'%d %d %d %d %d %d %d %d %d %d %d %d %d %d %f %f %s','CommentStyle','%','TreatAsEmpty',{'NaN'}); % load formated the correction file
						in = horzcat(double(cell2mat(in_cell(1:14))),double(cell2mat(in_cell(15:16)))); % convert cell aray (standard textscan output) to matrix with double precision
                        channel = ones(size(in,1),1).*plot_axesL1.(panel_use); % set fixed channel number = selected channel.
						x1 = datenum(in(:,3:8));                            % Read starting point/time of the correction + convert to matlab format (iGrav time is in such format) 
						x2 = datenum(in(:,9:14));                           % Read ending point/time of the correction
						y1 = in(:,15);                                      % Read staring point/Y Value of the correction (used especially for step correction). The value itself is no so important. Only the difference y2-y1 is used. 
						y2 = in(:,16);                                      % Read ending point/Y Value of the correction (used especially for step correction). 
                        for i = 1:size(in,1)                                % Run the correction algorithm for all correctors
                            switch in(i,1)                                  % switch between correction types (1 = steps, 2 = remove interval, >=3 = local fit). Switch is always stored in the first column of the correction file.
                                case 1                                      % Step removal. 
                                    if channel(i) <= size(data.(panel_use),2)     % continue only if such channel exists
                                        r = find(time.(panel_use) >= x2(i));      % find points recorded after the step occur.
                                        if ~isempty(r)                      % continue only if some points have been found
                                            data.(panel_use)(r,channel(i)) = data.(panel_use)(r,channel(i)) - (y2(i)-y1(i)); % remove the step by SUBTRACTING the given difference.
                                            [ty,tm,td,th,tmm] = datevec(now); % Time for logfile.
                                            fprintf(fid,'%s step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                                panel_use,channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),y1(i),...
                                                in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),y2(i),ty,tm,td,th,tmm);
                                        end
                                        clear r                             % remove temporary variable with indices. Same variable name will be used in next section.
                                    end
                                case 2                                      % Interval removal. Values between given dates will be removed (set to NaN)   
                                    r = find(time.(panel_use)>x1(i) & time.(panel_use)<x2(i)); % find points within the selected interval
                                    if ~isempty(r)                          % continue only if some points have been found
                                        data.(panel_use)(r,channel(i)) = NaN;     % remove selected interval = set to NaN!
                                        [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                        fprintf(fid,'%s channel %d time interval removed: Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                            panel_use,channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                            in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                    end
                                case 3                                      % Interpolate interval: Linearly. Values between given dates will be replaced with interpolated values
                                    r = find(time.(panel_use)>x1(i) & time.(panel_use)<x2(i)); % find points within the selected interval. 
                                    if ~isempty(r)                          % continue only if some points have been found
                                        ytemp = data.(panel_use)(time.(panel_use)<x1(i) | time.(panel_use)>x2(i),channel(i));  % copy the affected channel to temporary variable. Directly remove the values within the interval. Will be used for interpolation. 
                                        xtemp = time.(panel_use)(time.(panel_use)<x1(i) | time.(panel_use)>x2(i));             % get selected time interval 
                                        data.(panel_use)(r,channel(i)) = interp1(xtemp,ytemp,time.(panel_use)(r),'linear'); % Interpolate values for the affected interval only (use r as index)
                                        [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                        fprintf(fid,'%s channel %d time interval interpolated linearly: Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                            panel_use,channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                            in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                    end
                                case 4                                      % Interpolate interval: Spline. Values between given dates will be replaced with interpolated values
                                    r = find(time.(panel_use)>x1(i) & time.(panel_use)<x2(i)); % find points within the selected interval. 
                                    if ~isempty(r)                          % continue only if some points have been found
                                        ytemp = data.(panel_use)(time.(panel_use)<x1(i) | time.(panel_use)>x2(i),channel(i));  % copy the affected channel to temporary variable. Directly remove the values within the interval. Will be used for interpolation. 
                                        xtemp = time.(panel_use)(time.(panel_use)<x1(i) | time.(panel_use)>x2(i));             % get selected time interval 
                                        data.(panel_use)(r,channel(i)) = interp1(xtemp,ytemp,time.(panel_use)(r),'spline'); % Interpolate values for the affected interval only (use r as index)
                                        [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                        fprintf(fid,'%s channel %d time interval interpolated (spline): Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                            panel_use,channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                            in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                    end
                            end
                        end
						set(findobj('Tag','plotGrav_text_status'),'String','Data corrected.');drawnow % status
						set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated data
                        fclose(fid);
                        fclose(fileid);
                    catch error_message
						set(findobj('Tag','plotGrav_text_status'),'String','Data NOT corrected (see log file)');drawnow % status
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Correction file error: %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),ty,tm,td,th,tmm); % Write message to logfile
                        fclose(fid);
                        try
                            fclose(fileid);
                        end
					end
				end
			end
			%% CORRECTION FILE - show
		case 'correction_file_show'
            % Load and plot the correction file. To see where corrections
            % have been applied.
			set(findobj('Tag','plotGrav_text_status'),'String','Select correction file.');drawnow % send instructions to status bar
            if nargin == 1                                                  % => no additional input
                [name,path] = uigetfile({'*.txt'},'Select Correction file');    % Select the file with correctors
                file_name = fullfile(path,name);
            else
                file_name = char(varargin{1});                              % read additional function input
                name = 1;
            end
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes one handle. L1 will be used for plotting!
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData'); % get font size for new/correction description
            if name == 0                                                    % continue only if some time series have been loaded. Keep in mind, corrections are applied only on iGrav time series.
				set(findobj('Tag','plotGrav_text_status'),'String','No correction file selected.');drawnow % status
            else
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data with all time series. No time vector needed.
				if ~isempty(data.data_a)                                     % continue only if exists
					set(findobj('Tag','plotGrav_text_status'),'String','Plotting...');drawnow % status
					try
                        fileid = fopen(file_name);
                        in_cell = textscan(fileid,'%d %d %d %d %d %d %d %d %d %d %d %d %d %d %f %f %s','CommentStyle','%','TreatAsEmpty',{'NaN'}); % load formated the correction file
						in = horzcat(double(cell2mat(in_cell(1:14))),double(cell2mat(in_cell(15:16)))); % convert cell aray (standard textscan output) to matrix with double precision
						description = in_cell(17);                          % Read description
						x1 = datenum(in(:,3:8));                            % Read starting point/time of the correction + convert to matlab format (iGrav time is in such format) 
						x2 = datenum(in(:,9:14));                           % Read ending point/time of the correction
						y1 = in(:,15);                                      % Read staring point/Y Value of the correction (used especially for step correction). The value itself is no so important. Only the difference y2-y1 is used. 
						y2 = in(:,16);                                      % Read ending point/Y Value of the correction (used especially for step correction).  
						y = get(a1(1),'YLim');                              % Get current Y limits to plot the corrections within the same range.
                        set(gcf,'CurrentAxes',a1(1));                       % Set axes to be plotted in. 'text' function does not support passing handles.
                        for i = 1:size(in,1)                                % Plot all correctors (regardless if in loaded time range or not)
                            switch in(i,1)                                  % switch between correction types (1 = steps, 2 = remove interval, >=3 = local fit). Switch is always stored in the first column of the correction file. 
								case 1                                      % Step removal
									plot([x1(i),x1(i)],y,'k-');hold on      % Plot the step with black line.
									text(x1(i),y(1)+range(y)*0.05,sprintf('%s (%3.1f)',char(description{1,1}(i)),y2(i)-y1(i)),'Rotation',90,'FontSize',font_size-2,'VerticalAlignment','bottom','interpreter','none'); % Add step value
								case 2                                      % Interval removal    
                                    plot([x1(i),x2(i),x2(i),x1(i),x1(i)],[y(1),y(1),y(2),y(2),y(1)],'k--');
                                    text(x1(i),y(1)+range(y)*0.05,sprintf('%s (remove)',char(description{1,1}(i))),'Rotation',90,'FontSize',font_size-2,'VerticalAlignment','bottom','interpreter','none'); %
                                case 3
                                    plot([x1(i),x2(i),x2(i),x1(i),x1(i)],[y(1),y(1),y(2),y(2),y(1)],'k-.','Color',[0.5 0.5 0.5]);
                                    text(x1(i),y(1)+range(y)*0.05,sprintf('%s (linear)',char(description{1,1}(i))),'Rotation',90,'FontSize',font_size-2,'VerticalAlignment','bottom','interpreter','none'); %
                                case 4
                                    plot([x1(i),x2(i),x2(i),x1(i),x1(i)],[y(1),y(1),y(2),y(2),y(1)],':','Color',[0.5 0.5 0.5]);
                                    text(x1(i),y(1)+range(y)*0.05,sprintf('%s (spline)',char(description{1,1}(i))),'Rotation',90,'FontSize',font_size-2,'VerticalAlignment','bottom','interpreter','none'); %
                            end
                        end
                        set(gcf,'CurrentAxes',a1(2));                       % Set axes back to R1 (otherwise invisible)
						set(findobj('Tag','plotGrav_text_status'),'String','Correction file plotted.');drawnow % status
					catch
						set(findobj('Tag','plotGrav_text_status'),'String','Could not load correction file...');drawnow % status
					end
				end
            end
            
%%%%%%%%%%%%%%%%%%%%%%% V I S U A L I Z I N G %%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
		case 'uitable_push'
            %% Visualize data after pressing ui-table
            % The following code section will be run after changing
            % (checking/unchecking) one of the checkboxes on one of the
            % panels (iGrav,TRiLOGi,Other1,Other2)
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data stored in the previous section. Time will be loaded in plotGrav_plotData.m function
			if ~isempty(data)                                               % continue only if some data exist, i.e., run after loading data
                % Get ui-tables and plot axes
				set(findobj('Tag','plotGrav_text_status'),'String','Plotting...');drawnow % status 
				data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table, not data! All time series are stored in findobj('Tag','plotGrav_push_load'),'UserData').
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table. These tables will be used to plot only 'checked' time series.
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
				a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get axes of the First plot (left and right axes = L1 and R1)
				a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes of the Second plot (left and right axes = L2 and R2)
				a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes of the Third plot (left and right axes = L3 and R3)
                line_width = get(findobj('Tag','plotGrav_menu_line_width'),'UserData'); % get line width
                plot_type = get(findobj('Tag','plotGrav_view_plot_type'),'UserData'); % get plot type (line,bar...)
                
                % Clear all plots / reset all plots
				cla(a1(1));legend(a1(1),'off');ylabel(a1(1),[]);            % clear axes and remove legends and labels: First plot left (a1(1))
				cla(a1(2));legend(a1(2),'off');ylabel(a1(2),[]);            % clear axes and remove legends and labels: First plot right (a1(2))
				axis(a1(1),'auto');axis(a1(2),'auto');                      % Reset axis (not axes)
				cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);            % Do the same for other axes
				cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);
				axis(a2(1),'auto');axis(a2(2),'auto');
				cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);
				cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);
				axis(a3(1),'auto');axis(a3(2),'auto');
                
                % Find checked (selected) time series (columns of data
                % matrices). Use a loop changing the panel name
                panel = {'data_a','data_b','data_c','data_d'};
                for i = 1:length(panel)
                    % Checked: L1 (left first plot)
                    plot_axesL1.(panel{i}) = find(cell2mat(data_table.(panel{i})(:,1))==1); 
                    % Checked: L2 
                    plot_axesL2.(panel{i}) = find(cell2mat(data_table.(panel{i})(:,2))==1); 
                    % Checked: L3   
                    plot_axesL3.(panel{i}) = find(cell2mat(data_table.(panel{i})(:,3))==1); 
                    % Checked: R1 
                    plot_axesR1.(panel{i}) = find(cell2mat(data_table.(panel{i})(:,5))==1);
                    % Checked: R2 
                    plot_axesR2.(panel{i}) = find(cell2mat(data_table.(panel{i})(:,6))==1); 
                    % Checked: R3 
                    plot_axesR3.(panel{i}) = find(cell2mat(data_table.(panel{i})(:,7))==1);
                end
                
                % reset plot_mode = nothing is plotted by default (0 no plot, 1 - left only, 2 -right only, 3 - both, columns refer to Plots 1/2/3)
				plot_mode = [0 0 0];                                        
				set(findobj('Tag','plotGrav_push_reset_view'),'UserData',plot_mode);% store the plot_mode 
                % Declare variale to store legend entries. This variable
                % will be used only for printing to ensure the printed
                % figure has the same legend as the plotted one.
                legend_save = [];
                % Declare variable to synchronize all plots,i.e., to ensure
                % than the XTicks and Limits are the same, Plot1 is the
                % superior axes (L1 -> R1 -> L2 -> R2 -> L3 -> R3)  
                ref_axes = [];   
                % Declare ohter parameters used in this section (to reduce
                % the number of code rows)
                plot_axesR = []; % will store selected right axes (see 'plot_axesRX.yyyy' variable and ploGrav_plotData.m function)
				plot_axesL = []; % will store selected left axes (see 'plot_axesLX.yyyy' variable and ploGrav_plotData.m function)
                
				% Plot1: L1 only
                % First check if some (at least one) time series/channel is
                % selected for L1. Only if so, continue. Selected means
                % that plot_axesL1.* is not empty.
                if (~isempty(plot_axesL1.data_a) || ~isempty(plot_axesL1.data_b) || ~isempty(plot_axesL1.data_c) || ~isempty(plot_axesL1.data_d)) &&...
				   (isempty(plot_axesR1.data_a) && isempty(plot_axesR1.data_b) && isempty(plot_axesR1.data_c) && isempty(plot_axesR1.data_d)) 
					switch_plot = 1;                                        % 1 = left axes. See plotGrav_plotData.m function for details.
					plot_mode(1) = 1;                                       % 1 = left axes, first plot
					plot_axesL = plot_axesL1;                               % see ploGrav_plotData.m function
					legend_save = plotGrav_plotData(a1,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(1),plot_type(1:2)); % call the plotGrav_plotData function
                % Plot1: R1 only
                % Same procedure as for Plot1: L1. The only difference is
                % the plot_mode and switch_plot
                elseif (~isempty(plot_axesR1.data_a) || ~isempty(plot_axesR1.data_b) || ~isempty(plot_axesR1.data_c) || ~isempty(plot_axesR1.data_d)) &&... 
				   (isempty(plot_axesL1.data_a) && isempty(plot_axesL1.data_b) && isempty(plot_axesL1.data_c) && isempty(plot_axesL1.data_d)) 
					switch_plot = 2;                                        % 2 = right axes
					plot_mode(1) = 2;                                       % 1 = right axes, first plot
					plot_axesR = plot_axesR1;                               % see ploGrav_plotData function
					legend_save = plotGrav_plotData(a1,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(2),plot_type(1:2)); % call the plotGrav_plotData function
				% Plot1: R1 and L1
                % In this case, both left and right axes are visible and
                % used for plotting. Similar to plotyy function.
                elseif (~isempty(plot_axesL1.data_a) || ~isempty(plot_axesL1.data_b) || ~isempty(plot_axesL1.data_c) || ~isempty(plot_axesL1.data_d)) &&...
				   (~isempty(plot_axesR1.data_a) || ~isempty(plot_axesR1.data_b) || ~isempty(plot_axesR1.data_c) || ~isempty(plot_axesR1.data_d)) 
					switch_plot = 3;                                        % 3 = left + right axes
					plot_mode(1) = 3;                                       % 1 = left + right axes, first plot                                      
					plot_axesL = plot_axesL1;
					plot_axesR = plot_axesR1;
					legend_save = plotGrav_plotData(a1,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(1:2),plot_type(1:2)); % call the plotGrav_plotData function
					set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save); % store legend for printing
                end
                % Store obtained legend and removed used variables that
                % could interfere with next plot (2).
                set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save); % store legend for printting
                clear switch_plot ref_axes                                  % remove settings
                % Reset legend/axes variable
                legend_save = []; 
				plot_axesR = [];
                plot_axesL = [];
                
				% Plot 2. First get reference axes (to sync all plots)
                if plot_mode(1) == 0                                        % find out if plot1 exists. If not, create new reference.
                    ref_axes = [];
                elseif plot_mode(1) == 2                                    % if plot1 exists and contains only right axes (R1)
                    ref_axes = a1(2);
                else                                                        % otherwise use L1 axes. 
                    ref_axes = a1(1);
                end
                % L2 only
                if (~isempty(plot_axesL2.data_a) || ~isempty(plot_axesL2.data_b) || ~isempty(plot_axesL2.data_c) || ~isempty(plot_axesL2.data_d)) &&... 
				   (isempty(plot_axesR2.data_a) && isempty(plot_axesR2.data_b) && isempty(plot_axesR2.data_c) && isempty(plot_axesR2.data_d)) 
					switch_plot = 1;                                        % left axes only
					plot_mode(2) = 1;                                       % left axes, second plot only
					plot_axesL = plot_axesL2;    
					legend_save = plotGrav_plotData(a2,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(3),plot_type(3:4)); % call the function
				% Plot 2: R2 only
                % WARNING: The following code is not commented because the meaning
                % of the code can be derived from previous plots
                elseif (~isempty(plot_axesR2.data_a) || ~isempty(plot_axesR2.data_b) || ~isempty(plot_axesR2.data_c) || ~isempty(plot_axesR2.data_d)) &&... 
				   (isempty(plot_axesL2.data_a) && isempty(plot_axesL2.data_b) && isempty(plot_axesL2.data_c) && isempty(plot_axesL2.data_d))  
					switch_plot = 2;
					plot_mode(2) = 2;
					plot_axesR = plot_axesR2;                                  
					legend_save = plotGrav_plotData(a2,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(4),plot_type(3:4)); % call the plotGrav_plotData function
				% Plot 2: R2 and L2,see coments above.
                elseif (~isempty(plot_axesL2.data_a) || ~isempty(plot_axesL2.data_b) || ~isempty(plot_axesL2.data_c) || ~isempty(plot_axesL2.data_d)) &&...
				   (~isempty(plot_axesR2.data_a) || ~isempty(plot_axesR2.data_b) || ~isempty(plot_axesR2.data_c) || ~isempty(plot_axesR2.data_d)) 
					switch_plot = 3;
					plot_mode(2) = 3;
					plot_axesL = plot_axesL2;
					plot_axesR = plot_axesR2;
					legend_save = plotGrav_plotData(a2,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(3:4),plot_type(3:4)); % call the plotGrav_plotData function
                end
                set(findobj('Tag','plotGrav_menu_print_two'),'UserData',legend_save); % store legend for printing
                clear switch_plot ref_axes                                  % remove settings
                % Reset legend/axes variable
                legend_save = []; 
				plot_axesR = [];
                plot_axesL = [];
                
				% Plot 3. First get reference axes (to sync all plots)
                if plot_mode(1)+plot_mode(2) == 0                           % find out if plot1 or plot2 exist
                    ref_axes = [];                                          % if not, no reference axes limits == L3 will not be synchronized (because it is the only plot)
                elseif plot_mode(1) > 0 && plot_mode(1) ~= 2                % if plot1 exists, more specificaly, L1 (even when L1+R1 exist at the same time)
                    ref_axes = a1(1);
                elseif plot_mode(1) > 0 && plot_mode(1) == 2                % use R1 only if L1 does not exist ( 2 = only right)
                    ref_axes = a1(2);
                elseif plot_mode(1) == 0 && plot_mode(2) == 2               % use R2 only if plot1 and plot2:L2 do not exist
                    ref_axes = a2(2);
                elseif plot_mode(1) == 0 && plot_mode(2) ~= 2               % use L2 otherwise
                    ref_axes = a2(1);
                end
                % L3 only, see coments above (Plot 1).
                if (~isempty(plot_axesL3.data_a) || ~isempty(plot_axesL3.data_b) || ~isempty(plot_axesL3.data_c) || ~isempty(plot_axesL3.data_d)) &&... 
				   (isempty(plot_axesR3.data_a) && isempty(plot_axesR3.data_b) && isempty(plot_axesR3.data_c) && isempty(plot_axesR3.data_d)) 
					switch_plot = 1;
					plot_mode(3) = 1;
					plot_axesL = plot_axesL3;      
					legend_save = plotGrav_plotData(a3,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(5),plot_type(5:6)); % call the function
				% Plot3: R3 only see coments above.
                elseif (~isempty(plot_axesR3.data_a) || ~isempty(plot_axesR3.data_b) || ~isempty(plot_axesR3.data_c) || ~isempty(plot_axesR3.data_d)) &&... 
				   (isempty(plot_axesL3.data_a) && isempty(plot_axesL3.data_b) && isempty(plot_axesL3.data_c) && isempty(plot_axesL3.data_d))  
					switch_plot = 2;
					plot_mode(3) = 2;
					plot_axesR = plot_axesR3;                              
					legend_save = plotGrav_plotData(a3,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(6),plot_type(5:6)); % call the plotGrav_plotData function
				% Plot3: R3 and L3, see coments above.
                elseif (~isempty(plot_axesL3.data_a) || ~isempty(plot_axesL3.data_b) || ~isempty(plot_axesL3.data_c) || ~isempty(plot_axesL3.data_d)) &&...
				   (~isempty(plot_axesR3.data_a) || ~isempty(plot_axesR3.data_b) || ~isempty(plot_axesR3.data_c) || ~isempty(plot_axesR3.data_d)) 
					switch_plot = 3;
					plot_mode(3) = 3;
					plot_axesL = plot_axesL3;
					plot_axesR = plot_axesR3;
					legend_save = plotGrav_plotData(a3,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width(5:6),plot_type(5:6)); % call the plotGrav_plotData function
                end
                set(findobj('Tag','plotGrav_menu_print_three'),'UserData',legend_save); % store legend for printing
                clear switch_plot plot_axesL plot_axesR ref_axes    % remove settings
				
				set(findobj('Tag','plotGrav_push_reset_view'),'UserData',plot_mode);
				set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
                % Update date axis = convert to civil date format.
				plotGrav('push_date');
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load Data first.');drawnow % send message
			end                                                         % ~isempty(data)
			
		case 'push_date'
			%% PUSH_DATE
            % It is important to convert the plotted time values to civil
            % format (by default in matlab datenum format). The following
            % code is called after each plot. Newer matlab versions (>R2014)
            % support automatic update of 'dateticks'. However, plotGrav was
            % written and tested using matlab R2013a.
            % First get axes to refer to the axisting plots.
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes one handles
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    % get axes two handles
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');    % get axes three handles
			plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
            date_format = get(findobj('Tag','plotGrav_menu_date_format'),'UserData'); % get date format switch. See numeric identificator: http://de.mathworks.com/help/matlab/ref/datetick.html#inputarg_dateFormat
            num_of_ticks_x = get(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData'); % get number of tick for x axis
			% Switch between plot modes. This is done to avoid overlaying
			% of data ticks (e.g., of left and right axes)
            % Plot1
			switch plot_mode(1)                                
				case 1                                                      % Left plot only
					ref_lim = get(a1(1),'XLim');                            % get current x limits and use them a reference
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % create new ticks. Use always 9 ticks! Such setting does not follow natural tick sampling (e.g., one tick per day or week)
					set(a1(1),'XTick',xtick_value);                         % set new ticks (left)
					datetick(a1(1),'x',date_format,'keepticks');            % time in required format
					set(a1(2),'Visible','off');                             % turn of the right axes = make it not visible
					linkaxes([a1(1),a1(2)],'x');                            % link axes = synchronize, just in case
				case 2                                                      % Right plot only
					ref_lim = get(a1(2),'XLim');                            % get current x limits and use them a reference
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % create new ticks
					set(a1(2),'XTick',xtick_value);                         % set new ticks and labels (right)
					datetick(a1(2),'x',date_format,'keepticks');            % time in required format
					set(a1(1),'Visible','off');                             % turn of right axes
					linkaxes([a1(1),a1(2)],'x');                            % link axes, just in case
				case 3                                                      % Right and Left plot
					ref_lim = get(a1(1),'XLim');                            % use Left plot limits as reference
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % compute new ticks
					set(a1(1),'XTick',xtick_value); % place new labels and ticks
					set(a1(2),'XTick',xtick_value,'Visible','on','color','none','XTickLabel',[]); % make Right plot visible but remove ticks + set transparency
					datetick(a1(1),'x',date_format,'keepticks');            % time in required format
					linkaxes([a1(1),a1(2)],'x');                            % link axes, just in case
				otherwise
					ref_lim = [];                                       % no ref_lim if plot1 is not on
			end
			% Plot 2
            % The following code is commented sparingly, because the
            % meaning can be derived by looking at the previous (Plot1)
            % comments
			switch plot_mode(2)                                         	
				case 1                                                      % Left plot only
					if isempty(ref_lim)
						ref_lim = get(a2(1),'XLim');                        % get current x limits and use them a reference
					end
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % create new ticks
					set(a2(1),'XTick',xtick_value);                         % set new ticks and labels (left)
					datetick(a2(1),'x',date_format,'keepticks');            % time in required format
					set(a2(2),'Visible','off');                             % turn of right axes
					linkaxes([a2(1),a2(2)],'x');                            % link axes, just in case
				case 2                                                      % Right plot only
					if isempty(ref_lim)
						ref_lim = get(a2(2),'XLim');                        % get superior x limits and use them a reference
					end
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % create new ticks
					set(a2(2),'XTick',xtick_value);                         % set new ticks and labels (right)
					datetick(a2(2),'x',date_format,'keepticks');            % time in required format
					set(a2(1),'Visible','off');                             % turn of left axes
					linkaxes([a2(1),a2(2)],'x');                            % link axes, just in case
				case 3                                                      % Right and Left plot
					if isempty(ref_lim)
						ref_lim = get(a2(1),'XLim');                        % get superior x limits and use them a reference
					end
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % compute new ticks
					set(a2(1),'XTick',xtick_value);                         % place new labels and ticks
					set(a2(2),'XTick',xtick_value,'Visible','on','color','none','XTickLabel',[]); % make Right plot visible but remove ticks
					datetick(a2(1),'x',date_format,'keepticks');            % time in required format
					linkaxes([a2(1),a2(2)],'x');                            % link axes, just in case
				otherwise
					ref_lim = [];                                           % no ref_lim if plot2 is not on
			end
			% Plot 3
            switch plot_mode(3)
				case 1                                                      % Left plot only
					if isempty(ref_lim)
						ref_lim = get(a3(1),'XLim');                        % get current x limits and use them a reference
					end
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % create new ticks
					set(a3(1),'XTick',xtick_value);                         % set new ticks and labels (left)
					datetick(a3(1),'x',date_format,'keepticks');            % time in required format
					set(a3(2),'Visible','off');                             % turn of right axes
					linkaxes([a3(1),a3(2)],'x');                            % link axes, just in case
				case 2                                                      % Right plot only
					if isempty(ref_lim)
						ref_lim = get(a3(2),'XLim');                        % get current x limits and use them a reference
					end
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % create new ticks
					set(a3(2),'XTick',xtick_value);                         % set new ticks and labels (right)
					datetick(a3(2),'x',date_format,'keepticks');            % time in required format
					set(a3(1),'Visible','off');                             % turn of right axes
					linkaxes([a3(1),a3(2)],'x');                            % link axes, just in case
				case 3                                                      % Right and Left plot
					if isempty(ref_lim)
						ref_lim = get(a3(1),'XLim');                        % get current x limits and use them a reference
					end
					xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);        % compute new ticks
					set(a3(1),'XTick',xtick_value);                         % place new labels and ticks
					set(a3(2),'XTick',xtick_value,'Visible','on','color','none','XTickLabel',[]); % make Right plot visible but remove ticks
					datetick(a3(1),'x',date_format,'keepticks'); % time in YYYY/MM/DD HH:MM format
					linkaxes([a3(1),a3(2)],'x');                        % link axes, just in case
            end
            
        case 'set_date_1'
            %% Date format
            % User can set the date format, i.e. the appearance of X Ticks.
            % The ticks are set using datetick function (see 'push_date').
            % In the following part, user set and date format switch that
            % is then stored and used afterwards for all plots.
            date_format = get(findobj('Tag','plotGrav_menu_date_format'),'UserData'); % get current date format (to show it to user)
            if nargin == 1
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                set(findobj('Tag','plotGrav_text_status'),'String','Set date format and press ''confirm''');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',date_format);  % Make user input dialog visible + show current format
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            date_format = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get the new date format
            try
                set(findobj('Tag','plotGrav_menu_date_format'),'UserData',date_format); % Store the new format. Will be used by 'push_date' and plotGrav_plotData.m function
                plotGrav('push_date');                                  % call the section responsible for converting data formats (this section serves only for date switch insertion)
                set(findobj('Tag','plotGrav_text_status'),'String','Date Format set.');drawnow % status
            catch
                set(findobj('Tag','plotGrav_menu_date_format'),'UserData',1); % set default if som error occurs
                plotGrav('push_date');
            end
        case 'set_date_2'
            % This part opens a web browser to show help related to matlab
            % datetick function including desctiption of the date switch.
            web('http://de.mathworks.com/help/matlab/ref/datetick.html#inputarg_dateFormat');
            set(findobj('Tag','plotGrav_text_status'),'String','See web: matlab datetick: Symbolic identificator.');drawnow % send message to status bar with instructions
            
        case 'set_num_of_ticks_x'
            %% Number of Ticks
            % User can set number of ticks for X and Y axis. This will
            % affect all plots (1,2 and 3). Currently plotted time range
            % will be linearly divided into given parts with ticks.
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set number of ticks for X axis (e.g., 9)');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       % Make user input dialog visible  
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','9'); % Make user editable field visible and set the default value
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1})); 
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn of the user input dialogs 
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            try
                num_of_ticks = str2double(get(findobj('Tag','plotGrav_edit_text_input'),'String')); % get the input and covert it to double (matlab required a number as input for 'XLim' and 'XTick')
                if num_of_ticks >30 || num_of_ticks < 1                     % Check if reasonable value hase been inserted
                    set(findobj('Tag','plotGrav_text_status'),'String','Number of ticks must be between 1 - 30.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData',num_of_ticks); % store the input for future plotting (including printing)
                    plotGrav('uitable_push');                               % re-plot to make changes directly visible
                    set(findobj('Tag','plotGrav_text_status'),'String','Number of ticks set.');drawnow % status
                end
            catch
                set(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData',9); % set default
                plotGrav('uitable_push');
            end
        case 'set_num_of_ticks_y'
            % Same as previous but for Y ticks, see comments in there.
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set number of ticks for X axis (e.g., 5)');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       % Make user input dialog visible    
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','5'); % Make user editable field visible and set the default value 
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1})); 
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            try
                num_of_ticks = str2double(get(findobj('Tag','plotGrav_edit_text_input'),'String')); % get user input and convert it to double (matlab required a number as input for 'YLim' and 'YTick')
                if num_of_ticks >30 || num_of_ticks < 1                     % Check if reasonable value hase been inserted
                    set(findobj('Tag','plotGrav_text_status'),'String','Number of ticks must be between 1 - 30.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData',num_of_ticks);
                    plotGrav('uitable_push');
                    set(findobj('Tag','plotGrav_text_status'),'String','Number of ticks set.');drawnow % status
                end
            catch
                set(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData',5); % set default
                plotGrav('uitable_push');
            end
            
        case 'set_font_size'
            %% Set font size
            % User can set the font size for all axes,legends,labels.
            % Thereby, standard matlab font size numbering is used, i.e.,
            % font units = points.
            a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes of the First plot (left and right axes = L1 and R1). These handles will be use to change the font
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    % get axes of the Second plot (left and right axes = L2 and R2)
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');    % get axes of the Third plot (left and right axes = L3 and R3)
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set font size (e.g., 9)');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');        % Make user input dialog visible   
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','9'); % Make user editable field visible and set the default value 
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar                                                        
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % In case functin has two inputs (for example when called from plotGrav_scriptRun.m)
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off user input fields
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            try
                font_size = str2double(get(findobj('Tag','plotGrav_edit_text_input'),'String')); % get user input and convert it to double (matlab required a number as input for 'FontSize')
                if font_size >30 || font_size < 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Font size must be between 1 - 30.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_menu_set_font_size'),'UserData',font_size);
                    plotGrav('uitable_push');                               % re-plot all (plotGrav_plotData.m function uses fontsize)
                    set(findobj('Tag','plotGrav_text_status'),'String','Font size set.');drawnow % status
                    set(a1(1),'FontSize',font_size);set(a1(2),'FontSize',font_size);
                    set(a2(1),'FontSize',font_size);set(a2(2),'FontSize',font_size);
                    set(a3(1),'FontSize',font_size);set(a3(2),'FontSize',font_size);
                end
            catch
                set(findobj('Tag','plotGrav_menu_set_font_size'),'UserData',9); % set default
                plotGrav('uitable_push');                                   % re-plot
            end
        case 'set_data_points'
            %% Data points for plotting
            % User can use this option to plot only n-th data points of
            % each time series. For example use each second value from a 
            % time series [1 2 3 4 5 6] => [1 3 5] plot data points. 
            % This option affect only plotting, not stored data! The aim is 
            % to accelerate the plotting. By default all data points are
            % plotted, i.e., the value is set to 1.
            
            % Use either GUI (nargin == 1) or script (else)
            if nargin == 1  
                nth = get(findobj('Tag','plotGrav_menu_set_data_points'),'UserData'); % get current values
                set(findobj('Tag','plotGrav_text_status'),'String','Set integer to plot each n-th data point (e.g., 2)');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');        % Make user input dialog visible   
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',nth); % Make user editable field visible and set the default value 
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar                                                      
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % In case functin has two inputs (for example when called from plotGrav_scriptRun.m)
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off user input fields
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            try
                nth = round(str2double(get(findobj('Tag','plotGrav_edit_text_input'),'String'))); % get user input and convert it to integer
                if nth > 0                                                  % must be positive value
                    set(findobj('Tag','plotGrav_menu_set_data_points'),'UserData',nth);
                    plotGrav('uitable_push');                                   % re-plot
                    set(findobj('Tag','plotGrav_text_status'),'String','Plot n-th data points: set');drawnow 
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Value must be a positive integer.');drawnow 
                end
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Coult not set.');drawnow 
                plotGrav('uitable_push');                                   % re-plot
            end
        case 'set_plot_type'
            %% Set plot type (line, bar,...)
            % Use either GUI (nargin == 1) or script (else)
            if nargin == 1  
                set(findobj('Tag','plotGrav_text_status'),'String','Set a vector of integers (6) for plot type...waiting 6 seconds');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');        % Make user input dialog visible   
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','1;1;1;1;1;1'); % Make user editable field visible and set the default value 
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar                                                       
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % In case functin has two inputs (for example when called from plotGrav_scriptRun.m)
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off user input fields
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            plot_type = strsplit(get(findobj('Tag','plotGrav_edit_text_input'),'String'),';'); % split string
            plot_type = round(str2double(plot_type)); % convert to integers
            % Check the correct length
            if length(plot_type) ~= 6
                set(findobj('Tag','plotGrav_text_status'),'String','Vector with 6 values must be set');drawnow
            else
                set(findobj('Tag','plotGrav_view_plot_type'),'UserData',plot_type); % set the values
                plotGrav('uitable_push');                                   % re-plot
                set(findobj('Tag','plotGrav_text_status'),'String','Plot type set');drawnow
            end
            
		case 'reset_view'
            %% Reset view
            % Reset view means update all plots = delete all information
            % about current zoom level and re-plot selected channels.
			set(findobj('Tag','plotGrav_push_zoom_in'),'UserData',[]);      % Remove all information related to zoom level (see ZOOM_IN section)
			plotGrav('uitable_push');                                       % re-plot
            
		case 'uncheck_all'
            %% Uncheck all
            % User can uncheck all selected time series at once. This is
            % especially handy after selecting too many time series.
            % Unchecking will also reset all plot settings, inclusing
            % zooming level or inserted objects (lines, text...).
            % First get necesary data
			data_data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
			data_data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
			data_data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
			data_data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get plot 1 handles
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    % get plot 2 handles
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');    % get plot 3 handles
            % Reset plot
			cla(a1(1));legend(a1(1),'off');ylabel(a1(1),[]);                % clear axes and remove legends and labels
			cla(a1(2));legend(a1(2),'off');ylabel(a1(2),[]);                % clear axes and remove legends and labels
			axis(a1(1),'auto');axis(a1(2),'auto');                          % Reset axis (not axes)
			cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);                % clear axes and remove legends and labels
			cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);                % clear axes and remove legends and labels
			axis(a2(1),'auto');axis(a2(2),'auto');
			cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);                % clear axes and remove legends and labels
			cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);                % clear axes and remove legends and labels
			axis(a3(1),'auto');axis(a3(2),'auto');
            % Reset ui-tables
			data_data_a(:,[1,2,3,5,6,7]) = {false};                          % uncheck all fields
			set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_data_a); % update the table
			data_data_b(:,[1,2,3,5,6,7]) = {false};
			set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_data_b);
			data_data_c(:,[1,2,3,5,6,7]) = {false};
			set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_data_c);
			data_data_d(:,[1,2,3,5,6,7]) = {false};
			set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_data_d);
            
		case 'push_zoom_in'
			%% ZOOM = set Axis range
            % This part serves for changing the X Limits (time interval).
            % The Y limits are set automatically (by matlab). This code
            % therefore does not affect the Y limits, but creates always 
            % fixed number of (can be set by user, see 'set_y_L1' to 'set_y_R3') 
            % Y ticks. This is done to ensure the y grid is synchronized
            % for left and right axes.
            % In order to set the new zoom level (X limits), get the axes
            % handles.
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes one handle
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    % get axes two handle
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');    % get axes three handle
            num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
            
			set(findobj('Tag','plotGrav_text_status'),'String','Select two points...');drawnow % send message to status bar with instructions
			[selected_x,~] = ginput(2);                                     % get the the coordinates of two selected points. The Y coordinates are not important. Zooming only in X direction
			selected_x = sort(selected_x);                                  % sort the user input = ascending (this is required by matlab's xlim function)
            % Continue only if difference between selected points is > 0.
            % Otherwise, result in error.
			if diff(selected_x) > 0
				set(a1(1),'XLim',selected_x);                               % set xlimits for left axes (not important if visible or not)
				set(a1(2),'XLim',selected_x);                               % set xlimits for right axes 
				rL1 = get(a1(1),'YLim');                                    % get new ylimits (left)
				rR1 = get(a1(2),'YLim');                                    % get new ylimits (right)
				set(a1(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));  % set new ylimits (left)
				set(a1(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y));  % set new ylimits (right)
				% Plot2
				set(a2(1),'XLim',selected_x);                               % set xlimits for left axes (not important if visible or not)
				set(a2(2),'XLim',selected_x);                               % set xlimits for right axes 
				rL1 = get(a2(1),'YLim');                                    % get new ylimits (left)
				rR1 = get(a2(2),'YLim');                                    % get new ylimits (right)
				set(a2(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));  % set new ylimits (left)
				set(a2(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y));  % set new ylimits (right)
				% Plot3
				set(a3(1),'XLim',selected_x);                               % set xlimits for left axes (not important if visible or not)
				set(a3(2),'XLim',selected_x);                               % set xlimits for right axes 
				rL1 = get(a3(1),'YLim');                                    % get new ylimits (left)
				rR1 = get(a3(2),'YLim');                                    % get new ylimits (right)
				set(a3(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));  % set new ylimits (left)
				set(a3(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y));  % set new ylimits (right)
			end
			set(findobj('Tag','plotGrav_push_zoom_in'),'UserData',selected_x); % Store the zoom level
			set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
			plotGrav('push_date');                                          % update time ticks = always constant number of ticks at the time axis. 
        case 'push_zoom_in_set'
            % Same as previous, but user sets the range via command line.
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes one handle. Will be used to make the changes directly visible
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    % get axes two handle
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');    % get axes three handle
            num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
            % Get first (starting point) input from user
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set first date (YYYY MM DD HH MM SS)');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       % Show user input dialog. 
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',''); % by default, set to empty 
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                selected_date1 = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % read the FIRST input. Read only, will be converted to matlab datenum format later.
                % Get second (ending point) input from user
                set(findobj('Tag','plotGrav_text_status'),'String','Set second date (YYYY MM DD HH MM SS)');drawnow % send message to status bar with instructions
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',''); 
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                selected_date2 = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % read the SECOND input. Read only, will be converted to matlab datenum format later.
            else
                selected_date1 = char(varargin{1});
                selected_date2 = char(varargin{2});
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            % Try to set new range (same as for 'push_zoom_in')
            try
                selected_x(1) = datenum(selected_date1,'yyyy mm dd HH MM SS'); % convert user input to matlab format
                selected_x(2) = datenum(selected_date2,'yyyy mm dd HH MM SS');
                selected_x = sort(selected_x);                              % sort the user input = ascending (this is required by matlab's xlim function)
                % Continue only if difference between selected points is > 0.
                % Otherwise, result in error.
                if diff(selected_x) > 0
                    set(a1(1),'XLim',selected_x);                           % set xlimits for left axes (not important if visible or not)
                    set(a1(2),'XLim',selected_x);                           % set xlimits for right axes 
                    rL1 = get(a1(1),'YLim');                                % get new ylimits (left)
                    rR1 = get(a1(2),'YLim');                                % get new ylimits (right)
                    set(a1(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y)); % set new ylimits (left)
                    set(a1(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y)); % set new ylimits (right)
                    % Plot2
                    set(a2(1),'XLim',selected_x);                           % set xlimits for left axes (not important if visible or not)
                    set(a2(2),'XLim',selected_x);                           % set xlimits for right axes 
                    rL1 = get(a2(1),'YLim');                                % get new ylimits (left)
                    rR1 = get(a2(2),'YLim');                                % get new ylimits (right)
                    set(a2(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y)); % set new ylimits (left)
                    set(a2(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y)); % set new ylimits (right)
                    % Plot3
                    set(a3(1),'XLim',selected_x);                           % set xlimits for left axes (not important if visible or not)
                    set(a3(2),'XLim',selected_x);                           % set xlimits for right axes 
                    rL1 = get(a3(1),'YLim');                                % get new ylimits (left)
                    rR1 = get(a3(2),'YLim');                                % get new ylimits (right)
                    set(a3(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y)); % set new ylimits (left)
                    set(a3(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y)); % set new ylimits (right)
                end
                set(findobj('Tag','plotGrav_push_zoom_in'),'UserData',selected_x); % Store the zoom level. These values are used in plotGrav_plotData.m function
                set(findobj('Tag','plotGrav_text_status'),'String','X tick range set.');drawnow % status
                plotGrav('push_date');                                       % update time ticks = always constant number of ticks at the time axis. 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','X tick not set. Check input format (e.g., 2015 03 13 12 00 00).');drawnow % status
            end
		case 'push_zoom_y'
            % Silimar to push_zoom_in but for y axis only. This function is
            % no as useful as the zooming in X direction, because of the
            % axes handling. In this part, only current axes handle will be affectd.
            % Mostly, the right axes (R1,R2,R3) are 'current' as they are
            % superimposing the left axes.
            num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % first, get the numer of Y Ticks. See 'set_num_of_ticks_y' section
			set(findobj('Tag','plotGrav_text_status'),'String','Select two points...');drawnow % send message to status bar with instructions
			[~,selected_y] = ginput(2);                                     % get the the coordinates of two selected points. The X coordinates are not important. Zooming only in Y direction
			selected_y = sort(selected_y);                                  % sort the user input = ascending (this is required by matlab's ylim function)
            % Continue only if difference between selected points is > 0.
            % Otherwise, result in error.
            if diff(selected_y) > 0
				set(gca,'YLim',selected_y);                                 % set ylimits for current axis 
				set(gca,'YTick',linspace(selected_y(1),selected_y(2),num_of_ticks_y));               % set new ylimits (left)
            end
			set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
			plotGrav('push_date');                                          % update time ticks = always constant number of ticks at the time axis.
            
		case 'push_webcam'
			%% Select Webcam data
            % User can select an arbirary time epoch and this function will
            % look up the corresponding webcam snapshot, providing the path
            % to the snapshots is set correctly.
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data. Only to check if data already loaded! Not used or modified.
			if ~isempty(data)
				try                                                         % use try/catch: lot of snaphots are missing + take into account gross sampling
					set(findobj('Tag','plotGrav_text_status'),'String','Select a point...');drawnow % send message to status bar with instructions
					[selected_x,~] = ginput(1);                             % get one point. Only X/time cooridnate is important
					set(findobj('Tag','plotGrav_text_status'),'String','Searching image...');drawnow % send message
					[year,month,day] = datevec(selected_x);                 % convert the selected time epoch to civil time format. Snapshot file names contain information about time and date.
					ls = dir(fullfile(get(findobj('Tag','plotGrav_menu_webcam'),'UserData'),sprintf('Schedule_%04d%02d%02d*',year,month,day))); % get the list of all files in the Webcam folder taken on selected day 
					if ~isempty(ls)                                         % continue only if the webcam folder contains some Photos fulfillin the previous requirement
                        for i = 1:length(ls)                                % run a loop to filter out files/folder (especially '..' strings) not related to snapshot
							temp = ls(i).name;                              % store the current file/folder (dir output) in temporary variable.
							if length(temp)>2                               % only for files with reasonable name length
								date_webcam(i,1) = datenum(str2double(temp(10:13)),str2double(temp(14:15)),str2double(temp(16:17)),... % convert the file name to matlab time format for future searching of snapshot taken closest to the selected point.
													  str2double(temp(19:20)),str2double(temp(21:22)),str2double(temp(23:24)));
							else
								date_webcam(i,1) = -9e+10;                  % dummy
							end
                        end
                        % Find where the difference between selected point
                        % and snapshot time stamp is minimum.
						r = find(abs(selected_x - date_webcam) == min(abs(selected_x - date_webcam))); 
						if ~isempty(r)                                      % continue if such file has been found
							set(findobj('Tag','plotGrav_text_status'),'String','Loading image...');drawnow % status 
							A = imread(fullfile(get(findobj('Tag','plotGrav_menu_webcam'),'UserData'),ls(r(1)).name)); % get the image
							figure;image(A)                                 % Plot the loaded image into new window. It wouldn't look good when plotted into plotGrav plots/axes.
							title(ls(r(1)).name,'interpreter','none');      % Add a title with the file name.
							set(gca,'XTick',[],'YTick',[]);                 % remove the ticks = pixel indices.
						else
							set(findobj('Tag','plotGrav_text_status'),'String','No webcam image found.');drawnow % status 
						end
					else
						set(findobj('Tag','plotGrav_text_status'),'String','No webcam image found.');drawnow % status 
					end
				catch
					set(findobj('Tag','plotGrav_text_status'),'String','No webcam image found.');drawnow % status 
				end
				set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
			end
			
		case 'reverse_l1'
			%% Reverse Y axis
            % Reversing Y axis allows better visualisation of
            % anti-correlated time series.
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes one handle,...
			if get(findobj('Tag','plotGrav_menu_reverse_l1'),'UserData') == 1 % check current axis status (0 = Normal, 1 = reverse). Always switch to the oposit.
			   set(findobj('Tag','plotGrav_menu_reverse_l1'),'UserData',0); % update status
				set(a1(1),'YDir','reverse');                                % reverse direction
			else
			   set(findobj('Tag','plotGrav_menu_reverse_l1'),'UserData',1); % update status
				set(a1(1),'YDir','normal');                                 % set to normal
			end
		case 'reverse_r1'
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % same as for 'reverse_l1'
			if get(findobj('Tag','plotGrav_menu_reverse_r1'),'UserData') == 1
			   set(findobj('Tag','plotGrav_menu_reverse_r1'),'UserData',0);
				set(a1(2),'YDir','reverse');
			else
			   set(findobj('Tag','plotGrav_menu_reverse_r1'),'UserData',1);
				set(a1(2),'YDir','normal');
			end
		case 'reverse_l2'
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');      % same as for 'reverse_l1'
			if get(findobj('Tag','plotGrav_menu_reverse_l2'),'UserData') == 1
			   set(findobj('Tag','plotGrav_menu_reverse_l2'),'UserData',0);
				set(a2(1),'YDir','reverse');
			else
			   set(findobj('Tag','plotGrav_menu_reverse_l2'),'UserData',1);
				set(a2(1),'YDir','normal');
			end
		case 'reverse_r2'
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');      % same as for 'reverse_l1'
			if get(findobj('Tag','plotGrav_menu_reverse_r2'),'UserData') == 1
			   set(findobj('Tag','plotGrav_menu_reverse_r2'),'UserData',0);
				set(a2(2),'YDir','reverse');
			else
			   set(findobj('Tag','plotGrav_menu_reverse_r2'),'UserData',1);
				set(a2(2),'YDir','normal');
			end
		case 'reverse_l3'
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');      % same as for 'reverse_l1'
			if get(findobj('Tag','plotGrav_menu_reverse_l3'),'UserData') == 1
			   set(findobj('Tag','plotGrav_menu_reverse_l3'),'UserData',0);
				set(a3(1),'YDir','reverse');
			else
			   set(findobj('Tag','plotGrav_menu_reverse_l3'),'UserData',1);
				set(a3(1),'YDir','normal');
			end
		case 'reverse_r3'
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');      % same as for 'reverse_l1'
            if get(findobj('Tag','plotGrav_menu_reverse_r3'),'UserData') == 1
			   set(findobj('Tag','plotGrav_menu_reverse_r3'),'UserData',0);
				set(a3(2),'YDir','reverse');
			else
			   set(findobj('Tag','plotGrav_menu_reverse_r3'),'UserData',1);
				set(a3(2),'YDir','normal');
            end
            
		case 'set_y_L1'
           %% Set Y axis limits
            % Just like for X axis, user can set the plotted range.
            % However, the limits are set for each axis separaterly! The
            % code bellow repeats for each axis. See comments in the first
            % one.
			try
				a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get plot one handles (L1,R1)
                num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)');drawnow % send instructions to user
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make editable field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % if function called with two parameters, get the second one and use it as 'user input'
                end
                st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
				st = strsplit(st);                                          % split the user input (min max)
				yl(1) = str2double(st(1));                                  % convert string to double = min value (is required for 'YLim' settings)
				yl(2) = str2double(st(2));                                  % convert string to double = max value (is required for 'YLim' settings)
				set(a1(1),'YLim',yl,'YTick',linspace(yl(1),yl(2),num_of_ticks_y)); % set new limits and ticks
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Y limits set.');
			catch
				set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
			end
		case 'set_y_R1'
            try
				a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % see comments 'set_y_L1'
                num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData');
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)');drawnow % send instructions to user
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make editable field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % if function called with two parameters, get the second one and use it as 'user input'
                end                                               
				st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); 
				st = strsplit(st);                                      
				yl(1) = str2double(st(1));                              
				yl(2) = str2double(st(2));                              
				set(a1(2),'YLim',yl,'YTick',linspace(yl(1),yl(2),num_of_ticks_y)); 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Y limits set.');
			catch
				set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            end
		case 'set_y_L2'
			try
				a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');  % see comments 'set_y_L1'
                num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); 
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)');drawnow % send instructions to user
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make editable field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % if function called with two parameters, get the second one and use it as 'user input'
                end                                                   
				st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); 
				st = strsplit(st);                                      
				yl(1) = str2double(st(1));                              
				yl(2) = str2double(st(2));                              
				set(a2(1),'YLim',yl,'YTick',linspace(yl(1),yl(2),num_of_ticks_y));   
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Y limits set.');
			catch
				set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
			end
		case 'set_y_R2'
			try
				a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');  % see comments 'set_y_L1'
                num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData');
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)');drawnow % send instructions to user
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make editable field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % if function called with two parameters, get the second one and use it as 'user input'
                end                                                
				st = get(findobj('Tag','plotGrav_edit_text_input'),'String');
				st = strsplit(st);
				yl(1) = str2double(st(1));
				yl(2) = str2double(st(2));                              
				set(a2(2),'YLim',yl,'YTick',linspace(yl(1),yl(2),num_of_ticks_y)); 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Y limits set.');
			catch
				set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
			end
		case 'set_y_L3'
			try
				a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');  % see comments 'set_y_L1'
                num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); 
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)');drawnow % send instructions to user
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make editable field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % if function called with two parameters, get the second one and use it as 'user input'
                end                                                  
				st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); 
				st = strsplit(st);                                      
				yl(1) = str2double(st(1));                              
				yl(2) = str2double(st(2));                              
				set(a3(1),'YLim',yl,'YTick',linspace(yl(1),yl(2),num_of_ticks_y)); 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Y limits set.');
			catch
				set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
			end
		case 'set_y_R3'
            try
				a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');  % see comments 'set_y_L1'
                num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); 
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)');drawnow % send instructions to user
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make editable field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1})); % if function called with two parameters, get the second one and use it as 'user input'
                end                                                  
				st = get(findobj('Tag','plotGrav_edit_text_input'),'String');
				st = strsplit(st);                                      
				yl(1) = str2double(st(1));                             
				yl(2) = str2double(st(2));                              
				set(a3(2),'YLim',yl,'YTick',linspace(yl(1),yl(2),num_of_ticks_y)); 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Y limits set.');
			catch
				set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow 
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            end 
            
        case 'show_filter'
			%% Plot filter impulse
            set(findobj('Tag','plotGrav_text_status'),'String','Loading Filter...');drawnow % send message to status bar
            filter_file = get(findobj('Tag','plotGrav_edit_filter_file'),'String'); % get filter filename
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData'); % get font size. Will be used for new figure/plot with filter inpulse
            if ~isempty(filter_file)                                        % try to load the filter file/response if some string is given
                try 
                    switch filter_file(end-3:end)                           % switch between supported formats: mat = matlab output, otherwise, eterna modified format.
                        case '.mat'
                            Num = importdata(filter_file);                  % Impulse response as created using Matlab's Filter design toolbox
                        otherwise
                            Num = load(filter_file);                        % load filter file = in ETERNA format - header
                            Num = vertcat(Num(:,2),flipud(Num(1:end-1,2))); % stack the filter (ETERNA uses only one half of the repose = mirror the filter)
                    end
                    figure('Name','plotGrav: filter impulse response','Toolbar','figure'); % open new figure
                    a0_spectral = axes('FontSize',font_size);               % create new axes using default or user-set font size 
                    hold(a0_spectral,'on');                                 % all results in one window
                    grid(a0_spectral,'on');                                 % grid on always on, regardless main plotGrav setting
                    plot(a0_spectral,Num);                                  % plot the impulse response as function of indices
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % send message to status bar
                catch error_message
                    if strcmp(error_message.identifier,'MATLAB:FileIO:InvalidFid')
                         set(findobj('Tag','plotGrav_text_status'),'String','Filer file not found.');drawnow % send message to status bar
                    else
                         set(findobj('Tag','plotGrav_text_status'),'String','Could not load the filter file.');drawnow % send message to status bar
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','No filter file selected.');drawnow % status
            end
            
		case 'show_grid'
			%% Label/Legend/Grid
            % User can add or remove legends, grids and labels. In this
            % case, the legends and labels are created using loaded channel
            % names and units, i.e., user cannot modify them using this
            % section!
			temp = get(findobj('Tag','plotGrav_check_grid'),'Value');       % get grid swicth = GUI checkbox (0 = off, 1 = on)
            if temp == 1                                                    % always swithch to the opposit
				set(findobj('Tag','plotGrav_check_grid'),'Value',0);
			else
				set(findobj('Tag','plotGrav_check_grid'),'Value',1);
            end
            plotGrav('uitable_push');                                       % re-plot (otherwise would be visible after user checks one of the time series). It would be pointless/redundant to add the part of the code responsible for showing grid to this section.
		case 'show_label'                                                   % Do the same as for 'show_grid'
			temp = get(findobj('Tag','plotGrav_check_labels'),'Value');
            if temp == 1
				set(findobj('Tag','plotGrav_check_labels'),'Value',0);
			else
				set(findobj('Tag','plotGrav_check_labels'),'Value',1);
            end
            plotGrav('uitable_push');
		case 'show_legend'                                                   % Do the same as for 'show_grid'
			temp = get(findobj('Tag','plotGrav_check_legend'),'Value');
			if temp == 1
				set(findobj('Tag','plotGrav_check_legend'),'Value',0);
			else
				set(findobj('Tag','plotGrav_check_legend'),'Value',1);
			end
            plotGrav('uitable_push');
            
        case 'set_label_L1'
            %% Set labels manually
            % By default, plotGrav set the 'units' as labels for all axes
            % automatically. Nevertheless, user can set the label manually
            % using this function. The following code contains setting of
            % labels for all Y axes individually.
            a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set string with new label');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_label = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                ylabel(a1(1),user_label,'FontSize',font_size);
                set(findobj('Tag','plotGrav_text_status'),'String','L1 Y label set.');drawnow % Sent instructions to status bar
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set Y label.');drawnow % Sent instructions to status bar
            end
        case 'set_label_R1'
            a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set string with new label');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar       
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                 % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_label = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                ylabel(a1(2),user_label,'FontSize',font_size);
                set(findobj('Tag','plotGrav_text_status'),'String','R1 Y label set.');drawnow % Sent instructions to status bar
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set Y label.');drawnow % Sent instructions to status bar
            end
        case 'set_label_L2'
            a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set string with new label');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar     
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_label = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                ylabel(a2(1),user_label,'FontSize',font_size);
                set(findobj('Tag','plotGrav_text_status'),'String','L2 Y label set.');drawnow % Sent instructions to status bar
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set Y label.');drawnow % Sent instructions to status bar
            end
        case 'set_label_R2'
            a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set string with new label');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar       
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_label = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                ylabel(a2(2),user_label,'FontSize',font_size);
                set(findobj('Tag','plotGrav_text_status'),'String','R2 Y label set.');drawnow % Sent instructions to status bar
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set Y label.');drawnow % Sent instructions to status bar
            end
        case 'set_label_L3'
            a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set string with new label');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                    % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_label = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                ylabel(a3(1),user_label,'FontSize',font_size);
                set(findobj('Tag','plotGrav_text_status'),'String','L3 Y label set.');drawnow % Sent instructions to status bar
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set Y label.');drawnow % Sent instructions to status bar
            end
        case 'set_label_R3'
            a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set string with new label');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar    
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_label = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                ylabel(a3(2),user_label,'FontSize',font_size);
                set(findobj('Tag','plotGrav_text_status'),'String','R2 Y label set.');drawnow % Sent instructions to status bar
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set Y label.');drawnow % Sent instructions to status bar
            end
            
        case 'set_legend_L1'
            %% Set legend manually
            % By default, plotGrav set the 'channels' as legend for all axes
            % automatically. Nevertheless, user can set the legend manually
            % using this function. The following code contains setting of
            % legend for all axes individually.
            a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set new legend (delimiter = |)');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar     
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_legend = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            legend_save = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get existing legend (might be emtpy)
            try
                user_legend = strsplit(user_legend,'|');
                legend_save{1} = user_legend;                               % store the legend. Overwrite only L1 if existing. This legend will be used during printing as printing algorithm requires this approach.
                l = legend(a1(1),char(user_legend));
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest');           % change font and interpreter (because channels contain spacial sybols like _)
                set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save);
                set(findobj('Tag','plotGrav_text_status'),'String','L1 Legend set.');drawnow % 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set legend.');drawnow % Sent instructions to status bar
            end
        case 'set_legend_R1'
            a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set new legend (delimiter = |)');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar    
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_legend = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            legend_save = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % Existing legend (might be emtpy)
            try
                user_legend = strsplit(user_legend,'|');
                legend_save{2} = user_legend;                               % store the legend. Overwrite only R1 if existing. This legend will be used during printing as printing algorithm requires this approach.
                l = legend(a1(2),char(user_legend));
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast');           % change font and interpreter (because channels contain spacial sybols like _)
                set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save);
                set(findobj('Tag','plotGrav_text_status'),'String','R1 Legend set.');drawnow % 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set legend.');drawnow % Sent instructions to status bar
            end
        case 'set_legend_L2'
            a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set new legend (delimiter = |)');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar      
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                      % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_legend = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            legend_save = get(findobj('Tag','plotGrav_menu_print_two'),'UserData'); % Existing legend (might be emtpy)
            try
                user_legend = strsplit(user_legend,'|');
                legend_save{1} = user_legend;                               % store the legend. Overwrite only L2 if existing. This legend will be used during printing as printing algorithm requires this approach.
                l = legend(a2(1),char(user_legend));
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest');           % change font and interpreter (because channels contain spacial sybols like _)
                set(findobj('Tag','plotGrav_menu_print_two'),'UserData',legend_save);
                set(findobj('Tag','plotGrav_text_status'),'String','L2 Legend set.');drawnow % 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set legend.');drawnow % Sent instructions to status bar
            end
        case 'set_legend_R2'
            a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set new legend (delimiter = |)');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar      
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_legend = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            legend_save = get(findobj('Tag','plotGrav_menu_print_two'),'UserData'); % Existing legend (might be emtpy)
            try
                user_legend = strsplit(user_legend,'|');
                legend_save{2} = user_legend;                               % store the legend. Overwrite only R2 if existing. This legend will be used during printing as printing algorithm requires this approach.
                l = legend(a2(2),char(user_legend));
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast');           % change font and interpreter (because channels contain spacial sybols like _)
                set(findobj('Tag','plotGrav_menu_print_two'),'UserData',legend_save);
                set(findobj('Tag','plotGrav_text_status'),'String','R2 Legend set.');drawnow % 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set legend.');drawnow % Sent instructions to status bar
            end
        case 'set_legend_L3'
            a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set new legend (delimiter = |)');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar      
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_legend = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            legend_save = get(findobj('Tag','plotGrav_menu_print_three'),'UserData'); % Existing legend (might be emtpy)
            try
                user_legend = strsplit(user_legend,'|');
                legend_save{1} = user_legend;                               % store the legend. Overwrite only L3 if existing. This legend will be used during printing as printing algorithm requires this approach.
                l = legend(a3(1),char(user_legend));
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest');         % change font and interpreter (because channels contain spacial sybols like _)
                set(findobj('Tag','plotGrav_menu_print_three'),'UserData',legend_save);
                set(findobj('Tag','plotGrav_text_status'),'String','L3 Legend set.');drawnow % 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set legend.');drawnow % Sent instructions to status bar
            end
        case 'set_legend_R3'
            a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');      % first get the axis handle that corresponds to selected Y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set new legend (delimiter = |)');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar     
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end                                                     % wait 15 for user input    
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');                                            
            user_legend = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            legend_save = get(findobj('Tag','plotGrav_menu_print_three'),'UserData'); % Existing legend (might be emtpy)
            try
                user_legend = strsplit(user_legend,'|');
                legend_save{2} = user_legend;                               % store the legend. Overwrite only R3 if existing. This legend will be used during printing as printing algorithm requires this approach.
                l = legend(a3(2),char(user_legend));
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast');           % change font and interpreter (because channels contain spacial sybols like _)
                set(findobj('Tag','plotGrav_menu_print_three'),'UserData',legend_save);
                set(findobj('Tag','plotGrav_text_status'),'String','R3 Legend set.');drawnow % 
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set legend.');drawnow % Sent instructions to status bar
            end
            
        case 'set_line_width'
            %% Set line with manually
            % By default, plotGrav set the linewith to 0.5 all axes
            % automatically. Nevertheless, user can set the line width manually
            % using this function. The following code contains setting of
            % line width for all axes at onece.
            if nargin == 1
                set(findobj('Tag','plotGrav_text_status'),'String','Set L1 R1 L2 R2 L3 R3 line width');drawnow % Sent instructions to status bar
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','0.5 0.5 0.5 0.5 0.5 0.5');  % set user dialog to visible. Set String to '' (otherwise, the last used String would be shown)
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');       %
                set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar      
            else
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1}));
            end
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Make user input fields invisible
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');   
            user_line = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get the user input
            try
                user_line = strsplit(user_line,' ');                        % Split the input = for each axes 
                if length(user_line) == 6                                   % continue only if user sets line width for all axes (regardless number of plotted ones)
                    for i = 1:length(user_line)
                        line_save(i) = str2double(user_line(i));
                    end
                    set(findobj('Tag','plotGrav_menu_line_width'),'UserData',line_save); % store new line widths
                    plotGrav('uitable_push');                               % re-plot to make changes visible
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Six values must be set.');drawnow % 
                end
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not set line width.');drawnow % Set status
            end
            
		case 'show_earthquake'
            %% EARTHQUAKES
            % This part allows user to visualize the last 20 earthquakes
            % taking into account theri magnitude. The data are acquired
            % from GFZ Geofon database. This database contains a xml data
            % that is used to read the date, location and magnitude.
            % Plotted lines will disappear after re-plotting selected time
            % series.
            % Open a web-browser with Geofon data
			url = get(findobj('Tag','plotGrav_menu_show_earthquake'),'UserData'); % get the Geofon URL
			web(url);                                                       % open external or matlab browser
		case 'plot_earthquake'
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData')-1; % get font size. Will be used for text 'location and magnitude'
            try
                % User can sat the minimum magnitude of plotted
                % earthquaked. By default this value is set to 6.
                % First, get the GEOFON Data
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set minimum magnitude');drawnow % send instructions to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',6); % Make user input fields visible + set default value
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',char(varargin{1})); 
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn of user input fields
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                % Create a URL adress to GEOFON xml data taking into
                % account user input (magnitued) and default GEOFON  
                % web address (url)
                temp = [get(findobj('Tag','plotGrav_menu_plot_earthquake'),'UserData'),get(findobj('Tag','plotGrav_edit_text_input'),'String'),'&fmt=rss'];
                xDoc = xmlread(temp);                                       % open xml/RSS document (build in matlab function)
                allListitems = xDoc.getElementsByTagName('item');           % look up all items
                quake_name = {};                                            % prepare variable (must be cell)
                for k = 0:allListitems.getLength-1                          % loop for all found items
                   thisListitem = allListitems.item(k);                     % get current item
                   thisList = thisListitem.getElementsByTagName('title');   % search by 'title'
                   thisElement = thisList.item(0);                          % Assign current element                                      
                   quake_name{k+1,1} = {char(thisElement.getFirstChild.getData)}; % store title
                   if ~isempty(thisElement)                                 % continue if some 'title' exists
                       thisList = thisListitem.getElementsByTagName('description'); % search by 'description'
                       thisElement = thisList.item(0);                                      
                       temp = char(thisElement.getFirstChild.getData);      % get description
                       quake_time(k+1,1) = datenum(temp(1:20));             % store time (fixed format = 1:20)
                   end
                end
            catch
                set(findobj('Tag','plotGrav_text_status'),'String','Could not retrieve Earthquake data.');drawnow % status
                quake_time = [];
            end
            if ~isempty(quake_time)                                         % Continue only if xml data reading was successful
                try
                    % After reading GEOFON data, plot the data
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get first axes handles (Vertical lines showing earthquakes will be plotted to all axes)
                    a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    % get second axes handles
                    a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');    % get third axes handles

                    y = get(a1(1),'YLim');                                  % used Y range of L1 for plotting (do not plot outside the current view)
                    x = get(a1(1),'XLim');                                  % use to check if loaded earthquakes occurred within plotted window
                    set(gcf,'CurrentAxes',a1(1));                           % Set L1 axes as current ('text' does not support axes handle passing)
                    for i = 1:length(quake_time)                            % Run for all quakes
                        if quake_time(i) > x(1) && quake_time(i) < x(2)     % Plot only if within plotted time interval
                            plot([quake_time(i),quake_time(i)],y,'k--');    % Add vertical line
                            text(quake_time(i),y(1)+range(y)*0.05,quake_name{i},'Rotation',90,'FontSize',font_size-1,'VerticalAlignment','bottom') % +comment
                        end
                    end
                    set(gcf,'CurrentAxes',a1(2));                           % Set R1 back (otherwise invisible)
                    % Do the same for L2 axes
                    y = get(a2(1),'YLim');
                    x = get(a2(1),'XLim');
                    set(gcf,'CurrentAxes',a2(1));
                    for i = 1:length(quake_time)
                        if quake_time(i) > x(1) && quake_time(i) < x(2)
                            plot([quake_time(i),quake_time(i)],y,'k--');
                        end
                    end
                    set(gcf,'CurrentAxes',a2(2));                            % Set R2 back (otherwise invisible)
                    % Do the same for L3 axes
                    y = get(a3(1),'YLim');
                    x = get(a3(1),'XLim');
                    set(gcf,'CurrentAxes',a3(1));
                    for i = 1:length(quake_time)
                        if quake_time(i) > x(1) && quake_time(i) < x(2)
                            plot([quake_time(i),quake_time(i)],y,'k--');
                        end
                    end
                    set(gcf,'CurrentAxes',a3(2));                                            % Set R3 back (otherwise invisible)
                    set(findobj('Tag','plotGrav_text_status'),'String','Earthquakes (last 20) have been plotted.');drawnow % status
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Earthquakes retrieved, but NOT plotted.');drawnow % status
                end
            end
			
        case 'set_manual_drift'
            %% Set manual drift
            % Turn visibility on/off ONLY. No further function. Not related
            % to fitting functions.
            switch_drift = get(findobj('Tag','plotGrav_pupup_drift'),'Value');
            if switch_drift == 6
                set(findobj('Tag','plotGrav_edit_drift_manual'),'Visible','on');
            else
                set(findobj('Tag','plotGrav_edit_drift_manual'),'Visible','off');
            end
            
%%%%%%%%%%%%%%%%%%%%%%%%% E X P O R T I N G %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        %% EXPORT DATA   
        % Export allows user to save the data stored in iGrav, TRiLOGi,
        % Other1 and Other2 to tsf and mat file format. It works like 'save
        % as' function.
		case 'export_data_a_all'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data (this variable store iGrav together with other time series)
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time (includes iGrav time vector)
			units = get(findobj('Tag','plotGrav_text_data_a'),'UserData');   % get iGrav units. Will be included in the output.
			channels = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData'); % get iGrav channels (names)
            if nargin == 1
                plotGrav_exportData(time.data_a,data.data_a,channels,units,[],[],'iGrav',[]); % call general function for data export
            else
                plotGrav_exportData(time.data_a,data.data_a,channels,units,[],[],'iGrav',char(varargin{1})); % call general function for data export with output file name
            end
		case 'export_data_a_sel'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_a'),'UserData');   % get iGrav units
			channels = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData'); % get iGrav channels (names)
			data_data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav table
			select = find(cell2mat(data_data_a(:,1))==1);                    % get selected iGrav channels for L1
            if isempty(select)
                set(findobj('Tag','plotGrav_text_status'),'String','You must select at least one L1 channel.');drawnow % send to status bar
            else
                if nargin == 1
                    plotGrav_exportData(time.data_a,data.data_a,channels,units,select,[],'iGrav',[]);
                else
                    plotGrav_exportData(time.data_a,data.data_a,channels,units,select,[],'iGrav',char(varargin{1})); % call general function for data export with output file name
                end
            end
		case 'export_data_b_all'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_b'),'UserData'); % get data_b units
			channels = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get data_b channels (names)
            if nargin == 1
                plotGrav_exportData(time.data_b,data.data_b,channels,units,[],[],'TRiLOGi',[]);
            else
                plotGrav_exportData(time.data_b,data.data_b,channels,units,[],[],'TRiLOGi',char(varargin{1}));
            end
		case 'export_data_b_sel'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_b'),'UserData'); % get data_b units
			channels = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get data_b channels (names)
			data_data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the data_b table
			select = find(cell2mat(data_data_b(:,1))==1);                  % get selected data_b channels for L1            
            if isempty(select)
                set(findobj('Tag','plotGrav_text_status'),'String','You must select at least one L1 channel.');drawnow % send to status bar
            else
                if nargin == 1
                    plotGrav_exportData(time.data_b,data.data_b,channels,units,select,[],'TRiLOGi',[]);
                else
                    plotGrav_exportData(time.data_b,data.data_b,channels,units,select,[],'TRiLOGi',char(varargin{1}));
                end
            end
		case 'export_data_c_all'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_c'),'UserData');  % get data_c units
			channels = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData'); % get data_c channels (names)
            if nargin == 1
                plotGrav_exportData(time.data_c,data.data_c,channels,units,[],[],'Other1',[]);
            else
                plotGrav_exportData(time.data_c,data.data_c,channels,units,[],[],'Other1',char(varargin{1}));
            end
		case 'export_data_c_sel'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_c'),'UserData');  % get data_c units
			channels = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData'); % get data_c channels (names)
			data_data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the data_c table
			select = find(cell2mat(data_data_c(:,1))==1);                   % get selected data_c channels for L1
            if isempty(select)
                set(findobj('Tag','plotGrav_text_status'),'String','You must select at least one L1 channel.');drawnow % send to status bar
            else
                if nargin == 1
                    plotGrav_exportData(time.data_c,data.data_c,channels,units,select,[],'Other1',[]);
                else
                    plotGrav_exportData(time.data_c,data.data_c,channels,units,select,[],'Other1',char(varargin{1}));
                end
            end
		case 'export_data_d_all'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_d'),'UserData');  % get data_d units
			channels = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData'); % get data_d channels (names)
            if nargin == 1
                plotGrav_exportData(time.data_d,data.data_d,channels,units,[],[],'Other2',[]);
            else
                plotGrav_exportData(time.data_d,data.data_d,channels,units,[],[],'Other2',char(varargin{1}));
            end
		case 'export_data_d_sel'
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % get all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % get time
			units = get(findobj('Tag','plotGrav_text_data_d'),'UserData');  % get data_d units
			channels = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData'); % get data_d channels (names)
			data_data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the data_d table
			select = find(cell2mat(data_data_d(:,1))==1);                   % get selected data_d channels for L1
            if isempty(select)
                set(findobj('Tag','plotGrav_text_status'),'String','You must select at least one L1 channel.');drawnow % send to status bar
            else
                if nargin == 1
                    plotGrav_exportData(time.data_d,data.data_d,channels,units,select,[],'Other2',[]);
                else
                    plotGrav_exportData(time.data_d,data.data_d,channels,units,select,[],'Other2',char(varargin{1}));
                end
            end
            
        case 'print_all'
            %% PRINTING
            % User can print the plotted time series to jpg, eps or no
            % compression tiff files. Such print-out can contain one, two or
            % all three plots. In addition, user can export the currently
            % plotted figure to a new editable one ('print_three')
			plotGrav_printData(3,[],[],[]);                                    % 3 = all plots,see plotGrav_printData function input requirements
		case 'print_one'
			plotGrav_printData(1,[],[],[]);                                    % 1 = first plot only,see plotGrav_printData function input requirements
		case 'print_two'
			plotGrav_printData(2,[],[],[]);                                    % 2 = first and second plot,see plotGrav_printData function input requirements
		case 'print_three'
			plotGrav_printData(4,[],[],[]);                                    % 4 = export plot to a new, editable figure
            
%%%%%%%%%%%%%%%%%%%%%%%%% C O M P U T I N G %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        case 'select_point'
			%% Select point
            % This part allows user to select a point and writes the
            % numeric values to status bar and logfile.
			set(findobj('Tag','plotGrav_text_status'),'String','Select a point...');drawnow % send message to status bar with instructions
			[selected_x,selected_y] = ginput(1);                            % get one point (both x and y values)
			selected_x = datevec(selected_x);                               % convert to calendar date+time
			set(findobj('Tag','plotGrav_text_status'),'String',...          % write message to status line
				sprintf('Point selected: %04d/%02d/%02d %02d:%02d:%02d = %7.3f',...
				selected_x(1),selected_x(2),selected_x(3),selected_x(4),selected_x(5),round(selected_x(6)),selected_y));drawnow % status
			try                                                             % try if some logfile is selected/exists
				fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Always append ('a') the new comments!
            catch                                                           % If not, create a new one.
				fid = fopen('plotGrav_LOG_FILE.log','a');                           
			end
			[ty,tm,td,th,tmm] = datevec(now);                               % get current time for the logfile
			fprintf(fid,'Point selected: %04d/%02d/%02d %02d:%02d:%02d = %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
				selected_x(1),selected_x(2),selected_x(3),selected_x(4),selected_x(5),round(selected_x(6)),selected_y,ty,tm,td,th,tmm);
			fclose(fid);                                                    % close the logfile
            
		case 'compute_difference'
			%% Comute difference
            % Similar to 'select_point' but with computation of the
            % difference between the selected points.
			set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % send message to status bar with instructions
			[selected_x(1),selected_y(1)] = ginput(1);                      % get first point
			set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % send message to status bar with instructions
			[selected_x(2),selected_y(2)] = ginput(1);                      % get second point
			set(findobj('Tag','plotGrav_text_status'),'String',...          % write message to status line
				sprintf('X diff (1-2): %8.4f hours,   Y diff (1-2):  %8.4f',...
				(selected_x(1)-selected_x(2))*24,selected_y(1)-selected_y(2)));drawnow % status
			try                                                             % try if some logfile is selected/exists
				fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Always append ('a') the new comments!
			catch                                                           % If not, create a new one.
				fid = fopen('plotGrav_LOG_FILE.log','a');
			end
			[ty,tm,td,th,tmm] = datevec(now);                               % get current time for the logfile
			[ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x(1));            % convert to calendar date+time        
			[ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x(2));            % convert to calendar date+time
			fprintf(fid,'Difference computed (1-2): dX = %8.4f hours, dY = %8.4f. First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
				(selected_x(1)-selected_x(2))*24,selected_y(1)-selected_y(2),ty1,tm1,td1,th1,tmm1,ts1,selected_y(1),...
				ty2,tm2,td2,th2,tmm2,ts2,selected_y(2),ty,tm,td,th,tmm);
			fclose(fid);                                                    % close the logfile
        case 'compute_derivative'
            %% Compute derivative/difference
            % Compute difference between adjacent points
            % This function computes the difference between all points of
            % selected channel, whereas 'compute_differnce' returns the
            % difference between selected points (by user). This will be
            % computed regardless the sampling! This function does not
            % check for constant sampling!!
            
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time series. Time vector will be not be used.
            	
            if ~isempty(data)                                               % continue only if some data have been loaded
                % Logfile
                try                                                             % try if some logfile is selected/exists
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Always append ('a') the new comments!
                catch                                                           % If not, create a new one.
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
				set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
                % Get channel units. Will be used for output
                units.data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');         % get iGrav units
                units.data_b = get(findobj('Tag','plotGrav_text_data_b'),'UserData');         
                units.data_c = get(findobj('Tag','plotGrav_text_data_c'),'UserData');         
                units.data_d = get(findobj('Tag','plotGrav_text_data_d'),'UserData');  
                % Get channel names. Will be used for output. 'diff' will
                % be appended to the end.
				channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names).
				channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');   % get Other1 channels (names)
				channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');   % get Other2 channels (names)
                % Get UI tables (selected channels)
                data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');      % get the TRiLOGi table. 
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');      % get the TRiLOGi table. 
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');        % get the Other1 table
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');        % get the Other2 table
                try
                    % Find selected channles
                    % Set panel 'official' names. To reduce the code length, use a for loop for
                    % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
                    % filling the structure arrays.
                    panels = {'data_a','data_b','data_c','data_d'};  
                    % Run loop for all panels
                    for i = 1:length(panels)
                        plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                        run_index = length(units.(char(panels(i))))+1;          % get number of channels in panel. Compute this prior to appending new channels to i-th panel
                        if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i)))) % check if at least one channel selected
                            for j = 1:length(plot_axesL1.(char(panels(i)))) % compute for all selected channels
                                data.(char(panels(i)))(:,run_index) = vertcat(NaN,diff(data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))(j)))); % compute difference for current channel. Always add NaN to the beginning so the vector does not change in length (data(1)-data(0) => NaN)
%                                 data_table.(char(panels(i)))(run_index,1:7) = {};
%                                 channels.(char(panels(i)))(run_index) = {channels.(char*
                                units.(char(panels(i)))(run_index) = {char(units.(char(panels(i)))(plot_axesL1.(char(panels(i)))(j)))}; % add diff units. The same as input.
                                channels.(char(panels(i)))(run_index) = {[char(channels.(char(panels(i)))(plot_axesL1.(char(panels(i)))(j))),'_diff']}; % add diff name. The same as input + diff.
                                data_table.(char(panels(i)))(run_index,1:7) = {false,false,false,...        % add diff to ui-table
                                                    sprintf('[%2d] %s (%s)',run_index,char(channels.(char(panels(i)))(run_index)),char(units.(char(panels(i)))(run_index))),...
                                                        false,false,false};
                                ttime = datevec(now);
                                fprintf(fid,'%s channel %2d derivative/difference computed -> %2d (%04d/%02d/%02d %02d:%02d)\n',...
                                    char(panels(i)),plot_axesL1.(char(panels(i)))(j),run_index,...
                                    ttime(1),ttime(2),ttime(3),ttime(4),ttime(5));
                                run_index = run_index + 1;
                            end
                        end
                    end
                    % Store the results
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a);
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a);
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a);
                    set(findobj('Tag','plotGrav_text_data_b'),'UserData',units.data_b);
                    set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels.data_b);
                    set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.data_b);
                    set(findobj('Tag','plotGrav_text_data_c'),'UserData',units.data_c);
                    set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels.data_c);
                    set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.data_c);
                    set(findobj('Tag','plotGrav_text_data_d'),'UserData',units.data_d);
                    set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels.data_d);
                    set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.data_d);

                    set(findobj('Tag','plotGrav_text_status'),'String','Derivative/difference computed.');drawnow % status
                    fclose(fid);
                catch error_message
                    ttime = datevec(now);
                                fprintf(fid,'An error occurred during Derivative/diff computation: %s (%04d/%02d/%02d %02d:%02d)\n',...
                                    char(error_message.message),...
                                    ttime(1),ttime(2),ttime(3),ttime(4),ttime(5));
                    set(findobj('Tag','plotGrav_text_status'),'String','An error occurred.');drawnow % status
                    fclose(fid);
                end
            else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
        case 'compute_cumsum'
            %% Compute cumulative sum
            % Compute cumulative sum of selected channel. This is an
            % extenstion function to 'compute_derivative'. This will be 
            % computed regardless the sampling! This function does not
            % check for constant sampling!!
            
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time series. Time vector will be not be used.
            	
            if ~isempty(data)                                               % continue only if some data have been loaded
                % Logfile
                try                                                             % try if some logfile is selected/exists
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Always append ('a') the new comments!
                catch                                                           % If not, create a new one.
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
				set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
                % Get channel units. Will be used for output
                units.data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');         % get iGrav units
                units.data_b = get(findobj('Tag','plotGrav_text_data_b'),'UserData');         
                units.data_c = get(findobj('Tag','plotGrav_text_data_c'),'UserData');         
                units.data_d = get(findobj('Tag','plotGrav_text_data_d'),'UserData');  
                % Get channel names. Will be used for output. 'diff' will
                % be appended to the end.
				channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names).
				channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');   % get Other1 channels (names)
				channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');   % get Other2 channels (names)
                % Get UI tables (selected channels)
                data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');      % get the TRiLOGi table. 
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');      % get the TRiLOGi table. 
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');        % get the Other1 table
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');        % get the Other2 table
                try
                    % Find selected channles
                    % Set panel 'official' names. To reduce the code length, use a for loop for
                    % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
                    % filling the structure arrays.
                    panels = {'data_a','data_b','data_c','data_d'};  
                    % Run loop for all panels
                    for i = 1:length(panels)
                        plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                        run_index = length(units.(char(panels(i))))+1;          % get number of channels in panel. Compute this prior to appending new channels to i-th panel
                        if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i)))) % check if at least one channel selected
                            for j = 1:length(plot_axesL1.(char(panels(i)))) % compute for all selected channels
                                % By default first value of derivative
                                % function is an NaN. Avoid summing NaNs by
                                % checking the first element only.
                                if isnan(data.(char(panels(i)))(1,plot_axesL1.(char(panels(i)))(j)))
                                    data.(char(panels(i)))(:,run_index) = vertcat(NaN,cumsum(data.(char(panels(i)))(2:end,plot_axesL1.(char(panels(i)))(j)))); % compute cumulative sum for current channel.
                                else
                                    data.(char(panels(i)))(:,run_index) = vertcat(NaN,cumsum(data.(char(panels(i)))(2:end,plot_axesL1.(char(panels(i)))(j))));
                                end
                                units.(char(panels(i)))(run_index) = {char(units.(char(panels(i)))(plot_axesL1.(char(panels(i)))(j)))}; % add diff units. The same as input.
                                channels.(char(panels(i)))(run_index) = {[char(channels.(char(panels(i)))(plot_axesL1.(char(panels(i)))(j))),'_sum']}; % add diff name. The same as input + diff.
                                data_table.(char(panels(i)))(run_index,1:7) = {false,false,false,...        % add diff to ui-table
                                                    sprintf('[%2d] %s (%s)',run_index,char(channels.(char(panels(i)))(run_index)),char(units.(char(panels(i)))(run_index))),...
                                                        false,false,false};
                                ttime = datevec(now);
                                fprintf(fid,'%s channel %2d cumulative sum computed -> %2d (%04d/%02d/%02d %02d:%02d)\n',...
                                    char(panels(i)),plot_axesL1.(char(panels(i)))(j),run_index,...
                                    ttime(1),ttime(2),ttime(3),ttime(4),ttime(5));
                                run_index = run_index + 1;
                            end
                        end
                    end
                    % Store the results
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a);
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a);
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a);
                    set(findobj('Tag','plotGrav_text_data_b'),'UserData',units.data_b);
                    set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels.data_b);
                    set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.data_b);
                    set(findobj('Tag','plotGrav_text_data_c'),'UserData',units.data_c);
                    set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels.data_c);
                    set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.data_c);
                    set(findobj('Tag','plotGrav_text_data_d'),'UserData',units.data_d);
                    set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels.data_d);
                    set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.data_d);

                    set(findobj('Tag','plotGrav_text_status'),'String','Cumulative sum computed.');drawnow % status
                    fclose(fid);
                catch error_message
                    ttime = datevec(now);
                                fprintf(fid,'An error occurred during Cumulative sum computation: %s (%04d/%02d/%02d %02d:%02d)\n',...
                                    char(error_message.message),...
                                    ttime(1),ttime(2),ttime(3),ttime(4),ttime(5));
                    set(findobj('Tag','plotGrav_text_status'),'String','An error occurred.');drawnow % status
                    fclose(fid);
                end
            else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
		case 'compute_statistics'
			%% COMPUTE histogram
            % User can compute basic statistics such as mean, standard
            % deviation, min and max values via this function. Only
            % statistics of selected time series are computer (iGrav,
            % TRiLOGi, Other1 and/or Other2)
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data (all time series). No time vector is required for further computation
            if ~isempty(data)                                               % Check if some data have been loaded.
				set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
				data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table. Will be used to find selected/checked channels
				units.data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData'); % get iGrav units. Will be used for output/plot
				channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData'); % get iGrav channels (names). Will be used for output/plot
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi table
				units.data_b = get(findobj('Tag','plotGrav_text_data_b'),'UserData'); % get TRiLOGi units
				channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 table
				units.data_c = get(findobj('Tag','plotGrav_text_data_c'),'UserData'); % get Other1 units
				channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData'); % get Other1 channels
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 table
				units.data_d = get(findobj('Tag','plotGrav_text_data_d'),'UserData'); % get Other2 units
				channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData'); % get Other2 channels
				
                % try if some logfile is selected/exists
                try                                                         
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Always append ('a') the new comments!
                catch                                                       % If not, create a new one.
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                
                % Set panel names (fixed). Will be used for loop to reduce
                % the code length
                panels = {'data_a','data_b','data_c','data_d'};  
                for p = 1:length(panels)
                    plot_axesL1.(panels{p}) = find(cell2mat(data_table.(panels{p})(:,1))==1);     % find selected/checked channels for L1. Only L1 selection is important. The 'find' operation does not work with cell area => covert to matrix
                    % First check if at least one channel is selected/checked
                    if ~isempty(plot_axesL1.(panels{p}))                              
                        for i = 1:length(plot_axesL1.(panels{p}))           % compute for all (even one) selected channels
                            temp = data.(panels{p})(:,plot_axesL1.(panels{p})(i)); % create temporary variable with current (selected) data column/time series
                            temp(isnan(temp)) = [];                         % Remove NaNs. Functions such as 'mean' and 'std' would otherwise return NaN.
                            figure('Name','plotGrav: basic statistics','Toolbar','figure'); % open new figure for histograp plot
                            histfit(temp)                                   % histogram + fitted normal ditribution
                            title(sprintf('%s hitogram+fitted norm. distibution: %s',panels{i},char(channels.(panels{p})(plot_axesL1.(panels{p})(i)))),...
                                  'interpreter','none');                    % plot title with channel name
                            xlabel(char(units.(panels{p})(plot_axesL1.(panels{p})(i))));    % x label = untis (standard for histograms)
                            ylabel('frequency')
                            x = get(gca,'XLim');y = get(gca,'YLim');            % get x and y limits (to place text related to estimated values, see below)
                            text(x(2)*0.6,y(2)*0.9,sprintf('Mean = %7.3f',mean(temp))); % add text to current axis with mean value
                            text(x(2)*0.6,y(2)*0.8,sprintf('SD = %7.3f',std(temp))); % standard deviation
                            text(x(2)*0.6,y(2)*0.7,sprintf('Min = %7.3f',min(temp))); % min
                            text(x(2)*0.6,y(2)*0.6,sprintf('Max = %7.3f',max(temp))); % max
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s channel %2d: mean = %8.4f, SD = %8.4f, min = %8.4f, max = %8.4f, units = %s (%04d/%02d/%02d %02d:%02d)\n',...
                                                                    panels{i},plot_axesL1.(panels{p})(i),mean(temp),std(temp),min(temp),max(temp),char(units.(panels{p})(plot_axesL1.(panels{p})(i))),ty,tm,td,th,tmm); % write estimated values to logfile                                                        ty2,tm2,td2,th2,tmm2,ts2,selected_y(2),ty,tm,td,th,tmm);
                            clear temp                                          % remove used variable
                        end
                    end
                end
				set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
            
		case 'compute_spectral_valid'
			%% Compute spectral analysis using hann window
            % User can perform simple spectral analysis using fourier
            % transformation combined with an hanning window. The
            % transformation can be computed either for either longest
            % valid time interval or for whole time series regardless of
            % missing data (NaNs). Valid time series means no NaNs and
            % constant sampling is used (necesary for FFT). If whole time
            % series is selected, a linear interpolation is used to fill
            % the missing data. 
            % Works for all panels and L1 selected time series
            
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time series. Time vector will be loaded later.
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData'); % get font size. Will be used for output plots.
			if ~isempty(data)
				set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time vector. Will be used to derive sampling frequency
				data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');    % get the iGrav table. Will be used to find selected/checked time series
				channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names). Will be used for output plots. No units required.
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');% get the TRiLOGi table. 
				channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');  % get the Other1 table
				channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');   % get Other1 channels (names)
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');  % get the Other2 table
				channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');   % get Other2 channels (names)
				color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');              % get defined colors (used for output plot)

                % Set panel names (fixed). Will be used for loop to reduce
                % the code length
                panels = {'data_a','data_b','data_c','data_d'};  
                % open new figure for plotting. Otherwise, the result would be plotted in main plotGrav GUI figure.
                figure('Name','plotGrav: spectral analysis','Toolbar','figure'); 
                a0_spectral = axes('FontSize',font_size);                   % create new axes using defined font size
                hold(a0_spectral,'on');                                     % all results in one window
                grid(a0_spectral,'on');                                     % grid on
                color_num = 1;legend_spectral = [];                         % define temporary variables
                    
                for p = 1:length(panels)
                    plot_axesL1.(panels{p}) = find(cell2mat(data_table.(panels{p})(:,1))==1);     % find selected/checked channels in L1. Only selected time series will be used.
                    % Compute only if at least one channel selected.
                    if ~isempty(plot_axesL1.(panels{p})) 
                        % Compute for all selected channels
                        for i = 1:length(plot_axesL1.(panels{p}))           
                            time_resolution = mode(diff(time.(panels{p}))); % determine the time resolution (sampling period, not frequency)
                            [~,dataout,id] = plotGrav_findTimeStep(time.(panels{p}),data.(panels{p})(:,plot_axesL1.(panels{p})(i)),time_resolution); % find time steps. FFT only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            r = find((id(:,2)-id(:,1)) == max(id(:,2)-id(:,1))); % find the longest time interval without interruption
                            [~,~,~,~,h] = plotGrav_spectralAnalysis(dataout(id(r,1):id(r,2)),... % compute spectral analysis for the longest time interval. Use only the line handles ('h'). 
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % Using 'a0_spectral' handle, the result will be plotted automatically! No 'plot' function used here.
                            set(h,'color',color_scale(color_num,:));            % set line color using 'h' handles
                            color_num = color_num + 1;                          % increase color index = to used next color for next channel.
                            legend_spectral = [legend_spectral,channels.(panels{p})(plot_axesL1.(panels{p})(i))]; % stack legends for all selected channels and panels. Legend will be plotted at the end of this section.
                        end
                        clear time_resolution f amp pha y h r timeout dataout id i
                    end
                end
				% plot the stacked legend (contains all selected channels)
				l = legend(a0_spectral,legend_spectral);                    
				set(l,'FontSize',font_size,'interpreter','none');           % set legend properties: font size and interpreter to none. Reason for that is the fact that the channel names often contain underscore '_' which would be otehrwise interpreted us lower index
				
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
			end
		case 'compute_spectral_interp'
			%% Compute spectral analysis using hann window + interpolation
            % This code similar to 'compute_spectral_valid'. The only
            % difference is, that an interpolation is used to remove
            % missing(NaN) values in order to compute the fourier
            % transformation for the whole time series.
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time series. Time vector will be loaded later.
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData'); % get font size. Will be used for output plots.
            if ~isempty(data)                                               % continue only if some data have been loaded
				set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time: will be used to determine the sampling frequency and for interpolation
                data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');    % get the iGrav table. Will be used to find selected/checked time series
				channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names). Will be used for output plots. No units required.
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');% get the TRiLOGi table. 
				channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');  % get the Other1 table
				channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');   % get Other1 channels (names)
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');  % get the Other2 table
				channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');   % get Other2 channels (names)
				color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');              % get defined colors (used for output plot)

				% Set panel names (fixed). Will be used for loop to reduce
                % the code length
                panels = {'data_a','data_b','data_c','data_d'};  
                % open new figure for plotting. Otherwise, the result would be plotted in main plotGrav GUI figure.
                figure('Name','plotGrav: spectral analysis','Toolbar','figure'); 
                a0_spectral = axes('FontSize',font_size);                   % create new axes using defined font size
                hold(a0_spectral,'on');                                     % all results in one window
                grid(a0_spectral,'on');                                     % grid on
                color_num = 1;legend_spectral = [];                         % define temporary variables
                    
                for p = 1:length(panels)
                    plot_axesL1.(panels{p}) = find(cell2mat(data_table.(panels{p})(:,1))==1);     % find selected/checked channels in L1. Only selected time series will be used.
                    % Compute only if at least one channel selected.
                    if ~isempty(plot_axesL1.(panels{p}))          
                        % Compute for all selected channels
                        for i = 1:length(plot_axesL1.(panels{p}))           
                            time_resolution = mode(diff(time.(panels{p}))); % time resolution (sampling period)
                            time_in = time.(panels{p});                     % copy the whole time vector to temporary variable. Will be used for interpolation after removing NaNs
                            data_in = data.(panels{p})(:,plot_axesL1.(panels{p})(i)); % copy selected time series to temporary variable.
                            time_in(isnan(data_in)) = [];                   % remove NaNs from both, time vector and data. This ensures time and data have same dimensions and therefore can be used as input for 'interp1' function.
                            data_in(isnan(data_in)) = [];                       
                            timeout = time_in(1):time_resolution:time_in(end); % new output time vecor with constant sampling
                            dataout = interp1(time_in,data_in,timeout);     % interpolate to new time vector 
                            [~,~,~,~,h] = plotGrav_spectralAnalysis(dataout',... % compute spectral analysis for the new data vector (after removing NaN and interpolation). Use only the line handles ('h'). 
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % Using 'a0_spectral' handle, the result will be plotted automatically! No 'plot' function used here.
                            set(h,'color',color_scale(color_num,:));        % set line color of the plotted line
                            color_num = color_num + 1;                      % increase color index to ensure next line has different color.
                            legend_spectral = [legend_spectral,channels.(panels{p})(plot_axesL1.(panels{p})(i))]; % stack legend for all plotted time series. Legend will be, however, plotted at the end of this section
                            clear data_in time_in timeout_timeresolution
                        end
                    end
                    clear f amp pha y h r timeout dataout id i                  % Remove temporary variables. Same variable names will be used for remaining panels 
                end
				% plot the stacked legend (contains all selected channels)
				l = legend(a0_spectral,legend_spectral);                    
				set(l,'FontSize',font_size,'interpreter','none');           % set legend properties: font size and interpreter to none. Reason for that is the fact that the channel names often contain underscore '_' which would be otehrwise interpreted us lower index
				
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
            
        case 'compute_spectral_evolution'
			%% Compute spectral analysis of moving window
            % This code similar to 'compute_spectral_valid'. The only
            % difference is, that an analysis is performed only for one
            % channel and a moving window. The window length is set by
            % user.
            
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time series. Time vector will be loaded later.
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData'); % get font size. Will be used for output plots.
            date_format = get(findobj('Tag','plotGrav_menu_date_format'),'UserData'); % get date format switch. See numeric identificator: http://de.mathworks.com/help/matlab/ref/datetick.html#inputarg_dateFormat
            a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get axes of the First plot (left and right axes = L1 and R1)
				
            if ~isempty(data)                                               % continue only if some data have been loaded
				set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time: will be used to determine the sampling frequency and for interpolation
                data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');      % get the TRiLOGi table. 
				channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names). Will be used for output plots. No units required.
				data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');      % get the TRiLOGi table. 
				channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');        % get the Other1 table
				channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');   % get Other1 channels (names)
				data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');        % get the Other2 table
				channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');   % get Other2 channels (names)
                try
                    % Find selected channles
                    % Set panel 'official' names. To reduce the code length, use a for loop for
                    % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
                    % filling the structure arrays.
                    panels = {'data_a','data_b','data_c','data_d'};  
                    % First find all selected channels
                    for i = 1:length(panels)
                        plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                    end
                    if length([plot_axesL1.data_a,plot_axesL1.data_b,plot_axesL1.data_c,plot_axesL1.data_d]) == 1
                        % Get user input
                        if nargin == 1 
                            set(findobj('Tag','plotGrav_text_status'),'String','Set moving window length in hours');drawnow % send instructions to command promtp
                            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','96');  % make input text visible
                            set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                        else
                            set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                        end
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                        set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                        win_length = str2double(st)/24;                             % convert to double and time in days.
                        set(findobj('Tag','plotGrav_text_status'),'String','Starting computation...');drawnow % status
                        
                        for i = 1:length(panels)
                        % Check if only one channel selected (function does not work if more than one channel selected for fitting)
                            % Then continue with a loop searching the selected
                            % channel in all panels.
                            if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i))))
                                time_in = time.(char(panels(i)));                   % copy the whole time vector to temporary variable. Will be used for interpolation after removing NaNs
                                data_in = data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))); % copy selected time series to temporary variable.
                                % 
                                time_resolution = mode(diff(time.(char(panels(i))))); % time resolution of input time series(sampling period)
                                t_index = round(win_length/time_resolution);        % number of points (indices) within on window length
%                                 time_in(isnan(data_in)) = [];                       % remove NaNs from both, time vector and data. This ensures time and data have same dimensions and therefore can be used as input for 'interp1' function.
%                                 data_in(isnan(data_in)) = [];                       
                                timeout = time_in(1):time_resolution:time_in(end);  % new output time vecor with constant sampling
                                dataout = interp1(time_in,data_in,timeout);         % interpolate to new time vector 
                                % Create new figure for the plot
                                figure('Name','plotGrav: Spectrogram','Toolbar','figure',... % open new figure for plotting. Otherwise, the result would be plotted in main plotGrav GUI figure.
                                        'Units','Normalized','Position',[0.2229 0.2898 0.8115 0.3000],'PaperPositionMode','auto');
                                % Compute spectrogram. This will create plot
                                % with time on X axis, frequency on Y axis and
                                % Power Spectral density on Z axis
                                set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                                [~,f,t,ps] = spectrogram(dataout,t_index,round(t_index/2),length(dataout),1/(time_resolution*86400),'psd','yaxis');
                                % Plot the result. To obtain the same results
                                % as matlab's spectrogram, the PSD must be
                                % scaled to get dB/Hz. Add time_in(1) to get
                                % the date.
                                surf(t/86400+time_in(1),(1./f)/86400,10*log10(abs(ps)),'EdgeColor','none');
                                clear t f ps
                                view(0,90);
                                colorbar('east');
                                % Adjust ylimits to reasonable values.
                                ylim([time_resolution win_length]);
                                % Add description
                                title(sprintf('Power spectral density (dB/Hz): %s  (window length = %3.1f hours)'...
                                    ,char(channels.(char(panels(i)))(plot_axesL1.(char(panels(i))))),win_length*24),'interpreter','none');
                                ylabel('period (days)','FontSize',font_size)
                                % Final plot adjustments
                                set(gca,'FontSize',font_size,'XTick',get(a1(1),'XTick'),'XLim',get(a1(1),'XLim')); % set ticks to L1 (must be L1 as it is the input for analysis)
                                datetick(gca,'x',date_format,'keepticks');          % convert xtick to date
                            end
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','Spectral analysis computed.');drawnow % status 
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel.');drawnow % status 
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','An error occured.');drawnow % status 
                end
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
            
		case 'compute_filter_channel'
			%% Filter channel
			% In addition to the standard filtering perform during iGrav
			% time series processing, user can filter arbitrary channel.
			% However, user should keep in mind the temporal resolution.
			% The default filter is designed for one second data.
            
            % First, try to load the inpulse response file. Unlike iGrav or
            % Other time series, the loaded filter file is not stored in
            % the local plotGrav memory. Therefore, the file must be loaded
            % each time. Full file name set by the user (see File Selection
            % part) is used for this purpose.
			try
				set(findobj('Tag','plotGrav_text_status'),'String','Loading Filter...');drawnow % send message to status bar
				filter_file = get(findobj('Tag','plotGrav_edit_filter_file'),'String'); % get filter filename
				if ~isempty(filter_file)                                    % try to load the filter file/response if some string is given
                    switch filter_file(end-3:end)                           % switch between supported formats: mat = matlab output, otherwise, eterna modified format.
                        case '.mat'
                            Num = importdata(filter_file);                  % Impulse response as created using Matlab's Filter design toolbox
                        otherwise
                            Num = load(filter_file);                        % load filter file = in ETERNA format - header
                            Num = vertcat(Num(:,2),flipud(Num(1:end-1,2))); % stack the filter (ETERNA uses only one half of the repose = mirror the filter)
                    end
				else
					set(findobj('Tag','plotGrav_text_status'),'String','No filter file selected.');drawnow % status
					Num = [];                                               % throughout this file, [] means not data has been loaded => no plotting/loading/computing
				end
			catch
				Num = [];                                           
			end
			% Load all input time series
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     
			if ~isempty(data) && ~isempty(Num)                              % filter only if some data have been loaded and the filter file as well
                % Open logfile
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % load time vectors. Time is used to detect missing values. Filter cannot be applied if missing data are note taking into account.
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); 
				
                % Find selected channles
                % Set panel 'official' names. To reduce the code length, use a for loop for
                % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
                % filling the structure arrays.
                panels = {'data_a','data_b','data_c','data_d'};  
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
                % Start filtering
				set(findobj('Tag','plotGrav_text_status'),'String','Filtering...');drawnow % status
                for p = 1:length(panels)
                    % Proceed only if some channel selected and data Loaded.
                    if ~isempty(plot_axesL1.(panels{p})) && ~isempty(data.(panels{p}))      
                        channel_number = size(data.(panels{p}),2)+1;        % Get the current number of channels. This value will be used to append (+1) new filtered channel
                        time_resolution = round(mode(diff(time.(panels{p})))*864000)/864000;  % time resolution (sampling period). Only necesary for finding missing data (see plotGrav_findTimeStep.m function)
                        % Run for all selected channels
                        for j = 1:length(plot_axesL1.(panels{p}))           
                            % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.(panels{p}),data.(panels{p})(:,plot_axesL1.(panels{p})(j)),time_resolution); 
                            data_filt = [];time_filt = [];                  % prepare temporary variables (*_filt = filtered values)
                            for i = 1:size(id,1)                            % Apply the filter for for each time interval between time steps separately => piecewise filtering              
                                if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough. 
                                    [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv function (outputs only valid time interval, see plotGrav_conv function for details)
                                else
                                    ftime = timeout(id(i,1):id(i,2));       % if the interval is too short, set to NaN 
                                    fgrav(1:length(ftime),1) = NaN;
                                end
                                data_filt = vertcat(data_filt,fgrav,NaN);   % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                                time_filt = vertcat(time_filt,ftime,...     % stack the aux. time 
									ftime(end)+time_resolution/(2*24*60*60)); % this last part is for a NaN see vertcat(dataout above)  
                                % Remove used variables
                                clear ftime fgrav       
                            end
                            % Set units, channels and data table of the new channel
                            units.(panels{p})(channel_number) = units.(panels{p})(plot_axesL1.(panels{p})(j)); 
                            channels.(panels{p})(channel_number) = {sprintf('%s_filt',char(channels.(panels{p})(plot_axesL1.(panels{p})(j))))}; % add channel name
                            data_table.(panels{p})(channel_number,1:7) = {false,false,false,... % append the new channel to the ui-table.
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels.(panels{p})(channel_number)),char(units.(panels{p})((plot_axesL1.(panels{p})(j))))),...
																false,false,false};
                            % Append the filtered time series to data matrix
                            data.(panels{p})(:,channel_number) = interp1(time_filt,data_filt,time.(panels{p})); 
                            clear data_filt time_filt timeout dataout id    % Clear variables used in each for loop
                            % Write message to logfile
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'%s channel %d filtered -> %d (%04d/%02d/%02d %02d:%02d)\n',...
							panels{p},plot_axesL1.(panels{p})(j),channel_number,ty,tm,td,th,tmm);
                            % increase the number for next channel
                            channel_number = channel_number + 1;              
                        end
                        % Remove used variable. Same name but possible different values in loop run.
                        clear time_resolution channel_number 
                        % Store the new channel names, units and data table
                        set(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{p})),'Data',data_table.(panels{p})); 
                        set(findobj('Tag',sprintf('plotGrav_text_%s',panels{p})),'UserData',units.(panels{p})); 
                        set(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{p})),'UserData',channels.(panels{p}));                                 
                    end
                end
                fclose(fid);                                                % Close the logfile
                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated data matrix
				set(findobj('Tag','plotGrav_text_status'),'String','Selected channles have been filtered.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
			end
			
		case 'compute_remove_channel'
			%% Remove channels
            % User can duplicate and remove arbitrary channels. This
            % section serves for removing selected channels, i.e., columns
            % of loaded data matrices. The removal is PERMANENT! 
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            if ~isempty(data)                                               % proceed only if some data loaded. 
                % As usual, open the logfile.
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
				
                % Find selected channles
                % Set panel 'official' names. To reduce the code length, use a for loop for
                % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
                % filling the structure arrays.
                panels = {'data_a','data_b','data_c','data_d'};  
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
				
				set(findobj('Tag','plotGrav_text_status'),'String','Removing channels...');drawnow % status
				
				% Remove the selected channels = columns from data matrix.
                for p = 1:length(panels)
                    % Proceed only if channel selected and loaded
                    if ~isempty(plot_axesL1.(panels{p})) && ~isempty(data.(panels{p}))      
                        data.(panels{p})(:,plot_axesL1.(panels{p})) = [];       % remove selected columns with time series (it is not necesary to run for loop for this)
                        channels.(panels{p})(plot_axesL1.(panels{p})) = [];     % remove channel name
                        units.(panels{p})(plot_axesL1.(panels{p})) = [];        % remove units
                        data_table.(panels{p})(plot_axesL1.(panels{p}),:) = []; % remove from ui-table
                        for i = 1:length(plot_axesL1.(panels{p}))               % Run loop only for Log file: selecte channels only
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'%s channel %d removed (%04d/%02d/%02d %02d:%02d)\n',...
                                panels{p},plot_axesL1.(panels{p})(i),ty,tm,td,th,tmm);
                        end
                        % Create new ui-table without selected/removed
                        % channels. Run this loop especially to update the
                        % channel numers. Removal of a channel data_data_a(plot_axesL1.data_a,:) = [];
                        % does not invoke numbering update!!
                        for i = 1:length(channels.(panels{p}))              % Loop for all remaining channels
                            data_table.(panels{p})(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels{p})(i)),char(units.(panels{p})(i)))};
                        end
                        % Store the new channel names, units and data table
                        set(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{p})),'Data',data_table.(panels{p})); 
                        set(findobj('Tag',sprintf('plotGrav_text_%s',panels{p})),'UserData',units.(panels{p})); 
                        set(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{p})),'UserData',channels.(panels{p})); 
                    end
                end
				% store the updated data matrices
                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   
                % Close logfile
				fclose(fid);
				set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
            
		case 'compute_copy_channel'
			%% COPY CHANNEL
            % User can duplicate selected channels (all panels)
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data. Time vectors are not needed for this operation.
            if ~isempty(data)                                               % copy only if some data loaded
                % Try to open the logfile
				try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
				end
				% Find selected channles
                % Set panel 'official' names. To reduce the code length, use a for loop for
                % all panels (iGrav, TRiLOGi, Other 1 and 2). Use 'panels' as variable for
                % filling the structure arrays.
                panels = {'data_a','data_b','data_c','data_d'};  
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
				
				set(findobj('Tag','plotGrav_text_status'),'String','Copying channels...');drawnow % status
				
                try
                    for p = 1:length(panels)
                        % Proceed only if channel selected and loaded
                        if ~isempty(plot_axesL1.(panels{p})) && ~isempty(data.(panels{p}))  
                            % Get current number o channels (all not only selected ones). Will be used to append the new/copied channel at the and of the data matrix                
                            channel_number = size(data.(panels{p}),2)+1;
                            % Run following code for all selected channels
                            for j = 1:length(plot_axesL1.(panels{p}))                     
                                units.(panels{p})(channel_number) = units.(panels{p})(plot_axesL1.(panels{p})(j)); % copy/append units
                                channels.(panels{p})(channel_number) = {sprintf('%s_copy',char(channels.(panels{p})(plot_axesL1.(panels{p})(j))))}; % add channel name
                                data_table.(panels{p})(channel_number,1:7) = {false,false,false,... % add to ui-table. By default, the copied channel is not checked for either axes (=false)
                                                                    sprintf('[%2d] %s (%s)',channel_number,char(channels.(panels{p})(channel_number)),char(units.(panels{p})((plot_axesL1.(panels{p})(j))))),...
                                                                        false,false,false};
                                data.(panels{p})(:,channel_number) = data.(panels{p})(:,plot_axesL1.(panels{p})(j)); % append to data matrix
                                channel_number = channel_number + 1;        % increase the number for next channel
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'%s channel %d copied to %d (%04d/%02d/%02d %02d:%02d)\n',...
                                    panels{p},plot_axesL1.(panels{p})(j),channel_number-1,ty,tm,td,th,tmm);
                            end
                            % Store copied channel names, units and data table
                            set(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{p})),'Data',data_table.(panels{p})); 
                            set(findobj('Tag',sprintf('plotGrav_text_%s',panels{p})),'UserData',units.(panels{p})); 
                            set(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{p})),'UserData',channels.(panels{p})); 
                            % Remove variables. Same variable names will be used for other panels...
                            clear j channel_number ty tm td th tmm                  
                        end
                    end
                    % close logfile
                    fclose(fid);                                               
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store new/extended data matrices
                    set(findobj('Tag','plotGrav_text_status'),'String','Selected channels have been copied.');drawnow % status
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not copy selected channel.');drawnow % status
                end
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
		case 'compute_eof'
			%% Empirical orthogonal functions (EOF)
            % This part is in early BETA phase.
            % The aim of this part is to perform an EOF analysis of selected
            % time series. Only analyis is performed here (+visualisation).
            % In addition, user can export the results (see
            % 'export_rec_time_series' and 'export_eop_pattern').
            % This code is base on "A Manual for EOF and SVD Analyses of
            % Climatic Data" by H. Bjoernsson and S.A. Venegas (February
            % 1997).
            % Selection of time series from different panels (e.g., iGrav +
            % Other1) will call an interpolation of data to identical 
            % sampling,i.e., to iGrav time resolution!
            % No scaling is performed. It is assumed identical units are
            % used!
            
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data. Time vectors will be loaded later.
			a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');      % get axes handles for plotting. The EOF result will be plotted to GUI. 
			a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');    
			a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');   
            % Prepare axes for plotting. Only Axes 2 and 3 will be used for
            % actual plotting. Axes 1 contains selected channels.
			cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);                % clear axes and remove legends and labels
			cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);                % clear axes and remove legends and labels
			axis(a2(1),'auto');axis(a2(2),'auto');
			cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);                % clear axes and remove legends and labels
			cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);                % clear axes and remove legends and labels
			axis(a3(1),'auto');axis(a3(2),'auto');
            color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');          % get defined colors
            line_width = get(findobj('Tag','plotGrav_menu_line_width'),'UserData');     % get line width
            num_of_ticks_x = get(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData'); % get number of tick for y axis
            num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size

			
            % Prepare new variables. All EOF results will be stored in the
            % 'eof' structure array.
			eof.F = [];                                                     % the matrix notatio is identical to the one used in the "A Manual for EOF and SVD Analyses of Climatic Data"
			eof.chan_list = [];
			eof.unit_list = [];
			eof.mean_value = [];
			if ~isempty(data.data_a)                                         % proceed only if data_a data loaded
                % Get all required data
				time = get(findobj('Tag','plotGrav_text_status'),'UserData');               % load time vectors
				data_data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');      % get the iGrav ui-table. Will be used to find selected/checked channels.
				units_data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');         % get iGrav units. 
				channels_data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData'); % get iGrav channels (names). 
				data_data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');  % get the TRiLOGi table
				units_data_b = get(findobj('Tag','plotGrav_text_data_b'),'UserData');     % get TRiLOGi units
				channels_data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels
				data_data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');    % get the Other1 table
				units_data_c = get(findobj('Tag','plotGrav_text_data_c'),'UserData');       % get Other1 units
				channels_data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData'); % get Other1 channels
				data_data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');    % get the Other2 table
				units_data_d = get(findobj('Tag','plotGrav_text_data_d'),'UserData');       % get Other2 units
				channels_data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData'); % get Other2 channels
				plot_axesL1.data_a = find(cell2mat(data_data_a(:,1))==1);     % get selected iGrav channels for L1
				plot_axesL1.data_b = find(cell2mat(data_data_b(:,1))==1); % get selected TRiLOGi channels for L1
				plot_axesL1.data_c = find(cell2mat(data_data_c(:,1))==1);   % get selected Other1 channels for L1
				plot_axesL1.data_d = find(cell2mat(data_data_d(:,1))==1);   % get selected data_d channels for L1
				
				set(findobj('Tag','plotGrav_text_status'),'String','Computing EOF...');drawnow % status
				plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData');  % plot mode will be updated as EOF results will be plotted to GUI
				
                try
                    eof.ref_time = [time.data_a(1):mode(diff(time.data_a)):time.data_a(end)]';  % new reference time vector. All time series will be re-interpolated to this time vector. mode(diff(time.data_a)) is used to ensure constant sampling

                    % Prepare the F matrix, starting with iGrav
                    if ~isempty(plot_axesL1.data_a)                              % proceed only if selected. ~isempty(data.data_a) condition already used above
                        for i = 1:length(plot_axesL1.data_a)                     % compute for all selected channels
                            temp = interp1(time.data_a,data.data_a(:,plot_axesL1.data_a(i)),eof.ref_time); % interpolate current channel to ref_time
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))]; % Start stacking mean values. Mean will stored for further processing. Remove NaNs only for mean computation. Pairwise covariance will be then computed to avoid NaN issues.
                            temp = temp - eof.mean_value(end);                  % remove mean value (EOP requirement)
                            eof.unit_list = [eof.unit_list,units_data_a(plot_axesL1.data_a(i))]; % Stack units (for output)
                            eof.chan_list = [eof.chan_list,channels_data_a(plot_axesL1.data_a(i))]; % Stack channel names (for output)
                            eof.F = horzcat(eof.F,temp);                        % Stack columns = data for further EOF analysis (F matrix contains all/selected input time series)
                            clear temp
                        end
                    end
                    % Do the same for TRiLOGi. See comments above.
                    if ~isempty(plot_axesL1.data_b) && ~isempty(data.data_b)
                        for i = 1:length(plot_axesL1.data_b)                 
                            temp = interp1(time.data_b,data.data_b(:,plot_axesL1.data_b(i)),eof.ref_time); 
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);       
                            eof.unit_list = [eof.unit_list,units_data_b(plot_axesL1.data_b(i))];
                            eof.chan_list = [eof.chan_list,channels_data_b(plot_axesL1.data_b(i))];
                            eof.F = horzcat(eof.F,temp);                            
                            clear temp
                        end
                    end
                    % Do the same for Other1. See comments above.
                    if ~isempty(plot_axesL1.data_c) && ~isempty(data.data_c)
                        for i = 1:length(plot_axesL1.data_c)                 
                            temp = interp1(time.data_c,data.data_c(:,plot_axesL1.data_c(i)),eof.ref_time); 
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);         
                            eof.unit_list = [eof.unit_list,units_data_c(plot_axesL1.data_c(i))]; 
                            eof.chan_list = [eof.chan_list,channels_data_c(plot_axesL1.data_c(i))]; 
                            eof.F = horzcat(eof.F,temp);                            
                            clear temp
                        end
                    end

                    % Do the same for Other2. See comments above.
                    if ~isempty(plot_axesL1.data_d) && ~isempty(data.data_d)
                        for i = 1:length(plot_axesL1.data_d)                 
                            temp = interp1(time.data_d,data.data_d(:,plot_axesL1.data_d(i)),eof.ref_time); 
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);        
                            eof.unit_list = [eof.unit_list,units_data_d(plot_axesL1.data_d(i))]; 
                            eof.chan_list = [eof.chan_list,channels_data_d(plot_axesL1.data_d(i))]; 
                            eof.F = horzcat(eof.F,temp');                           
                            clear temp
                        end
                    end

                    % Compute EOF
                    if ~isempty(eof.F)                                          % Check if F matrix has been created
                        R = nancov(eof.F,'pairwise');                           % compute covarince matrix pairwise to allow existance of NaN
                        [eof.EOF,L] = eig(R);                                   % compute eigenvectors/EOF and eigenvalues (L)
                        eof.explained = diag(L)/trace(L)*100;                   % compute explained variance (in %)
                        eof.PC = eof.F*eof.EOF;                                 % compute principle components
                        for i = 1:size(eof.F,2)                                 % create legend related to principle components
                            eof.cur_legend{1,i} = sprintf('PC%1d (%4.1f%%)',i,eof.explained(size(eof.F,2)+1-i));
                        end
                        % Plot the results: PCs (temporary plot, will disappear
                        % after ploting something else (selecting channel).
                        % Nevertheless, the results will be stored for further
                        % export (save as, see 'export_rec_time_series' and
                        % 'export_eof_pcs')
                        h = plot(a2(1),eof.ref_time,fliplr(eof.PC));            % plot the computet PC (fluplr to sort it descendingly)
                        for i = 1:length(h)                                     % Set color for plotted lines + their width
                            set(h(i),'color',color_scale(i,:),'LineWidth',line_width(3));
                        end
                        if get(findobj('Tag','plotGrav_check_grid'),'Value')==1  % show grid if required (selected)
                            grid(a2(1),'on');                                   % only left axis (L2) is used
                        else
                            grid(a2(2),'off');
                        end
                        if get(findobj('Tag','plotGrav_check_legend'),'Value') ==1  % show legend if required (selected)
                            l = legend(a2(1),eof.cur_legend);               
                            set(l,'interpreter','none','FontSize',font_size);   % change font and interpreter (because channels contain spacial sybols like _)
                            legend(a2(2),'off');                                % legend for left axes always off (nothing is plotted)
                        else
                            legend(a2(1),'off');                                % turn of legends if not required
                            legend(a2(2),'off');
                        end
                        if get(findobj('Tag','plotGrav_check_labels'),'Value')==1  % show labels if required
                            ylabel(a2(1),'EOF time series','FontSize',font_size);  % label only for left axes
                            ylabel(a2(2),[]);
                        else
                            ylabel(a2(1),[]);
                            ylabel(a2(2),[]);
                        end
                        % Set limits                                            
                        ref_lim = get(a1(1),'XLim');                            % get current L1 X limits and use them a reference
                        xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x); % create new time ticks
                        set(a2(1),'YLimMode','auto','XLim',ref_lim,'XTick',xtick_value,'Visible','on'); % set X limits
                        rL1 = get(a2(1),'YLim'); 
                        set(a2(1),'YLimMode','auto','YTick',linspace(rL1(1),rL1(2),num_of_ticks_y)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')
                        set(a2(2),'Visible','off','XLim',ref_lim,'XTick',xtick_value); % set new X ticks (left)
                        linkaxes([a2(1),a2(2)],'x');                            % link axes, just in case
                        
                        % Plot the results: Reconstructions (temporary plot, 
                        % same as PC plot). Plot only the reconstruction
                        % for first component!!
                        Fr = eof.F*eof.EOF(:,end)*eof.EOF(:,end)';          % Keep in mind, EOF are stored in ascending order => start from the end
                        for i = 1:size(Fr,2)
                            Fr(:,i) = Fr(:,i) + eof.mean_value(i);          % add the mean value that has been removed prior to EOF analysis
                        end
                        h = plot(a3(1),eof.ref_time,Fr);            % plot the computet reconstruction (fluplr to sort it descendingly)
                        for i = 1:length(h)                                     % Set color for plotted lines + their width
                            set(h(i),'color',color_scale(i,:),'LineWidth',line_width(3));
                        end
                        if get(findobj('Tag','plotGrav_check_grid'),'Value')==1  % show grid if required (selected)
                            grid(a3(1),'on');                                   % only left axis (L2) is used
                        else
                            grid(a3(2),'off');
                        end
                        if get(findobj('Tag','plotGrav_check_legend'),'Value') ==1  % show legend if required (selected)
                            temp = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get legend of L1 (the same for reconstruction)
                            l = legend(a3(1),temp{1});                                     % set left legend
                            set(l,'interpreter','none','FontSize',font_size);   % change font and interpreter (because channels contain spacial sybols like _)
                            legend(a3(2),'off');                                % legend for left axes always off (nothing is plotted)
                        else
                            legend(a3(1),'off');                                % turn of legends if not required
                            legend(a3(2),'off');
                        end
                        if get(findobj('Tag','plotGrav_check_labels'),'Value')==1  % show labels if required
                            ylabel(a3(1),'EOF reconstruction','FontSize',font_size);  % label only for left axes
                            ylabel(a3(2),[]);
                        else
                            ylabel(a3(1),[]);
                            ylabel(a3(2),[]);
                        end
                        % Set limits                                            
                        ref_lim = get(a1(1),'XLim');                            % get current L1 X limits and use them a reference
                        xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x); % create new time ticks
                        set(a3(1),'YLimMode','auto','XLim',ref_lim,'XTick',xtick_value,'Visible','on'); % set X limits
                        rL1 = get(a3(1),'YLim'); 
                        set(a3(1),'YLimMode','auto','YTick',linspace(rL1(1),rL1(2),num_of_ticks_y)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')
                        set(a3(2),'Visible','off','XLim',ref_lim,'XTick',xtick_value); % set new X ticks (left)
                        linkaxes([a3(1),a3(2)],'x');                            % link axes, just in case
                        plot_mode(2:3) = [1 1];                                 % update plot mode (plot_mode(1) is on, otherwise no time series would be selected)
                        plotGrav('push_date');                                  % make sure X axis is in civil time
                        set(findobj('Tag','plotGrav_push_reset_view'),'UserData',plot_mode);% store updated plot_mode 
                        set(findobj('Tag','plotGrav_menu_compute_eof'),'UserData',eof);% store EOF results for possible exporting (see next section)
                        set(findobj('Tag','plotGrav_text_status'),'String','EOF computed.');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','EOF NOT computed.');drawnow % status
                    end 
                catch error_message
                    if strcmp(error_message.identifier,'MATLAB:license:checkouterror')
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, no licence (Statistics_Toolbox?)');drawnow % message
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','An (unkonwn) error occur during EOF analysis.');drawnow % status
                    end
                    
                end
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
			end
			
% 		case 'export_rec_time_series'
% 		% !!!!!!!!NEEDS TO BE CORRECTED!!!!!
% 			%% Export reconstructed time series + PCs
%             % After computing EOF, results are plotted to L2 axis. In
%             % addition, user can export the results to a plotGrav supportef
%             % file formats (tsf,mat)
% 			eof = get(findobj('Tag','plotGrav_menu_compute_eof'),'UserData');   % get EOF results 
% 			if ~isempty(eof)                                                % proceed only if EOF already computed  
%                 % Create channel names = Reconstructed time series using
%                 % different number of PCs.
%                 % + Reconstruct time series (all combination)
%                 for j = 1:size(eof.F,2)
%                     cur_pc{j} = sprintf('PC1-PC%1d',j);                        % current range of PCs used for recontruction
%                     Fr = eof.F*eof.EOF(:,end+1-j:end)*eof.EOF(:,end+1-j:end)'; % reconstruct data using only selected number of PCs. Keep in mind, EOF are stored in ascending order => start from the end
%                     Fr(:,j) = Fr(:,j) + eof.mean_value(j);                  % add subtracted mean value back
%                 end
%                 plotGrav_exportData(eof.ref_time,data,channels,units,select,fid,panel_name,varargin)
                
% 				data_out = datevec(eof.ref_time);                           % convert time vector to amtrix
% 				[name,path,filteridex] = uiputfile({'*.tsf'},'Select output file.'); % open ui dialog
% 				if name == 0
% 					set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
% 				else
% 					ch = 1;                                             % aux. variable (count channels)
% 					for j = 1:size(eof.F,2)
% 						cur_pc = sprintf('PC1-PC%1d',j);                % current PCs used for recontruction
% 						Fr = eof.F*eof.EOF(:,end+1-i:end)*eof.EOF(:,end+1-i:end)'; % reconstruct data using only selected number of PCs
% 						for i = 1:size(eof.F,2)
% 							comment(ch,1:4) = {'plotGrav',cur_pc,sprintf('%s',char(eof.chan_list(i))),char(eof.unit_list(i))}; % tsf header
% 							ch = ch + 1;
% 							Fr(:,i) = Fr(:,i) + eof.mean_value(i);      % add subtracted mean value
% 						end
% 						data_out = horzcat(data_out,Fr);                % prepare for writting
% 						clear Fr cur_pc
% 					end
% 					set(findobj('Tag','plotGrav_text_status'),'String','Writing...');drawnow % status
% 					plotGrav_writetsf(data_out,comment,[path,name],3);  % write output
% 					set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
% 				end
% 			else
% 				set(findobj('Tag','plotGrav_text_status'),'String','Compute EOF first.');drawnow % status
%             end
% 			eof = get(findobj('Tag','plotGrav_menu_compute_eof'),'UserData');% store EOF results 
% 			if ~isempty(eof)
% 				data_out = [datevec(eof.ref_time),fliplf(eop.pc)];      % output for writting
% 				[name,path,filteridex] = uiputfile({'*.tsf'},'Select output file.'); % open dialog
% 				if name == 0
% 					set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
% 				else
% 					for i = 1:size(eof.F,2)
% 						cur_pc = sprintf('PC%1d',i);                    % current PC
% 						comment(i,1:4) = {'plotGrav',cur_pc,sprintf('%s',char(eof.chan_list(i))),char(eof.unit_list(i))}; % tsf header
% 						clear Fr cur_pc
% 					end
% 					set(findobj('Tag','plotGrav_text_status'),'String','Writing...');drawnow % status
% 					plotGrav_writetsf(data_out,comment,[path,name],3);  % write output 
% 					set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
% 				end
% 			else
% 				set(findobj('Tag','plotGrav_text_status'),'String','Compute EOF first.');drawnow % status

% 			end

		case 'export_eof_pcs'
		   %% Export EOF PC
           % Export the computed EOF principle components to plotGrav supported file
           % format.
			eof = get(findobj('Tag','plotGrav_menu_compute_eof'),'UserData'); % store EOF results
            % Reconstruct time series using first PC
            Fr = eof.F*eof.EOF(:,end)*eof.EOF(:,end)';                      % Keep in mind, EOF are stored in ascending order => start from the end
            Fr = fliplr(Fr);                                                % ascending to descenting
            for i = 1:size(Fr,2)
                Fr(:,i) = Fr(:,i) + eof.mean_value(i);                      % add the mean value that has been removed prior to EOF analysis
            end
            if ~isempty(eof)                                                % proceed only if EOF computed
                % EOF time series (PCs)
                for i = 1:size(eof.EOF,2)                                   % Create channel names and untis. Units are by default unkwnon
                    channels(i) = {sprintf('PC%1d',i)};
                    units(i) = {'?'};
                end
                % Append reconstruciton
                for i = 1:size(Fr,2)                                        % Create channel names and untis. Units are by default unkwnon
                    channels(i+size(eof.EOF,2)) = {sprintf('PC%1d:reconst.',i)};
                    units(i+size(eof.EOF,2)) = {'?'};
                end
                dataout = [fliplr(eof.PC),fliplr(Fr)];                              % ascending to descending order (First column = first component)
                plotGrav_exportData(eof.ref_time,dataout,channels,units,[],[],'EOF Patterns',[]);
                set(findobj('Tag','plotGrav_text_status'),'String','EOF Patterns exported.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Compute EOF first.');drawnow % status
            end
            
		case 'fit_linear'
			%% Fitting polynomials
            % User can fit a polynomial up to degree 3 and subtract the
            % fitted curve.
            set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
            message_out = plotGrav_fitData(1,[],[],[]);
            set(findobj('Tag','plotGrav_text_status'),'String',message_out);drawnow % status
		case 'fit_quadratic'
			% Fit polynomial 2.degree
            set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
            message_out = plotGrav_fitData(2,[],[],[]);
            set(findobj('Tag','plotGrav_text_status'),'String',message_out);drawnow % status
        case 'fit_cubic'
			% Fit polynomial 3.degree
            set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
            message_out = plotGrav_fitData(3,[],[],[]);
            set(findobj('Tag','plotGrav_text_status'),'String',message_out);drawnow % status
		case 'fit_constant'
			% Fit polynomial 0.degree = subtract mean
            set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
            message_out = plotGrav_fitData(0,[],[],[]);
            set(findobj('Tag','plotGrav_text_status'),'String',message_out);drawnow % status
		case 'fit_user_set'
			% SUBTRACE polynomial X.degree = coefficient set by user
            % In this case, user input is required:
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % just to check if some data has been loaded
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d)
                set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                if nargin == 1 
                    set(findobj('Tag','plotGrav_text_status'),'String','Set coefficients of a polynomial (PN PN-1... P0)');drawnow % send instructions to command promtp
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                st = strsplit(st,' ');                                          % split string
                out_par = str2double(st);                                   % convert to double
                message_out = plotGrav_fitData(9999,[],[],[],out_par);      % call fitting function
                set(findobj('Tag','plotGrav_text_status'),'String',message_out);drawnow % status
            end
            
	   case 'fit_local'
            %% Local fit
            % Besides the standar data fitting (e.g., 'fit_linear'), user
            % can estimate 'local' fit, i.e., plot a curve for
            % interactively selected time interval. This feature was
            % designed for step removal. User can temporarly plot local
            % fits to see where the "gravity would be" if extrapolating
            % data recorded before step. + user can set the polynomial
            % degree.
            % This feature works only for iGrav panel! The plots are not
            % permanent, and not stored anywhere!
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
			if ~isempty(data.data_a)                                         % continue only if iGrav data loaded
                % First, get required data
				time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
				data_data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');  % get the iGrav ui-table to find selected channel
				plot_axesL1.data_a = find(cell2mat(data_data_a(:,1))==1);     % get selected iGrav channels for L1
				a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get first axes (L1) for future plotting
				if isempty(plot_axesL1.data_a)
					set(findobj('Tag','plotGrav_text_status'),'String','Select one iGrav channel!');drawnow % status
				elseif length(plot_axesL1.data_a) > 1
					set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                else   
                    % First get user input = polynomial degree
                    set(findobj('Tag','plotGrav_text_status'),'String','Set polynomial degree (e.g., 1)');drawnow % send instructions to command promtp
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','1'); % make input text visible + set to default value, 1 = linear fit
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                    deg = str2double(st);                                   % convert to double (required for polyfit function)
                    
                    set(gcf,'CurrentAxes',a1(1));                           % set axes L1 as current (otherwise could the picked values refere to other axes)
					set(findobj('Tag','plotGrav_text_status'),'String','Select first point (start)...');drawnow % send instruction to status bar
					[selected_x1,~] = ginput(1);
					set(findobj('Tag','plotGrav_text_status'),'String','Select second point (stop)...');drawnow % status
					[selected_x2,~] = ginput(1);
					set(findobj('Tag','plotGrav_text_status'),'String','Select extrapolation point...');drawnow % status
					[selected_x3,~] = ginput(1);
					selected_x = sort([selected_x1,selected_x2]);           % sort = ascending
                    r = find(time.data_a>selected_x(1) & time.data_a<selected_x(2)); % find points within the selected interval
                    r2 = find(time.data_a>min([selected_x1,selected_x2,selected_x3]) & time.data_a<max([selected_x1,selected_x2,selected_x3]));  % find points within the selected interval (extrapolation)
                    if ~isempty(r)                                          % continue only if some points have been found
                        try
                            ytemp = data.data_a(r,plot_axesL1.data_a);        % get selected channel within found interval
                            xtemp = time.data_a(r);                          % get selected time interval 
                            p = polyfit(xtemp(~isnan(ytemp)),ytemp(~isnan(ytemp)),deg); % Fit data
                            if ~isempty(r2)                                 % extrapolate only if some points have been found
                                otemp = polyval(p,time.data_a(r2));
                                plot(time.data_a(r2),otemp,'k');
                            end
                        catch
                            set(findobj('Tag','plotGrav_text_status'),'String','Could not fit the data.');drawnow % status
                        end
						clear temp r
                    end
                    set(gcf,'CurrentAxes',a1(2));                           % set back R1 (othwerwise invisible)
                    set(findobj('Tag','plotGrav_text_status'),'String','Fit for selected interval has been computed and plotted.');drawnow % status
				end
			end 
            
		case 'correlation_matrix'
            %% Correlation analysis
            % The correlation analysis alows user to estimate corretlation
            % coefficietns between selected channels (all panels). By
            % default all time series are re-interpolated to iGrav time
            % vector. If iGrav not loaded, TRiLOGi time is used...
            
            % Get required data
			data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');       % get font size (for plotting)

            % Find selected channels
            panels = {'data_a','data_b','data_c','data_d'};                 % will be used to simplify the code: run a for loop for all panels  
            for i = 1:length(panels)
                % Get ui-table and channel names
                data_table.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data'); 
                channels.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{i})),'UserData');
                % find selected channel
                plot_axesL1.(panels{i}) = find(cell2mat(data_table.(panels{i})(:,1))==1); % get selected channels (L1) for each panel
            end
            
            % Set reference time. All time series will be interpolated to
            % this time vector.
            eof.ref_time = [];                                              % declare variable
            if ~isempty(time.data_a)                                         % First, try to set data_a time as reference 
                eof.ref_time = time.data_a;                                  % new time (hourly resolution)
            end
            if isempty(eof.ref_time) && ~isempty(time.data_b)              % if iGrav data not loaded, continue finding reference time vector
                eof.ref_time = time.data_b;                                
            end
            if isempty(eof.ref_time) && ~isempty(time.data_c)              
                eof.ref_time = time.data_c;                                
            end
            if isempty(eof.ref_time) && ~isempty(time.data_d)              
                eof.ref_time = time.data_d;                                
            end
			eof.F = [];                                                     % will store all interpolated time series used to compute correlation matrix
			eof.chan_list = [];                                             % declare variable that will store channel names. Will be used for plotting. Units not important.
			eof.chan_list_log = [];                                         % declare variable for channel names written to logfile (will include panel and channel number, not names)
            if ~isempty(data)                                               % continue only if some data exists
                set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                try
                    % Stack data to one matrix
                    run_index = 1;
                    for i = 1:length(panels)                                    % loop for all panels
                        if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i))))  % check if at least one time series is selected in current panel
                            for j = 1:length(plot_axesL1.(char(panels(i))))                 % compute for all selected channels
                                temp = interp1(time.(char(panels(i))),data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))(j)),eof.ref_time); % interpolate current channel to ref_time
                                eof.chan_list = [eof.chan_list,channels.(char(panels(i)))(plot_axesL1.(char(panels(i)))(j))]; % add current channel name
                                eof.F = horzcat(eof.F,temp);                    % stack columns
                                eof.chan_list_log{run_index} = {sprintf('%s channel %2d',char(panels(i)),plot_axesL1.(char(panels(i)))(j))};
                                clear temp                                      % Clear variable before use data for next column
                                run_index = run_index + 1;
                            end
                        end
                    end
                    % Compute correlation
                    eof.F(isnan(sum(eof.F,2)),:) = [];                          % remove NaNs: whole rows where at leas one value is NaN (=>sum of [1 2 NaN] = NaN)
                    [r_pers,p] = corrcoef(eof.F);                               % correlation matrix and p values
                    r_boots = bootstrp(1000,@corrcoef,eof.F);                   % bootstrapping. By default, use 1000 as number of bootsraps. Call the corrcoef function using newly created matrix eof.F 
                    t.estim = r_pers.*sqrt((size(eof.F,1)-2)./(1-r_pers.^2));   % estimated t value
                    t.crit = tinv(0.95,size(eof.F,1)-2);                        % critical t value
                    mversion = version;                                         % get matlab version. New Matlab version (8.4 uses different interpreter switch, see below)
                    mversion = str2double(mversion(1:3));                       % to numeric: >= operation will be performed on 'mversion'
                    % Show correlation matrix
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation matrix'); % open new figure so results are not plotted to plotgrav GUI
                    imagesc(r_pers);                                            % Plot correlation matrix
                    r = find(isnan(r_pers) | isinf(r_pers));                    % Check if NaNs or Inf values in the correlation matrix exist
                    if ~isempty(r)                                              % If so, sen a warning message to title
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                     % set axis and view
                    colorbar;                                                   % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',font_size);                                  % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    % Show p value matrix
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation p value (close to 0 => significant corr.)'); % open new figure so results are not plotted to plotgrav GUI
                    imagesc(p);                                                 % Plot p value
                    r = find(isnan(p) | isinf(p));                              % Check if NaNs or Inf values in the correlation matrix exist
                    if ~isempty(r)                                              % If so, sen a warning message to title
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                     % set axis and view
                    colorbar;                                                   % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',font_size);                                  % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    % Show t test value matrix
                    figure('NumberTitle','off','Menu','none',...                % open new figure so results are not plotted to plotgrav GUI
                        'Name','plotGrav: correlation t test (>0 =>reject that there is no corr. (95%))');
                    imagesc(t.estim-t.crit);                                    % plot t test difference 
                    r = find(isnan(t.estim-t.crit) | isinf(t.estim-t.crit));    % Check if NaNs or Inf values in the correlation matrix exist
                    if ~isempty(r)                                              % If so, sen a warning message to title
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                     % set axis and view
                    colorbar;                                                   % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',font_size);                                  % font size
                    if mversion>=8.4                                            % Adjust the plot for newer matlab version
                        set(gca,'TickLabelInterpreter','none');
                    end
                    % Show bootsrap results: In this case, the bootsrap
                    % result for each pair will be plotted into a histogram.
                    % These histograms will be in ONE figure (using subplot
                    % function)
                    figure('NumberTitle','off','Menu','none',...                % open new figure so results are not plotted to plotgrav GUI
                        'Name','plotGrav: correlation bootstrap histograms');
                    si = 1;                                                     % subplot index
                    for i = 1:size(r_pers,1)                                    % for each row     
                        % Write results to logfile
                        if i > 1 % do not output autocorrelation
                            otime = datevec(now);
                            fprintf(fid,'Simple correlation analysis: %s  vs  %s = %7.5f, t_est = %7.4f, t_crit = %7.4f, p_val = %7.4f (%04d/%02d/%02d %02d:%02d)\n',...
                                char(eof.chan_list_log{1}),char(eof.chan_list_log{i}),r_pers(i,1),t.estim(i,1),t.crit,p(i,1),otime(1),otime(2),otime(3),otime(4),otime(5));
                        end
                        for j = 1:size(r_pers,2)                                % For each column
                            subplot(size(r_pers,1),size(r_pers,2),si)           % one subplot per one pair 
                            hist(r_boots(:,si),round(sqrt(1000)));              % show each bootstrap histrogram (1000 = number of bootsraps)
                            title(sprintf('%s - %s',char(eof.chan_list(i)),char(eof.chan_list(j))),'FontSize',font_size-1,'interpreter','none');
                            xlabel('corr.','FontSize',font_size-2);             % Reduce the fontsize. One plot may contain too many subplots!
                            set(gca,'FontSize',font_size-2);
                            si = si + 1;                                        % next subplot index
                        end
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Correlation computed.');drawnow % status
                catch error_message
                    otime = datevec(now);
                    fprintf(fid,'Correlation not computed. Error %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),otime(1),otime(2),otime(3),otime(4),otime(5));
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Correlation not computed.');drawnow % status
                end
            else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
			
		case 'correlation_matrix_select'
            % Just like in the previous section 'correlation_matrix', this
            % part allow computation of correlation coefficient for
            % arbitrary time series combinations (all panels). In this
            % case, however, user can reduce the analyis to a certain time
            % interval (will select manually).
            
            % Get required data
			data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');       % get font size (for plotting)
            
            % Find selected channels
            panels = {'data_a','data_b','data_c','data_d'};                 % will be used to simplify the code: run a for loop for all panels  
            for i = 1:length(panels)
                % Get ui-table and channel names
                data_table.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data'); 
                channels.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{i})),'UserData');
                % find selected channel
                plot_axesL1.(panels{i}) = find(cell2mat(data_table.(panels{i})(:,1))==1); % get selected channels (L1) for each panel
            end
            
            % Set reference time. All time series will be interpolated to
            % this time vector.
            eof.ref_time = [];                                              % declare variable
            if ~isempty(time.data_a)                                         % First, try to set data_a time as reference 
                eof.ref_time = time.data_a;                                  % new time (hourly resolution)
            end
            if isempty(eof.ref_time) && ~isempty(time.data_b)              % if iGrav data not loaded, continue finding reference time vector
                eof.ref_time = time.data_b;                                
            end
            if isempty(eof.ref_time) && ~isempty(time.data_c)              
                eof.ref_time = time.data_c;                                
            end
            if isempty(eof.ref_time) && ~isempty(time.data_d)              
                eof.ref_time = time.data_d;                                
            end
            set(findobj('Tag','plotGrav_text_status'),'String','Select two points (like for zooming)...');drawnow % send instruction to status bar
			[selected_x,~] = ginput(2);                                     % Get user input
            selected_x = sort(selected_x);                                  % in case user select first the second point and vice versa.
            eof.ref_time(eof.ref_time<selected_x(1) | eof.ref_time>selected_x(2)) = []; % remove time records outside selected time interval
            
            % The remaining code is identical to 'correlation_matrix'
			eof.F = [];                                                     % will store all interpolated time series used to compute correlation matrix
			eof.chan_list = [];                                             % declare variable that will store channel names. Will be used for plotting. Units not important.
            eof.chan_list_log = [];                                         % declare variable for channel names written to logfile (will include panel and channel number, not names)
            if ~isempty(data)                                               % continue only if some data exists
                set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                try
                    % Stack data to one matrix
                    run_index = 1;
                    for i = 1:length(panels)                                    % loop for all panels
                        if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i))))  % check if at least one time series is selected in current panel
                            for j = 1:length(plot_axesL1.(char(panels(i))))                 % compute for all selected channels
                                temp = interp1(time.(char(panels(i))),data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))(j)),eof.ref_time); % interpolate current channel to ref_time
                                eof.chan_list = [eof.chan_list,channels.(char(panels(i)))(plot_axesL1.(char(panels(i)))(j))]; % add current channel name
                                eof.F = horzcat(eof.F,temp);                    % stack columns
                                eof.chan_list_log{run_index} = {sprintf('%s channel %2d',char(panels(i)),plot_axesL1.(char(panels(i)))(j))};
                                clear temp                                      % Clear variable before use data for next column
                                run_index = run_index + 1;
                            end
                        end
                    end
                    % Compute correlation
                    eof.F(isnan(sum(eof.F,2)),:) = [];                          % remove NaNs: whole rows where at leas one value is NaN (=>sum of [1 2 NaN] = NaN)
                    [r_pers,p] = corrcoef(eof.F);                               % correlation matrix and p values
                    r_boots = bootstrp(1000,@corrcoef,eof.F);                   % bootstrapping. By default, use 1000 as number of bootsraps. Call the corrcoef function using newly created matrix eof.F 
                    t.estim = r_pers.*sqrt((size(eof.F,1)-2)./(1-r_pers.^2));   % estimated t value
                    t.crit = tinv(0.95,size(eof.F,1)-2);                        % critical t value
                    mversion = version;                                         % get matlab version. New Matlab version (8.4 uses different interpreter switch, see below)
                    mversion = str2double(mversion(1:3));                       % to numeric: >= operation will be performed on 'mversion'
                    % Show correlation matrix
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation matrix'); % open new figure so results are not plotted to plotgrav GUI
                    imagesc(r_pers);                                            % Plot correlation matrix
                    r = find(isnan(r_pers) | isinf(r_pers));                    % Check if NaNs or Inf values in the correlation matrix exist
                    if ~isempty(r)                                              % If so, sen a warning message to title
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                     % set axis and view
                    colorbar;                                                   % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',font_size);                                  % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    % Show p value matrix
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation p value (close to 0 => significant corr.)'); % open new figure so results are not plotted to plotgrav GUI
                    imagesc(p);                                                 % Plot p value
                    r = find(isnan(p) | isinf(p));                              % Check if NaNs or Inf values in the correlation matrix exist
                    if ~isempty(r)                                              % If so, sen a warning message to title
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                     % set axis and view
                    colorbar;                                                   % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',font_size);                                  % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    % Show t test value matrix
                    figure('NumberTitle','off','Menu','none',...                % open new figure so results are not plotted to plotgrav GUI
                        'Name','plotGrav: correlation t test (>0 =>reject that there is no corr. (95%))');
                    imagesc(t.estim-t.crit);                                    % plot t test difference 
                    r = find(isnan(t.estim-t.crit) | isinf(t.estim-t.crit));    % Check if NaNs or Inf values in the correlation matrix exist
                    if ~isempty(r)                                              % If so, sen a warning message to title
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                     % set axis and view
                    colorbar;                                                   % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',font_size);                                  % font size
                    if mversion>=8.4                                            % Adjust the plot for newer matlab version
                        set(gca,'TickLabelInterpreter','none');
                    end
                    % Show bootsrap results: In this case, the bootsrap
                    % result for each pair will be plotted into a histogram.
                    % These histograms will be in ONE figure (using subplot
                    % function)
                    figure('NumberTitle','off','Menu','none',...                % open new figure so results are not plotted to plotgrav GUI
                        'Name','plotGrav: correlation bootstrap histograms');
                    si = 1;                                                     % subplot index
                    eof.chan_list_log
                    for i = 1:size(r_pers,1)                                    % for each row     
                        % Write results to logfile
                        if i > 1 % do not output autocorrelation
                            otime = datevec(now); % current time for logfile
                            x1time = datevec(selected_x(1)); % first selected point
                            x2time = datevec(selected_x(2)); % first selected point
                            fprintf(fid,'Simple correlation analysis between %04d/%02d/%02d %02d:%02d:%03.1f - %04d/%02d/%02d %02d:%02d:%03.1f: %s  vs  %s = %7.5f, t_est = %7.4f, t_crit = %7.4f, p_val = %7.4f (%04d/%02d/%02d %02d:%02d)\n',...
                                x1time(1),x1time(2),x1time(3),x1time(4),x1time(5),x1time(6),...
                                x2time(1),x2time(2),x2time(3),x2time(4),x2time(5),x2time(6),...
                                char(eof.chan_list_log{1}),char(eof.chan_list_log{i}),r_pers(i,1),t.estim(i,1),t.crit,p(i,1),otime(1),otime(2),otime(3),otime(4),otime(5));
                        end
                        for j = 1:size(r_pers,2)                                % For each column
                            subplot(size(r_pers,1),size(r_pers,2),si)           % one subplot per one pair 
                            hist(r_boots(:,si),round(sqrt(1000)));              % show each bootstrap histrogram (1000 = number of bootsraps)
                            title(sprintf('%s - %s',char(eof.chan_list(i)),char(eof.chan_list(j))),'FontSize',font_size-1,'interpreter','none');
                            xlabel('corr.','FontSize',font_size-2);             % Reduce the fontsize. One plot may contain too many subplots!
                            set(gca,'FontSize',font_size-2);
                            si = si + 1;                                        % next subplot index
                        end
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Correlation computed.');drawnow % status
                catch error_message
                    otime = datevec(now);
                    fprintf(fid,'Correlation not computed. Error %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),otime(1),otime(2),otime(3),otime(4),otime(5));
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Correlation not computed.');drawnow % status
                end
            else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end
			
		case 'correlation_cross'
            %% Cross-Correlation
            % User can compute cross-correlation between two time series.
            % This option was designed to estimate iGrav's phase delay.
            % Nevertheless, it can be used for all panels. Such option
            % however, required interpolation. By default, data is
            % interpolated to iGrav time vecor. If iGrav not laoded, use
            % TRiLOGi, if TRiLOGi not loaded...

            % First, get all required data
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data
            time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
            
            % Find selected channels
            panels = {'data_a','data_b','data_c','data_d'};                 % will be used to simplify the code: run a for loop for all panels  
            for i = 1:length(panels)
                data_table.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data'); 
                plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
            end
            
            if ~isempty(data)                                               % continue only if data loaded
                try
					check = [plot_axesL1.data_a plot_axesL1.data_b plot_axesL1.data_c plot_axesL1.data_d]; % get number of all selected channels (e.g., [2 [] 3] = [2 3] = only two selected)
					if numel(check) ~= 2                    
						set(findobj('Tag','plotGrav_text_status'),'String','You can select only two channels (L1)...');drawnow % status
                    else
                        % Open logfile
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        % Get parameters related to maximim possible lag from user
                        if nargin == 1
                            set(findobj('Tag','plotGrav_text_status'),'String','Set maximum lag (in seconds, e.g. 20)');drawnow % send instructions to status bar
                            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','20');  % make input text visible + set default value
                            set(findobj('Tag','plotGrav_text_input'),'Visible','on'); 
                            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                        else
                            set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                        end
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off afterwards
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        set(findobj('Tag','plotGrav_text_status'),'String','Cross-correlation computing...');drawnow % status
                        max_lag = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                        max_lag = str2double(max_lag);                      % Convert to double (will be used with mathematical operations)
                        reg_mat = [];                                       % prepare variable for computation. This matrix will contain two time series used for cross-correlation
                        j = 1;                                              % column of reg_mat
                        channel_name = [];
						% Run loop for all panels and selected channels
                        for p = 1:length(panels)                            % i and j indices are reserved for other loops
                            if ~isempty(plot_axesL1.(char(panels(p)))) && ~isempty(data.(char(panels(p)))) % only if some channel selected
                                for i = 1:length(plot_axesL1.(char(panels(p)))) % Run loop for all selected chennels (max 2)
                                    if ~exist('ref_time','var')             % create ref. time vector if not already created (priority: iGrav -> TRiLOGi -> Other1 -> Other2)
                                        ref_time = time.(char(panels(p)));
                                    end
                                    reg_mat(:,j) = interp1(time.(char(panels(p))),data.(char(panels(p)))(:,plot_axesL1.(char(panels(p)))(i)),ref_time); % interpolate current channel to ref_time
                                    channel_name{j} = sprintf('%s %2d',char(panels(p)),plot_axesL1.(char(panels(p)))(i)); % store current chanel name (panel + number)
                                    j = j + 1;                              % next column
                                    
                                end
                            end
                        end  
                        % Depending on the maximim posible lag, switch
                        % between steps = shift of one time series with
                        % respect to the other. step = 1 => the time series
                        % will be shifte one element after another. step =
                        % 10 means than 9 elements will be skipped.
                        % The reason for this is the reduction of
                        % computation time. Shifting and computing time
                        % series more than 5000 may take hours.
                        if max_lag <500
                            step = 1;
                        elseif max_lag > 500 && max_lag<5000
                            step = 10;
                        else
                            step = 60;
                        end
                        lag = -max_lag:step:max_lag;
                        % Compute cross-correlation for all possible lags
                        corr_out = lag.*0;                                  % declare a variable. This variable will store the correlation coefficients
                        j = 1;                                              % index of corr_out matrix. Cannot be 'i' as i will be negative
                        for i = -max_lag:step:max_lag                       % Run for all lags (same as 'lag' variable)
                            x1 = reg_mat(:,1);                              % x1 is static time series                    
                            x2 = interp1(ref_time+i/86400,reg_mat(:,2),ref_time); % x2 will be shifted in each loop run. i/86400 = convert seconds to days (matlab datenum format)
                            r = find(isnan(x1+x2));                         % find NaNs
                            if ~isempty(r)                                  % Remove NaNs (necesary for correlation analysis)
                                x1(r) = [];
                                x2(r) = [];
                            end
                            temp = corrcoef(x1,x2);                         % Compute correlation
                            corr_out(j) = temp(1,2);                        % store the correlation coefficient (stantard corrcoef output is a matrix)
                            j = j + 1;                                      % increase the index
                            set(findobj('Tag','plotGrav_text_status'),'String',sprintf('Cross-correlation computing...(%3.0f%%)',(j/length(lag))*100));drawnow % status
                        end
                        % Plot results
                        figure('Name','plotGrav: cross-correlation');       % open new figure. Do not plot into GUI. Keep menu and toolbars ON so user can save and modify the plot.
                        nlag = -max_lag:step/50:max_lag;
                        ncor = interp1(lag,corr_out,nlag,'spline'); % refine the plot = insert a spline curve between the compution points/lags.
                        plot(nlag,ncor,'k-',lag,corr_out,'r.')
                        l = legend('fitted spline','computation points');
                        set(l,'FontSize',font_size);set(gca,'FontSize',font_size); % set font size
                        xlabel('lag (seconds)','FontSize',font_size);
                        set(findobj('Tag','plotGrav_text_status'),'String','Cross-correlation has been computed.');drawnow % status
                        % Write results to logfile
                        otime = datevec(now); % current time for logfile
                        fprintf(fid,'Cross-correlation analysis %s  vs  %s: max corr = %8.6f at %4.2f seconds, min corr = %8.6f at %4.2f seconds. Maximum lag = %3.1f (%04d/%02d/%02d %02d:%02d)\n',...
                            char(channel_name{1}),char(channel_name{2}),max(max(ncor)),max(nlag(ncor==max(ncor))),min(min(ncor)),max(nlag(ncor==min(ncor))),... % use max(max()) to avoid multiple outputs
                            max_lag,otime(1),otime(2),otime(3),otime(4),otime(5));
					end
                catch error_message
					set(findobj('Tag','plotGrav_text_status'),'String','Could not compute Cross-correlation.');drawnow % status
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % make sure is OFF in case some error occurred
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                    otime = datevec(now); % current time for logfile
                    fprintf(fid,'Cross-correlation not computed. Error %s (%04d/%02d/%02d %02d:%02d)\n',...
                        char(error_message.message),otime(1),otime(2),otime(3),otime(4),otime(5));
                    fclose(fid);
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
            end

		case 'regression_simple'
            %% Simple regression analysis
            % User can perform a regression analysis between two time
            % series. This option was designed to estimate iGrav's 
            % calibration coefficient. Nevertheless, it can be used for all 
            % panels. By default, data is interpolated to iGrav time vecor. 
            % If iGrav not laoded, use TRiLOGi, if TRiLOGi not loaded...
            
            % First load all required inputs
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
            panels = {'data_a','data_b','data_c','data_d'};  
            % Get all channel names, units and data tables + find selected channels
            for i = 1:length(panels)
                 % Get units. Will be used for output/plot
                units.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_text_%s',panels{i})),'UserData');
                % get channels names. Will be used for output/plot
                channels.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{i})),'UserData');
                % Get UI tables
                data_table.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data'); 
            end
            % continue only if data loaded
            if ~isempty(data.data_a)                                         
                % Open logfile
                try
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                catch
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Get user input
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set expression (space separated)');drawnow % send instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','A2 = A3 + B1 * B1 + T + 1'); % Show editable field
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn off
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                st0 = get(findobj('Tag','plotGrav_edit_text_input'),'String');   % get string
                st = strsplit(st0,' ');                                     % split string. Strings must be separated sith space!!

                % First, check if the statement contains '=' character. '=' must be the
                % second character!
                try
                    if strcmp(char(st{2}),'=') 
                        % Use the left-hand side to get the vector and reference time, 
                        % i.e. used for interpolation (in case statement contains 
                        % different time series, e.g., iGrav + data_b)
                        switch char(st{1}(1))
                            case 'A'
                                % ref_time stores the reference time vector
                                ref_time = time.data_a; 
                                % Response vector. 
                                y = data.data_a(:,str2double(st{1}(2:end)));
                                panel = 'data_a';
                            case 'B'
                                ref_time = time.data_b;
                                y = data.data_b(:,str2double(st{1}(2:end)));
                                panel = 'data_b';
                            case 'C'
                                ref_time = time.data_c;
                                y = data.data_c(:,str2double(st{1}(2:end)));
                                panel = 'data_c';
                            case 'D'
                                ref_time = time.data_d;
                                y = data.data_d(:,str2double(st{1}(2:end)));
                                panel = 'data_d';
                        end

                        % Declare variable for the next loop. The temp_matrix is the 
                        % matrix for the (multiple) linear regression, i.e., it 
                        % will store all vectors on the right-hand side = predictors.
                        % mult is used to change the sign. i is the starting index
                        % of the input expression (first is the left-hand side, second
                        % is '=' and the right-hand side starts with index 3.
                        temp_matrix = []; 
                        mult = 1;
                        i = 3;
                        % Run loop for each string/character of the expression.
                        while i <= length(st)
                            switch char(st{i}(1))
                                case 'A' % = iGrav
                                    % Use interp1 to ensure all input vectors have the
                                    % same length.
                                    temp_matrix = horzcat(temp_matrix,mult*interp1(time.data_a,data.data_a(:,str2double(st{i}(2:end))),ref_time));
                                    i = i + 1;
                                case 'B' % = TRiLOGi
                                    temp_matrix = horzcat(temp_matrix,mult*interp1(time.data_b,data.data_b(:,str2double(st{i}(2:end))),ref_time));
                                    i = i + 1;
                                case 'C' % = Other1
                                    temp_matrix = horzcat(temp_matrix,mult*interp1(time.data_c,data.data_c(:,str2double(st{i}(2:end))),ref_time));
                                    i = i + 1;
                                case 'D' % = Other2
                                    temp_matrix = horzcat(temp_matrix,mult*interp1(time.data_d,data.data_d(:,str2double(st{i}(2:end))),ref_time));
                                    i = i + 1;
                                case 't' % = time vector, e.g., for drift estimation
                                    % For 't', subtract mean to improve
                                    % nmerical sability = small condition
                                    % number.
                                    temp_matrix = horzcat(temp_matrix,mult*(ref_time - mean(ref_time)));
                                    i = i + 1;
                                case 'T'
                                    % Just like 't' but without average
                                    % value subtraction. A quadratic fit
                                    % could result in a large condiction
                                    % number, i.e., nearly singlular
                                    % temp_matrix!
                                    temp_matrix = horzcat(temp_matrix,mult*ref_time);
                                    i = i + 1;
                                case '+'
                                    mult = 1;
                                    i = i + 1;
                                case '-'
                                    mult = -1;
                                    i = i + 1;
                                case '*' % = this will automatically read the next string (i+1) and use it for multiplication
                                    switch char(st{i+1}(1))
                                        case 'A' % Again switch between Panels or Time vector and multiplie with the previos vector (now as column end)
                                            temp_matrix(:,end) = mult*temp_matrix(:,end).*interp1(time.data_a,data.data_a(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 'B'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end).*interp1(time.data_b,data.data_b(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 'C'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end).*interp1(time.data_c,data.data_c(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 'D'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end).*interp1(time.data_d,data.data_d(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 't'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end).*(ref_time - mean(ref_time));
                                        case 'T'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end).*ref_time;
                                        otherwise % = constants
                                            if ~isnan(str2double(st{i}(:)))
                                                temp_matrix = mult*temp_matrix(:,end).*ones(length(ref_time),1)*str2double(st{i+1}(:));
                                            end
                                    end
                                    i = i + 2; % Add 2 as we have used the i+1 index for the multiplication
                                case '/'
                                    switch char(st{i+1}(1))
                                        case 'A'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end)./interp1(time.data_a,data.data_a(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 'B'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end)./interp1(time.data_b,data.data_b(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 'C'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end)./interp1(time.data_c,data.data_c(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 'D'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end)./interp1(time.data_d,data.data_d(:,str2double(st{i+1}(2:end))),ref_time);
                                        case 't'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end)./(ref_time - mean(ref_time));
                                        case 'T'
                                            temp_matrix(:,end) = mult*temp_matrix(:,end)./ref_time;
                                        otherwise
                                            if ~isnan(str2double(st{i}(:)))
                                                temp_matrix = mult*temp_matrix(:,end)./ones(length(ref_time),1)*str2double(st{i+1}(:));
                                            end
                                    end
                                    i = i + 2;
                                otherwise
                                    % Append numberic values if given
                                    if ~isnan(str2double(st{i}(:)))
                                        temp_matrix = horzcat(temp_matrix,mult*ones(length(ref_time),1)*str2double(st{i}(:)));
                                        i = i + 1;
                                    end
                            end
                        end

                        % Compute the multiple linear regression using Matlab build in
                        % regression function. It is not necesary to remove NaNs as the
                        % function ingores them.
                        [out_par,out_par_sig,resid,~,~] = regress(y,temp_matrix);
                        out_par_sig = (out_par_sig(:,2)-out_par_sig(:,1))./4; % /4 as the regress function returns the interval for 95% == 2*sigma
                        
                        % Compute the fit, regress returns only output parameters and
                        % residuals, no fit.
                        out_fit = 0;
                        for i = 1:length(out_par)
                            out_fit = out_fit + temp_matrix(:,i)*out_par(i);
                        end

%                         % Plot the results
%                         date_format = get(findobj('Tag','plotGrav_menu_date_format'),'UserData'); % get current date format (to show it to user)
%                         font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
%                         figure('Name','plotGrav: regression analysis','Units','Normalized',...
%                             'PaperPositionMode','auto','Position',[0.25 0.3 0.5 0.4]); % open new figure. Do not plot into GUI. Keep menu and toolbars ON so user can save and modify the plot. 
%                         subplot(2,1,1)
%                         plot(ref_time,y,'k-',ref_time,out_fit,'r-'); 
%                         l = legend('Input','Fit');
%                         set(l,'FontSize',font_size);set(gca,'FontSize',font_size)
%                         datetick(gca,'x',date_format,'keepticks'); 
%                         subplot(2,1,2)
%                         plot(ref_time,resid,'k-'); 
%                         legend('Residuals');
%                         set(l,'FontSize',font_size);set(gca,'FontSize',font_size)
%                         datetick(gca,'x',date_format,'keepticks');

                        % Append the results using the specific panel name
                        column_num = size(data.(panel),2) + 1;
                        data.(panel)(:,column_num) = out_fit; % append fit to data matrix
                        data.(panel)(:,column_num+1) = resid; % append residuals to data matrix
                        units.(panel)(column_num) = {char(units.(panel)(str2double(st{1}(2:end))))}; % add fit units. The same as input.
                        units.(panel)(column_num+1) = {char(units.(panel)(str2double(st{1}(2:end))))}; % add resid units. The same as input.
                        channels.(panel)(column_num) = {[channels.(panel){str2double(st{1}(2:end))},'_RegFit']}; % add fit name. The same as input + RegFit suffix.
                        channels.(panel)(column_num+1) = {[channels.(panel){str2double(st{1}(2:end))},'_RegRes']}; % add residuals name. The same as input + RegFit suffix.
                        data_table.(panel)(column_num,1:7) = {false,false,false,...        % add fit to ui-table
                                                    sprintf('[%2d] %s (%s)',column_num,char(channels.(panel){column_num}),char(units.(panel){column_num})),...
                                                        false,false,false};
                        data_table.(panel)(column_num+1,1:7) = {false,false,false,...        % add residuals to ui-table
                                                    sprintf('[%2d] %s (%s)',column_num+1,char(channels.(panel){column_num+1}),char(units.(panel){column_num+1})),...
                                                        false,false,false};
                        % Write the results to log-file
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'%s channel %2d = Regression fit: ',panel,column_num);
                        for i = 1:length(out_par)
                            fprintf(fid,' %.6f +/- %.6f,',out_par(i),out_par_sig(i)); 
                        end
                        fprintf(fid,' (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        fprintf(fid,'%s channel %2d = Regression residuals input expression %s (%04d/%02d/%02d %02d:%02d)\n',panel,column_num+1,st0,ty,tm,td,th,tmm); 

                        % Store the results
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                        set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a);
                        set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a);
                        set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a);
                        set(findobj('Tag','plotGrav_text_data_b'),'UserData',units.data_b);
                        set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels.data_b);
                        set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.data_b);
                        set(findobj('Tag','plotGrav_text_data_c'),'UserData',units.data_c);
                        set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels.data_c);
                        set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.data_c);
                        set(findobj('Tag','plotGrav_text_data_d'),'UserData',units.data_d);
                        set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels.data_d);
                        set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.data_d);
                        % Close the log-file
                        fclose(fid);
                        % Send message to command line
                        set(findobj('Tag','plotGrav_text_status'),'String','The regression analysis results have been appended.');drawnow % message
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','The expression must contain = character.');drawnow % message
                    end
                catch error_message
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not evaluate the expression.');drawnow % message
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Expression evaluation error: %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),ty,tm,td,th,tmm);
                    fclose(fid);
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load iGrav data first.');drawnow % message
            end
		case 'simple_algebra'
			%% ALGEBRA
            % User can add, subract, multiply and divide channels and store
            % the results. These operations can be performed using
            % arbitrary panel/channel.
            % Supported statements/expressions:
            %   A1 = A2 + B3 + B4 * 3
            %   Delimiter = ' ', allowed operators:+-*/, no brackets. Each statement
            %   must contain at least one channel. The statement must begin with a
            %   channel, followed by ' = '. The operators have always even indices,
            %   [2:2:end]. Channels and numbers have odd indices. To use
            %   negative values of a certain channel, use *-1, e.g., A1
            %   = A2 * -1. The A symbols stands for iGrav, B for data_b, C
            %   for Other1 and D for Other2.
            
            % First load all required inputs
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); 
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); 
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
            units.data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');         % get iGrav units
            channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData'); % get iGrav channels (names)
            units.data_b = get(findobj('Tag','plotGrav_text_data_b'),'UserData');         
            channels.data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); 
            units.data_c = get(findobj('Tag','plotGrav_text_data_c'),'UserData');         
            channels.data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData'); 
            units.data_d = get(findobj('Tag','plotGrav_text_data_d'),'UserData');         
            channels.data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData'); 
            if ~isempty(data.data_a)                                         % continue only if data loaded
                % Open logfile
                try
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                catch
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
				% Get user input
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set expression (space separated)');drawnow % send instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','A2 = A3 + B1 * 3'); % Show editable field
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn off
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                st0 = get(findobj('Tag','plotGrav_edit_text_input'),'String');   % get string
                st = strsplit(st0,' ');                                     % split string. Strings must be separated sith space!!

                % First, check if the statement contains '=' character. '=' must be the
                % second character!
                try
                    if strcmp(char(st{2}),'=') 
                        % Use the left-hand side to get reference time, i.e. used for
                        % interpolation (in case statement contains different time series,
                        % e.g., iGrav + data_b)
                        switch char(st{1}(1))
                            case 'A'
                                % ref_time stores the reference time vector
                                ref_time = time.data_a;
                            case 'B'
                                ref_time = time.data_b;
                            case 'C'
                                ref_time = time.data_c;
                            case 'D'
                                ref_time = time.data_d;
                        end
                        % Continue with the statement on the right-hand side. The left side, i.e.
                        % output channel will be used later. The temp_matrix will (temporarily)
                        % store all affected/given channels. 
                        temp_matrix = []; 
                        % Append all given channels to the temp_matrix
                        for i = 3:length(st) % analyse the statement one string after another
                            % Append loaded channels
                            switch char(st{i}(1))
                                case 'A'
                                    temp_matrix = horzcat(temp_matrix,interp1(time.data_a,data.data_a(:,str2double(st{i}(2:end))),ref_time));
                                case 'B'
                                    temp_matrix = horzcat(temp_matrix,interp1(time.data_b,data.data_b(:,str2double(st{i}(2:end))),ref_time));
                                case 'C'
                                    temp_matrix = horzcat(temp_matrix,interp1(time.data_c,data.data_c(:,str2double(st{i}(2:end))),ref_time));
                                case 'D'
                                    temp_matrix = horzcat(temp_matrix,interp1(time.data_d,data.data_d(:,str2double(st{i}(2:end))),ref_time));
                            end
                            % Append numberic values if given
                            if ~isnan(str2double(st{i}(:)))
                                temp_matrix = horzcat(temp_matrix,ones(length(ref_time),1)*str2double(st{i}(:)));
                            end
                        end
                        % Create a command for the expression evaluation.
                        command = []; % command will be used to evaluate the mathematical expression
                        j = 1; % will be used to count temp_matrix columns. The i index used in the following loop does not correspond to temp_matrix columns!
                        for i = 3:length(st)
                            if mod(i,2) % operators must have even indices!
                                command = [command,sprintf('temp_matrix(:,%d)',j)];
                                j = j + 1;
                            else
                                % Switch between math. operators. The main reason is the
                                % multiplication od dividing element-wise, i.e., using '.*' or
                                % './'
                                switch char(st{i}(1))
                                    case '*'
                                        command = [command,'.',char(st{i}(1))];
                                    case '/'
                                        command = [command,'.',char(st{i}(1))];
                                    otherwise
                                        command = [command,char(st{i}(1))];
                                end
                            end
                        end

                        % Update the required column depending on the left-hand side expression
                        switch char(st{1}(1))
                            case 'A'
                                data.data_a(:,str2double(st{1}(2:end))) = eval(command); % Evaluate the command/expression
                                units.data_a(str2double(st{1}(2:end))) = {'?'}; % change/add units. By defauld, no unit
                                channels.data_a(str2double(st{1}(2:end))) = {sprintf('%s',[st{3:end}])}; % change the channel name
                                data_table.data_a(str2double(st{1}(2:end)),1:7) = {false,false,false,...        % add to ui-table
															sprintf('[%2d] %s (?)',str2double(st{1}(2:end)),[st{3:end}]),...
																false,false,false};
                                % Store the results
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                                set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a);
                                set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a);
                                set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a);
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav channel %2d: %s (%04d/%02d/%02d %02d:%02d)\n',str2double(st{1}(2:end)),st0,ty,tm,td,th,tmm);
                            case 'B'
                                data.data_b(:,str2double(st{1}(2:end))) = eval(command); % Evaluate the command/expression
                                units.data_b(str2double(st{1}(2:end))) = {'?'};
                                channels.data_b(str2double(st{1}(2:end))) = {sprintf('%s',[st{3:end}])}; % change the channel name
                                data_table.data_b(str2double(st{1}(2:end)),1:7) = {false,false,false,...        % add to ui-table
															sprintf('[%2d] %s (?)',str2double(st{1}(2:end)),[st{3:end}]),...
																false,false,false};
                                % Store the results
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                                set(findobj('Tag','plotGrav_text_data_b'),'UserData',units.data_b);
                                set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels.data_b);
                                set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.data_b);
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Trilogi channel %2d: %s (%04d/%02d/%02d %02d:%02d)\n',str2double(st{1}(2:end)),st0,ty,tm,td,th,tmm);
                            case 'C'
                                data.data_c(:,str2double(st{1}(2:end))) = eval(command); % Evaluate the command/expression
                                units.data_c(str2double(st{1}(2:end))) = {'?'};
                                channels.data_c(str2double(st{1}(2:end))) = {sprintf('%s',[st{3:end}])}; % change the channel name
                                data_table.data_c(str2double(st{1}(2:end)),1:7) = {false,false,false,...        % add to ui-table
															sprintf('[%2d] %s (?)',str2double(st{1}(2:end)),[st{3:end}]),...
																false,false,false};
                                % Store the results
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                                set(findobj('Tag','plotGrav_text_data_c'),'UserData',units.data_c);
                                set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels.data_c);
                                set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.data_c);
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Other1 channel %2d: %s (%04d/%02d/%02d %02d:%02d)\n',str2double(st{1}(2:end)),st0,ty,tm,td,th,tmm);
                            case 'D'
                                data.data_d(:,str2double(st{1}(2:end))) = eval(command); % Evaluate the command/expression
                                units.data_d(str2double(st{1}(2:end))) = {'?'};
                                channels.data_d(str2double(st{1}(2:end))) = {sprintf('%s',[st{3:end}])}; % change the channel name
                                data_table.data_d(str2double(st{1}(2:end)),1:7) = {false,false,false,...        % add to ui-table
															sprintf('[%2d] %s (?)',str2double(st{1}(2:end)),[st{3:end}]),...
																false,false,false};
                                % Store the results
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
                                set(findobj('Tag','plotGrav_text_data_d'),'UserData',units.data_d);
                                set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels.data_d);
                                set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.data_d);
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Other2 channel %2d: %s (%04d/%02d/%02d %02d:%02d)\n',str2double(st{1}(2:end)),st0,ty,tm,td,th,tmm);
                        end
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','The expression has been evaluated.');drawnow % message
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','The expression must contain = character.');drawnow % message
                    end
                catch error_message
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not evaluate the expression.');drawnow % message
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Expression evaluation error: %s (%04d/%02d/%02d %02d:%02d)\n',char(error_message.message),ty,tm,td,th,tmm);
                    fclose(fid);
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load iGrav data first.');drawnow % message
            end
            
		case 'remove_interval_selected'
			%% Remove Selected time interval
            % Especialy with respect to anomalous time variations, user can
            % remove a time interval by selecting it interactively. Such
            % selection will set all values of currenlty plotted (L1) time
            % series to NaN. Only this (one) channel will be affected. 
            % This operation works with all panels. 
            % The removal of anomalous time intervals via correction file is
            % coded in section 'correction_file'.
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
                
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % remove only if loaded
                % Open logfile (to document removed time interval)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(panels{i}) = find(cell2mat(data_table.(panels{i})(:,1))==1); % get selected channels (L1) for each panel
                end
				
				if isempty([plot_axesL1.data_a,plot_axesL1.data_b,plot_axesL1.data_c,plot_axesL1.data_d]) % continue only if at least one channel selected
					set(findobj('Tag','plotGrav_text_status'),'String','Select one channel (L1).');drawnow % status
				elseif length([plot_axesL1.data_a,plot_axesL1.data_b,plot_axesL1.data_c,plot_axesL1.data_d]) > 1 % continue if exactly one channel selected (otherwise not clear which channel should be affected)
					set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1.');drawnow % status
                else
                    % Get input from user
                    try
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % send instruction to status bar
                        [selected_x1,~] = ginput(1);                        % first/starting point
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % send instruction to status bar
                        [selected_x2,~] = ginput(1);                        % second/ending point
                        selected_x = sort([selected_x1,selected_x2]);       % sort = ascending (in case second is first and the other way around)
                        % Remove interval
                        for i = 1:length(panels)                            % run loop for all panels
                            if ~isempty(plot_axesL1.(panels{i})) && ~isempty(data.(panels{i}))
                                temp = data.(panels{i})(:,plot_axesL1.(panels{i})); % get selected channel and copy the values to temporary variable
                                r = find(time.(panels{i})>selected_x(1) & time.(panels{i})<selected_x(2)); % find points within the selected interval
                                if ~isempty(r)                              % continue only if some points have been found
                                    temp(r) = NaN;                          % remove the points
                                    data.(panels{i})(:,plot_axesL1.(panels{i})) = temp; % update data
                                end
                                clear temp r
                                % Write to logfile
                                [ty,tm,td,th,tmm] = datevec(now);           % current time (to document when has the removal been caried out)
                                [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1); % first/starting point date and time
                                [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2); % second/ending point date and time
                                fprintf(fid,'%s channel %d time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                    panels{i},plot_axesL1.(panels{i}),ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                            end
                        end
                        % Store the updated data
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store the updated table
                        plotGrav('uitable_push')                            % re-plot to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Selected time interval has been removed.');drawnow % status
                    catch
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Could not remove selected time interval.');drawnow % status
                    end
				end
            end
            
            
		case 'interpolate_interval_linear'
			%% Replace selected time interval with interpolated values
            % Especialy with respect to anomalous time variations, user can
            % replace a time interval by selecting it interactively. Such
            % selection will set all values of currenlty plotted (L1) time
            % series to values obtaines using linear interpolation between
            % selected points. Only this (one) channel will be affected. 
            % This operation works with all panels. 
            % The removal of anomalous time intervals via correction file is
            % coded in section 'correction_file'.
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
                
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % proceed only if loaded
                % Open logfile (to document interpolated time intervals)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                end
				
				if isempty([plot_axesL1.data_a,plot_axesL1.data_b,plot_axesL1.data_c,plot_axesL1.data_d]) % continue only if at least one channel selected
					set(findobj('Tag','plotGrav_text_status'),'String','Select one channel (L1).');drawnow % status
                    fclose(fid);                                            % close logfile
				elseif length([plot_axesL1.data_a,plot_axesL1.data_b,plot_axesL1.data_c,plot_axesL1.data_d]) > 1 % continue if exactly one channel selected (otherwise not clear which channel should be affected)
					set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1.');drawnow % status
                    fclose(fid);                                            % close logfile
                else
                    % Get input from user
                    try
                        % Get User input
                        if nargin == 1
                            set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % send instruction to status bar
                            [x1,~] = ginput(1);                                 % first/starting point
                            set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % send instruction to status bar
                            [x2,~] = ginput(1);                                 % second/ending point. 
                        else
                            x1 = datenum(varargin{1},'yyyy mm dd HH MM SS');
                            x2 = datenum(varargin{2},'yyyy mm dd HH MM SS');
                        end
                        % Interpolate interval
                        for i = 1:length(panels)                            % run loop for all panels
                            if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i)))) % check if current panel selected and data loaded
                                r = find(time.(char(panels(i)))>x1 & time.(char(panels(i)))<x2); % find points within the selected interval. 
                                if ~isempty(r)                              % continue only if some points have been found
                                    ytemp = data.(char(panels(i)))(time.(char(panels(i)))<x1 | time.(char(panels(i)))>x2,plot_axesL1.(char(panels(i)))); % copy the affected channel to temporary variable. Directly remove the values within the interval. Will be used for interpolation. 
                                    xtemp = time.(char(panels(i)))(time.(char(panels(i)))<x1 | time.(char(panels(i)))>x2); % get selected time interval 
                                    data.(char(panels(i)))(r,plot_axesL1.(char(panels(i)))) = interp1(xtemp,ytemp,time.(char(panels(i)))(r),'linear'); % Interpolate values for the affected interval only (use r as index)
                                    % Write to logfile
                                    [ty,tm,td,th,tmm] = datevec(now);           % current time (to document when has the removal been caried out)
                                    [ty1,tm1,td1,th1,tmm1,ts1] = datevec(x1); % first/starting point date and time
                                    [ty2,tm2,td2,th2,tmm2,ts2] = datevec(x2); % second/ending point date and time
                                    fprintf(fid,'%s channel %d time interval interpolated linearly: Start = %04d/%02d/%02d %02d:%02d:%02.0f, Stop = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                        char(panels(i)),plot_axesL1.(char(panels(i))),ty1,tm1,td1,th1,tmm1,ts1,...
                                        ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                                end
                            end
                        end
                        % Store the updated data
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store the updated table
                        plotGrav('uitable_push')                            % re-plot to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Selected time interval has been interpolated.');drawnow % status
                    catch
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Could not interpolated selected time interval.');drawnow % status
                    end
				end
            end
        case 'interpolate_interval_auto'
            %% Remove missing data using automatic search algorithm
            % User can replace the missing data, i.e., NaNs (not missing
            % time epochs!) provided valid values are found within a
            % user-defined time interval. For example, user set on input 10
            % seconds, then this function finds first all NaNs and then
            % seeks valid values within +/-10 seconds from each NaN and
            % replace the n-th NaN with interpolated value. This is done
            % for one selected channel.
            
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
                
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % proceed only if loaded
                % Open logfile (to document interpolated time intervals)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                end
                
				% Get User input
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set maximum missing interval (in seconds)');drawnow % send instructions to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','10'); % Show editable field + set default value
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                threshold = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get string
                threshold = str2double(threshold)/86400;                    % Convert to time in days
                
                if isempty([plot_axesL1.data_a;plot_axesL1.data_b;plot_axesL1.data_c;plot_axesL1.data_d]) % continue only if at least one channel selected
					set(findobj('Tag','plotGrav_text_status'),'String','Select one channel (L1).');drawnow % status
                    fclose(fid);                                            % close logfile
                else
                    % Get input from user
                    try
                        % Interpolate interval
                        for p = 1:length(panels)                            % run loop for all panels
                            for j = 1:length(plot_axesL1.(char(panels(p)))) % run loop for all selected channels
                                if ~isempty(plot_axesL1.(char(panels(p)))) && ~isempty(data.(char(panels(p)))) % check if current panel is selected and data are loaded
                                    r = find(isnan(data.(char(panels(p)))(:,plot_axesL1.(char(panels(p)))(j)))); % find all NaNs in
                                    if ~isempty(r)                              % continue only if at least one NaN has been found.
                                        for i = 1:length(r)
                                            set(findobj('Tag','plotGrav_text_status'),'String',sprintf('Removing NaNs...(%4.1f%%).',i/length(r)*100));drawnow % status
                                            x1 = time.(char(panels(p)))(r(i))-threshold; % set time limits: for current NaN
                                            x2 = time.(char(panels(p)))(r(i))+threshold;
                                            ytemp = data.(char(panels(p)))(time.(char(panels(p)))>= x1 & time.(char(panels(p))) <= x2,plot_axesL1.(char(panels(p)))(j)); % find the affected data
                                            xtemp = time.(char(panels(p)))(time.(char(panels(p))) >= x1 & time.(char(panels(p))) <= x2); % get selected time interval 
                                            % Remove all NaNs from current interval so NaNs adjacent to the
                                            % current one are not preventing the interpolation (it is only
                                            % important that at least two valid values are within the interval,
                                            % one before and one after current NaN)
                                            xtemp(isnan(ytemp)) = [];
                                            ytemp(isnan(ytemp)) = [];
                                            if length(xtemp) >= 2           % at least two data points required
                                                ttime = datevec(time.(char(panels(p)))(r(i)));
                                                fprintf(fid,'%s channel %2d: Replacing missing/NaNs %04d/%02d/%02d %02d:%02d:%02d +/-%5.2f seconds.\n',...
                                                    char(panels(p)),plot_axesL1.(char(panels(p)))(j),ttime(1),ttime(2),ttime(3),ttime(4),ttime(5),ttime(6),threshold*86400);
                                                data.(char(panels(p)))(r(i),plot_axesL1.(char(panels(p)))(j)) = interp1(xtemp,ytemp,time.(char(panels(p)))(r(i)),'linear'); % Interpolate values for the affected interval only (use r as index)
                                                clear xtemp ytemp x1 x2
                                            end
                                        end
                                    else
                                        fprintf(fid,'%s channel %2d: No NaNs found\n',char(panels(p)),plot_axesL1.(char(panels(p)))(j));
                                    end
                                end
                            end
                        end
                        % Store the updated data
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store the updated table
                        plotGrav('uitable_push')                            % re-plot to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Missing data have been interpolated (if present).');drawnow % status
                    catch error_message
                        ltime = datevec(now);
                        fprintf(fid,'An error occurred during the interpolation of missing data: %s (%04d/%02d/%02d %02d:%02d)\n',...
                                char(error_message.message),ltime(1),ltime(2),ltime(3),ltime(4),ltime(5));
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','An error occurred during the interpolation of missing data.');drawnow % status
                    end
                end
            end

		case 'remove_step_selected'
			%% Remove selected step
            % User can remove gravity steps interactively. This section
            % allow user to do so all panels, provided one channel (L1) is
            % selected. Ther removal of step via correction file is
            % described in section 'correction_file'
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
            
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % remove only if loaded
				% Open logfile (to document removed time interval)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                end
				
                if isempty([plot_axesL1.data_a(:)',plot_axesL1.data_b(:)',plot_axesL1.data_c(:)',plot_axesL1.data_d(:)']) % continue only if at least one channel selected
					set(findobj('Tag','plotGrav_text_status'),'String','Select one channel (L1).');drawnow % status
				elseif length([plot_axesL1.data_a(:)',plot_axesL1.data_b(:)',plot_axesL1.data_c(:)',plot_axesL1.data_d(:)']) > 1 % continue if exactly one channel selected (otherwise not clear which channel should be affected)
					set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1.');drawnow % status
                else
                    % Get input from user
                    try
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % send instructions to status bar
                        [selected_x1,selected_y1] = ginput(1);              % get the input: first point = before step (both X and Y values will be used)
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % send instructions to status bar
                        [selected_x2,selected_y2] = ginput(1);              % get the input: second point = after step (both X and Y values will be used)
                        % Remove interval
                        for i = 1:length(panels)                            % run loop for all panels
                            if ~isempty(plot_axesL1.(char(panels(i)))) && ~isempty(data.(char(panels(i))))
                                temp = data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))); % get selected channel and copy it to temporary variable
                                r = find(time.(char(panels(i)))>=selected_x2);          % find points afected by step = all recorded after step = all after second User input
                                if ~isempty(r)                              % continue only if some points have been found
                                    temp(r) = temp(r) - (selected_y2-selected_y1); % remove the step via subtracting the difference of selected Y values
                                    data.(char(panels(i)))(:,plot_axesL1.(char(panels(i)))) = temp; % update the matrix
                                end
                                clear temp r
                                % Write to logfile
                                [ty,tm,td,th,tmm] = datevec(now);           % current time (to document when has the removal been caried out)
                                [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1); % first/starting point date and time
                                [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2); % second/ending point date and time
                                fprintf(fid,'%s step removed for channel %2d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                    char(panels(i)),plot_axesL1.(char(panels(i))),ty1,tm1,td1,th1,tmm1,ts1,selected_y1,...
                                    ty2,tm2,td2,th2,tmm2,ts2,selected_y2,ty,tm,td,th,tmm);
                            end
                        end
                        % Store the updated data
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store the updated table
                        plotGrav('uitable_push')                            % re-plot to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Selected step has been removed.');drawnow % status
                    catch
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Could not remove selected step.');drawnow % status
                    end
                end
            end
				
		case 'remove_Xsd'
			%% Remove Spikes: use SD
            % User can remove time series spikes using simple condition
            % based on standard deviation (SD). All values above user defined
            % multiple of SD will be set to NaN. This can be done for all
            % panels and channels.
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
            
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % proceed only if loaded
				% Open logfile (to document removed time interval)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                end
                % Check how many channels are selected (minimum one)
                if isempty([plot_axesL1.data_a(:)',plot_axesL1.data_b(:)',plot_axesL1.data_c(:)',plot_axesL1.data_d(:)'])
					set(findobj('Tag','plotGrav_text_status'),'String','Select at least one channel');drawnow % status
                else
                    try
                        % Get input from user = SD multiplicator
                        if nargin == 1
                            set(findobj('Tag','plotGrav_text_status'),'String','Set SD multiplicator (data > X *SD=NaN)');drawnow % send instructions to status bar
                            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','3'); % Show editable field + set default value
                            set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                        else
                            set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                        end
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                        sd_mult = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get string
                        sd_mult = str2double(sd_mult);                          % Convert to double precision (will be used for math. operation)
                        % Run loop for all panels and channels
                        for p = 1:length(panels)                            % loop for panels
                            if ~isempty(plot_axesL1.(char(panels(p)))) && ~isempty(data.(char(panels(p)))) % check if some chanel selected and data loaded
                                for i = 1:length(plot_axesL1.(char(panels(p)))) % compute for all selected channels
                                    temp = data.(char(panels(p)))(:,plot_axesL1.(char(panels(p)))(i)); % copy current time series to temporary variable
                                    temp = temp - mean(temp(~isnan(temp))); % subtract mean value not taking NaNs into account (this is necesary as 'temp' will be compared to SD which varies around 0).
                                    r = find(abs(temp)>sd_mult*std(temp(~isnan(temp))));  % find points where SD*multiplicator > observed variations
                                    if ~isempty(r)                          % continue only if some points have been found
                                        data.(char(panels(p)))(r,plot_axesL1.(char(panels(p)))(i)) = NaN; % remove the data>X*SD directly in original data (not necesary to use 'temp' again)
                                    end
                                    clear temp r                            % remove variables used in each loop run
                                    % Write to logfile
                                    [ty,tm,td,th,tmm] = datevec(now);       % time for logfile
                                    fprintf(fid,'%s channel %d spikes > %3.1f * standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                        char(panels(p)),plot_axesL1.(char(panels(p)))(i),sd_mult,ty,tm,td,th,tmm);
                                end	
                            end
                        end
                        % Store updated values
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                        plotGrav('uitable_push');                           % re-plot all to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Spikes removed.');drawnow % status
                    catch error_message
                        if strcmp(error_message.identifier,'MATLAB:license:checkouterror')
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Upps, no matlab licence (Statistics_Toolbox?)');drawnow % message
                        else
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Spikes has not been removed (unknown reason).');drawnow % message
                        end
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % message
            end
        case 'remove_set'
			%% Remove Spikes: set range
            % User can remove time series spikes by setting a range. All
            % values above this range will be set to NaN. This can be done
            % for all panels and channels.
            % The following code is a modification of 'remove_Xsd'
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
            
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % proceed only if loaded
				% Open logfile (to document removed time interval)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                end
                % Check how many channels are selected (minimum one)
                if isempty([plot_axesL1.data_a(:)',plot_axesL1.data_b(:)',plot_axesL1.data_c(:)',plot_axesL1.data_d(:)'])
					set(findobj('Tag','plotGrav_text_status'),'String','Select at least one channel');drawnow % status
                else
                    try
                        % Get input from user = range
                        if nargin == 1
                            set(findobj('Tag','plotGrav_text_status'),'String','Set Y range (e.g., 0 0.5)');drawnow % send instructions to status bar
                            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','0 0.5'); % Show editable field + set default value
                            set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                        else
                            set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                        end
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                        range_set = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get string
                        range_set = str2double(strsplit(range_set,' '));    % Convert to double precision = split and convert. 
                        % Run loop for all panels and channels
                        for p = 1:length(panels)                            % loop for panels
                            if ~isempty(plot_axesL1.(char(panels(p)))) && ~isempty(data.(char(panels(p)))) % check if some chanel selected and data loaded
                                for i = 1:length(plot_axesL1.(char(panels(p)))) % compute for all selected channels
                                    temp = data.(char(panels(p)))(:,plot_axesL1.(char(panels(p)))(i)); % copy current time series to temporary variable
                                    r = find(temp>range_set(2) | temp<range_set(1));  % find points outside of range
                                    if ~isempty(r)                          % continue only if some points have been found
                                        data.(char(panels(p)))(r,plot_axesL1.(char(panels(p)))(i)) = NaN; % remove the data>X*SD directly in original data (not necesary to use 'temp' again)
                                    end
                                    clear temp r                            % remove variables used in each loop run
                                    % Write to logfile
                                    [ty,tm,td,th,tmm] = datevec(now);       % time for logfile
                                    fprintf(fid,'%s channel %d spikes outside %.7g - %.7g removed (%04d/%02d/%02d %02d:%02d)\n',...
                                        char(panels(p)),plot_axesL1.(char(panels(p)))(i),range_set(1),range_set(2),ty,tm,td,th,tmm);
                                end	
                            end
                        end
                        % Store updated values
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                        plotGrav('uitable_push');                           % re-plot all to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Spikes removed.');drawnow % status
                    catch error_message
                        if strcmp(error_message.identifier,'MATLAB:license:checkouterror')
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Upps, no matlab licence (Statistics_Toolbox?)');drawnow % message
                        else
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Spikes has not been removed (unknown reason).');drawnow % message
                        end
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % message
            end
        case 'replace_range_by'
			%% Set all values out of range to selected value
            % Similar to 'remove_set' but values outside the range are
            % replace by values set by user
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data'); % get the iGrav ui-table
            data_table.data_b = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data'); % get the TRiLOGi ui-table
            data_table.data_c = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data'); % get the Other1 ui-table
            data_table.data_d = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data'); % get the Other2 ui-table
            
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % proceed only if loaded
				% Open logfile (to document removed time interval)
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Find all selected channels
                panels = {'data_a','data_b','data_c','data_d'};  
                for i = 1:length(panels)
                    plot_axesL1.(char(panels(i))) = find(cell2mat(data_table.(char(panels(i)))(:,1))==1); % get selected channels (L1) for each panel
                end
                % Check how many channels are selected (minimum one)
                if isempty([plot_axesL1.data_a(:)',plot_axesL1.data_b(:)',plot_axesL1.data_c(:)',plot_axesL1.data_d(:)'])
					set(findobj('Tag','plotGrav_text_status'),'String','Select at least one channel');drawnow % status
                else
                    try
                        % Get input from user = range
                        if nargin == 1
                            set(findobj('Tag','plotGrav_text_status'),'String','Set Y range (e.g., 0 0.5)');drawnow % send instructions to status bar
                            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','0 0.5'); % Show editable field + set default value
                            set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar  
                            range_set = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get string
                            range_set = str2double(strsplit(range_set,' '));    % Convert to double precision = split and convert.
                            set(findobj('Tag','plotGrav_text_status'),'String','Set new value (e.g., 0)');drawnow % send instructions to status bar
                            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','0');  
                            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar  
                            % Get value used to replace value out of range
                            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                            new_value = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get string
                            new_value = str2double(new_value);
                        else
                            set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                            temp = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get string
                            temp = strsplit(temp,';');
                            range_set = str2double(strsplit(temp{1},' '));  % Convert to double precision = split and convert. 
                            new_value = str2double(temp{2});                % Convert to double precision (only one value)
                        end
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                        % Run loop for all panels and channels
                        for p = 1:length(panels)                            % loop for panels
                            if ~isempty(plot_axesL1.(char(panels(p)))) && ~isempty(data.(char(panels(p)))) % check if some chanel selected and data loaded
                                for i = 1:length(plot_axesL1.(char(panels(p)))) % compute for all selected channels
                                    temp = data.(char(panels(p)))(:,plot_axesL1.(char(panels(p)))(i)); % copy current time series to temporary variable
                                    r = find(temp>range_set(2) | temp<range_set(1));  % find points outside of range
                                    if ~isempty(r)                          % continue only if some points have been found
                                        data.(char(panels(p)))(r,plot_axesL1.(char(panels(p)))(i)) = new_value; % remove the data>X*SD directly in original data (not necesary to use 'temp' again)
                                    end
                                    clear temp r                            % remove variables used in each loop run
                                    % Write to logfile
                                    [ty,tm,td,th,tmm] = datevec(now);       % time for logfile
                                    fprintf(fid,'%s channel %d spikes outside %.7g - %.7g set to %.7g (%04d/%02d/%02d %02d:%02d)\n',...
                                        char(panels(p)),plot_axesL1.(char(panels(p)))(i),range_set(1),range_set(2),new_value,ty,tm,td,th,tmm);
                                end	
                            end
                        end
                        % Store updated values
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                        plotGrav('uitable_push');                           % re-plot all to see the changes
                        fclose(fid);                                        % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Spikes removed.');drawnow % status
                    catch error_message
                        if strcmp(error_message.identifier,'MATLAB:license:checkouterror')
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Upps, no matlab licence (Statistics_Toolbox?)');drawnow % message
                        else
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Spikes has not been removed (unknown reason).');drawnow % message
                        end
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % message
            end
		case 'compute_decimate'
			%% Re-interpolated data ALL panels (decimate/resample)
            % This option allows the re-itnerpolation/decimation of all
            % time series loaded in plotGrav. By default, iGrav and SG030
            % time series are decimated after corrections. This is
            % additional resampling option that affects all time series.
            % The time series are resamplted to identical resolution NOT
            % idetical time interval!!! The starting and ending time epoch
            % of each time series stays the same! It is not important
            % which time series are selected, all will be resampled!
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            
            if ~isempty(data.data_a) || ~isempty(data.data_b) || ~isempty(data.data_c) || ~isempty(data.data_d) % proceed only if loaded
                % Open logfile
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Get input from user = time resolution in seconds
                if nargin == 1
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new sampling interval (in seconds)');drawnow % send instructions to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','3600');  % make input text visible + set default value, in this case 1 hour (=3600 seconds)
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % 
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
				set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off editable fields
				set(findobj('Tag','plotGrav_text_input'),'Visible','off');
				resol = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                resol = str2double(resol);                                  % convert to double (from string)
				try
                    set(findobj('Tag','plotGrav_text_status'),'String','Starting interpolation...');drawnow % status
                    % Run for all panels
                    panels = {'data_a','data_b','data_c','data_d'};  
                    for p = 1:length(panels)    
                        if ~isempty(data.(char(panels(p))))                 % procees if current panel contains some data
                           ctime_resolution = mode(diff(time.(char(panels(p)))))*86400; % get current time resolution in seconds (only for logfile)
                           tn = [time.(char(panels(p)))(1):resol/86400:time.(char(panels(p)))(end)]'; % new time vector. Covert input time resolution in seconds to days (/86400)
                           data.(char(panels(p))) = interp1(time.(char(panels(p))),data.(char(panels(p))),tn); % Use LINEAR interpolation! Overwrite existing data
                           time.(char(panels(p))) = tn;clear tn             % set new values + delete temp. variable. Will be stored later after running for all panels
                           % Write to logfile
                           [ty,tm,td,th,tmm] = datevec(now);               % time for logfile
                           fprintf(fid,'%s channels re-sampled from: %8.2f to %8.2f seconds (%04d/%02d/%02d %02d:%02d)\n',...
                                char(panels(p)),ctime_resolution,resol,ty,tm,td,th,tmm);
                           clear ctime_resolution
                        end
                    end
                    fclose(fid);                                            % close logfile
					% Store new data and time vectors
					set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
					set(findobj('Tag','plotGrav_text_status'),'UserData',time); 
					set(findobj('Tag','plotGrav_text_status'),'String','All channels have been re-sampled');drawnow % status
				catch
                    fclose(fid);                                            % close logfile
					set(findobj('Tag','plotGrav_text_status'),'String','Could not perform interpolation (unkonw error).');drawnow % status
				end
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow % status
            end
        case 'compute_decimate_select'
            %% Re-interpolated Select panel (decimate/resample)
            % This option allows the re-itnerpolation/decimation all
            % time series of required panel. By default, iGrav and SG030
            % time series are decimated after corrections. This is
            % additional resampling option. The starting and ending time 
            % epoch of each time series stays the same! It is not important
            % which time series are selected, all in the required panel
            % will be resampled! 
            
            % Get panel name (defined in button/menu 'CallBack')
            panel = char(varargin{1});
            
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time sereis
            time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            if ~isempty(data.(panel))                                       % continue only if some data have been loaded
                % Open logfile for appending new message
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                % Get input from user = time resolution in seconds
                if nargin == 2
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new sampling interval (in seconds)');drawnow % send instructions to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','3600');  % make input text visible + set default value, in this case 1 hour (=3600 seconds)
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % 
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar 
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off editable fields
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                    resol = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                else
                    resol = char(varargin{2});
                end
                resol = str2double(resol);                                  % convert to double (from string)
				try
                    set(findobj('Tag','plotGrav_text_status'),'String','Starting interpolation...');drawnow % status
                    ctime_resolution = mode(diff(time.(panel)))*86400; % get current time resolution in seconds (only for logfile)
                    tn = [time.(panel)(1):resol/86400:time.(panel)(end)]'; % new time vector. Covert input time resolution in seconds to days (/86400)
                    data.(panel) = interp1(time.(panel),data.(panel),tn); % Use LINEAR interpolation! Overwrite existing data
                    time.(panel) = tn;clear tn                        % set new values + delete temp. variable. Will be stored later after running for all panels
                    % Write to logfile
                    [ty,tm,td,th,tmm] = datevec(now);               % time for logfile
                    fprintf(fid,'%s channels re-sampled from: %8.2f to %8.2f seconds (%04d/%02d/%02d %02d:%02d)\n',...
                        panel,ctime_resolution,resol,ty,tm,td,th,tmm);
                    clear ctime_resolution
                    fclose(fid);                                            % close logfile
					% Store new data and time vectors
					set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
					set(findobj('Tag','plotGrav_text_status'),'UserData',time); 
					set(findobj('Tag','plotGrav_text_status'),'String',sprintf('All %s channels have been re-sampled',panel));drawnow % status
                catch error_message
                    if strcmp(error_message.message,'The grid vectors are not strictly monotonic increasing.')
                        [ty,tm,td,th,tmm] = datevec(now); % time for logfile
                        fprintf(fid,'Could not re-sample %s: input time vector contains ambiguities. Run ''Remove-Ambiguities'' first (%04d/%02d/%02d %02d:%02d).\n',...
                            char(panel),ty,tm,td,th,tmm);
                        fclose(fid);                                            % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Run ''Remove-Ambiguities''.');drawnow % status
                    else
                        [ty,tm,td,th,tmm] = datevec(now); % time for logfile
                        fprintf(fid,'Could not re-sample %s: Error: %s (%04d/%02d/%02d %02d:%02d).\n',...
                            char(panel),error_message.message,ty,tm,td,th,tmm);
                        fclose(fid);                                            % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Could not perform interpolation (see logfile).');drawnow % status
                    end
				end
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow % status
            end
        case 'compute_remove_ambiguities'
            %% Remove ambiguities = correct non-monochromatic time vector
            % This option allows to correct time vectors that contain
            % ambiguous data points = same time value more that onece. This
            % typicaly prevents the intepolation. This function remove all
            % duplicate values
            
            % Get panel name (defined in button/menu 'CallBack')
            panel = char(varargin{1});
            
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time sereis
            time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            if ~isempty(data.(panel))                                       % continue only if some data have been loaded
                % Open logfile for appending new message
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
				try
                    set(findobj('Tag','plotGrav_text_status'),'String','Removing...');drawnow % status
                    time_temp = time.(panel); % store time vector
                    data_temp = data.(panel); % get data. Data will be re-arranged according to time vector
                    % Sort the time vector and data
                    [time_temp,temp_index] = sort(time_temp,1);
                    data_temp = data_temp(temp_index,:);
                    % Use unique time values only
                    [time.(panel),temp_index] = unique(time_temp);
                    data.(panel) = data_temp(temp_index,:);
                    % Write to logfile
                    [ty,tm,td,th,tmm] = datevec(now); % time for logfile
                    fprintf(fid,'%s time vector corrected (%04d/%02d/%02d %02d:%02d).\n',panel,ty,tm,td,th,tmm);
                    fclose(fid);                                            % close logfile
					% Store new data and time vectors
					set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
					set(findobj('Tag','plotGrav_text_status'),'UserData',time); 
					set(findobj('Tag','plotGrav_text_status'),'String',sprintf('%s time vector corrected',panel));drawnow % status
                catch error_message
                    [ty,tm,td,th,tmm] = datevec(now); % time for logfile
                    fprintf(fid,'Could not re-sample %s: Error: %s (%04d/%02d/%02d %02d:%02d).\n',...
                        char(panel),error_message.message,ty,tm,td,th,tmm);
                    fclose(fid);                                            % close logfile
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not correct time vector (see logfile).');drawnow % status
				end
			else
				set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow % status
            end
        case 'compute_time_shift'
            %% Introduce time shift
            % This option allows for introduction of a time shift for
            % selected channels. Only selected channel will be "shifted"!
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            
            % Prepare variable for loop = all panels in one loop
            panels = {'data_a','data_b','data_c','data_d'};
            % Get all channel names, units and data tables + find selected channels
            for i = 1:length(panels)
                 % Get units. Will be used for output/plot
                units.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_text_%s',panels{i})),'UserData');
                % get channels names. Will be used for output/plot
                channels.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_edit_%s_path',panels{i})),'UserData');
                % Get UI tables
                data_table.(panels{i}) = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panels{i})),'Data'); 
            end
            
            % Open logfile
            try
                fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
            catch
                fid = fopen('plotGrav_LOG_FILE.log','a');
            end
            
            if ~isempty(data.data_a)
                if nargin == 1
                    % Get user input = time shift in seconds.
                    set(findobj('Tag','plotGrav_text_status'),'String','Time shift in seconds');drawnow % send instructions to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'String','0'); % show editable field + set default value
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else % set using plotGrav script option
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off editable fields
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                try 
                    % Get user input
                    new_shift = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    new_shift = str2double(new_shift);
                    % Run for all panels (however only selected channels will
                    % be affected
                    for p = 1:length(panels)   
                        if ~isempty(data.(char(panels(p))))                 % procees if current panel contains some data
                            % Find all selected channels
                            plot_axesL1.(char(panels(p))) = find(cell2mat(data_table.(char(panels(p)))(:,1))==1); % get selected channels (L1) for each panel
                            % Check at least one channel is selected
                            if ~isempty(plot_axesL1.(char(panels(p))))
                                % Run for all selected channels
                                for i = 1:length(plot_axesL1.(char(panels(p))))
                                    channel_number = size(data.(char(panels(p))),2)+1;  % get current number o channels (all not only selected ones). Will be used to append the new channel at the and of the data matrix                
                                    units.(char(panels(p)))(channel_number) = units.(char(panels(p)))(plot_axesL1.(char(panels(p)))(i)); % copy/append units
                                    channels.(char(panels(p)))(channel_number) = {sprintf('%s_shift%3.1fs',char(channels.(char(panels(p)))(plot_axesL1.(char(panels(p)))(i))),new_shift)}; % add channel name
                                    data_table.(char(panels(p)))(channel_number,1:7) = {false,false,false,... % add to ui-table. By default, the new channel is not checked for either axes (=false)
                                                                            sprintf('[%2d] %s (%s)',channel_number,char(channels.(char(panels(p)))(channel_number)),char(units.(char(panels(p)))((plot_axesL1.(char(panels(p)))(i))))),...
                                                                                false,false,false};
                                    data.(char(panels(p)))(:,channel_number) = ...
                                        interp1(time.(char(panels(p)))+new_shift/86400,data.(char(panels(p)))(:,plot_axesL1.(char(panels(p)))(i)),time.(char(panels(p))));
                                   % Write to logfile
                                   [ty,tm,td,th,tmm] = datevec(now);        % time for logfile
                                   fprintf(fid,'%s channel %2d = time shifted channel %d: %5.2f seconds (%04d/%02d/%02d %02d:%02d)\n',...
                                        char(panels(p)),channel_number,plot_axesL1.(char(panels(p)))(i),new_shift,ty,tm,td,th,tmm);
                                   set(findobj('Tag','plotGrav_text_status'),'String',...
                                       sprintf('%s channel %2d = time shifted channel %2d: %5.2f seconds',char(panels(p)),channel_number,plot_axesL1.(char(panels(p)))(i),new_shift));drawnow % message
                                   clear channel_number
                                end
                            end
                        end
                    end
                    % Store all updated variables
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store shifted data
                    set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a); % store iGrav units
                    set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a); % store iGrav channels (names)
                    set(findobj('Tag','plotGrav_text_data_b'),'UserData',units.data_b);         
                    set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels.data_b); 
                    set(findobj('Tag','plotGrav_text_data_c'),'UserData',units.data_c);         
                    set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels.data_c); 
                    set(findobj('Tag','plotGrav_text_data_d'),'UserData',units.data_d);         
                    set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels.data_d); 
                    set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a); % store the iGrav ui-table
                    set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.data_b); % store the TRiLOGi ui-table
                    set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.data_c); % store the Other1 ui-table
                    set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.data_d); % store the Other2 ui-table
                    fclose(fid); % close log file
                catch error_message
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'An error occurred during time shift: %s (%04d/%02d/%02d %02d:%02d)\n',...
                                char(error_message.message),ty,tm,td,th,tmm);
                    set(findobj('Tag','plotGrav_text_status'),'String','An error occurred during time shift.');drawnow % message
                    fclose(fid);
                    
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load (iGrav) data first.');drawnow % message
            end 
            
            
		case 'get_polar'
			%% GET Polar motion effect
            % User can either load polar motion effect using 'Tides tsf
            % file' or using 'plotGrav_Atmacs_and_EOP.m' function that gets
            % the lates Earth Orientation Parameters (EOP) and computed the
            % resulting gravity effect (acceleration). The polar motion
            % effect and length of day (LOD) are computed based on 'Torge
            % (1989): Gravimetry' formula.
            % Function works only if some time series is loaded using
            % 'iGrav' panel and appends polar motion and LOD time series at
            % the end of it.
            
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');    % get the iGrav ui-table (two new channels will be appended)
            units.data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');             % get iGrav units (two new channels will be appended)
            channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names) (two new channels will be appended)
            
            if ~isempty(data.data_a)                                         % proceed only if data_a time series loaded
                if nargin == 1
                    % Get user input = station coordinates. Fixed URL is used
                    % to get Polar motion and LOD parameters
                    set(findobj('Tag','plotGrav_text_status'),'String','Latitude and Longitude (in deg, space separated)');drawnow % send instructions to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'String','49.14490 12.87687'); % show editable field + set default values (Wettzell)
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off editable fields
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Downloading/Computing EOP...');drawnow % status
                try
                    % Open logfile
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
					user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
					user_in = strsplit(user_in,' ');                        % split string using space symbol
					Lat = str2double(user_in(1));                           % Convert to latitude and longitude
					Lon = str2double(user_in(2));
					atmacs_url_link_loc = '';                               % Required input, see 'plotGrav_Atmacs_and_EOP.m' (used to computed atmacs effect)
					atmacs_url_link_glo = '';  
					[pol_corr,lod_corr,~,~,corr_check] = plotGrav_Atmacs_and_EOP(time.data_a,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo); % call polar motion/LOD function
					c = length(channels.data_a);                             % get current number of channel. Two new channels (polar effect and LOD effect will be appended)
                    if corr_check(1)+corr_check(2) == 2                     % 'plotGrav_Atmacs_and_EOP.m' check-sum output
						[ty,tm,td,th,tmm] = datevec(now);                   % logfile time
						% Polar motion
						units.data_a(c+1) = {'nm/s^2'};                      % add units
						channels.data_a(c+1) = {'polar motion effect'};      % add channel name
						data_table.data_a(c+1,1:7) = {false,false,false,...        % add to ui-table
															sprintf('[%2d] %s (%s)',c+1,char(channels.data_a(c+1)),char(units.data_a(c+1))),...
																false,false,false};
						data.data_a(:,c+1) = -pol_corr;                      % add/append data (convert correction to effect)
						fprintf(fid,'iGrav channel %d == polar motion effect. Used coordinates: lat = %9.6f deg, lon = %9.6f deg (%04d/%02d/%02d %02d:%02d)\n',...
                            c+1,Lat,Lon,ty,tm,td,th,tmm);
						% LOD
						units.data_a(c+2) = {'nm/s^2'};                      % add units
						channels.data_a(c+2) = {'LOD effect'};               % add channel name
						data_table.data_a(c+2,1:7) = {false,false,false,...  % add to ui-table
															sprintf('[%2d] %s (%s)',c+2,char(channels.data_a(c+2)),char(units.data_a(c+2))),...
																false,false,false};
						data.data_a(:,c+2) = -lod_corr;                      % add data (convert correction to effect)
						fprintf(fid,'iGrav channel %d == length of day effect. Used coordinates: lat = %9.6f deg, lon = %9.6f deg (%04d/%02d/%02d %02d:%02d)\n',...
                            c+2,Lat,Lon,ty,tm,td,th,tmm);
						% Store updated data/ui-table/channels/units
						set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a); % update table
						set(findobj('Tag','plotGrav_push_load'),'UserData',data); 
						set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a); % update iGrav units
						set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a); % update iGrav channels (names)
						fclose(fid);
						set(findobj('Tag','plotGrav_text_status'),'String','Polar motion and LOD effect computed.');drawnow % message
					else
						fclose(fid);
						set(findobj('Tag','plotGrav_text_status'),'String','Polar motion and LOD effect NOT computed.');drawnow % message
                    end
                catch
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Polar motion and LOD effect NOT computed.');drawnow % message
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load (iGrav) data first.');drawnow % message
            end 
            
		case 'get_atmacs'
			%% GET Atmacs data
            % The main correction routine for iGrav (SG030) computes the
            % atmospheric effect using single admittance approach. To
            % increase the accuracy of computed atmospheric effect, user
            % can get the Atmcacs effect (selected sites) using
            % 'plotGrav_Atmacs_and_EOP.m' function. This section allows
            % user to set the input parameters and append the acquired
            % atmacs time series to iGrav panel.
         
            % First get all required inputs
			data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all data 
			time = get(findobj('Tag','plotGrav_text_status'),'UserData');   % load time
            data_table.data_a = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');    % get the iGrav ui-table (two new channels will be appended)
            units.data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');             % get iGrav units (two new channels will be appended)
            channels.data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get iGrav channels (names) (two new channels will be appended)

            if ~isempty(time.data_a)                                         % proceed only if iGrav data loaded
                % Get user input = 2x URL with local and global part +
                % channel number with in-situ pressure variations (will be
                % used to compute the residual effect). Main single admittance
                % will be used for residual effect (See GUI)
                if nargin == 1                                              % This function can be called with more then one input. If only one input (function name = 'get_atmacs'), then get user input. Otherwise, use function input for further computation.
                    set(findobj('Tag','plotGrav_text_status'),'String','Set url for local part (if needed use , as delimiter)');drawnow % send instruction to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','http://atmacs.bkg.bund.de/data/results/lm/we_lm2_12km_19deg.grav');% Show user input field and set default URL (wettzell)
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on'); 
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                    temp = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get User Input local URL
                    % Split string in case several links on input 
                    if isempty(temp)
                        atmacs_url_link_loc = '';
                    else
                        atmacs_url_link_loc = strsplit(temp,',');
                    end
                    set(findobj('Tag','plotGrav_text_status'),'String','Set url for global part (if needed use , as delimiter)');drawnow % update send instruction to status bar
                    set(findobj('Tag','plotGrav_edit_text_input'),'String','http://atmacs.bkg.bund.de/data/results/icon/we_icon384_19deg.grav'); % update Editable field to new/global part URL
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar                                                      % wait 8 seconds for user input
                    temp = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get User Input global URL
                    atmacs_url_link_glo = strsplit(temp,',');
                    set(findobj('Tag','plotGrav_text_status'),'String','iGrav pressure channel (for pressure in mBar)');drawnow % new instruction to set the channel number
                    set(findobj('Tag','plotGrav_edit_text_input'),'String','2'); % Update the editable field. By default iGrav second channel contains pressure variations
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar                                                   % wait 8 seconds for user input
                    press_channel = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % Get pressure channel number
                else
                    % Make sure the input is either empty string or cell
                    % containing all urls
                    if isempty(varargin{1})
                        atmacs_url_link_loc = '';
                    else
                        atmacs_url_link_loc = strsplit(varargin{1},',');
                    end   
                    atmacs_url_link_glo = strsplit(varargin{2},',');
                    press_channel = char(varargin{3});                  
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off editable fields
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_status'),'String','Downloading/Computing Atmacs...');drawnow % status
                Lat = [];Lon = [];                                          % No coordinates are required for Atmospheric effect
                % Call Atmcas function. The output does not include
                % residual effect!! This will be computed afterwards.
                [~,~,atmo_corr,pressure,corr_check] = plotGrav_Atmacs_and_EOP(time.data_a,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo); 
                admittance_factor = str2double(get(findobj('Tag','plotGrav_edit_admit_factor'),'String'));  % get admittance factor stored in main GUI 'Admittance' editable field.
                if corr_check(3) == 1                                       % 'plotGrav_Atmacs_and_EOP' check sum (used to identify what and if computed)
                    % Open logfile
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);                       % Time for logfile
                    try
                        % Append new time series: Atmacs effect
                        units.data_a(length(channels.data_a)+1) = {'nm/s^2'};     % append units
                        channels.data_a(length(channels.data_a)+1) = {'Atmacs effect'}; % append channel name
                        data_table.data_a(length(channels.data_a),1:7) = {false,false,false,... % append to table. Waring use length(channels.data_a) not length(channels.data_a)+1 as channels.data_a already updated!
                                                                sprintf('[%2d] %s (%s)',length(channels.data_a),char(channels.data_a(length(channels.data_a))),char(units.data_a(length(channels.data_a)))),...
                                                                    false,false,false};
                        if ~isempty(press_channel)                              % add residual effect if local pressure available
                            dp = data.data_a(:,str2double(press_channel)) - pressure/100; % pressure difference = local - model. /100 => convert Pa to hPa
                            data.data_a(:,length(channels.data_a)) = -atmo_corr + admittance_factor*dp; % compute the gravity effect = -correction(=effect) + admittance * pressure residuals.
                            % Write to logfile
                            fprintf(fid,'iGrav channel %d == Atmacs total effect including residual effect (admittance = %4.2f nm/s^2/hPa, local url=',length(channels.data_a),admittance_factor);
                            for j = 1:length(atmacs_url_link_loc)
                                fprintf(fid,'%s,',atmacs_url_link_loc{j});
                            end
                            fprintf(fid,' global url=');
                            for j = 1:length(atmacs_url_link_glo)
                                fprintf(fid,'%s,',atmacs_url_link_glo{j});
                            end
                            fprintf(fid,' %04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        else
                            data.data_a(:,length(channels.data_a)) = -atmo_corr;  % add data (convert correction to effect)
                            % Write to logfile
                            fprintf(fid,'iGrav channel %d == Atmacs total effect without residaul effect. Local url=',length(channels.data_a));
                            for j = 1:length(atmacs_url_link_loc);
                                fprintf(fid,'%s,',atmacs_url_link_loc{j});
                            end
                            fprintf(fid,' global url=');
                            for j = 1:length(atmacs_url_link_glo);
                                fprintf(fid,'%s,',atmacs_url_link_glo{j});
                            end
                            fprintf(fid,' %04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        end
                        % Append new time series: Atmacs pressure (to be able
                        % to reconstruct the residual effect)
                        units.data_a(length(channels.data_a)+1) = {'mBar'};       % append units
                        channels.data_a(length(channels.data_a)+1) = {'Atmacs pressure'}; % append channel name
                        data_table.data_a(length(channels.data_a),1:7) = {false,false,false,... % append to ui-table
                                            sprintf('[%2d] %s (%s)',length(channels.data_a),char(channels.data_a(length(channels.data_a))),char(units.data_a(length(channels.data_a)))),...
                                                false,false,false};

                        data.data_a(:,length(channels.data_a)) = pressure/100;    % append pressure. /100 => convert Pa to hPa 
                        fprintf(fid,'iGrav channel %d == Atmacs pressure (%04d/%02d/%02d %02d:%02d)\n',...
                                length(channels.data_a),ty,tm,td,th,tmm);
                        % Store the results
                        set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.data_a); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.data_a); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.data_a); % update iGrav channels (names)
                        fclose(fid);                                            % close logfile
                        set(findobj('Tag','plotGrav_text_status'),'String','Atmacs effect computed.');drawnow % message
                    catch
                        set(findobj('Tag','plotGrav_text_status'),'String','Atmacs effect computed but NOT appended.');drawnow % message
                    end
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Atmacs NOT computed.');drawnow % message
                end
            end

%%%%%%%%%%%%%%%%%%%  O T H E R   F U N C T I O N S %%%%%%%%%%%%%%%%%%%%%%%%  
        case 'edit_channel_names_data_a'
            %% Edit channel names
            % The changes like 'set_legend_L1' or 'set_label_L1'  modify
            % the legends and labels only temporarily (unit calling
            % 'uitable_push'). This option allows changing the channel
            % names in the ui-table = permanently (until calling
            % 'load_all_data').
            
            % First get current data_a ui-table/names/units (will be
            % updated)
            panels = 'data_a';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in iGrav. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_a'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                % Get new channel names either fro user (GUI) or from plotGrav
                % function input (plotGrav_scriptRun.m function does that)
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new names (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        % Open logfile
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   % Time for logfile
                        % Check if number of inserted channels (X) does not
                        % exceed number of existing channels. If so change
                        % only first X channels! 
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d name changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                channels.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        % Store new channel names
                        set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.(panels));             % set updated units 
                        set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels.(panels));     % set updated channels (names) 
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel names have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
        case 'edit_channel_names_data_b'
            % For comments see 'edit_channel_names_data_a'
            panels = 'data_b';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in TRiLOGi. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_b'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new names (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d name changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                channels.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.(panels));    % set the updated ui-tabl
                        set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels.(panels));     % set updated channels (names) 
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel names have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
        case 'edit_channel_names_data_c'
            % For comments see 'edit_channel_names_data_a'
            panels = 'data_c';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in Other1. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_c'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new names (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d name changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                channels.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_edit_data_c_path'),'UserData',channels.(panels));     % set updated channels (names) 
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel names have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
        case 'edit_channel_names_data_d'
            % For comments see 'edit_channel_names_data_a'
            panels = 'data_d';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in Other2. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_d'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new names (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d name changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                channels.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_edit_data_d_path'),'UserData',channels.(panels));     % set updated channels (names) 
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel names have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
            
        case 'edit_channel_units_data_a'
            %% Edit channel units.
            % The changes like 'set_legend_L1' or 'set_label_L1'  modify
            % the legends and labels only temporarily (unit calling
            % 'uitable_push'). This option allows changing the channel
            % units in the ui-table = permanently (until calling
            % 'load_all_data').
            
            % First get current data_a ui-table/names/units (will be
            % updated)
            panels = 'data_a';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in iGrav. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_a_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_a'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                % Get new channel units either fro user (GUI) or from plotGrav
                % function input (plotGrav_scriptRun.m function does that)
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new units (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        % Open logfile
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   % Time for logfile
                        % Check if number of inserted channels (X) does not
                        % exceed number of existing channels. If so change
                        % only first X channels! 
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d units changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                units.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        % Store new channel names
                        set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_text_data_a'),'UserData',units.(panels));             % set updated units  
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel units have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
        case 'edit_channel_units_data_b'
            % Edit data_b units. For comments, see 'edit_channel_units_data_a'
            panels = 'data_b';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in data_b. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_b_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_b'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new units (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        % Open logfile
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d units changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                units.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_text_data_b'),'UserData',units.(panels));             % set updated units  
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel units have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
        case 'edit_channel_units_data_c'
            % Edit data_c units. For comments, see 'edit_channel_units_data_a'
            panels = 'data_c';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in data_c. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_c_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_c'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new units (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        % Open logfile
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d units changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                units.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_text_data_c'),'UserData',units.(panels));             % set updated units  
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel units have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
        case 'edit_channel_units_data_d'
            % Edit data_d units. For comments, see 'edit_channel_units_data_a'
            panels = 'data_d';                                              % 
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % Just to check if some data loaded in data_d. Will not be modified!
            data_table.(panels) = get(findobj('Tag','plotGrav_uitable_data_d_data'),'Data');    % get the ui-table 
            units.(panels) = get(findobj('Tag','plotGrav_text_data_d'),'UserData');             % get units 
            channels.(panels) = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData');     % get channels (names)
            if ~isempty(data.(panels))
                if nargin == 1                                      
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new units (delimiter= ; )');drawnow % send message to status bar with instructions
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','');  % Make user input dialog visible + set default value  = empty
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                    set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
                    waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); % Wait for confirmation
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
                else                                                            % if plotGrav function called with more inputs
                    set(findobj('Tag','plotGrav_edit_text_input'),'String',char(varargin{1}));
                end
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % Turn off user input dialog and editable field
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                user_in = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                user_in = strsplit(user_in,';');                            % split string using ; symbol
                if ~isempty(user_in)                                        % proceed only if something inserted
                    try
                        % Open logfile
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);                   
                        if length(user_in) > length(channels.(panels))
                            max_channel = length(channels.(panels));
                        else
                            max_channel = length(user_in);
                        end
                        for i = 1:max_channel                               % run for all inserted channel names (max = X)
                            if ~strcmp(char(user_in(i)),'[]')                    % [] symbol means do not change this name!
                                fprintf(fid,'%s channel %2d units changed: %s -> %s (%04d/%02d/%02d %02d:%02d)\n',panels,i,char(channels.(panels)(i)),char(user_in(i)),ty,tm,td,th,tmm);
                                units.(panels)(i) = {char(user_in(i))};       % change the user name
                                data_table.(panels)(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels.(panels)(i)),char(units.(panels)(i)))}; % +update the ui-table using new channel name
                            end
                        end
                        set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',data_table.(panels));    % set the updated ui-table 
                        set(findobj('Tag','plotGrav_text_data_d'),'UserData',units.(panels));             % set updated units  
                        fclose(fid);
                        plotGrav('uitable_push');                           % re-plot to see the changes.
                        set(findobj('Tag','plotGrav_text_status'),'String','New channel units have been set.');drawnow 
                    catch
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Upps, some error occurred.');drawnow
                    end
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow
            end
            
		case 'insert_rectangle'
			%% INSERT objects
            % Iser can interactively insert text, rectangles, lines and
            % circles to GUI (all) Plots. This can be used to add comments
            % or emphatize some time series features. The insertion is
            % temporary. Object will disappear after re-plotting (calling
            % 'uitable_push')
            
            % Insert rectangle:
            % Get line width of new rectangle
            line_width = get(findobj('Tag','plotGrav_menu_line_width'),'UserData');     % get line width
			set(findobj('Tag','plotGrav_text_status'),'String','Lower left corner...');drawnow % send instructions to status bar
			[select_x(1),select_y(1)] = ginput(1);                          % get lower left coorinates
			set(findobj('Tag','plotGrav_text_status'),'String','Upper right corner...');drawnow % status
			[select_x(2),select_y(2)] = ginput(1);                          % get upper right coorinates
			r = rectangle('Position',[select_x(1),select_y(1),abs(diff(select_x)),abs(diff(select_y))],'LineWidth',max(line_width));% Plot the recantle and set the maximum plotted line_width 
			cur = get(findobj('Tag','plotGrav_insert_rectangle'),'UserData'); % Get already plotted rectangles 
			cur = [cur,r];                                                  % append the new rectangle handle
			set(findobj('Tag','plotGrav_insert_rectangle'),'UserData',cur); % overwrite the variable with plotted rectangle with new values (old+new). These handles are the used to remove plotted rectangles
			set(findobj('Tag','plotGrav_text_status'),'String','Rectangle inserted.');drawnow % status
		case 'insert_circle'
            % Insert elipse: do the same as for 'insert_rectangle'
            line_width = get(findobj('Tag','plotGrav_menu_line_width'),'UserData');
			set(findobj('Tag','plotGrav_text_status'),'String','Lower left corner...');drawnow 
			[select_x(1),select_y(1)] = ginput(1);
			set(findobj('Tag','plotGrav_text_status'),'String','Upper right corner...');drawnow 
			[select_x(2),select_y(2)] = ginput(1);
			r = rectangle('Position',[select_x(1),select_y(1),abs(diff(select_x)),abs(diff(select_y))],'Curvature',[1 1],...
				'LineWidth',max(line_width));
			cur = get(findobj('Tag','plotGrav_insert_circle'),'UserData');
			cur = [cur,r];
			set(findobj('Tag','plotGrav_insert_circle'),'UserData',cur);
			set(findobj('Tag','plotGrav_text_status'),'String','Elipse inserted.');drawnow 
		case 'insert_line'
            % Insert line: do the same as for 'insert_rectangle'
            line_width = get(findobj('Tag','plotGrav_menu_line_width'),'UserData');
			set(findobj('Tag','plotGrav_text_status'),'String','First point...');drawnow 
			[select_x(1),select_y(1)] = ginput(1);
			set(findobj('Tag','plotGrav_text_status'),'String','Second point...');drawnow 
			[select_x(2),select_y(2)] = ginput(1);
			r = plot(select_x,select_y,'k','LineWidth',max(line_width));
			cur = get(findobj('Tag','plotGrav_insert_line'),'UserData');
			cur = [cur,r];
			set(findobj('Tag','plotGrav_insert_line'),'UserData',cur);
			set(findobj('Tag','plotGrav_text_status'),'String','Line inserted.');drawnow 
		case 'insert_text'
            % Get sring
			set(findobj('Tag','plotGrav_text_status'),'String','Set string');drawnow % send instructions to status bar
			set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','Text here'); % show editable field ans set default text
            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); %
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
            string_in = get(findobj('Tag','plotGrav_edit_text_input'),'String');
            % Get fontsize
            font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData'); % get font size
            set(findobj('Tag','plotGrav_text_status'),'String','Set fontsize');drawnow % send instructions to status bar
			set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String',font_size); % show editable field ans set default text
            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); %
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
            font_size = str2double(get(findobj('Tag','plotGrav_edit_text_input'),'String'));
            % Alignment
            set(findobj('Tag','plotGrav_text_status'),'String','Set Alignment');drawnow % send instructions to status bar
			set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','center'); % show editable field ans set default text
            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); %
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
            alignment = get(findobj('Tag','plotGrav_edit_text_input'),'String');
            % Color
            set(findobj('Tag','plotGrav_text_status'),'String','Set color');drawnow % send instructions to status bar
			set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on','String','k'); % show editable field ans set default text
            set(findobj('Tag','plotGrav_push_confirm'),'Visible','on');drawnow % Show confirmation button 
            waitfor(findobj('Tag','plotGrav_push_confirm'),'Visible','off'); %
            set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
            col = get(findobj('Tag','plotGrav_edit_text_input'),'String');
            
            set(findobj('Tag','plotGrav_text_input'),'Visible','off');  % turn of visibility of status bar   
			set(findobj('Tag','plotGrav_text_status'),'String','Select position...');drawnow % update instructions
			[select_x(1),select_y(1)] = ginput(1);                          % get possition                         
			r = text(select_x,select_y,string_in,'HorizontalAlignment',alignment,...
					'FontSize',font_size);              % place text
			set(r,'Color',col);
			cur = get(findobj('Tag','plotGrav_insert_text'),'UserData');
			cur = [cur,r];
			set(findobj('Tag','plotGrav_insert_text'),'UserData',cur);
			set(findobj('Tag','plotGrav_text_status'),'String','Text inserted.');drawnow
            
		case 'remove_rectangle'
            %% REMOVE Objects
            % The inserted object can be removed (the handles are always
            % tored in GUI uicontrols). Either all or the last inserted
            % object can be removed. In addition all objects will disappear
            % after re-plot, i.e., calling 'uitable_push'
            
            % Remove ALL rectangles:
			cur = get(findobj('Tag','plotGrav_insert_rectangle'),'UserData'); % get hanbles to all inserted rectangles
			if ~isempty(cur)                                                % proceed only some rectangle exists
				for c = 1:length(cur)                                       % Run for all rectangles                                
					try
						delete(cur(c));                                     % delete the object using their handles
					end
				end
				set(findobj('Tag','plotGrav_insert_rectangle'),'UserData',[]); % Reset the container with rectangle handles
				set(findobj('Tag','plotGrav_text_status'),'String','Rectangles removed.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No rectangles found.');drawnow % status
			end
		case 'remove_rectangle_last'
            % Remove last inserted rectangles:
			cur = get(findobj('Tag','plotGrav_insert_rectangle'),'UserData'); % get hanbles to all inserted rectangles
			if ~isempty(cur)                                                % proceed only some rectangle exists
				delete(cur(end));                                           % delete the last object using its handle
				cur(end) = [];                                              % remove the handle from variable
				set(findobj('Tag','plotGrav_insert_rectangle'),'UserData',cur); % update the container with handles
				set(findobj('Tag','plotGrav_text_status'),'String','Last inserted rectangle removed.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No rectangles found.');drawnow % status
			end
		case 'remove_circle'
			% Remove ALL elipses: do the same as for 'remove_rectangle'
			cur = get(findobj('Tag','plotGrav_insert_circle'),'UserData');
			if ~isempty(cur)                                           
				for c = 1:length(cur)
					try
						delete(cur(c));
					end
				end
				set(findobj('Tag','plotGrav_insert_circle'),'UserData',[]);
				set(findobj('Tag','plotGrav_text_status'),'String','Circles removed.');drawnow 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No ellipse found.');drawnow % status
			end
		case 'remove_circle_last'
            % Remove last inserted elipse: see 'remove_rectangle_last' for
            % comments
			cur = get(findobj('Tag','plotGrav_insert_circle'),'UserData');
			if ~isempty(cur)                                           % continua only if data have been loaded
				delete(cur(end));
				cur(end) = [];
				set(findobj('Tag','plotGrav_insert_circle'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Last inserted elipse removed.');drawnow 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No ellipse found.');drawnow 
			end
			
		case 'remove_line'
            % Remove ALL lines: do the same as for 'remove_rectangle'
			cur = get(findobj('Tag','plotGrav_insert_line'),'UserData');
			if ~isempty(cur)                                           % continue only if data have been loaded
				for c = 1:length(cur)
					try
						delete(cur(c));
					end
				end
				set(findobj('Tag','plotGrav_insert_line'),'UserData',[]);
				set(findobj('Tag','plotGrav_text_status'),'String','Lines removed.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No lines found.');drawnow 
			end
		case 'remove_line_last'
            % Remove last inserted line: see 'remove_rectangle_last' for
            % comments
			cur = get(findobj('Tag','plotGrav_insert_line'),'UserData');
			if ~isempty(cur)                                           
				delete(cur(end));
				cur(end) = [];
				set(findobj('Tag','plotGrav_insert_line'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Last inserted line removed.');drawnow 
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No lines found.');drawnow 
			end
			
		case 'remove_text'
            % Remove ALL text: do the same as for 'remove_rectangle'
			cur = get(findobj('Tag','plotGrav_insert_text'),'UserData');
			if ~isempty(cur)                                          
				for c = 1:length(cur)
					try
						delete(cur(c));
					end
				end
				set(findobj('Tag','plotGrav_insert_text'),'UserData',[]);
				set(findobj('Tag','plotGrav_text_status'),'String','Text removed.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No text found.');drawnow % status
			end
		case 'remove_text_last'
            % Remove last inserted text: see 'remove_rectangle_last' for
            % comments
			cur = get(findobj('Tag','plotGrav_insert_text'),'UserData');
            if ~isempty(cur)                                           % continue only if data have been loaded
				delete(cur(end));
				cur(end) = [];
				set(findobj('Tag','plotGrav_insert_text'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Last inserted text removed.');drawnow % status
			else
				set(findobj('Tag','plotGrav_text_status'),'String','No text found.');drawnow % status
            end
            
		case 'reset_tables'
            %% Reset ui-tables
            % This is intern plotGrav function for resetting ui-tables. The
            % tables shouls be resetted after pressing 'Load data' button.
            % This ensures no error occurs when plotting after data has
            % been loaded. By default iGrav panel contains iGrav (raw)
            % measuremetns and TRiLOGi controller outputs. Loading of other
            % time series to these panels will automatically adjust the
            % ui-tables. Other 1 and 2 are empty. Loading of ot
            
            % Set iGrav channel names and units
			channels_data_a = {'Grav','Baro-Press','Grav-Bal','TiltX-Bal','TiltY-Bal',...
								'Temp-Bal','Grav-Ctrl','TiltX-Ctrl','TiltY-Ctrl','Temp-Ctrl',...
								'Neck-T1','Neck-T2','Body-T','Belly-T','PCB-T','Aux-T','Dewar-Pwr',...
								'Dewar-Press','He-Level','GPS-Signal','TimeStamp','Grav_calib',...
								'Grav_filt','Grav_filt-tide/pol-atmo',...
								'Grav_filt-tide/pol-atmo-drift','tides','pol','atmo','drift'};
			units_data_a = {'V','mBar','V','V','V','V','V','W','W','V','K','K','K',...
						   'K','C','C','mW','PSI','Percent','bool','s','nm/s^2','nm/s^2','nm/s^2',...
						   'nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2'};
            % Set TRiLOGi channel names and untis
			channels_data_b = {'TempExt','TempIn','TempCompIn','TempCompOut','TempRegIn',...
								'TempRegOut','HeGasPres','Vin','Mains','LowBat','UPSAlarm','FanTach',...
								'CompFault','IN6','IN7','IN8','OUT1','FanOn','HeGasValv','RefrigComp','Out5',...
								'DCPwrCntrl','EnclosHeater','FanSpdCntrl','T09-iG-Top','T10-iG-Upper',...
								'T11-iG-Mid','T12-iG-Bot','T13-iG-Head','T14-iG-Ambient','T15-iG-H2oSupply',...
								'T16-iG-H2oReturn','OUT1S','OUT2S','OUT3S','OUT4S','OUT5S','OUT6S','PIDValue','OUT8S'};
			units_data_b = {'DegC','DegC','DegC','DegC','DegC','DegC','KPa','DCV','Bool','Bool','Bool',...
							'RPM','Bool','Bool','Bool','Bool','Bool','Bool','Bool','Bool','Bool','Bool',...
							'Bool','PCNT','DegC','DegC','DegC','DegC','DegC','DegC','DegC','DegC',...
							'Bool','Bool','Bool','Bool','Bool','Bool','PCNT','Bool'};
			% Store units/names
			set(findobj('Tag','plotGrav_text_data_a'),'UserData',units_data_a);
			set(findobj('Tag','plotGrav_text_data_b'),'UserData',units_data_b);
			set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels_data_a);
			set(findobj('Tag','plotGrav_edit_data_b_path'),'UserData',channels_data_b);
            % Create data for ui-table including default checked/unchecked
            % fields (false, true): iGrav
			for i = 1:length(channels_data_a)
				if i >= 22 && i <= 23                                           % by default on in L1
					data_table_data_a(i,1:7) = {true,false,false,sprintf('[%2d] %s (%s)',i,char(channels_data_a(i)),char(units_data_a(i))),false,false,false};
				elseif i == 25                                                  % by default on in L2
					data_table_data_a(i,1:7) = {false,true,false,sprintf('[%2d] %s (%s)',i,char(channels_data_a(i)),char(units_data_a(i))),false,false,false};
				else
					data_table_data_a(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_data_a(i)),char(units_data_a(i))),false,false,false};
				end
			end
            % Create data for ui-table including default checked/unchecked
            % fields (false, true): TRiLOGi
			set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table_data_a,'UserData',data_table_data_a);clear data_table_data_a
            for i = 1:length(channels_data_b)
				if i >= 25 && i <= 29                                           % by default on in L3
					data_table_data_b(i,1:7) = {false,false,true,sprintf('[%2d] %s (%s)',i,char(channels_data_b(i)),char(units_data_b(i))),false,false,false};
				elseif i == 39                                                   % by default on in R3
					data_table_data_b(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_data_b(i)),char(units_data_b(i))),false,false,true};
				else
					data_table_data_b(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_data_b(i)),char(units_data_b(i))),false,false,false};
				end
            end
            % Store/update the ui-tables
			set(findobj('Tag','plotGrav_uitable_data_b_data'),'Data',data_table_data_b,'UserData',data_table_data_b);clear data_table_data_b
			set(findobj('Tag','plotGrav_uitable_data_c_data'),'Data',{false,false,false,'NotAvailable',false,false,false});     % Other 1 table
			set(findobj('Tag','plotGrav_uitable_data_d_data'),'Data',{false,false,false,'NotAvailable',false,false,false});    % Other 2 table
            % Re-set data containers + store them
			time.data_a = [];time.data_b = [];time.data_c = [];time.data_d = [];
			data.data_a = [];data.data_b = [];data.data_c = [];data.data_d = [];
			set(findobj('Tag','plotGrav_text_status'),'UserData',time); 
			set(findobj('Tag','plotGrav_push_load'),'UserData',data);   
%             % Re-set plots
%             a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get axes of the First plot (left and right axes = L1 and R1)
%             a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes of the Second plot (left and right axes = L2 and R2)
%             a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes of the Third plot (left and right axes = L3 and R3)
%             set(findobj('Tag','plotGrav_menu_line_width'),'UserData',[0.5 0.5 0.5 0.5 0.5 0.5]); % set default line width
%             set(findobj('Tag','plotGrav_push_reset_view'),'UserData',[0 0 0]) % => nothing plotted
%             set(findobj('Tag','plotGrav_menu_set_font_size'),'UserData',9); % default font size
%             set(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData',5); % default number of ticks (Y)
%             set(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData',9); % default number of ticks (X)
%             set(findobj('Tag','plotGrav_menu_date_format'),'UserData','dd/mm/yyyy HH:MM'); % default time format
%             % Clear all plots / reset all plots
%             cla(a1(1));legend(a1(1),'off');ylabel(a1(1),[]);            % clear axes and remove legends and labels: First plot left (a1(1))
%             cla(a1(2));legend(a1(2),'off');ylabel(a1(2),[]);            % clear axes and remove legends and labels: First plot right (a1(2))
%             axis(a1(1),'auto');axis(a1(2),'auto');                      % Reset axis (not axes)
%             cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);            % Do the same for other axes and axis
%             cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);
%             axis(a2(1),'auto');axis(a2(2),'auto');
%             cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);
%             cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);
%             axis(a3(1),'auto');axis(a3(2),'auto');
            
		case 'reset_tables_sg030'
            % Similarly to 'reset_table', this section sets the correct
            % channel and units in case SG030 data is loaded
			channels_data_a = {'Grav-1','Grav-2','Baro-1','Grav-1_calib',...
								'Grav-1_filt','Grav-1_filt-tide/pol-atmo',...
								'Grav-1_filt-tide/pol-atmo-drift','tides','pol','atmo','drift'};
			units_data_a = {'V','V','mBar','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2'};
			% Store units/channels
			set(findobj('Tag','plotGrav_text_data_a'),'UserData',units_data_a);
			set(findobj('Tag','plotGrav_edit_data_a_path'),'UserData',channels_data_a);
            % Create ui-table
            for i = 1:length(channels_data_a)
				if i >= 22-18 && i <= 23-18                                           % by default on in L1
					data_table_data_a(i,1:7) = {true,false,false,sprintf('[%2d] %s (%s)',i,char(channels_data_a(i)),char(units_data_a(i))),false,false,false};
				elseif i == 25-18                                                  % by default on in L2
					data_table_data_a(i,1:7) = {false,true,false,sprintf('[%2d] %s (%s)',i,char(channels_data_a(i)),char(units_data_a(i))),false,false,false};
				else
					data_table_data_a(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_data_a(i)),char(units_data_a(i))),false,false,false};
				end
            end
            % Store/update ui-table
			set(findobj('Tag','plotGrav_uitable_data_a_data'),'Data',data_table_data_a,'UserData',data_table_data_a);clear data_table_data_a
            
        case 'script_run'
            %% Run script
            % plotGrav supports scripting, i.e., instead of using GUI, user
            % can call a script with plotGrav commands.
            
            % Get input either using GUI or via sting input
            if nargin == 1
                [name,path] = uigetfile({'*.plg'},'Select plotGrav script');    % Get plotGrav script file name (*.plg)
                file_name = fullfile(path,name);
            else
                file_name = char(varargin{1});
                if strcmp(file_name,'[]'); %  [] == no input. It needs to be converted to 0/1 switch as used by uigetfile function
                    name = 0;
                else
                    name = 1;
                end
            end
            if name == 0                                                    % If cancelled-> no input. This howerver, does not mean that the default file name has been changed or set to []!                                              
				set(findobj('Tag','plotGrav_text_status'),'String','You must select a script file.');drawnow % status
			else
				plotGrav_scriptRun(file_name);
            end
            
%%%%%%%%%%%%%%%%%%%  F I L E   S E L E C T I O N %%%%%%%%%%%%%%%%%%%%%%%%%%
			%% Select files/paths interactively
            % This section contains code for selection of input files such
            % as iGrav, TRiLOGi, Other1, Other2, Logfile, Webcam path,
            % Tides, Filter.
            % The interactive selction of files is very easy using matlab.
            % Uigetfile is used for selection files and uigetdir for paths.
            % Therefore, no extensive comments are required. Codes for 
            % selection of correction file as well as printing and export 
            % outputs are not here, but in corresponding sections.
		case 'select_data_a'                                                 % Selce data_a input PATH.
			path = uigetdir('Select iGrav Data Path');                      % get the path.
			if path == 0                                                    % Send message the user                 
				set(findobj('Tag','plotGrav_text_status'),'String','You must select the iGrav path.');drawnow 
            else                                                            % Otherwise, store the selected file path for future.
				set(findobj('Tag','plotGrav_edit_data_a_path'),'String',path);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','iGrav paht selected.');drawnow 
			end
		case 'select_data_a_file'                                            % Select iGrav input file
			[name,path] = uigetfile({'*.mat;*.tsf;*.dat;*.030;*.029;*.038;*.csv',...
                'plotGrav supported (*.mat,*.tsf,*.dat,*.030,*.029;*.038,*.csv)';...
                '*.*','All files'},...
                'Select iGrav Data File');    % Use cell array {'*.tsf';'*.dat';'*.mat'} as file filter
			if path == 0                                                    % If cancelled-> no input. This howerver, does not mean that the default file name has been changed or set to []!                                              
				set(findobj('Tag','plotGrav_text_status'),'String','You must select the iGrav file.');drawnow % status
			else
				set(findobj('Tag','plotGrav_edit_data_a_path'),'String',[path,name]);drawnow % Store the full file name for future loading.
				set(findobj('Tag','plotGrav_text_status'),'String','iGrav file selected.');drawnow % status
			end
		case 'select_data_b'                                               % Select TRiLOGi input path
			path = uigetdir('Select TRiLOGi Data Path');
			if path == 0                                                
				set(findobj('Tag','plotGrav_text_status'),'String','You must select the TRiLOGi path.');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_data_b_path'),'String',path);drawnow
				set(findobj('Tag','plotGrav_text_status'),'String','TRiLOGi paht selected.');drawnow 
			end
		case 'select_data_b_file'                                          % Select TRiLOGi input file                                         
			[name,path] = uigetfile({'*.mat;*.tsf;*.dat;*.030;*.029;*.csv',...
                'plotGrav supported (*.mat,*.tsf,*.dat,*.030,*.029,*.csv)';...
                '*.*','All files'},...
                'Select TRiLOGi Data File');
			if path == 0                                                
				set(findobj('Tag','plotGrav_text_status'),'String','You must select a TRiLOGi file.');drawnow
			else
				set(findobj('Tag','plotGrav_edit_data_b_path'),'String',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','TRiLOGi file selected.');drawnow 
			end
		case 'select_data_c'                                                % Select Other1 input file                                                
			[name,path] = uigetfile({'*.mat;*.tsf;*.dat;*.csv',...
                'plotGrav supported (*.mat,*.tsf,*.dat,*.csv)';...
                '*.*','All files'},...
                'Select Other1 TSoft/DAT (Soil moisure), MAT or CSV file'); 
			if name == 0                                                    
				set(findobj('Tag','plotGrav_text_status'),'String','No file selected.');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_data_c_path'),'String',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Other1 file selected.');drawnow 
			end
		case 'select_data_d'                                                % Select Other2 input file      
			[name,path] = uigetfile({'*.mat;*.tsf;*.dat;*.csv',...
                'plotGrav supported (*.mat,*.tsf,*.dat,*.csv)';...
                '*.*','All files'},...
                'Select Other2 TSoft/DAT (Soil moisure), MAT or CSV file');
			if name == 0                                            
				set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_data_d_path'),'String',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Other2 file selected.');drawnow 
			end
		case 'select_tides'                                                 % Select file with tide effect
			[name,path] = uigetfile('*.tsf','Select a tsf file with tides (channel 1)');
			if name == 0                                            
				set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_tide_file'),'String',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Tides file selected.');drawnow 
			end
		case 'select_filter'                                                % Select file with filter impulse response. This file must be in fixed format, i.e., ETERNA minus header
			[name,path] = uigetfile('*.*','Select a tsf file with ETERNA filter (response)');
			if name == 0                                        
				set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_filter_file'),'String',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Fitler file selected.');drawnow 
			end
		case 'select_webcam'                                                % Select path with webcam snapshots. The snapshot Name structure is fixed, i.e. fixed prefix is used. See 'push_webcam' section
			path = uigetdir('Select Webcam Image Path');
			if path == 0                                               
				set(findobj('Tag','plotGrav_text_status'),'String','You must select the Webcam path.');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_webcam_path'),'String',path);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Webcam paht selected.');drawnow 
			end
		case 'select_unzip'                                                 % Select program for unzipping. 7zip commands are used in plotGrav_FTP.m function. plotGrav.m used build-in matlab unzip function
			[name,path] = uigetfile('*.exe','Select 7zip/Unzip file');
			if name == 0                                                
				set(findobj('Tag','plotGrav_text_status'),'String','You must select the Unzip file.');drawnow 
			else
				set(findobj('Tag','plotGrav_menu_ftp'),'UserData',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Unzip file selected.');drawnow 
			end
		case 'select_logfile'                                               % Select log file
			[name,path] = uiputfile('*.log','Select log file');
            if name == 0                                                
				set(findobj('Tag','plotGrav_text_status'),'String','You must select a log file.');drawnow 
			else
				set(findobj('Tag','plotGrav_edit_logfile_file'),'String',[path,name]);drawnow 
				set(findobj('Tag','plotGrav_text_status'),'String','Unzip file selected.');drawnow 
            end   
        
        case 'append_channels'
            %% Adding channels to panel
            % This function adds new channels to already loaded panel
            % providing some data (iGrav have been loaded prior calling
            % this function). All loaded channels will be resampled to
            % panel time vector!! New channels will be then appended to
            % existing ones.
            
            panel = char(varargin{1});
            
            data = get(findobj('Tag','plotGrav_push_load'),'UserData');     % load all time sereis
            if ~isempty(data.(panel))                                       % continue only if some data have been loaded
                % Open logfile for appending new message
                try
					fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
				catch
					fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                try
                    % Ge other data = time vector, uitable, existing channels
                    % and units (new values will be appended)
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time vectors. Time is used to detect missing values. Filter cannot be applied if missing data are note taking into account.
                    data_panel = get(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panel)),'Data');      % get the iGrav ui-table. Will be used to find selected/checked channels
                    units_panel = get(findobj('Tag',sprintf('plotGrav_text_%s',panel)),'UserData');         % get iGrav units. Will be used to set output/filtered time series units.
                    channels_panel = get(findobj('Tag',sprintf('plotGrav_edit_%s_path',panel)),'UserData'); % get iGrav channels (names). Will be used to derive output/filtered channel name.
                    % Prompt user to select new input file
                    set(findobj('Tag','plotGrav_text_status'),'String','Select file...');drawnow % status
                    % Open either dialog or use script input
                    if nargin == 2
                        [name,path] = uigetfile({'*.mat;*.tsf;*.dat;*.030;*.029;*.038',...
                            'plotGrav supported (*.mat,*.tsf,*.dat,*.030,*.029,*.038)';...
                            '*.*','All files'},...
                            'Select file for appending');
                        % Continue only if user select some file
                        if name ~= 0
                            input_file = fullfile(path,name);
                            file_selected = 1;
                        else
                            file_selected = 0;
                        end
                    else
                        input_file = char(varargin{2});
                        file_selected = 1;
                    end
                    
                    if file_selected == 0                                            
                        set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow 
                    else
                        % Get file type
                        switch input_file(end-2:end)
                            case 'tsf'
                                format_switch = 1;
                            case 'mat'
                                format_switch = 2;
                            case 'dat'
                                format_switch = 3;
                            case '029'
                                format_switch = 1;
                            case '030'
                                format_switch = 1;
                            case '038'
                                format_switch = 1;
                            otherwise
                                format_switch = 0;
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','Appending new channels...');drawnow % status
                        % Load data
                        [time_new,data_new,channels_new,units_new] = plotGrav_loadData(input_file,format_switch,[],[],[],panel);
                        % Get the current number of channels in panel
                        current_num = size(data.(panel),2);
                        % Interpolate to default time resolution
                        if ~isempty(time_new)
                            data.(panel)(:,current_num+1:current_num+size(data_new,2)) = interp1(time_new,data_new,time.(panel));
                            % Append new channel names and units
                            channels_panel = horzcat(reshape(channels_panel,[1,length(channels_panel)]),reshape(channels_new,[1,length(channels_new)]));
                            units_panel = horzcat(reshape(units_panel,[1,length(units_panel)]),reshape(units_new,[1,length(units_new)]));
                            % Append names to ui-table
                            for i = 1:length(channels_new)
                                data_panel(current_num+i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',...
                                    current_num+i,char(channels_new(i)),char(units_new(i))),false,false,false};
                            end
                            % Store updated variables
                            set(findobj('Tag','plotGrav_push_load'),'UserData',data);
                            set(findobj('Tag','plotGrav_text_status'),'UserData',time);
                            set(findobj('Tag',sprintf('plotGrav_uitable_%s_data',panel)),'Data',data_panel);      
                            set(findobj('Tag',sprintf('plotGrav_text_%s',panel)),'UserData',units_panel);         
                            set(findobj('Tag',sprintf('plotGrav_edit_%s_path',panel)),'UserData',channels_panel);
                            % Writte message to logfile
                            ttime = datevec(now);
                            fprintf(fid,'New channels appended to %s: %s (%04d/%02d/%02d %02d:%02d)\n',panel,input_file,...
                                ttime(1),ttime(2),ttime(3),ttime(4),ttime(5));
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Channels appended.');drawnow % status
                        end
                    end
                catch
                    if exist('fid','var') == 1
                        fclose(fid);
                    end
                    set(findobj('Tag','plotGrav_text_status'),'String','Data not appended.');drawnow % status
                end
            else
                set(findobj('Tag','plotGrav_text_status'),'String','Load main data first.');drawnow % status
            end
        case 'show_paths'
			%% SHOW PATHS
            % To see what files have been selected, user can open a new
            % figure with an overview about all selected paths and files.
            
            % Get all selected files/paths
			path_data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'String');
			path_data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'String');
			file_tides = get(findobj('Tag','plotGrav_edit_tide_file'),'String');
			file_filter = get(findobj('Tag','plotGrav_edit_filter_file'),'String');
			path_webcam = get(findobj('Tag','plotGrav_edit_webcam_path'),'String');
			file_data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'String');
			file_data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'String');
			unzip_exe = get(findobj('Tag','plotGrav_menu_ftp'),'UserData');
			file_logfile = get(findobj('Tag','plotGrav_edit_logfile_file'),'String');
            % Open new figure (do not plot to GUI)
			p3 = figure('Resize','on','Menubar','none','ToolBar','none',... % allow resizing if file names too long
				'NumberTitle','off','Color',[0.941 0.941 0.941],...
				'Name','plotGrav: paths/files settings');
            % Create uicontrols with file names and paths
			uicontrol(p3,'Style','Text','String','iGrav paht:','units','normalized',...
					'Position',[0.02,0.89,0.13,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',path_data_a,'units','normalized','HorizontalAlignment','left',...
					  'Position',[0.17,0.90,0.8,0.06],'FontSize',9,'BackgroundColor','w','Enable','off');
			uicontrol(p3,'Style','Text','String','TRiLOGi:','units','normalized',...
					  'Position',[0.02,0.82,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',path_data_b,'units','normalized',...
					  'Position',[0.17,0.83,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Other1 file:','units','normalized',...
					  'Position',[0.02,0.75,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',file_data_c,'units','normalized',...
					  'Position',[0.17,0.76,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Other2 file:','units','normalized',...
					  'Position',[0.02,0.68,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',file_data_d,'units','normalized',...
					  'Position',[0.17,0.69,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Tide/Pol file:','units','normalized',...
					  'Position',[0.02,0.61,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',file_tides,'units','normalized',...
					  'Position',[0.17,0.62,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Filter file:','units','normalized',...
					  'Position',[0.02,0.54,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',file_filter,'units','normalized',...
					  'Position',[0.17,0.55,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Webcam file:','units','normalized',...
					  'Position',[0.02,0.54-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',path_webcam,'units','normalized',...
					  'Position',[0.17,0.55-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Unzip exe:','units','normalized',...
					  'Position',[0.02,0.47-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',unzip_exe,'units','normalized',...
					  'Position',[0.17,0.48-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'HorizontalAlignment','left','Enable','off');
			uicontrol(p3,'Style','Text','String','Logfile:','units','normalized',...
					  'Position',[0.02,0.40-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
			uicontrol(p3,'Style','Edit','String',file_logfile,'units','normalized',...
					  'Position',[0.17,0.41-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
					  'Enable','off','HorizontalAlignment','left');
		  
    end                                                                     % nargin == 0
end