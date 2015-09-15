function plotGrav(in_switch)
%PLOTGRAV visualize iGrav-006 data
% This GUI is designed for iGrav006. Visualisation of data obtained by other
% iGravs would need source code modifications. The aim of this function is
% to visualize time series recorded by iGrav as well as iGFE (field
% enclosure). Further updates will allow visualisation of other time series
% (Other1, e.g., soil moisture and Other2, e.g., groundwater).
% 
% Required functions:
%   plotGrav_conv.m
%   plotGrav_findTimeStep.m
%   plotGrav_fit.m
%   plotGrav_FTP.m
%   plotGrav_loadtsf.m
%   plotGrav_plotData.m
%   plotGrav_spectralAnalysis.m
%   plotGrav_writetsf.m
% This functions should be stored in the same folder as plotGrav.m
% 
% Some comments:
% - it is allowed to run only one window per Matlab.
% - this function was tested using Matlab r2013a + statistical toolbox + 
%   curve fitting + signal processing toolbox.
% - should work also using Matlab r2014b .
% - after loading, the function adds 7 new channels to the iGrav tsf. These
%   are the filtered and corrected gravity values (provided filter and
%   tides are set correctly). The filtered values are obtained after
%   convolution corrected for phase shift and interpolated to original time
%   resolution.
% - be patient, it take some time to read all data an plot it.
% - the spectral analysis can be computed for the longest interval without
%   interruption or for re-interpolated time series.
% - prior to the spectral anlysis, a linear trend is removed.
% - TRiLOGi files contain many errors. Therefore, check the code if new
%   TRiLOGi version is available.
% - It is not recommented to compute spectral analysis for TRiLOGi data
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
%                                                   M.Mikolaj, 21.7.2015
%                                                   mikolaj@gfz-potsdam.de

if nargin == 0
    check_open_window = get(findobj('Tag','plotGrav_check_legend'),'Value'); % check if no other plotGrav window is open (works only with one window)
    if numel(check_open_window)>0
        fprintf('Please use only one app window in Matlab\n')               % send message to command window
    else
        %% Generate GUI
        % SET PATHS!!
        path_igrav = '\\dms\hygra\iGrav\iGrav006 Data\';
        path_trilogi = '\\dms\hygra\iGrav\iGrav006 Data\Controller Data\';
        file_tides = '\\dms\hygra\iGrav\Software\plotGrav\WE_iGrav_TideEffect_CurrentFile_60sec.tsf';
        file_filter = '\\dms\hygra\iGrav\Software\plotGrav\N01S1M01.NLF';
        file_unzip = 'E:\Program Files\7-Zip\7z.exe';
        path_webcam = '\\dms\hygra\iGrav\iGrav006 Webcam';
        file_other1 = '';
        file_other2 = '';
        file_logfile = 'plotGrav_LOG_FILE.log';
        
        scrs = get(0,'screensize');
        F1 = figure('Position',[50 50 scrs(3)-50*2, scrs(4)-50*3],...       % create main window
                    'Tag','plotGrav_main_menu','Resize','on','Menubar','none','ToolBar','none',...
                    'NumberTitle','off','Color',[0.941 0.941 0.941],...
                    'Name','plotGrav: plot iGrav data');
        % File
        m1 = uimenu('Label','File');
        m10 = uimenu(m1,'Label','Select');
        m101=uimenu(m10,'Label','iGrav');
                uimenu(m101,'Label','Path','CallBack','plotGrav select_igrav');
                uimenu(m101,'Label','File','CallBack','plotGrav select_igrav_file');
        m102 = uimenu(m10,'Label','TRiLOGi');
                uimenu(m102,'Label','Path','CallBack','plotGrav select_trilogi');
                uimenu(m102,'Label','File','CallBack','plotGrav select_trilogi_file');
        uimenu(m10,'Label','Other1 tsf/dat file','CallBack','plotGrav select_other1');
        uimenu(m10,'Label','Other2 tsf/dat file','CallBack','plotGrav select_other2');
        uimenu(m10,'Label','Tides tsf file','CallBack','plotGrav select_tides');
        uimenu(m10,'Label','Filter file','CallBack','plotGrav select_filter');
        uimenu(m10,'Label','Webcam path','CallBack','plotGrav select_webcam');
        uimenu(m10,'Label','7zip exe','CallBack','plotGrav select_unzip');
        uimenu(m10,'Label','Log File','CallBack','plotGrav select_logfile');
        m12 = uimenu(m1,'Label','Export');
        m121 = uimenu(m12,'Label','Stacked iGrav data');
              uimenu(m121,'Label','All channels','Callback','plotGrav export_igrav_all');
              uimenu(m121,'Label','Selected channels (L1)','Callback','plotGrav export_igrav_sel');
        m122  = uimenu(m12,'Label','Stacked TRiLOGi data');
              uimenu(m122,'Label','All channels','Callback','plotGrav export_trilogi_all');
              uimenu(m122,'Label','Selected channels (L1)','Callback','plotGrav export_trilogi_sel');
        m13 = uimenu(m1,'Label','Print');
        	  uimenu(m13,'Label','All plots','CallBack','plotGrav print_all',...
                         'Tag','plotGrav_menu_print_all','UserData',[]);
        	  uimenu(m13,'Label','Plot 1 (L1+R1)','CallBack','plotGrav print_one',...
                         'Tag','plotGrav_menu_print_one','UserData',[]);
        	  uimenu(m13,'Label','Plot 2 (L2+R2)','CallBack','plotGrav print_two',...
                         'Tag','plotGrav_menu_print_two','UserData',[]);
        	  uimenu(m13,'Label','Plot 3 (L3+R3)','CallBack','plotGrav print_three',...
                         'Tag','plotGrav_menu_print_three','UserData',[]);
        uimenu(m1,'Label','Connect to FTP','CallBack','plotGrav_FTP','Tag',...
                  'plotGrav_menu_ftp','UserData',file_unzip);
        m14 = uimenu(m1,'Label','Correction file');
              uimenu(m14,'Label','Apply','CallBack','plotGrav correction_file','Tag',...
                  'plotGrav_menu_correction_file','UserData',[]);
              uimenu(m14,'Label','Show','CallBack','plotGrav correction_file_show','Tag',...
                  'plotGrav_menu_correction_file','UserData',[]);
        % View
        m2 = uimenu('Label','View');
            uimenu(m2,'Label','Convert/Update date','Callback','plotGrav push_date');
        m20 = uimenu(m2,'Label','Earthquakes');
            uimenu(m20,'Label','List','CallBack','plotGrav show_earthquake',...
                      'UserData','http://geofon.gfz-potsdam.de/eqinfo/list.php','Tag','plotGrav_menu_show_earthquake');
            uimenu(m20,'Label','Plot (last 20)','CallBack','plotGrav plot_earthquake',...
                      'Tag','plotGrav_menu_plot_earthquake','UserData','http://geofon.gfz-potsdam.de/eqinfo/list.php?latmin=&latmax=&lonmin=&lonmax=&magmin=');
            uimenu(m2,'Label','File paths','CallBack','plotGrav show_paths',...
                      'UserData',[],'Tag','plotGrav_menu_show_pahts');
            uimenu(m2,'Label','Filter','CallBack','plotGrav show_filter',...
                      'UserData',[],'Tag','plotGrav_menu_show_filter');
            uimenu(m2,'Label','Reset view','Callback','plotGrav reset_view');
        m22 = uimenu(m2,'Label','Label/Legend');
            uimenu(m22,'Label','Label','Callback','plotGrav show_label');
            uimenu(m22,'Label','Legend','Callback','plotGrav show_legend');
            uimenu(m22,'Label','Grid','Callback','plotGrav show_grid');
        m21 = uimenu(m2,'Label','Reverse Y axis');
            uimenu(m21,'Label','L1','Callback','plotGrav reverse_l1','UserData',1,...
                      'Tag','plotGrav_menu_reverse_l1');
            uimenu(m21,'Label','R1','Callback','plotGrav reverse_r1','UserData',1,...
                      'Tag','plotGrav_menu_reverse_r1');
            uimenu(m21,'Label','L2','Callback','plotGrav reverse_l2','UserData',1,...
                      'Tag','plotGrav_menu_reverse_l2');
            uimenu(m21,'Label','R2','Callback','plotGrav reverse_r2','UserData',1,...
                      'Tag','plotGrav_menu_reverse_r2');
            uimenu(m21,'Label','L3','Callback','plotGrav reverse_l3','UserData',1,...
                      'Tag','plotGrav_menu_reverse_l3');
            uimenu(m21,'Label','R3','Callback','plotGrav reverse_r3','UserData',1,...
                      'Tag','plotGrav_menu_reverse_r3');
        m23 = uimenu(m2,'Label','Set Y axis');
            uimenu(m23,'Label','L1','Callback','plotGrav set_y_L1');
            uimenu(m23,'Label','R1','Callback','plotGrav set_y_R1');
            uimenu(m23,'Label','L2','Callback','plotGrav set_y_L2');
            uimenu(m23,'Label','R2','Callback','plotGrav set_y_R2');
            uimenu(m23,'Label','L3','Callback','plotGrav set_y_L3');
            uimenu(m23,'Label','R3','Callback','plotGrav set_y_R3');
            uimenu(m2,'Label','Select point','Callback','plotGrav select_point');
            uimenu(m2,'Label','Webcam','Callback','plotGrav push_webcam',...
                      'Tag','plotGrav_menu_webcam','UserData',path_webcam);
            uimenu(m2,'Label','Zoom in','Callback','plotGrav push_zoom_in','UserData',[]);
            
        % Compute
        m3 = uimenu('Label','Compute');
        	  uimenu(m3,'Label','Algebra','CallBack','plotGrav simple_algebra');
              uimenu(m3,'Label','Atmacs','CallBack','plotGrav get_atmacs');
        m30 = uimenu(m3,'Label','Correlation');
              uimenu(m30,'Label','Simple all','CallBack','plotGrav correlation_matrix');
              uimenu(m30,'Label','Simple select','CallBack','plotGrav correlation_matrix_select');
              uimenu(m30,'Label','Cross','CallBack','plotGrav correlation_cross');
        	  uimenu(m3,'Label','Difference','CallBack','plotGrav compute_difference');
        m32 = uimenu(m3,'Label','EOF/PCA');
              uimenu(m32,'Label','Compute','CallBack','plotGrav compute_eof',...
                  'Tag','plotGrav_menu_compute_eof','UserData',[]);
              uimenu(m32,'Label','Export PCs','CallBack','plotGrav export_pcs',...
                  'Tag','plotGrav_menu_compute_export_pcs','UserData',[]);
              uimenu(m32,'Label','Export reconstucted time.series','CallBack','plotGrav export_rec_time_series',...
                  'Tag','plotGrav_menu_compute_export_rec','UserData',[]);
              uimenu(m32,'Label','Export EOP pattern','CallBack','plotGrav export_eop_pattern',...
                  'Tag','plotGrav_menu_compute_export_rec','UserData',[]);
        uimenu(m3,'Label','Filter channel','CallBack','plotGrav compute_filter_channel');
        m31 =  uimenu(m3,'Label','Spectral analysis');
               uimenu(m31,'Label','Max valid interval','Callback','plotGrav compute_spectral_valid');
               uimenu(m31,'Label','Ignore NaNs (interpolate)','Callback','plotGrav compute_spectral_interp');
               uimenu(m3,'Label','Statistics','Callback','plotGrav compute_statistics');
        m33 = uimenu(m3,'Label','Fit');
              uimenu(m33,'Label','Subtract mean','CallBack','plotGrav fit_constant');
              uimenu(m33,'Label','Linear','CallBack','plotGrav fit_linear');
              uimenu(m33,'Label','Quadratic','CallBack','plotGrav fit_quadratic');
              uimenu(m33,'Label','Cubic','CallBack','plotGrav fit_cubic');
              uimenu(m33,'Label','Set coefficients','CallBack','plotGrav fit_user_set');
%        m331 = uimenu(m33,'Label','Sine');
%               uimenu(m331,'Label','One','CallBack','plotGrav fit_sine1');
        m33 = uimenu(m3,'Label','Fit locally');
              uimenu(m33,'Label','Linear','CallBack','plotGrav fit_linear_local');
              uimenu(m33,'Label','Quadratic','CallBack','plotGrav fit_quadrat_local');
              uimenu(m33,'Label','Cubic','CallBack','plotGrav fit_cubic_local');
            
        uimenu(m3,'Label','Pol+LOD','CallBack','plotGrav get_polar');
        uimenu(m3,'Label','Regression','CallBack','plotGrav regression_simple');
        uimenu(m3,'Label','Resample','CallBack','plotGrav compute_decimate');

        m4  = uimenu('Label','Edit');
        m42  = uimenu(m4,'Label','Insert');
        m41 = uimenu(m4,'Label','Remove');
              uimenu(m41,'Label','Channel','CallBack','plotGrav compute_remove_channel');
        m414 = uimenu(m41,'Label','Inserted');
        m4141 = uimenu(m414,'Label','Ellipse');
              uimenu(m4141,'Label','All','CallBack','plotGrav remove_circle');
              uimenu(m4141,'Label','Last','CallBack','plotGrav remove_circle_last');
        m4142 = uimenu(m414,'Label','Line');
              uimenu(m4142,'Label','All','CallBack','plotGrav remove_line');
              uimenu(m4142,'Label','Last','CallBack','plotGrav remove_line_last');
        m4143 = uimenu(m414,'Label','Rectangles');
              uimenu(m4143,'Label','All','CallBack','plotGrav remove_rectangle');
              uimenu(m4143,'Label','Last','CallBack','plotGrav remove_rectangle_last');
        m4144 = uimenu(m414,'Label','Text');
              uimenu(m4144,'Label','All','CallBack','plotGrav remove_text');
              uimenu(m4144,'Label','Last','CallBack','plotGrav remove_text_last');
        m411 = uimenu(m41,'Label','Interval');
              uimenu(m411,'Label','Selected channel','CallBack','plotGrav remove_interval_selected');
              uimenu(m411,'Label','All channels','CallBack','plotGrav remove_interval_all');
        m413 = uimenu(m41,'Label','Spikes');
              uimenu(m413,'Label','> 3 SD','CallBack','plotGrav remove_3sd');
              uimenu(m413,'Label','> 2 SD','CallBack','plotGrav remove_2sd');
        m412 = uimenu(m41,'Label','Step');
              uimenu(m412,'Label','Selected channel','CallBack','plotGrav remove_step_selected');
              uimenu(m412,'Label','All gravity channels','CallBack','plotGrav remove_step_all');
        
              uimenu(m42,'Label','Rectangle','CallBack','plotGrav insert_rectangle',...
                     'Tag','plotGrav_insert_rectangle','UserData',[]);
              uimenu(m42,'Label','Ellipse','CallBack','plotGrav insert_circle',...
                     'Tag','plotGrav_insert_circle','UserData',[]);
              uimenu(m42,'Label','Line','CallBack','plotGrav insert_line',...
                     'Tag','plotGrav_insert_line','UserData',[]);
              uimenu(m42,'Label','Text','CallBack','plotGrav insert_text',...
                     'Tag','plotGrav_insert_text','UserData',[]);
        m43 = uimenu(m4,'Label','Copy');
              uimenu(m43,'Label','Channel','CallBack','plotGrav compute_copy_channel');
        
        % Panels
        p1 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','iGrav','R1','R2','R3'},...
                    'Position',[0.01,0.25,0.13,0.50],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
                    'Tag','plotGrav_uitable_igrav_data','Visible','on','FontSize',9,'RowName',[],...
                    'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],...
                    'CellEditCallback','plotGrav uitable_push','UserData',[]);
        p2 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','TRiLOGi','R1','R2','R3'},...
                    'Position',[0.145,0.25,0.13,0.50],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
                    'Tag','plotGrav_uitable_trilogi_data','Visible','on','FontSize',9,'RowName',[],...
                    'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],...
                    'CellEditCallback','plotGrav uitable_push','UserData',[]);
        p3 = uipanel(F1,'Units','normalized','Position',[0.01,0.76,0.265,0.33-0.10],...
                     'Tag','plotGrav_uipanel_settings','Title','Settings','FontSize',9,...
                     'UserData',[]);
        p4 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','Other1','R1','R2','R3'},...
                    'Position',[0.01,0.02,0.13,0.22],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
                    'Tag','plotGrav_uitable_other1_data','Visible','on','FontSize',9,'RowName',[],...
                    'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],'CellEditCallback','plotGrav uitable_push');
        p5 = uitable(F1,'Units','normalized','ColumnName',{'L1','L2','L3','Other2','R1','R2','R3'},...
                    'Position',[0.145,0.02,0.13,0.22],'ColumnFormat',{'logical','logical','logical','char','logical','logical','logical'},...
                    'Tag','plotGrav_uitable_other2_data','Visible','on','FontSize',9,'RowName',[],...
                    'ColumnWidth',{24,24,24,'auto',24,24,24},'ColumnEditable',[true,true,true,false,true,true,true],'CellEditCallback','plotGrav uitable_push');
        % PLOT SETTINGS        
              % Time text
        uicontrol(p3,'Style','Text','String','Time min.:','units','normalized',...
                  'Position',[0.02,0.56+0.29,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Text','String','Time max.:','units','normalized',...
                  'Position',[0.02,0.44+0.29,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');   
        uicontrol(p3,'Style','Text','String','year','units','normalized',...
                  'Position',[0.16,0.61+0.32,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Text','String','month','units','normalized',...
                  'Position',[0.26,0.61+0.32,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Text','String','day','units','normalized',...
                  'Position',[0.345,0.61+0.32,0.10,0.09],'FontSize',8);
        uicontrol(p3,'Style','Text','String','hour','units','normalized',...
                  'Position',[0.44,0.61+0.32,0.10,0.09],'FontSize',8);
              % Time edit
        temp = now;temp = datevec(temp-8);                                  % get current time and covert it to calendar/time - 8 days
        uicontrol(p3,'Style','Edit','String',sprintf('%04d',temp(1)),'units','normalized',...
                  'Position',[0.17,0.565+0.29,0.09,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_year');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',temp(2)),'units','normalized',...
                  'Position',[0.27,0.565+0.29,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_month');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',temp(3)),'units','normalized',...
                  'Position',[0.36,0.565+0.29,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_day');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',00),'units','normalized',...
                  'Position',[0.45,0.565+0.29,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_start_hour');
        temp = now;temp = datevec(temp-1);                                  % get current time and covert it to calendar/time - one day
        uicontrol(p3,'Style','Edit','String',sprintf('%04d',temp(1)),'units','normalized',...
                  'Position',[0.17,0.445+0.29,0.09,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_year');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',temp(2)),'units','normalized',...
                  'Position',[0.27,0.445+0.29,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_month');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',temp(3)),'units','normalized',...
                  'Position',[0.36,0.445+0.29,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_day');
        uicontrol(p3,'Style','Edit','String',sprintf('%02d',23),'units','normalized',...
                  'Position',[0.45,0.445+0.29,0.08,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_time_stop_hour');
              % Calib factor + admittance
        uicontrol(p3,'Style','Text','String','Calibration:','units','normalized',...
                  'Position',[0.54,0.56+0.29,0.15,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String','-914.78','units','normalized',...
                  'Position',[0.70,0.56+0.29,0.12,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_calb_factor');
        uicontrol(p3,'Style','Edit','String','-14.2','units','normalized',...
                  'Position',[0.83,0.56+0.29,0.12,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_calb_delay');
        uicontrol(p3,'Style','Text','String','nm/s^2 / V','units','normalized',...
                  'Position',[0.70,0.61+0.33,0.15,0.09],'FontSize',8,'HorizontalAlignment','left',...
                  'Tag','plotGrav_text_nms2','UserData',[]);
        uicontrol(p3,'Style','Text','String','seconds','units','normalized',...
                  'Position',[0.85,0.61+0.33,0.13,0.09],'FontSize',8,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Text','String','Admittance:','units','normalized',...
                  'Position',[0.54,0.44+0.29,0.15,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String','-2.9','units','normalized',...
                  'Position',[0.70,0.445+0.29,0.12,0.09],'FontSize',9,'BackgroundColor','w',...
                  'tag','plotGrav_edit_admit_factor');
        uicontrol(p3,'Style','Text','String','nm/s^2 / hPa','units','normalized',...
                  'Position',[0.83,0.44+0.29,0.16,0.09],'FontSize',9,'HorizontalAlignment','left');
              % Drift+Resampling
        uicontrol(p3,'Style','Text','String','Drift fit:','units','normalized',...
                  'Position',[0.02,0.60,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Popupmenu','String','none|constant value|linear|quadratic|cubic','units','normalized',...
                  'Position',[0.17,0.66,0.18,0.05],'FontSize',9,'Tag','plotGrav_pupup_drift','backgroundcolor','w',...
                  'Value',1);
        uicontrol(p3,'Style','Text','String','Resample:','units','normalized',...
                  'Position',[0.54,0.60,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String','60','units','normalized',...
                  'Position',[0.7,0.605,0.12,0.09],'FontSize',9,'Tag','plotGrav_edit_resample','backgroundcolor','w');
        uicontrol(p3,'Style','Text','String','seconds','units','normalized',...
                  'Position',[0.83,0.60,0.16,0.09],'FontSize',9,'HorizontalAlignment','left');
              % Show
        uicontrol(p3,'Style','Checkbox','String','Grid','units','normalized',...
                  'Position',[0.02,0.45,0.13,0.09],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_check_grid','Value',1,'Visible','off');
        uicontrol(p3,'Style','Checkbox','String','Legend','units','normalized',...
                  'Position',[0.02,0.32,0.13,0.09],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_check_legend','Value',1,'Visible','off');
        uicontrol(p3,'Style','Checkbox','String','Labels','units','normalized',...
                  'Position',[0.02,0.20,0.13,0.09],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_check_labels','Value',1,'Visible','off');
        uicontrol(p3,'Style','Pushbutton','String','Rem. interval','units','normalized',...
                  'Position',[0.17,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_date','Value',0,'CallBack','plotGrav remove_interval_all',...
                  'UserData',0);
        uicontrol(p3,'Style','Pushbutton','String','Zoom in','units','normalized',...
                  'Position',[0.37,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_zoom_in','Value',0,'CallBack','plotGrav push_zoom_in',...
                  'UserData',[]);
        uicontrol(p3,'Style','Pushbutton','String','Reset view','units','normalized',...
                  'Position',[0.57,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_reset_view','Value',0,'CallBack','plotGrav reset_view',...
                  'UserData',[0 0 0]);
        uicontrol(p3,'Style','Pushbutton','String','Uncheck all','units','normalized',...
                  'Position',[0.77,0.41,0.18,0.12],'FontSize',9,'HorizontalAlignment','left',...
                  'Tag','plotGrav_push_push_uncheck_all','Value',0,'CallBack','plotGrav uncheck_all',...
                  'UserData',[]);
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
              
                % Text input
        uicontrol(p3,'Style','Text','String','User input:','units','normalized',...
                  'Tag','plotGrav_text_input','UserData',[],'Visible','off',...
                  'Position',[0.02,0.15,0.13,0.09],'FontSize',9,'HorizontalAlignment','left');
        uicontrol(p3,'Style','Edit','String','','units','normalized','Visible','off',...
                  'Position',[0.17,0.16,0.81,0.09],'FontSize',9,'BackgroundColor','w',...
                  'Tag','plotGrav_edit_text_input','HorizontalAlignment','left','UserData',[]);
              % Load + status
        uicontrol(p3,'Style','pushbutton','String','Load data','units','normalized',...
                  'Position',[0.80,0.02,0.18,0.13],'FontSize',9,'FontWeight','bold','Tag',...
                  'plotGrav_push_load','CallBack','plotGrav load_all_data','UserData',[]);
        uicontrol(p3,'units','normalized','Position',[0.02,0.030,0.73,0.09],'Style','Text',...
            'FontSize',9,'FontAngle','italic','String','Check the settings and press Load data ->',...
            'Tag','plotGrav_text_status','UserData',[]);
                % Paths/files (invisible)
        p30 = uipanel(F1,'Units','normalized','Position',[0.01,0.76,0.265,0.33-0.10],...
                     'Tag','plotGrav_uipanel_settings','Title','Settings','FontSize',9,...
                     'UserData',[],'Visible','off');
                uicontrol(p30,'Style','Text','String','iGrav paht:','units','normalized',...
                  'Tag','plotGrav_text_igrav','UserData',[],...
                  'Position',[0.02,0.89,0.13,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p30,'Style','Edit','String',path_igrav,'units','normalized',...
                          'Position',[0.17,0.90,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_igrav_path','HorizontalAlignment','left','UserData',[]);
                uicontrol(p30,'Style','Text','String','TRiLOGi:','units','normalized',...
                          'Tag','plotGrav_text_trilogi','UserData',[],...
                          'Position',[0.02,0.82,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p30,'Style','Edit','String',path_trilogi,'units','normalized',...
                          'Position',[0.17,0.83,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_trilogi_path','HorizontalAlignment','left','UserData',[]);
                uicontrol(p30,'Style','Text','String','Other1 file:','units','normalized','UserData',[],...
                          'Position',[0.02,0.75,0.145,0.06],'FontSize',9,'HorizontalAlignment','left',...
                          'Tag','plotGrav_text_other1');
                uicontrol(p30,'Style','Edit','String',file_other1,'units','normalized','UserData',[],...
                          'Position',[0.17,0.76,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_other1_path','HorizontalAlignment','left','UserData',[]);
                uicontrol(p30,'Style','Text','String','Other2 file:','units','normalized',...
                          'Position',[0.02,0.68,0.145,0.06],'FontSize',9,'HorizontalAlignment','left',...
                          'Tag','plotGrav_text_other2','UserData',[]);
                uicontrol(p30,'Style','Edit','String',file_other2,'units','normalized','UserData',[],...
                          'Position',[0.17,0.69,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_other2_path','HorizontalAlignment','left');
                uicontrol(p30,'Style','Text','String','Tide/Pol file:','units','normalized',...
                          'Position',[0.02,0.61,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p30,'Style','Edit','String',file_tides,'units','normalized',...
                          'Position',[0.17,0.62,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_tide_file','HorizontalAlignment','left');
                uicontrol(p30,'Style','Text','String','Filter file:','units','normalized',...
                          'Position',[0.02,0.54,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p30,'Style','Edit','String',file_filter,'units','normalized',...
                          'Position',[0.17,0.55,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_filter_file','HorizontalAlignment','left');
                uicontrol(p30,'Style','Text','String','Webcam file:','units','normalized',...
                          'Position',[0.02,0.54-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p30,'Style','Edit','String',path_webcam,'units','normalized',...
                          'Position',[0.17,0.55-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_webcam_path','HorizontalAlignment','left');
                uicontrol(p30,'Style','Text','String','Logfile:','units','normalized',...
                          'Position',[0.02,0.47-0.07,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p30,'Style','Edit','String',file_logfile,'units','normalized',...
                          'Position',[0.17,0.48-0.07,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'Tag','plotGrav_edit_logfile_file','HorizontalAlignment','left');
                      
              
        % AXES
        aL1 = axes('units','normalized','Position',[0.33,0.71,0.63,0.26],'Tag','axesL1','FontSize',9);
        aR1 = axes('units','normalized','Position',[0.33,0.71,0.63,0.26],'Tag','axesR1',...
            'color','none','YAxisLocation','right','FontSize',9);
        ylabel(aL1,'L1');ylabel(aR1,'R1');
        set(findobj('Tag','plotGrav_check_grid'),'UserData',[aL1,aR1]);
        aL2 = axes('units','normalized','Position',[0.33,0.39,0.63,0.26],'Tag','axesL2','FontSize',9);
        aR2 = axes('units','normalized','Position',[0.33,0.39,0.63,0.26],'Tag','axesR2','FontSize',9,...
            'color','none','YAxisLocation','right');
        ylabel(aL2,'L2');ylabel(aR2,'R2');
        set(findobj('Tag','plotGrav_check_legend'),'UserData',[aL2,aR2]);
        aL3 = axes('units','normalized','Position',[0.33,0.06,0.63,0.26],'Tag','axesL3','FontSize',9);
        aR3 = axes('units','normalized','Position',[0.33,0.06,0.63,0.26],'Tag','axesR3','FontSize',9,...
            'color','none','YAxisLocation','right');
        ylabel(aL3,'L3');ylabel(aR3,'R3');
        set(findobj('Tag','plotGrav_check_labels'),'UserData',[aL3,aR3]);
        
        plotGrav('reset_tables');
        
        color_scale = [1 0 0;0 1 0;0 0 1;0 0 0;1 1 0;0 0.5 0;0.5 0.5 0.5;0.6 0.2 0.0;0.75 0.75 0.75;0.85 0.16 0;0.53 0.32 0.32]; % crate colours (for plots)
        color_scale(length(color_scale)+1:100,1) = 1;                       % remaining lines = red
        set(findobj('Tag','plotGrav_text_nms2'),'UserData',color_scale);
        
        %%
    end % numel(check_open_window)>0
    else
        warning('off');                                                     % turn off warning (especially for polynomial fitting)
        switch in_switch
            case 'load_all_data'
                plotGrav('reset_tables');                                   % reset all tables
                %% Get user inputs
                set(findobj('Tag','plotGrav_text_status'),'String','Starting...');drawnow % drawnow = right now
                start_time = [str2double(get(findobj('Tag','plotGrav_edit_time_start_year'),'String')),... % Get date of start year
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_month'),'String')),... % month
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_day'),'String')),...   % day
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_hour'),'String')),0,0];% hour (minutes and seconds == 0)  
                
                end_time = [str2double(get(findobj('Tag','plotGrav_edit_time_stop_year'),'String')),... % Get date of end
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_month'),'String')),... % month
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_day'),'String')),...   % day
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_hour'),'String')),0,0];% hour (minutes and seconds == 0)  
                
                file_path_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'String'); % iGrav path
                file_path_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'String'); % get TRiLOGi path
                file_path_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'String'); % get Ohter1 path
                file_path_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'String'); % get Other2 path
                tide_file = get(findobj('Tag','plotGrav_edit_tide_file'),'String'); % get tidal effect file
                filter_file = get(findobj('Tag','plotGrav_edit_filter_file'),'String'); % get filter file
%                 unzip_exe = get(findobj('Tag','plotGrav_menu_ftp'),'UserData');
                
                calib_factor = str2double(get(findobj('Tag','plotGrav_edit_calb_factor'),'String'));  % get calibration factor
                calib_delay = str2double(get(findobj('Tag','plotGrav_edit_calb_delay'),'String'));  % get calibration factor
                admittance_factor = str2double(get(findobj('Tag','plotGrav_edit_admit_factor'),'String'));  % get admittance factor
                drift_fit = get(findobj('Tag','plotGrav_pupup_drift'),'Value');  % get admittance factor
                
                igrav_prefix = 'Data_iGrav006_';                            % iGrav file prefix
                trilogi_suffix = '_ENC12345.tsf';                           % trilogi file suffix (except 001, 002,...)
                trilogi_channels = 40;                                      % number of trilogi channels
                igrav_channels = 21;                                        % number of igrav channels (original file)
                igrav_time_resolution = 1;                                  % igrav time sampling in seconds
                time_in(:,7) = [datenum(start_time):1:datenum(end_time)]';  % create input time vector (matlab format)
                time_in(:,1:6) = datevec(time_in(:,7));                 % crate input time matrix (calendar date + time)             
                
                try
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'w');
                catch
                    fid = fopen('plotGrav_LOG_FILE.log','w');
                end
                fprintf(fid,'plotGrav LogFile: recording since pressing Load Data button\nLoading data between: %04d/%02d/%02d %02d  - %04d/%02d/%02d %02d\n',...
                    time_in(1,1),time_in(1,2),time_in(1,3),time_in(1,4),time_in(end,1),time_in(end,2),time_in(end,3),time_in(end,4));
                %% Load iGrav data
                if ~isempty(file_path_igrav)
                    time.igrav = [];                                        % prepare variable (time.igrav will store time in matlab format)
                    data.igrav = [];                                        % prepare variable (data.igrav will store tsoft channels)
                    igrav_loaded = 0;                                       % aux. variable to check if at least one file has been loaded
                    if strcmp(file_path_igrav(end-3:end),'.tsf')            % switch between file/folder input
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav/TSF data...');drawnow % send message to status bar
                        try
                            [time.igrav,data.igrav,channels_igrav,units_igrav] = plotGrav_loadtsf(file_path_igrav); % load data
                            for i = 1:length(channels_igrav)
                                temp = strsplit(char(channels_igrav(i)),':');  % split string (Location:Intrument:Measurement). See plotGrav_loadtsf functions
                                channels_igrav(i) = temp(end);         % set channel name
                                data_table_igrav(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false}; % update table
                                clear temp                              % remove temp variable
                            end
                            set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',...
                                    data_table_igrav,'UserData',data_table_igrav);
                            set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % store Data
                            set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % store hannel names
                            if length(find(isnan(data.igrav))) ~= numel(data.igrav) % check if loaded data contains numeric values
                                data.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = []; % remove time epochs out of requested range
                                time.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = [];
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'igrav data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                igrav_loaded = 2;
                            else
                                data.igrav = [];                                  % otherwise empty
                                time.igrav = [];
                                fprintf(fid,'No iGrav data loaded\n');
                            end
                            set(findobj('Tag','plotGrav_uitable_igrav_data'),'data',...
                                    get(findobj('Tag','plotGrav_uitable_igrav_data'),'UserData')); % store data! This data will be then loaded
                        catch
                            data.igrav = [];                                    % otherwise empty
                            time.igrav = [];
                            fprintf(fid,'No iGrav data loaded\n');
                            fprintf('Could not load iGrav data: %s\n',file_path_igrav);
                        end
                    elseif strcmp(file_path_igrav(end-3:end),'.mat')            % switch between file/folder input
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav/MAT data...');drawnow % send message to status bar
                        try
                            temp = importdata(file_path_igrav);
                            time.igrav = datenum(double(temp.time));temp.time = [];
                            data.igrav = double(temp.data);temp.data = [];
                            channels_igrav = temp.channels;
                            units_igrav = temp.units;
                            clear temp
                            for i = 1:length(channels_igrav)
                                data_table_igrav(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false}; % update table
                            end
                            set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',...
                                    data_table_igrav,'UserData',data_table_igrav);
                            set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % store Data
                            set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % store hannel names
                            if length(find(isnan(data.igrav))) ~= numel(data.igrav) % check if loaded data contains numeric values
                                data.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = []; % remove time epochs out of requested range
                                time.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = [];
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'igrav data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                igrav_loaded = 2;
                            else
                                data.igrav = [];                                  % otherwise empty
                                time.igrav = [];
                                fprintf(fid,'No iGrav data loaded\n');
                            end
                            set(findobj('Tag','plotGrav_uitable_igrav_data'),'data',...
                                    get(findobj('Tag','plotGrav_uitable_igrav_data'),'UserData')); % store data! This data will be then loaded
                        catch
                            data.igrav = [];                                    % otherwise empty
                            time.igrav = [];
                            fprintf(fid,'No iGrav data loaded\n');
                            fprintf('Could not load iGrav data: %s\n',file_path_igrav);
                        end
                    elseif strcmp(file_path_igrav(end-3:end),'.030')        % read SG030 data
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading SG030 data...');drawnow % send message to status bar
                        for i = 1:length(time_in(:,7))                      % for loop for each day
                            try  
                                set(findobj('Tag','plotGrav_text_status'),'String',...
                                    sprintf('Loading SG030 data...%04d/%02d/%02d',time_in(i,1),time_in(i,2),time_in(i,3)));drawnow % send message to status bar
                                file_name = sprintf('%s%02d%02d%02d.030',file_path_igrav(1:end-10),abs(time_in(i,1)-2000),time_in(i,2),time_in(i,3)); % create file name
                                [ttime,tdata] = plotGrav_loadtsf(file_name);    % load file and store to temporary variables
                                if max(abs(diff(ttime))) > 1.9/86400 && max(abs(diff(ttime))) <= 10/86400 % interpolate if max missing time interval is < 10 seconds (and >= 2 seconds)
                                    ntime = [ttime(1):1/86400:ttime(end)]';     % new time vector with one second resolution
                                    tdata = interp1(ttime,tdata,ntime,'linear');% interpolate value for new time vector
                                    ttime = ntime;clear ntime;
                                    [ty,tm,td,th,tmm] = datevec(now);       % prepare variables for Logfile
                                    fprintf(fid,'SG030 missing data interpolation (max 10 seconds):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
                                end
                                ntime = ttime;ndata = tdata;                % temp. variables
                                ntime(isnan(sum(ndata(:,1:3),2))) = [];     % remove NaNs
                                ndata(isnan(sum(ndata(:,1:3),2)),:) = [];
                                if max(abs(diff(ntime))) > 1.9/86400 && max(abs(diff(ntime))) <= 10/86400 % interpolate if max missing time interval is < 10 seconds (and >= 2 seconds
                                    tdata = interp1(ntime,ndata,ttime,'linear');% interpolate value for new time vector
                                    clear ntime ndata;
                                    [ty,tm,td,th,tmm] = datevec(now);       % prepare variables for Logfile
                                    fprintf(fid,'SG030 NaNs interpolation (max 10 seconds):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
                                end
                                igrav_loaded = 3;                               % set the aux. variable to one == file has been loaded
                            catch
                                ttime = datenum(time_in(i,1:3));                % if data has not been loaded correctly, just add a dummy
                                tdata(1,1:3) = NaN;                         % insert NaNs
                                fprintf('Could not load SG030 data: %s\n',file_name); % send message to command line that this iGrav file could not be loaded
                                fprintf(fid,'Could not load SG030 data: %s\n',file_name); % logfile
                            end
                            time.igrav = vertcat(time.igrav,ttime);             % stack the temporary variable on already loaded ones (time)
                            data.igrav = vertcat(data.igrav,tdata);             % stack the temporary variable on already loaded ones (data)
                            clear ttime tdata r file_name                       % remove used variables    
                        end
                        if length(find(isnan(data.igrav))) ~= numel(data.igrav) % check if loaded data contains numeric values: for logfile 
                            data.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = []; % remove time epochs out of requested range
                            time.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = []; % do the same for time vector
                            [ty,tm,td,th,tmm] = datevec(now);                   % prepare variables for Logfile
                            fprintf(fid,'SG030 data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                        else
                            data.igrav = [];                                    % otherwise empty
                            time.igrav = [];
                            fprintf(fid,'No SG030 data loaded\n');
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'data',...
                            get(findobj('Tag','plotGrav_uitable_igrav_data'),'UserData')); % store data! This data will be then loaded
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading iGrav data...');drawnow % send message to status bar
                        for i = 1:length(time_in(:,7))                          % for loop for each day
                            try  
                                try                                              % use try/catch in case something goes wrong
                                    if exist(fullfile(file_path_igrav,...        % try to unzip the igrav file if necesary
                                        sprintf('iGrav006_%04d',time_in(i,1)),sprintf('%02d%02d',time_in(i,2),time_in(i,3))),'dir') ~= 7
                                        set(findobj('Tag','plotGrav_text_status'),'String',...
                                            sprintf('Unzipping iGrav data...%04d/%02d/%02d',time_in(i,1),time_in(i,2),time_in(i,3)));drawnow % send message to status bar
                                        file_in = fullfile(file_path_igrav,...  % create input file name = file path + file prefix + date
                                            sprintf('iGrav006_%04d',time_in(i,1)),sprintf('iGrav006_%04d%02d%02d.zip',time_in(i,1),time_in(i,2),time_in(i,3)));
                                        file_out = fullfile(file_path_igrav,... % create output file name = file path + file prefix + date
                                            sprintf('iGrav006_%04d',time_in(i,1))); 
    %                                     command = sprintf('"%s" %s %s',...       % unzipping command
    %                                        unzip_exe,'x -y',file_in);            % unzip file (=x) and overwrite if necesary (=y)       
    %                                     unix(command);   
                                        unzip(file_in,file_out);                % unzip using built in matlab function
                                    end
                                catch
                                    set(findobj('Tag','plotGrav_text_status'),'String',...
                                            sprintf('Could not unzip iGrav data...%04d/%02d/%02d',time_in(i,1),time_in(i,2),time_in(i,3)));drawnow % send message to status bar
                                    fprintf(fid,'Could not unzip iGrav data...%04d/%02d/%02d\n',time_in(i,1),time_in(i,2),time_in(i,3)); % logfile
                                end
                                set(findobj('Tag','plotGrav_text_status'),'String',...
                                    sprintf('Loading iGrav data...%04d/%02d/%02d',time_in(i,1),time_in(i,2),time_in(i,3)));drawnow % send message to status bar
                                file_name = fullfile(file_path_igrav,...        % create input (not zip) file name = file path + file prefix + date
                                    sprintf('iGrav006_%04d',time_in(i,1)),sprintf('%02d%02d',time_in(i,2),time_in(i,3)),sprintf('%s%02d%02d.tsf',igrav_prefix,time_in(i,2),time_in(i,3)));
                                [ttime,tdata] = plotGrav_loadtsf(file_name);    % load file and store to temporary variables
                                if max(abs(diff(ttime))) > 1.9/86400 && max(abs(diff(ttime))) <= 10/86400 % interpolate if max missing time interval is < 10 seconds (and >= 2 seconds)
                                    ntime = [ttime(1):1/86400:ttime(end)]';     % new time vector with one second resolution
                                    tdata = interp1(ttime,tdata,ntime,'linear');% interpolate value for new time vector
                                    ttime = ntime;clear ntime;
                                    [ty,tm,td,th,tmm] = datevec(now);                   % prepare variables for Logfile
                                    fprintf(fid,'iGrav missing data interpolation (max 10 seconds):%s (%04d/%02d/%02d %02d:%02d)\n',file_name,ty,tm,td,th,tmm); % write to logfile
                                end
                                igrav_loaded = 1;                               % set the aux. variable to one == file has been loaded
                            catch
                                ttime = datenum(time_in(i,1:3));                % if data has not been loaded correctly, just add a dummy
                                tdata(1,1:igrav_channels) = NaN;                % insert NaNs
                                fprintf('Could not load iGrav data: %s\n',file_name); % send message to command line that this iGrav file could not be loaded
                                fprintf(fid,'Could not load iGrav data: %s\n',file_name); % logfile
                            end
                            time.igrav = vertcat(time.igrav,ttime);             % stack the temporary variable on already loaded ones (time)
                            data.igrav = vertcat(data.igrav,tdata);             % stack the temporary variable on already loaded ones (data)
                            clear ttime tdata r file_name                       % remove used variables    
                        end
                        if length(find(isnan(data.igrav))) ~= numel(data.igrav) % check if loaded data contains numeric values: for logfile 
                            data.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = []; % remove time epochs out of requested range
                            time.igrav(time.igrav<datenum(start_time) | time.igrav>datenum(end_time),:) = []; % do the same for time vector
                            [ty,tm,td,th,tmm] = datevec(now);                   % prepare variables for Logfile
                            fprintf(fid,'iGrav data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                        else
                            data.igrav = [];                                    % otherwise empty
                            time.igrav = [];
                            fprintf(fid,'No iGrav data loaded\n');
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'data',...
                            get(findobj('Tag','plotGrav_uitable_igrav_data'),'UserData')); % store data! This data will be then loaded
                    end
                else
                    data.igrav = [];                                        % if no iGrav paht selected, set time and data to []
                    time.igrav = [];
                    set(findobj('Tag','plotGrav_uitable_igrav_data'),'data',...
                        {false,false,false,'NotAvailable',false,false,false}); % update table
                    igrav_loaded = 0;
                    fprintf(fid,'No iGrav data loaded\n');
                end
                
                %% Load TRiLOGi data
                if strcmp(file_path_trilogi(end-3:end),'.tsf')            % switch between file/folder input
                    try
                        [time.trilogi,data.trilogi,channels_trilogi,units_trilogi] = plotGrav_loadtsf(file_path_trilogi); % load data
                        for i = 1:length(channels_trilogi)
                            temp = strsplit(char(channels_trilogi(i)),':');  % split string (Location:Intrument:Measurement). See plotGrav_loadtsf functions
                            channels_trilogi(i) = temp(end);         % set channel name
                            data_table_trilogi(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_trilogi(i)),char(units_trilogi(i))),false,false,false}; % update table
                            clear temp                              % remove temp variable
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',...
                                data_table_trilogi,'UserData',data_table_trilogi);
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % store Data
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % store hannel names
                        if length(find(isnan(data.trilogi))) ~= numel(data.trilogi) % check if loaded data contains numeric values
                            data.trilogi(time.trilogi<datenum(start_time) | time.trilogi>datenum(end_time),:) = []; % remove time epochs out of requested range
                            time.trilogi(time.trilogi<datenum(start_time) | time.trilogi>datenum(end_time),:) = [];
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'trilogi data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            trilogi_loaded = 2;
                        else
                            data.trilogi = [];                                  % otherwise empty
                            time.trilogi = [];
                            fprintf(fid,'No trilogi data loaded\n');
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'data',...
                                get(findobj('Tag','plotGrav_uitable_trilogi_data'),'UserData')); % store data! This data will be then loaded
                    catch
                        data.trilogi = [];                                    % otherwise empty
                        time.trilogi = [];
                        fprintf(fid,'No trilogi data loaded\n');
                        fprintf('Could not load trilogi data: %s\n',file_path_trilogi);
                    end
                elseif strcmp(file_path_trilogi(end-3:end),'.mat')            % switch between file/folder input
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi/MAT data...');drawnow % send message to status bar
                        try
                            temp = importdata(file_path_trilogi);
                            time.trilogi = datenum(double(temp.time));temp.time = [];
                            data.trilogi = double(temp.data);temp.data = [];
                            channels_trilogi = temp.channels;
                            units_trilogi = temp.units;
                            clear temp
                            for i = 1:length(channels_trilogi)
                                data_table_trilogi(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_trilogi(i)),char(units_trilogi(i))),false,false,false}; % update table
                            end
                            set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',...
                                    data_table_trilogi,'UserData',data_table_trilogi);
                            set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % store Data
                            set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % store hannel names
                            if length(find(isnan(data.trilogi))) ~= numel(data.trilogi) % check if loaded data contains numeric values
                                data.trilogi(time.trilogi<datenum(start_time) | time.trilogi>datenum(end_time),:) = []; % remove time epochs out of requested range
                                time.trilogi(time.trilogi<datenum(start_time) | time.trilogi>datenum(end_time),:) = [];
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                trilogi_loaded = 1;
                            else
                                data.trilogi = [];                                  % otherwise empty
                                time.trilogi = [];
                                fprintf(fid,'No TRiLOGi data loaded\n');
                            end
                            set(findobj('Tag','plotGrav_uitable_trilogi_data'),'data',...
                                get(findobj('Tag','plotGrav_uitable_trilogi_data'),'UserData')); % store data! This data will be then loaded
                    catch
                        data.trilogi = [];                                    % otherwise empty
                        time.trilogi = [];
                        fprintf(fid,'No trilogi data loaded\n');
                        fprintf('Could not load trilogi data: %s\n',file_path_trilogi);
                    end
                else
                    if ~isempty(file_path_trilogi)
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading TRiLOGi data...');drawnow % send message to status bar
                        time.trilogi = [];                                      % prepare variable (time.trilogi will store time in matlab format)
                        data.trilogi = [];                                      % prepare variable (data.trilogi will store tsoft channels)
                        trilogi_loaded = 0;                                     % aux. variable to check if at least one file has been loaded
                        for i = 1:length(time_in(:,7))                          % for loop for each day                            
                            condit_trilogi = 10;fi = 0;                         % aux. variables, condit_trilogi = minimum number of loaded rows (one TRiLOGi day can be stored in many files, plotGrav will use only that one with has at least condit_trilogi rows)
                            try                                                 % use try/catch (many TRiLOGi files are not stored in proper format)
                                while condit_trilogi <= 10                      % loop = repeat until the file with at least condit_trilogi rows if found
                                    fi = fi + 1;                                % fi is the running number in the TRiLOGi file name
                                    file_name = fullfile(file_path_trilogi,...  % create file name = path + date + suffix
                                        sprintf('%04d%02d%02d_%03d%s',time_in(i,1),time_in(i,2),time_in(i,3),fi,trilogi_suffix));
                                    [ttime,tdata] = plotGrav_loadtsf(file_name); % load the current file
                                    if length(ttime) < 10                       % check how many rows does the file contain
                                        condit_trilogi = 0;
                                    else
                                        condit_trilogi = 20;
                                    end
                                end
                                [tyear,tmonth,tday,thour,tmin,tsec] = datevec(ttime); % convert back to civil time
                                tday = time_in(i,3);                            % make sure the current day is used (TRiLOGi writes sometime wrong day in first few rows).
                                ttime = datenum(tyear,tmonth,tday,thour,tmin,tsec); % convert to matlab time
                                trilogi_loaded = 1; 
                            catch
                                ttime = datenum(time_in(i,1:3));                % current file time (hours = 0)
                                tdata(1,1:trilogi_channels) = NaN;              % insert NaN
                                fprintf('Could not load TRiLOGi data: %s\n',file_name); % send message to command line that this TRiLOGi file could not be loaded
                            end
                            time.trilogi = vertcat(time.trilogi,ttime);         % stack the temporary variable on already loaded ones (time)
                            data.trilogi = vertcat(data.trilogi,tdata);         % stack the temporary variable on already loaded ones (data)
                            clear ttime tdata file_name                         % remove used variables
                        end
                        if length(find(isnan(data.trilogi))) ~= numel(data.trilogi) % check if loaded data contains numeric values
                            data.trilogi(time.trilogi<datenum(start_time) | time.trilogi>datenum(end_time),:) = []; % remove time epochs out of requested range
                            time.trilogi(time.trilogi<datenum(start_time) | time.trilogi>datenum(end_time),:) = [];
                            try
                                r = find(diff(time.trilogi) == 0);              % find time epochs with wrong/zero increase
                                if ~isempty(r)
                                   time.trilogi(r+1) = time.trilogi(r) + mode(diff(time.trilogi)); % correct those time epochs (add one minute)
                                end
                                clear r
                            end
                        else
                            data.trilogi = [];                                  % otherwise empty
                            time.trilogi = [];
                        end
                        if trilogi_loaded == 0                                  % if no data loaded
                            set(findobj('Tag','plotGrav_uitable_trilogi_data'),'data',...
                                {false,false,false,'NotAvailable',false,false,false}); % update table
                                time.trilogi = [];
                                data.trilogi = [];
                                fprintf(fid,'No TRiLOGi data loaded\n');
                        else
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'TRiLOGi data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            set(findobj('Tag','plotGrav_uitable_trilogi_data'),'data',...
                                get(findobj('Tag','plotGrav_uitable_trilogi_data'),'UserData'));
                        end
                    else
                        fprintf(fid,'No TRiLOGi data loaded\n');                % if no TRiLOGi path has been selected
                        time.trilogi = [];
                        data.trilogi = [];
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'data',...
                            {false,false,false,'NotAvailable',false,false,false}); % update table
                    end
                end
                %% Load Other1 data
                set(findobj('Tag','plotGrav_text_status'),'String','Loading Other1 data...');drawnow % send message to status bar
                if ~isempty(file_path_other1)
                    try                                                     % Try to load the data. One file contains ALL data => no loop like for iGrav and TRiLOGi
                        switch file_path_other1(end-2:end)                  % switch between supported file formats
                            case 'tsf'                                      % read tsoft
                                [time.other1,data.other1,channels_other1,units_other1] = plotGrav_loadtsf(file_path_other1); % load data
                                for i = 1:length(channels_other1)
                                    temp = strsplit(char(channels_other1(i)),':');  % split string (Location:Intrument:Measurement). See plotGrav_loadtsf functions
                                    channels_other1(i) = temp(end);         % set channel name
                                    data_table_other1(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_other1(i)),char(units_other1(i))),false,false,false}; % update table
                                    clear temp                              % remove temp variable
                                end
                            case 'dat'                                      % read Soil moisture cluster data
                                [time.other1,data.other1,temp] = plotGrav_readcsv(file_path_other1,4,',',1,'"yyyy-mm-dd HH:MM:SS"','All');
                                channels_other1 = temp(2,2:end);            % channel name
                                units_other1 = temp(3,2:end);               % channel units
                                cut = [];
                                for i = 1:length(channels_other1)           % update Other1 table
                                    if ~isempty(channels_other1{i})
                                        data_table_other1(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_other1(i)),char(units_other1(i))),false,false,false};
                                    else
                                        cut = vertcat(cut,i);
                                    end
                                    clear temp
                                end
                                channels_other1(cut) = [];
                                units_other1(cut) = [];
                                clear cut
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',...
                            data_table_other1,'UserData',data_table_other1);
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % store Data
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % store hannel names
                        if length(find(isnan(data.other1))) ~= numel(data.other1) % check if loaded data contains numeric values
                            data.other1(time.other1<datenum(start_time) | time.other1>datenum(end_time),:) = []; % remove time epochs out of requested range
                            time.other1(time.other1<datenum(start_time) | time.other1>datenum(end_time),:) = [];
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Other1 data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        else
                            data.other1 = [];                                  % otherwise empty
                            time.other1 = [];
                            fprintf(fid,'No Other1 data loaded\n');
                        end
                    catch
                        fprintf('Could not load Other1 data: %s\n',file_path_other1); % send message to command line that this Other1 file could not be loaded
                    end
                else
                    fprintf(fid,'No Other1 data loaded\n');
                    time.other1 = [];
                    data.other1 = [];
                    set(findobj('Tag','plotGrav_uitable_other1_data'),'data',...
                        {false,false,false,'NotAvailable',false,false,false}); % update table
                end
                %% Load Other2 data (currently not active)
                set(findobj('Tag','plotGrav_text_status'),'String','Loading Other2 data...');drawnow % send message to status bar
                if ~isempty(file_path_other2)                               % same as for Other 1
                    try
                        switch file_path_other2(end-2:end)
                            case 'tsf'                                      % read tsoft
                                [time.other2,data.other2,channels_other2,units_other2] = plotGrav_loadtsf(file_path_other2);
                                for i = 1:length(channels_other2)
                                    temp = strsplit(char(channels_other2(i)),':');  % split string (Location:Intrument:Measurement)
                                    channels_other2(i) = temp(end);
                                    data_table_other2(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_other2(i)),char(units_other2(i))),false,false,false};
                                    clear temp
                                end
                            case 'dat'                                      % read Soil moisture cluster data
                                [time.other2,data.other2,temp] = plotGrav_readcsv(file_path_other2,4,',',1,'"yyyy-mm-dd HH:MM:SS"','All');
                                channels_other2 = temp(2,2:end);
                                units_other2 = temp(3,2:end);
                                cut = [];
                                for i = 1:length(channels_other2)           % update other2 table
                                    if ~isempty(channels_other2{i})
                                        data_table_other2(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_other2(i)),char(units_other2(i))),false,false,false};
                                    else
                                        cut = vertcat(cut,i);
                                    end
                                    clear temp
                                end
                                channels_other2(cut) = [];
                                units_other2(cut) = [];
                                clear cut
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',...
                            data_table_other2,'UserData',data_table_other2);
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2);
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2);
                        if length(find(isnan(data.other2))) ~= numel(data.other2) % check if loaded data contains numeric values
                            data.other2(time.other2<datenum(start_time) | time.other2>datenum(end_time),:) = []; % remove time epochs out of requested range
                            time.other2(time.other2<datenum(start_time) | time.other2>datenum(end_time),:) = [];
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Other2 data loaded (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        else
                            data.other2 = [];                                  % otherwise empty
                            time.other2 = [];
                            fprintf(fid,'No Other2 data loaded\n');
                        end
                    catch
                        fprintf('Could not load Other2 data: %s\n',file_path_other2); % send message to command line that this Other2 file could not be loaded
                    end
                else
                    fprintf(fid,'No Other2 data loaded\n');
                    time.other2 = [];
                    data.other2 = [];
                    set(findobj('Tag','plotGrav_uitable_other2_data'),'data',...
                        {false,false,false,'NotAvailable',false,false,false}); % update table
                end
                %% Load filter
                % Filter
                if igrav_loaded == 1 || igrav_loaded == 3                   % load only if iGrav data have been loaded
                    try
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Filter...');drawnow % send message to status bar
                        if ~isempty(filter_file)                                % try to load the filter file/response if some string is given
                            Num = load(filter_file);                            % load filter file = in ETERNA format - header
                            Num = vertcat(Num(:,2),flipud(Num(1:end-1,2)));     % stack the filter (ETERNA uses only one half of the repose = mirror the filter)
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Filter loaded: %s (%04d/%02d/%02d %02d:%02d)\n',filter_file,ty,tm,td,th,tmm);
                        else
                            Num = [];                                           % if not loaded, set to [] (empty)
                        end
                    catch
                        fprintf('Could not load filter: %s\n',filter_file);     % send message to command line that filter file could not be loaded
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not load filter file %s (%04d/%02d/%02d %02d:%02d)\n',filter_file,ty,tm,td,th,tmm);
                        Num = [];                                               % if not loaded, set to [] (empty)
                    end
                else
                    Num = [];                                               % if not loaded, set to [] (empty)
                end
                
                %% Filter data
                if (igrav_loaded == 1 || igrav_loaded == 3) && ~isempty(Num) % filter only if at least one iGrav/SG030 file has been loaded and the filter file as well
                    set(findobj('Tag','plotGrav_text_status'),'String','Filtering...');drawnow % status
                    data.filt = [];time.filt = [];                          % prepare variables (*.filt = filtered values)
                    for j = 1%:size(data.igrav,2)                           % set which channels should be filtered (1:size(data.igrav,2) = all channels)
                        [timeout,dataout,id] = plotGrav_findTimeStep(time.igrav,data.igrav(:,j),igrav_time_resolution/(24*60*60)); % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                        dout = [];                                          % aux. variable
                        for i = 1:size(id,1)                                % use for each time interval (between time steps that have been found using plotGrav_findTimeStep function) separately                 
                            if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough
                                [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv = Convolution function (outputs only valid time interval, see plotGrav_conv function for details)
                            else
                                ftime = timeout(id(i,1):id(i,2));           % if the interval is too short, set to NaN 
                                fgrav(1:length(ftime),1) = NaN;
                            end
                            dout = vertcat(dout,fgrav,NaN);                 % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                            if j == 1
                                time.filt = vertcat(time.filt,ftime,...     % stack the aux. time only for first channel (same for all)
                                    ftime(end)+igrav_time_resolution/(2*24*60*60)); % this last part is for a NaN, see vertcat(dout above)   
                            end
                            clear ftime fgrav
                        end
                        data.filt = horzcat(data.filt,dout);                % stack the aux. data horizontally (all channels)
                    end
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data filtered (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                    time.filt(end) = [];                                    % remove last value (is equal NaN, see dout = vertcat(dout,fgrav,NaN))
                    data.filt(end) = [];
                else
                    data.filt = [];                                         % otherwise, set to empty + write to logfile
                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No iGrav data filtering (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                end
                
                %% Tides
                if igrav_loaded == 1 || igrav_loaded == 3
                    try                                                         % try to load tides
                        set(findobj('Tag','plotGrav_text_status'),'String','Loading Tides...');drawnow % status
                        if ~isempty(tide_file)                                  % load only if a file is given
                            [time.tide,data.tide] = plotGrav_loadtsf(tide_file); % load tsoft file
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Tide file loaded %s (%04d/%02d/%02d %02d:%02d)\n',tide_file,ty,tm,td,th,tmm); % logfile
                        else
                            time.tide = [];                                     % otherwise set to empty
                            data.tide = [];
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No tide file (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        end
                    catch
                        fprintf('Could not load Tides: %s\n',tide_file);
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No tide file %s (%04d/%02d/%02d %02d:%02d)\n',tide_file,ty,tm,td,th,tmm);
                        time.tide = [];                                         % set to empty if an error occurs
                        data.tide = [];
                    end
                else
                    time.tide = [];                                         % set to empty if an error occurs
                    data.tide = [];
                end
                %% Correct time series
                if igrav_loaded == 1                                        % iGrav data loaded
                    try                     
                        set(findobj('Tag','plotGrav_text_status'),'String','Computing corrections...');drawnow % status
                        if calib_delay~=0                                   % introduce time shift if available
                            data.igrav(:,1) = interp1(time.igrav+calib_delay/86400,data.igrav(:,1),time.igrav);
                            fprintf(fid,'SG030 phase shift introduced = %4.2f s (%04d/%02d/%02d %02d:%02d)\n',calib_delay,ty,tm,td,th,tmm);
                            if ~isempty(data.filt) 
                                data.filt(:,1) = interp1(time.filt+calib_delay/86400,data.filt(:,1),time.filt);
                            end
                        end
                        data.igrav(:,22) = data.igrav(:,1)*calib_factor;        % Calibrated gravity (add igrav channel 22)
                        data.igrav(:,28) = (data.igrav(:,2) - mean(data.igrav(~isnan(data.igrav(:,2)),2)))*admittance_factor; % atmospheric effect - mean value (channel 28)
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data atmo correction = %4.2f nm/s^2/hPa (%04d/%02d/%02d %02d:%02d)\n',admittance_factor,ty,tm,td,th,tmm);
                        if ~isempty(data.filt)                                  % use filtered values only if filtering was successful
                            data.igrav(:,23) = interp1(time.filt,data.filt(:,1),time.igrav)*calib_factor; % Gravity: calibrated and filtered (igrav channel 23)
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data calibrated = %4.2f nm/s^2/V (%04d/%02d/%02d %02d:%02d)\n',calib_factor,ty,tm,td,th,tmm);
                            if ~isempty(data.tide)                              % correct for tide only if loaded
                                if size(data.tide) > 7                          % interpolated polar motion effect, if the tide tsf file contains more than one channel (assumed that this channel contains polar motion acceleration)
                                    data.igrav(:,27) = interp1(time.tide,data.tide(:,2),time.igrav); % polar motion effect (channel 27)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data corrected for polar motion (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                else
                                    data.igrav(:,27) = 0;                       % otherwise equal 0 
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data not corrected for polar motion (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                end
                                data.igrav(:,26) = interp1(time.tide,data.tide(:,1),time.igrav); % tide effect (channel 26)
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data corrected for tides (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            else
                                data.igrav(:,26) = 0;                           % if not loaded, set to zero 
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data not corrected for tides/polar motion (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            end
                            data.igrav(:,24) = data.igrav(:,23) - data.igrav(:,26) - data.igrav(:,27) - data.igrav(:,28); % corrected (filtered and calibrated) gravity (channel 24)

                            switch drift_fit                                    % select drift approximation
                                case 1
                                    data.igrav(:,29) = 0;                       % no drift estimated
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data: No drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                                case 2
                                    data.igrav(:,29) = mean(data.igrav(~isnan(data.igrav(:,24)),24)); % mean value
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data: Constant drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                case 3
                                    [out_par,out_sig,out_fit] = plotGrav_fit(time.igrav,data.igrav(:,24),'poly1');
                                    data.igrav(:,29) = out_fit;                 % drift curve (channel 29)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data: Linear drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                case 4
                                    [out_par,out_sig,out_fit] = plotGrav_fit(time.igrav,data.igrav(:,24),'poly2');
                                    data.igrav(:,29) = out_fit;                 % drift curve (channel 29)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data: Quadratic drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                case 5
                                    [out_par,out_sig,out_fit] = plotGrav_fit(time.igrav,data.igrav(:,24),'poly3');
                                    data.igrav(:,29) = out_fit;                 % drift curve (channel 29)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'iGrav data: Cubic drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            end
                            data.igrav(:,25) = data.igrav(:,24) - data.igrav(:,29); % corrected gravity (filtered, calibrated, corrected, de-trended) (channel 25)
                        elseif igrav_loaded == 0
                            data.igrav(:,[23,24,25,26,27,29]) = 0;              % set to zero if filtered data not available (except atmospheric effect)
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No iGrav data correction due to missing filter file (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        else
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No iGrav data correction. It is assumed that the loaded file contains corrected values. (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        end
                    catch
                        fprintf('Could not correct gravity\n');                 % send message to command line
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not correct gravity (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                    end
                elseif igrav_loaded == 3                                    % SG030 data
                    plotGrav('reset_tables_sg030');
                    try                     
                        set(findobj('Tag','plotGrav_text_status'),'String','Computing corrections...');drawnow % status
                        if calib_delay~=0                                   % introduce time shift if available
                            data.igrav(:,1) = interp1(time.igrav+calib_delay/86400,data.igrav(:,1),time.igrav);
                            fprintf(fid,'SG030 phase shift introduced = %4.2f s (%04d/%02d/%02d %02d:%02d)\n',calib_delay,ty,tm,td,th,tmm);
                            if ~isempty(data.filt) 
                                data.filt(:,1) = interp1(time.filt+calib_delay/86400,data.filt(:,1),time.filt);
                            end
                        end
                        data.igrav(:,22-18) = data.igrav(:,1)*calib_factor;        % Calibrated gravity (add igrav channel 22)
                        data.igrav(:,28-18) = (data.igrav(:,3) - mean(data.igrav(~isnan(data.igrav(:,3)),3)))*admittance_factor; % atmospheric effect - mean value (channel 10)
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data atmo correction = %4.2f nm/s^2/hPa (%04d/%02d/%02d %02d:%02d)\n',admittance_factor,ty,tm,td,th,tmm);
                        if ~isempty(data.filt)                                  % use filtered values only if filtering was successful
                            data.igrav(:,23-18) = interp1(time.filt,data.filt(:,1),time.igrav)*calib_factor; % Gravity: calibrated and filtered (igrav channel 5)
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data calibrated = %4.2f nm/s^2/V (%04d/%02d/%02d %02d:%02d)\n',calib_factor,ty,tm,td,th,tmm);
                            if ~isempty(data.tide)                              % correct for tide only if loaded
                                if size(data.tide) > 7                          % interpolated polar motion effect, if the tide tsf file contains more than one channel (assumed that this channel contains polar motion acceleration)
                                    data.igrav(:,27-18) = interp1(time.tide,data.tide(:,2),time.igrav); % polar motion effect (channel 9)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data corrected for polar motion (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                else
                                    data.igrav(:,27-18) = 0;                       % otherwise equal 0 
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data not corrected for polar motion (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                end
                                data.igrav(:,26-18) = interp1(time.tide,data.tide(:,1),time.igrav); % tide effect (channel 8)
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data corrected for tides (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            else
                                data.igrav(:,26-18) = 0;                           % if not loaded, set to zero 
                                [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data not corrected for tides/polar motion (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            end
                            data.igrav(:,24-18) = data.igrav(:,23-18) - data.igrav(:,26-18) - data.igrav(:,27-18) - data.igrav(:,28-18); % corrected (filtered and calibrated) gravity (channel 6)

                            switch drift_fit                                    % select drift approximation
                                case 1
                                    data.igrav(:,29-18) = 0;                       % no drift estimated
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data: No drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                                case 2
                                    data.igrav(:,29-18) = mean(data.igrav(~isnan(data.igrav(:,24-18)),24-18)); % mean value
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data: Constant drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                case 3
                                    [out_par,out_sig,out_fit] = plotGrav_fit(time.igrav,data.igrav(:,24-18),'poly1');
                                    data.igrav(:,29-18) = out_fit;                 % drift curve (channel 29)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data: Linear drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                case 4
                                    [out_par,out_sig,out_fit] = plotGrav_fit(time.igrav,data.igrav(:,24-18),'poly2');
                                    data.igrav(:,29-18) = out_fit;                 % drift curve (channel 29)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data: Quadratic drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                                case 5
                                    [out_par,out_sig,out_fit] = plotGrav_fit(time.igrav,data.igrav(:,24-18),'poly3');
                                    data.igrav(:,29-18) = out_fit;                 % drift curve (channel 29)
                                    [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'SG030 data: Cubic drift (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            end
                            data.igrav(:,25-18) = data.igrav(:,24-18) - data.igrav(:,29-18); % corrected gravity (filtered, calibrated, corrected, de-trended) (channel 25)
                        elseif igrav_loaded == 0
                            data.igrav(:,[23,24,25,26,27,29]-18) = 0;              % set to zero if filtered data not available (except atmospheric effect)
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No SG030 data correction due to missing filter file (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        else
                            [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'No SG030 data correction. It is assumed that the loaded file contains corrected values. (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        end
                    catch
                        fprintf('Could not correct gravity\n');                 % send message to command line
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not correct gravity (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm); % write to logfile
                    end
                end
                %% Resample
                if igrav_loaded == 1 || igrav_loaded == 3
                    try
                        resample = str2double(get(findobj('Tag','plotGrav_edit_resample'),'String')); % get resampling value
                        if resample >= 2                                        % resample igrav data only if required sampling > 1 second
                            set(findobj('Tag','plotGrav_text_status'),'String','Resampling iGrav data...');drawnow % send message to status bar
                            ntime = [time.igrav(1):resample/86400:time.igrav(end)]'; % create new time vector
                            dnew(1:length(ntime),1:size(data.igrav,2)) = 0;     % prepare new variable
                            for c = 1:size(data.igrav,2)                        % for each column
                               dnew(:,c) = interp1(time.igrav,data.igrav(:,c),ntime);
                            end
                            time.igrav = ntime;                                 % update time vector
                            data.igrav = dnew;                                  % update data matrix
                            clear c dnew ntime                                  % remove used variables
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav data resampled to %4.1f sec (%04d/%02d/%02d %02d:%02d)\n',resample,ty,tm,td,th,tmm); % logfile
                        else
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'No iGrav data resampling (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                        end

                    catch
                        set(findobj('Tag','plotGrav_text_status'),'String','Could not resample iGrav data.');drawnow % status
                        [ty,tm,td,th,tmm] = datevec(now);fprintf(fid,'Could not resample gravity (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                    end
                    data.filt = [];time.filt = [];data.tide = [];time.tide = [];% remove used variable;
                    % Store the resampled data and time
                    set(findobj('Tag','plotGrav_text_status'),'UserData',time); % store the data 
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                    clear data time                                             % remove variables
                    set(findobj('Tag','plotGrav_text_status'),'String','The requested files have been loaded.');drawnow % status
                    plotGrav('uitable_push');                                   % visualize (see next section)
                    plotGrav('push_date');                                      % update time
                    fclose(fid);                                                % close logfile
                elseif igrav_loaded == 2
                    set(findobj('Tag','plotGrav_text_status'),'UserData',time); % store the data 
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                    clear data time                                             % remove variables
                    set(findobj('Tag','plotGrav_text_status'),'String','The selected file has been loaded.');drawnow % status
                    plotGrav('uitable_push');                                   % visualize (see next section)
                    plotGrav('push_date');                                      % update time
                    fclose(fid);                                                % close logfile 
                else
                    set(findobj('Tag','plotGrav_text_status'),'UserData',time); % store the data 
                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                    clear data time                                             % remove variables
                    set(findobj('Tag','plotGrav_text_status'),'String','The selected files have been loaded.');drawnow % status
                    plotGrav('uitable_push');                                   % visualize (see next section)
                    plotGrav('push_date');                                      % update time
                    fclose(fid);                                                % close logfile 
                end
                    
            case 'uitable_push'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)
                    %% Get data
                    set(findobj('Tag','plotGrav_text_status'),'String','Plotting...');drawnow % status 
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                    a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                    a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                    cla(a1(1));legend(a1(1),'off');ylabel(a1(1),[]);        % clear axes and remove legends and labels
                    cla(a1(2));legend(a1(2),'off');ylabel(a1(2),[]);        % clear axes and remove legends and labels
                    axis(a1(1),'auto');axis(a1(2),'auto');                  % Reset axis (not axes)
                    cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);        % clear axes and remove legends and labels
                    cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);        % clear axes and remove legends and labels
                    axis(a2(1),'auto');axis(a2(2),'auto');
                    cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);        % clear axes and remove legends and labels
                    cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);        % clear axes and remove legends and labels
                    axis(a3(1),'auto');axis(a3(2),'auto');

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL2.igrav = find(cell2mat(data_igrav(:,2))==1); % get selected iGrav channels for L2
                    plot_axesL3.igrav = find(cell2mat(data_igrav(:,3))==1);
                    plot_axesR1.igrav = find(cell2mat(data_igrav(:,5))==1);
                    plot_axesR2.igrav = find(cell2mat(data_igrav(:,6))==1);
                    plot_axesR3.igrav = find(cell2mat(data_igrav(:,7))==1);

                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL2.trilogi = find(cell2mat(data_trilogi(:,2))==1);
                    plot_axesL3.trilogi = find(cell2mat(data_trilogi(:,3))==1);
                    plot_axesR1.trilogi = find(cell2mat(data_trilogi(:,5))==1);
                    plot_axesR2.trilogi = find(cell2mat(data_trilogi(:,6))==1);
                    plot_axesR3.trilogi = find(cell2mat(data_trilogi(:,7))==1);

                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL2.other1 = find(cell2mat(data_other1(:,2))==1);
                    plot_axesL3.other1 = find(cell2mat(data_other1(:,3))==1);
                    plot_axesR1.other1 = find(cell2mat(data_other1(:,5))==1);
                    plot_axesR2.other1 = find(cell2mat(data_other1(:,6))==1);
                    plot_axesR3.other1 = find(cell2mat(data_other1(:,7))==1);

                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    plot_axesL2.other2 = find(cell2mat(data_other2(:,2))==1);
                    plot_axesL3.other2 = find(cell2mat(data_other2(:,3))==1);
                    plot_axesR1.other2 = find(cell2mat(data_other2(:,5))==1);
                    plot_axesR2.other2 = find(cell2mat(data_other2(:,6))==1);
                    plot_axesR3.other2 = find(cell2mat(data_other2(:,7))==1);

                    plot_mode = [0 0 0];                                    % reset plot_mode = nothing is plotted by default (0 no plot, 1 - left only, 2 -right only, 3 - both)
                    set(findobj('Tag','plotGrav_push_reset_view'),'UserData',plot_mode);% store the plot_mode 

                    %% Plot1
                    % L1 only
                    if (~isempty(plot_axesL1.igrav) || ~isempty(plot_axesL1.trilogi) || ~isempty(plot_axesL1.other1) || ~isempty(plot_axesL1.other2)) &&...
                       (isempty(plot_axesR1.igrav) && isempty(plot_axesR1.trilogi) && isempty(plot_axesR1.other1) && isempty(plot_axesR1.other2)) 
                        switch_plot = 1;                                    % 1 = left axes
                        plot_mode(1) = 1;                                   % 1 = left axes
                        plot_axesL = plot_axesL1;                           % see ploGrav_plotData function
                        plot_axesR = [];                                    % see ploGrav_plotData function
                        ref_axes = [];                                      % Plot1 is the superior axes (L1 -> R1 -> L2 -> R2 -> L3 -> R3)
                        legend_save = plotGrav_plotData(a1,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend_save   % remove used settings
                    end

                    % R1 only
                    if (~isempty(plot_axesR1.igrav) || ~isempty(plot_axesR1.trilogi) || ~isempty(plot_axesR1.other1) || ~isempty(plot_axesR1.other2)) &&... 
                       (isempty(plot_axesL1.igrav) && isempty(plot_axesL1.trilogi) && isempty(plot_axesL1.other1) && isempty(plot_axesL1.other2)) 
                        switch_plot = 2;                                    % 2 = right axes
                        plot_mode(1) = 2;                                   % 1 = right axes
                        plot_axesL = [];                                    % see ploGrav_plotData function
                        plot_axesR = plot_axesR1;                           % see ploGrav_plotData function
                        ref_axes = [];                                      % Plot1 is the superior axes (L1 -> R1 -> L2 -> R2 -> L3 -> R3)
                        legend_save = plotGrav_plotData(a1,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend_save   % remove used settings
                    end

                    % R1 and L1
                    if (~isempty(plot_axesL1.igrav) || ~isempty(plot_axesL1.trilogi) || ~isempty(plot_axesL1.other1) || ~isempty(plot_axesL1.other2)) &&...
                       (~isempty(plot_axesR1.igrav) || ~isempty(plot_axesR1.trilogi) || ~isempty(plot_axesR1.other1) || ~isempty(plot_axesR1.other2)) 
                        switch_plot = 3;                                    % 2 = right axes
                        plot_mode(1) = 3;                                   % 1 = right axes
                        plot_axesL = plot_axesL1;                           % see ploGrav_plotData function
                        plot_axesR = plot_axesR1;                           % see ploGrav_plotData function
                        ref_axes = [];                                      % Plot1 is the superior axes (L1 -> R1 -> L2 -> R2 -> L3 -> R3)
                        legend_save = plotGrav_plotData(a1,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_one'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend_save   % remove used settings
                    end
                    
                    %% Plot 2
                    % L2 only
                    if (~isempty(plot_axesL2.igrav) || ~isempty(plot_axesL2.trilogi) || ~isempty(plot_axesL2.other1) || ~isempty(plot_axesL2.other2)) &&... 
                       (isempty(plot_axesR2.igrav) && isempty(plot_axesR2.trilogi) && isempty(plot_axesR2.other1) && isempty(plot_axesR2.other2)) 
                        switch_plot = 1;                                    % left axes only
                        plot_mode(2) = 1;                                   % left axes only
                        plot_axesL = plot_axesL2;                           % see ploGrav_plotData function                          
                        plot_axesR = [];                                    % see ploGrav_plotData function
                        if plot_mode(1) == 0                                % find out if plot1 exists
                            ref_axes = [];                                  % if not, no reference axes limits
                        elseif plot_mode(1) == 2                            % if plot1 exists and contains only right axes
                            ref_axes = a1(2);
                        else                                                % otherwise use L1 axes
                            ref_axes = a1(1);
                        end
                        legend_save = plotGrav_plotData(a2,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the function
                        set(findobj('Tag','plotGrav_menu_print_two'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend save   % remove settings
                    end
                    
                    % R2 only
                    if (~isempty(plot_axesR2.igrav) || ~isempty(plot_axesR2.trilogi) || ~isempty(plot_axesR2.other1) || ~isempty(plot_axesR2.other2)) &&... 
                       (isempty(plot_axesL2.igrav) && isempty(plot_axesL2.trilogi) && isempty(plot_axesL2.other1) && isempty(plot_axesL2.other2))  
                        switch_plot = 2;                                    % 2 = right axes
                        plot_mode(2) = 2;                                   % 1 = right axes
                        plot_axesL = [];                                    % see ploGrav_plotData function
                        plot_axesR = plot_axesR2;                           % see ploGrav_plotData function
                        if plot_mode(1) == 0                                % find out if plot1 exists
                            ref_axes = [];                                  % if not, no reference axes limits
                        elseif plot_mode(1) == 2                            % if plot1 exists and contains only right axes
                            ref_axes = a1(2);
                        else                                                % otherwise use L1 axes
                            ref_axes = a1(1);
                        end                                     
                        legend_save = plotGrav_plotData(a2,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_two'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend_save    % remove used settings
                    end
                    
                    % R2 and L2
                    if (~isempty(plot_axesL2.igrav) || ~isempty(plot_axesL2.trilogi) || ~isempty(plot_axesL2.other1) || ~isempty(plot_axesL2.other2)) &&...
                       (~isempty(plot_axesR2.igrav) || ~isempty(plot_axesR2.trilogi) || ~isempty(plot_axesR2.other1) || ~isempty(plot_axesR2.other2)) 
                        switch_plot = 3;                                    % 2 = right axes
                        plot_mode(2) = 3;                                   % 1 = right axes
                        plot_axesL = plot_axesL2;                           % see ploGrav_plotData function
                        plot_axesR = plot_axesR2;                           % see ploGrav_plotData function
                        if plot_mode(1) == 0                                % find out if plot1 exists
                            ref_axes = [];                                  % if not, no reference axes limits
                        elseif plot_mode(1) == 2                            % if plot1 exists and contains only right axes
                            ref_axes = a1(2);
                        else                                                % otherwise use L1 axes
                            ref_axes = a1(1);
                        end  
                        legend_save = plotGrav_plotData(a2,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_two'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend_save  % remove used settings
                    end
                    
                    %% Plot 3
                    % L3 only
                    if (~isempty(plot_axesL3.igrav) || ~isempty(plot_axesL3.trilogi) || ~isempty(plot_axesL3.other1) || ~isempty(plot_axesL3.other2)) &&... 
                       (isempty(plot_axesR3.igrav) && isempty(plot_axesR3.trilogi) && isempty(plot_axesR3.other1) && isempty(plot_axesR3.other2)) 
                        switch_plot = 1;                                    % left axes only
                        plot_mode(3) = 1;                                   % left axes only
                        plot_axesL = plot_axesL3;                           % see ploGrav_plotData function                          
                        plot_axesR = [];                                    % see ploGrav_plotData function
                        if plot_mode(1)+plot_mode(2) == 0                   % find out if plot1 or plot2 exist
                            ref_axes = [];                                  % if not, no reference axes limits
                        elseif plot_mode(1) > 0 && plot_mode(1) ~= 2        % if plot1 exists, but not only right axes
                            ref_axes = a1(1);
                        elseif plot_mode(1) > 0 && plot_mode(1) == 2        % use R1
                            ref_axes = a1(2);
                        elseif plot_mode(1) == 0 && plot_mode(2) == 2       % use R2
                            ref_axes = a2(2);
                        elseif plot_mode(1) == 0 && plot_mode(2) ~= 2       % user L2
                            ref_axes = a2(1);
                        end
                        legend_save = plotGrav_plotData(a3,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the function
                        set(findobj('Tag','plotGrav_menu_print_three'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes    % remove settings
                    end
                    
                    % R3 only
                    if (~isempty(plot_axesR3.igrav) || ~isempty(plot_axesR3.trilogi) || ~isempty(plot_axesR3.other1) || ~isempty(plot_axesR3.other2)) &&... 
                       (isempty(plot_axesL3.igrav) && isempty(plot_axesL3.trilogi) && isempty(plot_axesL3.other1) && isempty(plot_axesL3.other2))  
                        switch_plot = 2;                                    % 2 = right axes
                        plot_mode(3) = 2;                                   % 1 = right axes
                        plot_axesL = [];                                    % see ploGrav_plotData function
                        plot_axesR = plot_axesR3;                           % see ploGrav_plotData function
                        if plot_mode(1)+plot_mode(2) == 0                   % find out if plot1 or plot2 exist
                            ref_axes = [];                                  % if not, no reference axes limits
                        elseif plot_mode(1) > 0 && plot_mode(1) ~= 2        % if plot1 exists, but not only right axes
                            ref_axes = a1(1);
                        elseif plot_mode(1) > 0 && plot_mode(1) == 2        % use R1
                            ref_axes = a1(2);
                        elseif plot_mode(1) == 0 && plot_mode(2) == 2       % use R2
                            ref_axes = a2(2);
                        elseif plot_mode(1) == 0 && plot_mode(2) ~= 2       % user L2
                            ref_axes = a2(1);
                        end                                  
                        legend_save = plotGrav_plotData(a3,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_three'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes legend_save   % remove used settings
                    end
                    
                    % R3 and L3
                    if (~isempty(plot_axesL3.igrav) || ~isempty(plot_axesL3.trilogi) || ~isempty(plot_axesL3.other1) || ~isempty(plot_axesL3.other2)) &&...
                       (~isempty(plot_axesR3.igrav) || ~isempty(plot_axesR3.trilogi) || ~isempty(plot_axesR3.other1) || ~isempty(plot_axesR3.other2)) 
                        switch_plot = 3;                                    % 2 = right axes
                        plot_mode(3) = 3;                                   % 1 = right axes
                        plot_axesL = plot_axesL3;                           % see ploGrav_plotData function
                        plot_axesR = plot_axesR3;                           % see ploGrav_plotData function
                        if plot_mode(1)+plot_mode(2) == 0                   % find out if plot1 or plot2 exist
                            ref_axes = [];                                  % if not, no reference axes limits
                        elseif plot_mode(1) > 0 && plot_mode(1) ~= 2        % if plot1 exists, but not only right axes
                            ref_axes = a1(1);
                        elseif plot_mode(1) > 0 && plot_mode(1) == 2        % use R1
                            ref_axes = a1(2);
                        elseif plot_mode(1) == 0 && plot_mode(2) == 2       % use R2
                            ref_axes = a2(2);
                        elseif plot_mode(1) == 0 && plot_mode(2) ~= 2       % user L2
                            ref_axes = a2(1);
                        end 
                        legend_save = plotGrav_plotData(a3,ref_axes,switch_plot,data,plot_axesL,plot_axesR); % call the plotGrav_plotData function
                        set(findobj('Tag','plotGrav_menu_print_three'),'UserData',legend_save); % store legend for printing
                        clear switch_plot plot_axesL plot_axesR ref_axes    % remove used settings
                    end
                    
                    set(findobj('Tag','plotGrav_push_reset_view'),'UserData',plot_mode);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
                    plotGrav('push_date');
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load Data first.');drawnow % send message
                end                                                         % ~isempty(data)
                
            case 'push_date'
                %% PUSH_DATE
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
                % Plot1
                switch plot_mode(1)                                         % switch between plot modes (PLOT 1)
                    case 1                                                  % Left plot only
                        ref_lim = get(a1(1),'XLim');                        % get current x limits and use them a reference
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % tick labels (4 decimal places)
                        end
                        set(a1(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (left)
                        set(a1(2),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (right)
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                            datetick(a1(1),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        set(a1(2),'Visible','off');                         % turn of right axes
                        linkaxes([a1(1),a1(2)],'x');                        % link axes, just in case
                    case 2                                                  % Right plot only
                        ref_lim = get(a1(2),'XLim');                        % get current x limits and use them a reference
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % tick labels (4 decimal places)
                        end
                        set(a1(2),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (right)
                        set(a1(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (left)
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                            datetick(a1(2),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        set(a1(1),'Visible','off');                         % turn of right axes
                        linkaxes([a1(1),a1(2)],'x');                        % link axes, just in case
                    case 3                                                  % Right and Left plot
                        ref_lim = get(a1(1),'XLim');                        % use Left plot limits as reference
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % compute new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % create new labels (4 decimal places
                        end
                        set(a1(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % place new labels and ticks
                        set(a1(2),'XTick',xtick_value,'Visible','on','color','none','XTickLabel',[]); % make Right plot visible but remove ticks
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0   % switch between matlab time and calendar/time
                            datetick(a1(1),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        linkaxes([a1(1),a1(2)],'x');                        % link axes, just in case
                    otherwise
                        ref_lim = [];                                       % no ref_lim if plot1 is not on
                end
                % Plot 2
                switch plot_mode(2)                                         % switch between plot modes (PLOT 2)
                    case 1                                                  % Left plot only
                        if isempty(ref_lim)
                            ref_lim = get(a2(1),'XLim');                    % get current x limits and use them a reference
                        end
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % tick labels (4 decimal places)
                        end
                        set(a2(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (left)
                        set(a2(2),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (right)
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                            datetick(a2(1),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        set(a2(2),'Visible','off');                         % turn of right axes
                        linkaxes([a2(1),a2(2)],'x');                        % link axes, just in case
                    case 2                                                  % Right plot only
                        if isempty(ref_lim)
                            ref_lim = get(a2(2),'XLim');                    % get current x limits and use them a reference
                        end
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % tick labels (4 decimal places)
                        end
                        set(a2(2),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (right)
                        set(a2(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (left)
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                            datetick(a2(2),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        set(a2(1),'Visible','off');                         % turn of right axes
                        linkaxes([a2(1),a2(2)],'x');                        % link axes, just in case
                    case 3                                                  % Right and Left plot
                        if isempty(ref_lim)
                            ref_lim = get(a2(1),'XLim');                    % get current x limits and use them a reference
                        end
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % compute new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % create new labels (4 decimal places)
                        end
                        set(a2(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % place new labels and ticks
                        set(a2(2),'XTick',xtick_value,'Visible','on','color','none','XTickLabel',[]); % make Right plot visible but remove ticks
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0   % switch between matlab time and calendar/time
                            datetick(a2(1),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        linkaxes([a2(1),a2(2)],'x');                        % link axes, just in case
                    otherwise
                        ref_lim = [];                                       % no ref_lim if plot1 is not on
                end
                % Plot 3
                switch plot_mode(3)                                         % switch between plot modes (PLOT 3)
                    case 1                                                  % Left plot only
                        if isempty(ref_lim)
                            ref_lim = get(a3(1),'XLim');                    % get current x limits and use them a reference
                        end
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);  % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % tick labels (4 decimal places)
                        end
                        set(a3(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (left)
                        set(a3(2),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (right)
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                            datetick(a3(1),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        set(a3(2),'Visible','off');                         % turn of right axes
                        linkaxes([a3(1),a3(2)],'x');                        % link axes, just in case
                    case 2                                                  % Right plot only
                        if isempty(ref_lim)
                            ref_lim = get(a3(2),'XLim');                    % get current x limits and use them a reference
                        end
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);  % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % tick labels (4 decimal places)
                        end
                        set(a3(2),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (right)
                        set(a3(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % set new ticks and labels (left)
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                            datetick(a3(2),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        set(a3(1),'Visible','off');                         % turn of right axes
                        linkaxes([a3(1),a3(2)],'x');                        % link axes, just in case
                    case 3                                                  % Right and Left plot
                        if isempty(ref_lim)
                            ref_lim = get(a3(1),'XLim');                    % get current x limits and use them a reference
                        end
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);   % compute new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i)); % create new labels (4 decimal places)
                        end
                        set(a3(1),'XTick',xtick_value,'XTickLabel',xtick_lable); % place new labels and ticks
                        set(a3(2),'XTick',xtick_value,'Visible','on','color','none','XTickLabel',[]); % make Right plot visible but remove ticks
%                         if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0   % switch between matlab time and calendar/time
                            datetick(a3(1),'x','yyyy/mm/dd HH:MM','keepticks'); % time in YYYY/MM/DD HH:MM format
%                         end
                        linkaxes([a3(1),a3(2)],'x');                        % link axes, just in case
                    otherwise
                        ref_lim = [];                                       % no ref_lim if plot1 is not on
                end
                
                if get(findobj('Tag','plotGrav_push_date'),'UserData') == 0  % switch between matlab time and calendar/time
                    set(findobj('Tag','plotGrav_push_date'),'UserData',1)   % update 'Convert time button
                else
                    set(findobj('Tag','plotGrav_push_date'),'UserData',0)   % update 'Convert time button
                end
            case 'reset_view'
                set(findobj('Tag','plotGrav_push_zoom_in'),'UserData',[]);drawnow % status
                plotGrav('uitable_push');
                plotGrav('push_date');
                %% ZOOM_IN
            case 'push_zoom_in'
                set(findobj('Tag','plotGrav_text_status'),'String','Select two points...');drawnow % status
                [selected_x,selected_y] = ginput(2);
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get axes one handle
                a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
                selected_x = sort(selected_x);                              % sort = ascending
                % Plot1
                if diff(selected_x) > 0
                    set(a1(1),'XLim',selected_x);                               % set xlimits for left axes (not important if visible or not)
                    set(a1(2),'XLim',selected_x);                               % set xlimits for right axes 
                    rL1 = get(a1(1),'YLim');                                    % get new ylimits (left)
                    rR1 = get(a1(2),'YLim');                                    % get new ylimits (right)
                    set(a1(1),'YTick',linspace(rL1(1),rL1(2),5));               % set new ylimits (left)
                    set(a1(2),'YTick',linspace(rR1(1),rR1(2),5));               % set new ylimits (right)
                    % Plot2
                    set(a2(1),'XLim',selected_x);                               % set xlimits for left axes (not important if visible or not)
                    set(a2(2),'XLim',selected_x);                               % set xlimits for right axes 
                    rL1 = get(a2(1),'YLim');                                    % get new ylimits (left)
                    rR1 = get(a2(2),'YLim');                                    % get new ylimits (right)
                    set(a2(1),'YTick',linspace(rL1(1),rL1(2),5));               % set new ylimits (left)
                    set(a2(2),'YTick',linspace(rR1(1),rR1(2),5));               % set new ylimits (right)
                    % Plot3
                    set(a3(1),'XLim',selected_x);                               % set xlimits for left axes (not important if visible or not)
                    set(a3(2),'XLim',selected_x);                               % set xlimits for right axes 
                    rL1 = get(a3(1),'YLim');                                    % get new ylimits (left)
                    rR1 = get(a3(2),'YLim');                                    % get new ylimits (right)
                    set(a3(1),'YTick',linspace(rL1(1),rL1(2),5));               % set new ylimits (left)
                    set(a3(2),'YTick',linspace(rR1(1),rR1(2),5));               % set new ylimits (right)
                end
                set(findobj('Tag','plotGrav_push_zoom_in'),'UserData',selected_x);drawnow % status
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
                plotGrav('push_date');
                
            case 'select_point'
                %% Select point
                set(findobj('Tag','plotGrav_text_status'),'String','Select a point...');drawnow % status
                [selected_x,selected_y] = ginput(1);                        % get one point
                selected_x = datevec(selected_x);                           % convert to calendar date+time
                set(findobj('Tag','plotGrav_text_status'),'String',...      % write message
                    sprintf('Point selected: %04d/%02d/%02d %02d:%02d:%02d = %7.3f',...
                    selected_x(1),selected_x(2),selected_x(3),selected_x(4),selected_x(5),round(selected_x(6)),selected_y));drawnow % status
                try
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                catch
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                [ty,tm,td,th,tmm] = datevec(now);
                fprintf(fid,'Point selected: %04d/%02d/%02d %02d:%02d:%02d = %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                    selected_x(1),selected_x(2),selected_x(3),selected_x(4),selected_x(5),round(selected_x(6)),selected_y,ty,tm,td,th,tmm);
                fclose(fid);
            case 'compute_difference'
                %% Comute difference
                set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % status
                [selected_x(1),selected_y(1)] = ginput(1);                        % get one point
                set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % status
                [selected_x(2),selected_y(2)] = ginput(1);                        % get one point
                set(findobj('Tag','plotGrav_text_status'),'String',...      % write message
                    sprintf('X diff (1-2): %8.4f hours,   Y diff (1-2):  %8.4f',...
                    (selected_x(1)-selected_x(2))*24,selected_y(1)-selected_y(2)));drawnow % status
                try
                    fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                catch
                    fid = fopen('plotGrav_LOG_FILE.log','a');
                end
                [ty,tm,td,th,tmm] = datevec(now);
                [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x(1));
                [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x(2));
                fprintf(fid,'Difference computed (1-2): dX = %8.4f hours, dY = %8.4f. First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                    (selected_x(1)-selected_x(2))*24,selected_y(1)-selected_y(2),ty1,tm1,td1,th1,tmm1,ts1,selected_y(1),...
                    ty2,tm2,td2,th2,tmm2,ts2,selected_y(2),ty,tm,td,th,tmm);
                fclose(fid);
            case 'push_webcam'
                %% Select Webcam data
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % get all data 
                if ~isempty(data)
                    try
                        set(findobj('Tag','plotGrav_text_status'),'String','Select a point...');drawnow % status
                        [selected_x,selected_y] = ginput(1);                        % get one point
                        set(findobj('Tag','plotGrav_text_status'),'String','Searching image...');drawnow % status 
                        [year,month,day] = datevec(selected_x);
                        ls = dir(fullfile(get(findobj('Tag','plotGrav_menu_webcam'),'UserData'),sprintf('Schedule_%04d%02d%02d*',year,month,day)));
                        if ~isempty(ls)
                            for i = 1:length(ls)
                                temp = ls(i).name;
                                if length(temp)>2                                 % only for files with reasonable name length
                                    date_webcam(i,1) = datenum(str2double(temp(10:13)),str2double(temp(14:15)),str2double(temp(16:17)),...
                                                          str2double(temp(19:20)),str2double(temp(21:22)),str2double(temp(23:24)));
                                else
                                    date_webcam(i,1) = -9e+10;
                                end
                            end
                            r = find(abs(selected_x - date_webcam) == min(abs(selected_x - date_webcam)));
                            if ~isempty(r)
                                set(findobj('Tag','plotGrav_text_status'),'String','Loading image...');drawnow % status 
                                A = imread(fullfile(get(findobj('Tag','plotGrav_menu_webcam'),'UserData'),ls(r(1)).name));
                                figure
                                image(A)
                                title(ls(r(1)).name,'interpreter','none');
                                set(gca,'XTick',[],'YTick',[]);
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
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle,...
                if get(findobj('Tag','plotGrav_menu_reverse_l1'),'UserData') == 1 % check current axis status
                   set(findobj('Tag','plotGrav_menu_reverse_l1'),'UserData',0); % update status
                    set(a1(1),'YDir','reverse');                            % reverse direction
                else
                   set(findobj('Tag','plotGrav_menu_reverse_l1'),'UserData',1); % update status
                    set(a1(1),'YDir','normal');                             % set to normal
                end
            case 'reverse_r1'
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get axes one handle,...
                if get(findobj('Tag','plotGrav_menu_reverse_r1'),'UserData') == 1
                   set(findobj('Tag','plotGrav_menu_reverse_r1'),'UserData',0);
                    set(a1(2),'YDir','reverse');
                else
                   set(findobj('Tag','plotGrav_menu_reverse_r1'),'UserData',1);
                    set(a1(2),'YDir','normal');
                end
            case 'reverse_l2'
                a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle,...
                if get(findobj('Tag','plotGrav_menu_reverse_l2'),'UserData') == 1
                   set(findobj('Tag','plotGrav_menu_reverse_l2'),'UserData',0);
                    set(a2(1),'YDir','reverse');
                else
                   set(findobj('Tag','plotGrav_menu_reverse_l2'),'UserData',1);
                    set(a2(1),'YDir','normal');
                end
            case 'reverse_r2'
                a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');  % get axes two handle,...
                if get(findobj('Tag','plotGrav_menu_reverse_r2'),'UserData') == 1
                   set(findobj('Tag','plotGrav_menu_reverse_r2'),'UserData',0);
                    set(a2(2),'YDir','reverse');
                else
                   set(findobj('Tag','plotGrav_menu_reverse_r2'),'UserData',1);
                    set(a2(2),'YDir','normal');
                end
            case 'reverse_l3'
                a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle,...
                if get(findobj('Tag','plotGrav_menu_reverse_l3'),'UserData') == 1
                   set(findobj('Tag','plotGrav_menu_reverse_l3'),'UserData',0);
                    set(a3(1),'YDir','reverse');
                else
                   set(findobj('Tag','plotGrav_menu_reverse_l3'),'UserData',1);
                    set(a3(1),'YDir','normal');
                end
            case 'reverse_r3'
                a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle,...
                if get(findobj('Tag','plotGrav_menu_reverse_r3'),'UserData') == 1
                   set(findobj('Tag','plotGrav_menu_reverse_r3'),'UserData',0);
                    set(a3(2),'YDir','reverse');
                else
                   set(findobj('Tag','plotGrav_menu_reverse_r3'),'UserData',1);
                    set(a3(2),'YDir','normal');
                end
                %% EXPORT DATA
            case 'export_igrav_all'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % get all data 
                time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % get time
                units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData'); % get iGrav units
                channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                try 
                    [name,path,selection] = uiputfile({'*.tsf';'*.mat'},'Select your iGrav output file'); % get output file
                    if name == 0                                            % If cancelled-> no output
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing iGrav data...');drawnow % status
                        switch selection
                            case 2
                                dataout.time = time.igrav;
                                dataout.data = data.igrav;
                                dataout.channels = channels_igrav;
                                dataout.units = units_igrav;
                                save([path,name],'dataout','-v7.3');
                                clear dataout
                            otherwise
                                dataout = [datevec(time.igrav),data.igrav];             % standard input for plotGrav_writetsf function
                                for i = 1:length(units_igrav)
                                    comment(i,1:4) = {'Wettzell','iGrav006',char(channels_igrav(i)),char(units_igrav(i))};  % create tsf header (input for plotGrav_writetsf function)
                                end
                                plotGrav_writetsf(dataout,comment,[path,name],3);            % write to tsf (2 decimal places)
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','iGrav data have been written to selected file.');drawnow % status
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);
                        fprintf(fid,'iGrav data written to %s (%04d/%02d/%02d %02d:%02d)\n',...
                            [path,name],ty,tm,td,th,tmm);
                        fclose(fid);
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not write the iGrav data!');drawnow % status
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Could not write iGrav data (%04d/%02d/%02d %02d:%02d)\n',...
                        ty,tm,td,th,tmm);
                    fclose(fid);
                end
            case 'export_igrav_sel'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % get all data 
                time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % get time
                units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData'); % get iGrav units
                channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1);     % get selected iGrav channels for L1
                try 
                    [name,path,selection] = uiputfile({'*.tsf';'*.mat'},'Select your iGrav output file'); % get output file
                    if name == 0                                            % If cancelled-> no output
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing iGrav data...');drawnow % status
                        switch selection
                            case 2
                                dataout.time = time.igrav;
                                dataout.data = data.igrav(:,plot_axesL1.igrav);
                                dataout.channels = channels_igrav(plot_axesL1.igrav);
                                dataout.units = units_igrav(plot_axesL1.igrav);
                                save([path,name],'dataout','-v7.3');
                                clear dataout
                            otherwise
                                dataout = [datevec(time.igrav),data.igrav(:,plot_axesL1.igrav)]; % standard input for plotGrav_writetsf function
                                channels_igrav = channels_igrav(plot_axesL1.igrav);     % remove unselected channels
                                units_igrav = units_igrav(plot_axesL1.igrav);           % remove unselected channels
                                for i = 1:length(units_igrav)
                                    comment(i,1:4) = {'Wettzell','iGrav006',char(channels_igrav(i)),char(units_igrav(i))};  % create tsf header (input for plotGrav_writetsf function)
                                end
                                plotGrav_writetsf(dataout,comment,[path,name],3);            % write to tsf (3 decimal places)
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','iGrav data have been written to selected file.');drawnow % status
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);
                        fprintf(fid,'iGrav data written to %s (%04d/%02d/%02d %02d:%02d)\n',...
                            [path,name],ty,tm,td,th,tmm);
                        fclose(fid);
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not write the iGrav data.');drawnow % status
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Could not write iGrav data (%04d/%02d/%02d %02d:%02d)\n',...
                        ty,tm,td,th,tmm);
                    fclose(fid);
                end
            case 'export_trilogi_all'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % get all data 
                time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % get time
                units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData'); % get trilogi units
                channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get trilogi channels (names)
                try 
                    [name,path,selection] = uiputfile({'*.tsf';'*.mat'},'Select your TRiLOGi output file'); % get output file
                    if name == 0                                            % If cancelled-> no output
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing TRiLOGi data...');drawnow % status
                        switch selection
                            case 2
                                dataout.time = time.trilogi;
                                dataout.data = data.trilogi;
                                dataout.channels = channels_trilogi;
                                dataout.units = units_trilogi;
                                save([path,name],'dataout','-v7.3');
                                clear dataout
                            otherwise
                                dataout = [datevec(time.trilogi),data.trilogi];         % standard input for plotGrav_writetsf function
                                for i = 1:length(units_trilogi)
                                    comment(i,1:4) = {'Wettzell','iGrav006',char(channels_trilogi(i)),char(units_trilogi(i))};  % create tsf header (input for plotGrav_writetsf function)
                                end
                                plotGrav_writetsf(dataout,comment,[path,name],3);   % write to tsf (3 decimal places)
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','TRiLOGi data have been written to selected file.');drawnow % status
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);
                        fprintf(fid,'TRiLOGi data written to %s (%04d/%02d/%02d %02d:%02d)\n',...
                            [path,name],ty,tm,td,th,tmm);
                        fclose(fid);
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not write the TRiLOGi data!');drawnow % status
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Could not write TRiLOGi data (%04d/%02d/%02d %02d:%02d)\n',...
                        ty,tm,td,th,tmm);
                    fclose(fid);
                end
            case 'export_trilogi_sel'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % get all data 
                time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % get time
                units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData'); % get trilogi units
                channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get trilogi channels (names)
                data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the trilogi table
                plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1);     % get selected trilogi channels for L1
                try 
                    
                    [name,path,selection] = uiputfile({'*.tsf';'*.mat'},'Select your TRiLOGi output file'); % get output file
                    if name == 0                                                % If cancelled-> no output
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing TRiLOGi data...');drawnow % status
                        switch selection
                            case 2
                                dataout.time = time.trilogi;
                                dataout.data = data.trilogi(:,plot_axesL1.trilogi);
                                dataout.channels = channels_trilogi(plot_axesL1.trilogi);
                                dataout.units = units_trilogi(plot_axesL1.trilogi);
                                save([path,name],'dataout','-v7.3');
                                clear dataout
                            otherwise
                                dataout = [datevec(time.trilogi),data.trilogi(:,plot_axesL1.trilogi)]; % standard input for plotGrav_writetsf function
                                channels_trilogi = channels_trilogi(plot_axesL1.trilogi); % remove unselected channels
                                units_trilogi = units_trilogi(plot_axesL1.trilogi);     % remove unselected channels
                                for i = 1:length(units_trilogi)
                                    comment(i,1:4) = {'Wettzell','iGrav006',char(channels_trilogi(i)),char(units_trilogi(i))};  % create tsf header (input for plotGrav_writetsf function)
                                end
                                plotGrav_writetsf(dataout,comment,[path,name],3);            % write to tsf (2 decimal places)
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','TRiLOGi data have been written to selected file.');drawnow % status
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        [ty,tm,td,th,tmm] = datevec(now);
                        fprintf(fid,'TRiLOGi data written to %s (%04d/%02d/%02d %02d:%02d)\n',...
                            [path,name],ty,tm,td,th,tmm);
                        fclose(fid);
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not write the TRiLOGi data.');drawnow % status
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Could not write TRiLOGi data (%04d/%02d/%02d %02d:%02d)\n',...
                        ty,tm,td,th,tmm);
                    fclose(fid);
                end
            case 'uncheck_all'
                data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                cla(a1(1));legend(a1(1),'off');ylabel(a1(1),[]);            % clear axes and remove legends and labels
                cla(a1(2));legend(a1(2),'off');ylabel(a1(2),[]);            % clear axes and remove legends and labels
                axis(a1(1),'auto');axis(a1(2),'auto');                      % Reset axis (not axes)
                cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);            % clear axes and remove legends and labels
                cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);            % clear axes and remove legends and labels
                axis(a2(1),'auto');axis(a2(2),'auto');
                cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);            % clear axes and remove legends and labels
                cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);            % clear axes and remove legends and labels
                axis(a3(1),'auto');axis(a3(2),'auto');
                data_igrav(:,[1,2,3,5,6,7]) = {false};                      % uncheck all fields
                set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update the table
                data_trilogi(:,[1,2,3,5,6,7]) = {false};
                set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi);
                data_other1(:,[1,2,3,5,6,7]) = {false};
                set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1);
                data_other2(:,[1,2,3,5,6,7]) = {false};
                set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2);
                
            case 'compute_statistics'
                %% COMPUTE histogram
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData'); % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData'); % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData'); % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData'); % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)
                    
                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav)
                        for i = 1:length(plot_axesL1.igrav)                  % compute for all selected channels
                            temp = data.igrav(:,plot_axesL1.igrav(i));
                            temp(isnan(temp)) = [];
                            figure('Name','plotGrav: basic statistics','Menubar','none'); % open new figure
                            histfit(temp)                                   % histogram + fitted normal ditribution
                            title(sprintf('iGrav hitogram+fitted norm. distibution: %s',char(channels_igrav(plot_axesL1.igrav(i)))),...
                                  'interpreter','none');                    % plot title
                            xlabel(char(units_igrav(plot_axesL1.igrav(i)))); % x label
                            ylabel('frequency')                             % ylabel
                            x = get(gca,'XLim');y = get(gca,'YLim');        % get x and y limits (to place text)
                            text(x(2)*0.6,y(2)*0.9,sprintf('Mean = %7.3f',mean(temp))); % mean
                            text(x(2)*0.6,y(2)*0.8,sprintf('SD = %7.3f',std(temp))); % standard deviation
                            text(x(2)*0.6,y(2)*0.7,sprintf('Min = %7.3f',min(temp))); % min
                            text(x(2)*0.6,y(2)*0.6,sprintf('Max = %7.3f',max(temp))); % max
                            clear temp                                      % remove used variable
                        end
                    end
                    % TRiLOGi data
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected trilogi channels for L1
                    if ~isempty(plot_axesL1.trilogi)
                        for i = 1:length(plot_axesL1.trilogi)                  % compute for all selected channels
                            temp = data.trilogi(:,plot_axesL1.trilogi(i));
                            temp(isnan(temp)) = [];
                            figure('Name','plotGrav: basic statistics','Menubar','none'); % open new figure
                            histfit(temp)                                   % histogram + fitted normal ditribution
                            title(sprintf('TRiLOGi hitogram+fitted norm. distibution: %s',char(channels_trilogi(plot_axesL1.trilogi(i)))),...
                                  'interpreter','none');                    % plot title
                            xlabel(char(units_trilogi(plot_axesL1.trilogi(i)))); % x label
                            ylabel('frequency')                             % ylabel
                            x = get(gca,'XLim');y = get(gca,'YLim');        % get x and y limits (to place text)
                            text(x(2)*0.6,y(2)*0.9,sprintf('Mean = %7.3f',mean(temp))); % mean
                            text(x(2)*0.6,y(2)*0.8,sprintf('SD = %7.3f',std(temp))); % standard deviation
                            text(x(2)*0.6,y(2)*0.7,sprintf('Min = %7.3f',min(temp))); % min
                            text(x(2)*0.6,y(2)*0.6,sprintf('Max = %7.3f',max(temp))); % max
                            clear temp                                      % remove used variable
                        end
                    end
                    % Other1 data
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected other1 channels for L1
                    if ~isempty(plot_axesL1.other1)
                        for i = 1:length(plot_axesL1.other1)                  % compute for all selected channels
                            temp = data.other1(:,plot_axesL1.other1(i));
                            temp(isnan(temp)) = [];
                            figure('Name','plotGrav: basic statistics','Menubar','none'); % open new figure
                            histfit(temp)                                   % histogram + fitted normal ditribution
                            title(sprintf('Other1 hitogram+fitted norm. distibution: %s',char(channels_other1(plot_axesL1.other1(i)))),...
                                  'interpreter','none');                    % plot title
                            xlabel(char(units_other1(plot_axesL1.other1(i)))); % x label
                            ylabel('frequency')                             % ylabel
                            x = get(gca,'XLim');y = get(gca,'YLim');        % get x and y limits (to place text)
                            text(x(2)*0.6,y(2)*0.9,sprintf('Mean = %7.3f',mean(temp))); % mean
                            text(x(2)*0.6,y(2)*0.8,sprintf('SD = %7.3f',std(temp))); % standard deviation
                            text(x(2)*0.6,y(2)*0.7,sprintf('Min = %7.3f',min(temp))); % min
                            text(x(2)*0.6,y(2)*0.6,sprintf('Max = %7.3f',max(temp))); % max
                            clear temp                                      % remove used variable
                        end
                    end
                    % Other2 data
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    if ~isempty(plot_axesL1.other2)
                        for i = 1:length(plot_axesL1.other2)                  % compute for all selected channels
                            temp = data.other2(:,plot_axesL1.other2(i));
                            temp(isnan(temp)) = [];
                            figure('Name','plotGrav: basic statistics','Menubar','none'); % open new figure
                            histfit(temp)                                   % histogram + fitted normal ditribution
                            title(sprintf('Other2 hitogram+fitted norm. distibution: %s',char(channels_other2(plot_axesL1.other2(i)))),...
                                  'interpreter','none');                    % plot title
                            xlabel(char(units_other2(plot_axesL1.other2(i)))); % x label
                            ylabel('frequency')                             % ylabel
                            x = get(gca,'XLim');y = get(gca,'YLim');        % get x and y limits (to place text)
                            text(x(2)*0.6,y(2)*0.9,sprintf('Mean = %7.3f',mean(temp))); % mean
                            text(x(2)*0.6,y(2)*0.8,sprintf('SD = %7.3f',std(temp))); % standard deviation
                            text(x(2)*0.6,y(2)*0.7,sprintf('Min = %7.3f',min(temp))); % min
                            text(x(2)*0.6,y(2)*0.6,sprintf('Max = %7.3f',max(temp))); % max
                            clear temp                                      % remove used variable
                        end
                    end
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'compute_spectral_valid'
                %% Compute spectral analysis using hann window
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)
                    color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');          % get defined colors

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    f0_spectral = figure('Name','plotGrav: spectral analysis','Toolbar','figure'); % open new figure
                    a0_spectral = axes('FontSize',9);                       % create new axes
                    hold(a0_spectral,'on');                                 % all results in one window
                    grid(a0_spectral,'on');                                 % grid on
                    color_num = 1;legend_spectral = [];                     % prepare variables
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav)
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            time_resolution = mode(diff(time.igrav));       % time resolution (sampling period)
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),time_resolution); % find time steps. FFT only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            r = find((id(:,2)-id(:,1)) == max(id(:,2)-id(:,1))); % find the longest time interval without interruption
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout(id(r,1):id(r,2)),... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_igrav(plot_axesL1.igrav(i))]; % add legend
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    % TRiLOGi data
                    if ~isempty(plot_axesL1.trilogi)
                        for i = 1:length(plot_axesL1.trilogi)               % compute for all selected channels
                            time_resolution = mode(diff(time.trilogi));     % time resolution (sampling period)
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),time_resolution); % find time steps. FFT only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            r = find((id(:,2)-id(:,1)) == max(id(:,2)-id(:,1))); % find the longest time interval without interruption
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout(id(r,1):id(r,2)),... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_trilogi(plot_axesL1.trilogi(i))]; % add legend
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    % Other1 data
                    if ~isempty(plot_axesL1.other1)
                        for i = 1:length(plot_axesL1.other1)                % compute for all selected channels
                            time_resolution = mode(diff(time.other1));      % time resolution (sampling period)
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.other1,data.other1(:,plot_axesL1.other1(i)),time_resolution); % find time steps. FFT only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            r = find((id(:,2)-id(:,1)) == max(id(:,2)-id(:,1))); % find the longest time interval without interruption
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout(id(r,1):id(r,2)),... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_other1(plot_axesL1.other1(i))]; % add legend
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    % Other2 data
                    if ~isempty(plot_axesL1.other2)
                        for i = 1:length(plot_axesL1.other2)                % compute for all selected channels
                            time_resolution = mode(diff(time.other2));      % time resolution (sampling period)
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.other2,data.other2(:,plot_axesL1.other2(i)),time_resolution); % find time steps. FFT only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            r = find((id(:,2)-id(:,1)) == max(id(:,2)-id(:,1))); % find the longest time interval without interruption
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout(id(r,1):id(r,2)),... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_other2(plot_axesL1.other2(i))]; % add legend
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    
                    l = legend(a0_spectral,legend_spectral);                % show legend
                    set(l,'FontSize',8,'interpreter','none');               % set legend properties
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'compute_spectral_interp'
                %% Compute spectral analysis using hann window + interpolation
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status 
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)
                    color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');          % get defined colors

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    f0_spectral = figure('Name','plotGrav: spectral analysis','Toolbar','figure'); % open new figure
                    a0_spectral = axes('FontSize',9);                       % create new axes
                    hold(a0_spectral,'on');                                 % all results in one window
                    grid(a0_spectral,'on');                                 % grid on
                    color_num = 1;legend_spectral = [];                     % prepare variables
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav)
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            time_resolution = mode(diff(time.igrav));       % time resolution (sampling period)
                            time_in = time.igrav;                         % input time vector
                            data_in = data.igrav(:,plot_axesL1.igrav(i)); % input data vector
                            time_in(isnan(data_in)) = [];                   % remove NaNs
                            data_in(isnan(data_in)) = [];                   % remove NaNs
                            timeout = time_in(1):time_resolution:time_in(end); % new time vecor
                            dataout = interp1(time_in,data_in,timeout);     % interpolate to new time vector 
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout',... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_igrav(plot_axesL1.igrav(i))]; % add legend
                            clear data_in time_in timeout_timeresolution
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    % TRiLOGi data
                    if ~isempty(plot_axesL1.trilogi)
                        for i = 1:length(plot_axesL1.trilogi)               % compute for all selected channels
                            time_resolution = mode(diff(time.trilogi));     % time resolution (sampling period)
                            time_in = time.trilogi;                         % input time vector
                            data_in = data.trilogi(:,plot_axesL1.trilogi(i)); % input data vector
                            time_in(isnan(data_in)) = [];                   % remove NaNs
                            data_in(isnan(data_in)) = [];                   % remove NaNs
                            timeout = time_in(1):time_resolution:time_in(end); % new time vecor
                            dataout = interp1(time_in,data_in,timeout);     % interpolate to new time vector 
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout',... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_trilogi(plot_axesL1.trilogi(i))]; % add legend
                            clear data_in time_in timeout_timeresolution
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    % Other1 data
                    if ~isempty(plot_axesL1.other1)
                        for i = 1:length(plot_axesL1.other1)                % compute for all selected channels
                            time_resolution = mode(diff(time.other1));       % time resolution (sampling period)
                            time_in = time.other1;                         % input time vector
                            data_in = data.other1(:,plot_axesL1.other1(i)); % input data vector
                            time_in(isnan(data_in)) = [];                   % remove NaNs
                            data_in(isnan(data_in)) = [];                   % remove NaNs
                            timeout = time_in(1):time_resolution:time_in(end); % new time vecor
                            dataout = interp1(time_in,data_in,timeout);     % interpolate to new time vector 
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout',... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_other1(plot_axesL1.other1(i))]; % add legend
                            clear data_in time_in timeout_timeresolution
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    % Other2 data
                    if ~isempty(plot_axesL1.other2)
                        for i = 1:length(plot_axesL1.other2)                % compute for all selected channels
                            time_resolution = mode(diff(time.other2));       % time resolution (sampling period)
                            time_in = time.other2;                         % input time vector
                            data_in = data.other2(:,plot_axesL1.other2(i)); % input data vector
                            time_in(isnan(data_in)) = [];                   % remove NaNs
                            data_in(isnan(data_in)) = [];                   % remove NaNs
                            timeout = time_in(1):time_resolution:time_in(end); % new time vecor
                            dataout = interp1(time_in,data_in,timeout);     % interpolate to new time vector 
                            [f,amp,pha,y,h] = plotGrav_spectralAnalysis(dataout',... % compute spectral analysis for the longest time interval
                                        1/(time_resolution*86400),'hann',[],a0_spectral); % set frequency and window
                            set(h,'color',color_scale(color_num,:));        % set line color
                            color_num = color_num + 1;                      % increase color index
                            legend_spectral = [legend_spectral,channels_other2(plot_axesL1.other2(i))]; % add legend
                        end
                    end
                    clear f amp pha y h r timeout dataout id i
                    
                    l = legend(a0_spectral,legend_spectral);                % show legend
                    set(l,'FontSize',8,'interpreter','none');               % set legend properties
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status 
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'select_other1'
                %% Select files/paths interactively
                [name,path] = uigetfile({'*.tsf';'*.dat'},'Select Other1 TSoft or DAT (Soil moisure) file');
                if name == 0                                            % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','No file selected.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_other1_path'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Other1 file selected.');drawnow % status
                end
            case 'select_other2'
                [name,path] = uigetfile({'*.tsf';'*.dat'},'Select Other2 TSoft or DAT (Soil moisure) file');
                if name == 0                                            % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_other2_path'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Other2 file selected.');drawnow % status
                end
            case 'select_igrav'
                path = uigetdir('Select iGrav Data Path');
                if path == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select the iGrav path.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_igrav_path'),'String',path);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','iGrav paht selected.');drawnow % status
                end
            case 'select_igrav_file'
                [name,path] = uigetfile({'*.tsf'},'Select iGrav Data File');
                if path == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select the iGrav file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_igrav_path'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','iGrav file selected.');drawnow % status
                end
            case 'select_trilogi'
                path = uigetdir('Select TRiLOGi Data Path');
                if path == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select the TRiLOGi path.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_trilogi_path'),'String',path);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','TRiLOGi paht selected.');drawnow % status
                end
            case 'select_trilogi_file'
                [name,path] = uigetfile({'*.tsf'},'Select TRiLOGi Data File');
                if path == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select a TRiLOGi file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_trilogi_path'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','TRiLOGi file selected.');drawnow % status
                end
            case 'select_tides'
                [name,path] = uigetfile('*.tsf','Select a tsf file with tides (channel 1)');
                if name == 0                                            % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_tide_file'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Tides file selected.');drawnow % status
                end
            case 'select_filter'
                [name,path] = uigetfile('*.*','Select a tsf file with ETERNA filter (response)');
                if name == 0                                            % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','No file selected');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_filter_file'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitler file selected.');drawnow % status
                end
            case 'select_webcam'
                path = uigetdir('Select Webcam Image Path');
                if path == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select the Webcam path.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_webcam_path'),'String',path);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Webcam paht selected.');drawnow % status
                end
            case 'select_unzip'
                [name,path] = uigetfile('*.exe','Select 7zip/Unzip file');
                if name == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select the Unzip file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_menu_ftp'),'UserData',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Unzip file selected.');drawnow % status
                end
            case 'select_logfile'
                [name,path] = uiputfile('*.log','Select log file');
                if name == 0                                                % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select a log file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_edit_logfile_file'),'String',[path,name]);drawnow % status
                    set(findobj('Tag','plotGrav_text_status'),'String','Unzip file selected.');drawnow % status
                end
            case 'print_all'
                %% Printing all plots
                [name,path,filteridex] = uiputfile({'*.jpg';'*.eps'},'Select output file (extension: jpg or eps)');
                if name == 0                                               % If cancelled-> no output
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Printing...');drawnow % status
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                    a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                    a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                    plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
                    scrs = get(0,'screensize');                             % get monitor resolution
                    F2c = figure('Position',[50 50 scrs(3)-50*2, scrs(4)-50*3],... % create new invisible window for printing
                        'Resize','off','Menubar','none','ToolBar','none',...
                        'NumberTitle','off','Color',[0.941 0.941 0.941],...
                        'Name','plotGrav: plot iGrav data','visible','off');
                    if plot_mode(1) > 0
                        a1c(1) = copyobj(a1(1),F2c);                        % copy axes to the new figure (only if something is plotted)
                        a1c(2) = copyobj(a1(2),F2c);                        
                        set(a1c(1),'units','normalized','Position',[0.185,0.71,0.63,0.26]); % move the axes in the center of the figure
                        set(a1c(2),'units','normalized','Position',[0.185,0.71,0.63,0.26]);
                        rL1 = get(a1c(1),'YLim'); 
                        set(a1c(1),'YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')       
                        % Create legend (is not copied automatically)
                        temp = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get legend
                        l = legend(a1c(1),temp{1});                             % set left legend
                        set(l,'interpreter','none','FontSize',8,'Location','NorthWest'); % set font 
                        l = legend(a1c(2),temp{2});                             % set legend on right
                        set(l,'interpreter','none','FontSize',8,'Location','NorthEast'); % set font
                    end
                    if plot_mode(2) > 0
                        a2c(1) = copyobj(a2(1),F2c);                        % copy axes to the new figure (only if something is plotted)
                        a2c(2) = copyobj(a2(2),F2c);
                        set(a2c(1),'units','normalized','Position',[0.185,0.39,0.63,0.26]); % move the axes to the center of the figure
                        set(a2c(2),'units','normalized','Position',[0.185,0.39,0.63,0.26]); % move the axes to the center of the figure
                        rL1 = get(a2c(1),'YLim'); 
                        set(a2c(1),'YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')       
                        temp = get(findobj('Tag','plotGrav_menu_print_two'),'UserData'); % get legend
                        l = legend(a2c(1),temp{1});                             % set left legend
                        set(l,'interpreter','none','FontSize',8,'Location','NorthWest'); % set font 
                        l = legend(a2c(2),temp{2});                             % set legend on right
                        set(l,'interpreter','none','FontSize',8,'Location','NorthEast'); % set font
                    end
                    if plot_mode(3) > 0
                        a3c(1) = copyobj(a3(1),F2c);                        % copy axes to the new figure (only if something is plotted)
                        a3c(2) = copyobj(a3(2),F2c);
                        set(a3c(1),'units','normalized','Position',[0.185,0.06,0.63,0.26]); % move the axes to the center of the figure
                        set(a3c(2),'units','normalized','Position',[0.185,0.06,0.63,0.26]); % move the axes to the center of the figure
                        rL1 = get(a3c(1),'YLim'); 
                        set(a3c(1),'YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')       
                        temp = get(findobj('Tag','plotGrav_menu_print_three'),'UserData');
                        l = legend(a3c(1),temp{1});                             % left legend
                        set(l,'interpreter','none','FontSize',8,'Location','NorthWest');
                        l = legend(a3c(2),temp{2});                             % legend on right
                        set(l,'interpreter','none','FontSize',8,'Location','NorthEast');
                    end
%                     temp = get(findobj('Tag','plotGrav_insert_recangle'),'UserData');
%                     if ~isempty(temp);
%                         for an = 1:length(temp)
%                             a = annotation('rectangle');
%                             set(a,'Position',get(temp(an),'Position'));
%                             set(a,'Color',get(temp(an),'Color'));
%                             set(a,'LineStyle',get(temp(an),'LineStyle'));
%                             set(a,'LineWidth',get(temp(an),'LineWidth'));
%                         end
%                     end
                    % Print
                    set(F2c,'paperpositionmode','auto');                    % the printed file will have the same dimensions as figure
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Data plotted: %s (%04d/%02d/%02d %02d:%02d)\n',...
                        [path,name],ty,tm,td,th,tmm);
                    fclose(fid);
                    switch filteridex
                        case 2                                              % eps
                            print(F2c,'-depsc','-r400',[path,name]);
                        case 1                                              % jpg
                            print(F2c,'-djpeg','-r400',[path,name]);
                    end
                    close(F2c)                                              % close the window
                    set(findobj('Tag','plotGrav_text_status'),'String','The figure has been printed.');drawnow % status
                    
                end
                
            case 'print_one'
                %% Print first plot
                [name,path,filteridex] = uiputfile({'*.jpg';'*.eps'},'Select output file (extension: jpg or eps)');
                if name == 0                                               % If cancelled-> no output
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Printing...');drawnow % status
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                    plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
                    scrs = get(0,'screensize');                             % get monitor resolution
                    F2c = figure('Position',[50 50 scrs(3)-50*2, scrs(4)-50*3],... % create new invisible window for printing
                        'Resize','off','Menubar','none','ToolBar','none',...
                        'NumberTitle','off','Color',[0.941 0.941 0.941],...
                        'Name','plotGrav: plot iGrav data','visible','off');
                    if plot_mode(1) > 0
                        a1c(1) = copyobj(a1(1),F2c);                        % copy axes to the new figure (only if something is plotted)
                        a1c(2) = copyobj(a1(2),F2c);                        
                        set(a1c(1),'units','normalized','Position',[0.185,0.71,0.63,0.26]); % move the axes in the center of the figure
                        set(a1c(2),'units','normalized','Position',[0.185,0.71,0.63,0.26]);
                    end
                    rL1 = get(a1c(1),'YLim'); 
                    set(a1c(1),'YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')       
                       
                    % Create legend (is not copied automatically)
                    temp = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get legend
                    l = legend(a1c(1),temp{1});                             % set left legend
                    set(l,'interpreter','none','FontSize',8,'Location','NorthWest'); % set font 
                    l = legend(a1c(2),temp{2});                             % set legend on right
                    set(l,'interpreter','none','FontSize',8,'Location','NorthEast'); % set font
                    
                    % Print
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Data plotted: %s (%04d/%02d/%02d %02d:%02d)\n',...
                        [path,name],ty,tm,td,th,tmm);
                    fclose(fid);
                    set(F2c,'paperpositionmode','auto');                    % the printed file will have the same dimensions as figure
                    switch filteridex
                        case 2                                              % eps
                            print(F2c,'-depsc',[path,name]);
                        case 1                                              % jpg
                            print(F2c,'-djpeg','-r400',[path,name]);
                    end
                    close(F2c)                                              % close the window
                    set(findobj('Tag','plotGrav_text_status'),'String','The figure has been printed.');drawnow % status
                    
                end
            case 'print_two'
                %% Print second plot
                [name,path,filteridex] = uiputfile({'*.jpg';'*.eps'},'Select output file (extension: jpg or eps)');
                if name == 0                                               % If cancelled-> no output
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Printing...');drawnow % status
                    a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes one handle
                    plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
                    scrs = get(0,'screensize');                             % get monitor resolution
                    F2c = figure('Position',[50 50 scrs(3)-50*2, scrs(4)-50*3],... % create new invisible window for printing
                        'Resize','off','Menubar','none','ToolBar','none',...
                        'NumberTitle','off','Color',[0.941 0.941 0.941],...
                        'Name','plotGrav: plot iGrav data','visible','off');
                    if plot_mode(1) > 0
                        a2c(1) = copyobj(a2(1),F2c);                        % copy axes to the new figure (only if something is plotted)
                        a2c(2) = copyobj(a2(2),F2c);                        
                        set(a2c(1),'units','normalized','Position',[0.185,0.71,0.63,0.26]); % move the axes in the center of the figure
                        set(a2c(2),'units','normalized','Position',[0.185,0.71,0.63,0.26]);
                        % Create legend (is not copied automatically)
                        temp = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get legend
                        l = legend(a2c(1),temp{1});                             % set left legend
                        set(l,'interpreter','none','FontSize',8,'Location','NorthWest'); % set font 
                        l = legend(a2c(2),temp{2});                             % set legend on right
                        set(l,'interpreter','none','FontSize',8,'Location','NorthEast'); % set font
                    end
                    rL1 = get(a2c(1),'YLim'); 
                    set(a2c(1),'YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')       
                       
                    
                    % Print
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Data plotted: %s (%04d/%02d/%02d %02d:%02d)\n',...
                        [path,name],ty,tm,td,th,tmm);
                    fclose(fid);
                    set(F2c,'paperpositionmode','auto');                    % the printed file will have the same dimensions as figure
                    switch filteridex
                        case 2                                              % eps
                            print(F2c,'-depsc',[path,name]);
                        case 1                                              % jpg
                            print(F2c,'-djpeg','-r400',[path,name]);
                    end
                    close(F2c)                                              % close the window
                    set(findobj('Tag','plotGrav_text_status'),'String','The figure has been printed.');drawnow % status
                    
                end
            case 'print_three'
                %% Print third plot
                [name,path,filteridex] = uiputfile({'*.jpg';'*.eps'},'Select output file (extension: jpg or eps)');
                if name == 0                                               % If cancelled-> no output
                    set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Printing...');drawnow % status
                    a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes one handle
                    plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData'); % get plot mode
                    scrs = get(0,'screensize');                             % get monitor resolution
                    F2c = figure('Position',[50 50 scrs(3)-50*2, scrs(4)-50*3],... % create new invisible window for printing
                        'Resize','off','Menubar','none','ToolBar','none',...
                        'NumberTitle','off','Color',[0.941 0.941 0.941],...
                        'Name','plotGrav: plot iGrav data','visible','off');
                    if plot_mode(1) > 0
                        a3c(1) = copyobj(a3(1),F2c);                        % copy axes to the new figure (only if something is plotted)
                        a3c(2) = copyobj(a3(2),F2c);                        
                        set(a3c(1),'units','normalized','Position',[0.185,0.71,0.63,0.26]); % move the axes in the center of the figure
                        set(a3c(2),'units','normalized','Position',[0.185,0.71,0.63,0.26]);
                        % Create legend (is not copied automatically)
                        temp = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get legend
                        l = legend(a3c(1),temp{1});                             % set left legend
                        set(l,'interpreter','none','FontSize',8,'Location','NorthWest'); % set font 
                        l = legend(a3c(2),temp{2});                             % set legend on right
                        set(l,'interpreter','none','FontSize',8,'Location','NorthEast'); % set font
                    end
                    rL1 = get(a3c(1),'YLim'); 
                    set(a3c(1),'YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')       
                       
                    % Print
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    [ty,tm,td,th,tmm] = datevec(now);
                    fprintf(fid,'Data plotted: %s (%04d/%02d/%02d %02d:%02d)\n',...
                        [path,name],ty,tm,td,th,tmm);
                    fclose(fid);
                    set(F2c,'paperpositionmode','auto');                    % the printed file will have the same dimensions as figure
                    switch filteridex
                        case 2                                              % eps
                            print(F2c,'-depsc',[path,name]);
                        case 1                                              % jpg
                            print(F2c,'-djpeg','-r400',[path,name]);
                    end
                    close(F2c)                                              % close the window
                    set(findobj('Tag','plotGrav_text_status'),'String','The figure has been printed.');drawnow % status
                end
            case 'show_filter'
                %% Plot filter impulse
                try
                    set(findobj('Tag','plotGrav_text_status'),'String','Loading Filter...');drawnow % send message to status bar
                    filter_file = get(findobj('Tag','plotGrav_edit_filter_file'),'String'); % get filter filename
                    if ~isempty(filter_file)                                % try to load the filter file/response if some string is given
                        Num = load(filter_file);                            % load filter file = in ETERNA format - header
                        Num = vertcat(Num(:,2),flipud(Num(1:end-1,2)));     % stack the filter (ETERNA uses only one half of the repose = mirror the filter)
                        f0_filter = figure('Name','plotGrav: filter impulse response','Toolbar','figure'); % open new figure
                        a0_spectral = axes('FontSize',9);                       % create new axes
                        hold(a0_spectral,'on');                                 % all results in one window
                        grid(a0_spectral,'on');                                 % grid on
                        plot(a0_spectral,Num);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % send message to status bar
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','No filter file selected.');drawnow % status
                    end
                catch
                    fprintf('Could not load filter: %s\n',filter_file);       % send message to command line that filter file could not be loaded
                end
                %% Label/Legend/Grid
            case 'show_grid'
                temp = get(findobj('Tag','plotGrav_check_grid'),'Value');
                if temp == 1
                    set(findobj('Tag','plotGrav_check_grid'),'Value',0);
                else
                    set(findobj('Tag','plotGrav_check_grid'),'Value',1);
                end
            case 'show_label'
                temp = get(findobj('Tag','plotGrav_check_labels'),'Value');
                if temp == 1
                    set(findobj('Tag','plotGrav_check_labels'),'Value',0);
                else
                    set(findobj('Tag','plotGrav_check_labels'),'Value',1);
                end
            case 'show_legend'
                temp = get(findobj('Tag','plotGrav_check_legend'),'Value');
                if temp == 1
                    set(findobj('Tag','plotGrav_check_legend'),'Value',0);
                else
                    set(findobj('Tag','plotGrav_check_legend'),'Value',1);
                end
            case 'compute_filter_channel'
                %% Filter channels
                % Load filter
                try
                    set(findobj('Tag','plotGrav_text_status'),'String','Loading Filter...');drawnow % send message to status bar
                    filter_file = get(findobj('Tag','plotGrav_edit_filter_file'),'String'); % get filter filename
                    if ~isempty(filter_file)                                % try to load the filter file/response if some string is given
                        Num = load(filter_file);                            % load filter file = in ETERNA format - header
                        Num = vertcat(Num(:,2),flipud(Num(1:end-1,2)));     % stack the filter (ETERNA uses only one half of the repose = mirror the filter)
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','No filter file selected.');drawnow % status
                        Num = [];
                    end
                catch
                    fprintf('Could not load filter: %s\n',filter_file);       % send message to command line that filter file could not be loaded
                    Num = [];
                end
                % Filter data
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data) && ~isempty(Num)                          % filter only if some data have been loaded and the filter file as well
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Filtering...');drawnow % status
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        channel_number = size(data.igrav,2)+1;
                        time_resolution = round(mode(diff(time.igrav))*864000)/864000;  % time resolution (sampling period)
                        for j = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.igrav,data.igrav(:,plot_axesL1.igrav(j)),time_resolution); % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            data_filt = [];time_filt = [];                      % prepare variables (*_filt = filtered values)
                            for i = 1:size(id,1)                            % use for each time interval (between time steps) separately                 
                                if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough
                                    [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv function (outputs only valid time interval, see plotGrav_conv function for details)
                                else
                                    ftime = timeout(id(i,1):id(i,2));       % if the interval is too short, set to NaN 
                                    fgrav(1:length(ftime),1) = NaN;
                                end
                                data_filt = vertcat(data_filt,fgrav,NaN);   % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                                time_filt = vertcat(time_filt,ftime,...     % stack the aux. time 
                                        ftime(end)+time_resolution/(2*24*60*60)); % this last part is for a NaN see vertcat(dout above)  
                                clear ftime fgrav
                            end
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(j)); % add units
                            channels_igrav(channel_number) = {sprintf('%s_filt',char(channels_igrav(plot_axesL1.igrav(j))))}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav((plot_axesL1.igrav(j))))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = interp1(time_filt,data_filt,time.igrav); % add data
                            channel_number = channel_number + 1;            % next channel
                            clear data_filt time_filt timeout dataout id
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d filtered (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(j),ty,tm,td,th,tmm);
                        end
                        
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        channel_number = size(data.trilogi,2)+1;
                        time_resolution = mode(diff(time.trilogi));           % time resolution (sampling period)
                        for j = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(j)),time_resolution); % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            data_filt = [];time_filt = [];                      % prepare variables (*_filt = filtered values)
                            for i = 1:size(id,1)                            % use for each time interval (between time steps) separately                 
                                if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough
                                    [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv function (outputs only valid time interval, see plotGrav_conv function for details)
                                else
                                    ftime = timeout(id(i,1):id(i,2));       % if the interval is too short, set to NaN 
                                    fgrav(1:length(ftime),1) = NaN;
                                end
                                data_filt = vertcat(data_filt,fgrav,NaN);   % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                                time_filt = vertcat(time_filt,ftime,...     % stack the aux. time 
                                        ftime(end)+time_resolution/(2*24*60*60)); % this last part is for a NaN see vertcat(dout above)  
                                clear ftime fgrav
                            end
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(j)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s_filt',char(channels_trilogi(plot_axesL1.trilogi(j))))}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi((plot_axesL1.trilogi(j))))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = interp1(time_filt,data_filt,time.trilogi); % add data
                            channel_number = channel_number + 1;            % next channel
                            clear data_filt time_filt timeout dataout id
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d filtered (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(j),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % other1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                        channel_number = size(data.other1,2)+1;
                        time_resolution = mode(diff(time.other1));           % time resolution (sampling period)
                        for j = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.other1,data.other1(:,plot_axesL1.other1(j)),time_resolution); % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            data_filt = [];time_filt = [];                      % prepare variables (*_filt = filtered values)
                            for i = 1:size(id,1)                            % use for each time interval (between time steps) separately                 
                                if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough
                                    [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv function (outputs only valid time interval, see plotGrav_conv function for details)
                                else
                                    ftime = timeout(id(i,1):id(i,2));       % if the interval is too short, set to NaN 
                                    fgrav(1:length(ftime),1) = NaN;
                                end
                                data_filt = vertcat(data_filt,fgrav,NaN);   % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                                time_filt = vertcat(time_filt,ftime,...     % stack the aux. time 
                                        ftime(end)+time_resolution/(2*24*60*60)); % this last part is for a NaN see vertcat(dout above)  
                                clear ftime fgrav
                            end
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(j)); % add units
                            channels_other1(channel_number) = {sprintf('%s_filt',char(channels_other1(plot_axesL1.other1(j))))}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1((plot_axesL1.other1(j))))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = interp1(time_filt,data_filt,time.other1); % add data
                            channel_number = channel_number + 1;            % next channel
                            clear data_filt time_filt timeout dataout id
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d filtered (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(j),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end 
                    
                    % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        channel_number = size(data.other2,2)+1;
                        time_resolution = mode(diff(time.other2));          % time resolution (sampling period)
                        for j = 1:length(plot_axesL1.other2)                % compute for all selected channels
                            [timeout,dataout,id] = plotGrav_findTimeStep(time.other2,data.other2(:,plot_axesL1.other2(j)),time_resolution); % find time steps. Filter can be use only for evenly spaced data (see plotGrav_findTimeStep function for details)
                            data_filt = [];time_filt = [];                      % prepare variables (*_filt = filtered values)
                            for i = 1:size(id,1)                            % use for each time interval (between time steps) separately                 
                                if length(dataout(id(i,1):id(i,2))) > length(Num)*2 % filter only if the current time interval is long enough
                                    [ftime,fgrav] = plotGrav_conv(timeout(id(i,1):id(i,2)),dataout(id(i,1):id(i,2)),Num,'valid'); % use plotGrav_conv function (outputs only valid time interval, see plotGrav_conv function for details)
                                else
                                    ftime = timeout(id(i,1):id(i,2));       % if the interval is too short, set to NaN 
                                    fgrav(1:length(ftime),1) = NaN;
                                end
                                data_filt = vertcat(data_filt,fgrav,NaN);   % stack the aux. data vertically (current channel) + NaN to mark holes between fillering sequences
                                time_filt = vertcat(time_filt,ftime,...     % stack the aux. time 
                                        ftime(end)+time_resolution/(2*24*60*60)); % this last part is for a NaN see vertcat(dout above)  
                                clear ftime fgrav
                            end
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(j)); % add units
                            channels_other2(channel_number) = {sprintf('%s_filt',char(channels_other2(plot_axesL1.other2(j))))}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2((plot_axesL1.other2(j))))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = interp1(time_filt,data_filt,time.other2); % add data
                            channel_number = channel_number + 1;            % next channel
                            clear data_filt time_filt timeout dataout id
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d filtered (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(j),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                        
                        fclose(fid);
                    end
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
                
            case 'compute_remove_channel'
                %% Remove channels
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Removing...');drawnow % status
                    
                    % iGrav
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        data.igrav(:,plot_axesL1.igrav) = [];        % remove data
                        channels_igrav(plot_axesL1.igrav) = [];    % remove channel name
                        units_igrav(plot_axesL1.igrav) = [];       % remove units
                        data_igrav(plot_axesL1.igrav,:) = [];        % remove from data table
                        for i = 1:length(plot_axesL1.igrav)                 % Log for all selected channels
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d removed (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % update data
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav);
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % get iGrav units
                        
                        for i = 1:length(channels_igrav)
                            data_igrav(i,4) = {sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i)))};
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav);
                        
                    end
                    
                    % trilogi
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        data.trilogi(:,plot_axesL1.trilogi) = [];        % remove data
                        channels_trilogi(plot_axesL1.trilogi) = [];    % remove channel name
                        units_trilogi(plot_axesL1.trilogi) = [];       % remove units
                        data_trilogi(plot_axesL1.trilogi,:) = [];        % remove from data table
                        for i = 1:length(plot_axesL1.trilogi)                 % Log for all selected channels
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d removed (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % update data
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi);
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % get trilogi units
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi);
                    end
                    
                    % Other1
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                            data.other1(:,plot_axesL1.other1) = [];        % remove data
                            channels_other1(plot_axesL1.other1) = [];    % remove channel name
                            units_other1(plot_axesL1.other1) = [];       % remove units
                            data_other1(plot_axesL1.other1,:) = [];        % remove from data table
                        for i = 1:length(plot_axesL1.other1)                 % Log for all selected channels
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d removed (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % update data
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1);
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % get other1 units
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1);
                    end
                    
                    % Ohter2
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        data.other2(:,plot_axesL1.other2) = [];        % remove data
                        channels_other2(plot_axesL1.other2) = [];    % remove channel name
                        units_other2(plot_axesL1.other2) = [];       % remove units
                        data_other2(plot_axesL1.other2,:) = [];        % remove from data table
                        for i = 1:length(plot_axesL1.other2)                 % Log for all selected channels
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d removed (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % update data
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2);
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % get other2 units
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2);
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'compute_copy_channel'
                %% COPY CHANNEL
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % copy only if some data loaded
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Filtering...');drawnow % status
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        channel_number = size(data.igrav,2)+1;
                        for j = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(j)); % add units
                            channels_igrav(channel_number) = {sprintf('%s_copy',char(channels_igrav(plot_axesL1.igrav(j))))}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav((plot_axesL1.igrav(j))))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = data.igrav(:,plot_axesL1.igrav(j)); % add data
                            channel_number = channel_number + 1;            % next channel
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d coppied to %d (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(j),channel_number,ty,tm,td,th,tmm);
                        end
                        
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        channel_number = size(data.trilogi,2)+1;
                        for j = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(j)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s_copy',char(channels_trilogi(plot_axesL1.trilogi(j))))}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi((plot_axesL1.trilogi(j))))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = data.trilogi(plot_axesL1.trilogi(j)); % add data
                            channel_number = channel_number + 1;            % next channel
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d coppied (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(j),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % other1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                        channel_number = size(data.other1,2)+1;
                        for j = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(j)); % add units
                            channels_other1(channel_number) = {sprintf('%s_filt',char(channels_other1(plot_axesL1.other1(j))))}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1((plot_axesL1.other1(j))))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = data.other1(plot_axesL1.other1(j)); % add data
                            channel_number = channel_number + 1;            % next channel
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d coppied (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(j),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end 
                    
                    % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        channel_number = size(data.other2,2)+1;
                        for j = 1:length(plot_axesL1.other2)                % compute for all selected channels
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(j)); % add units
                            channels_other2(channel_number) = {sprintf('%s_filt',char(channels_other2(plot_axesL1.other2(j))))}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2((plot_axesL1.other2(j))))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = data.other2(plot_axesL1.other2(j)); % add data
                            channel_number = channel_number + 1;            % next channel
                            clear data_filt time_filt timeout dataout id
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d coppied (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(j),ty,tm,td,th,tmm);
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                        
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
                %% EOF
            case 'compute_eof'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                start_time = [str2double(get(findobj('Tag','plotGrav_edit_time_start_year'),'String')),... % Get date of start year
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_month'),'String')),... % month
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_day'),'String')),...   % day
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_hour'),'String')),0,0];% hour (minutes and seconds == 0)  
                
                end_time = [str2double(get(findobj('Tag','plotGrav_edit_time_stop_year'),'String')),... % Get date of end
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_month'),'String')),... % month
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_day'),'String')),...   % day
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_hour'),'String')),0,0];% hour (minutes and seconds == 0)
                
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');  % get axes one handle
                a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                cla(a2(1));legend(a2(1),'off');ylabel(a2(1),[]);        % clear axes and remove legends and labels
                cla(a2(2));legend(a2(2),'off');ylabel(a2(2),[]);        % clear axes and remove legends and labels
                axis(a2(1),'auto');axis(a2(2),'auto');
                cla(a3(1));legend(a3(1),'off');ylabel(a3(1),[]);        % clear axes and remove legends and labels
                cla(a3(2));legend(a3(2),'off');ylabel(a3(2),[]);        % clear axes and remove legends and labels
                axis(a3(1),'auto');axis(a3(2),'auto');
                
                eof.ref_time = [datenum(start_time):1/24:datenum(end_time)]';
                eof.F = [];
                eof.chan_list = [];
                eof.unit_list = [];
                eof.mean_value = [];
                if ~isempty(data)                                           % remove only if exists
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)
                    color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');          % get defined colors

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData');% get plot_mode 
                    
                    % iGrav
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            temp = interp1(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);         % remove mean value (EOP requirement)
                            eof.unit_list = [eof.unit_list,units_igrav(plot_axesL1.igrav(i))]; % add current units
                            eof.chan_list = [eof.chan_list,channels_igrav(plot_axesL1.igrav(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % trilogi
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            temp = interp1(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);         % remove mean value (EOP requirement)
                            eof.unit_list = [eof.unit_list,units_trilogi(plot_axesL1.trilogi(i))]; % add current units
                            eof.chan_list = [eof.chan_list,channels_trilogi(plot_axesL1.trilogi(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % other1
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            temp = interp1(time.other1,data.other1(:,plot_axesL1.other1(i)),eof.ref_time); % interpolate current channel to ref_time
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);         % remove mean value (EOP requirement)
                            eof.unit_list = [eof.unit_list,units_other1(plot_axesL1.other1(i))]; % add current units
                            eof.chan_list = [eof.chan_list,channels_other1(plot_axesL1.other1(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % other2
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            temp = interp1(time.other2,data.other2(:,plot_axesL1.other2(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.mean_value = [eof.mean_value,mean(temp(~isnan(temp)))];
                            temp = temp - eof.mean_value(end);         % remove mean value (EOP requirement)
                            eof.unit_list = [eof.unit_list,units_other2(plot_axesL1.other2(i))]; % add current units
                            eof.chan_list = [eof.chan_list,channels_other2(plot_axesL1.other2(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp');                            % stack columns
                            clear temp
                        end
                    end
                    
                    % Compute EOF
                    if ~isempty(eof.F)
                        R = nancov(eof.F,'pairwise');                               % compute covarince matrix pairwise to allow inclusion of NaN
                        [eof.EOF,L] = eig(R);                                       % compute eigenvectors/EOF and eigenvalues (L)
                        eof.explained = diag(L)/trace(L)*100;                       % explained variance (%)
                        eof.PC = eof.F*eof.EOF;                                             % compute principle components
                        for i = 1:size(eof.F,2)                                     % create legend
                            eof.cur_legend{1,i} = sprintf('PC%1d (%4.1f%%)',i,eof.explained(size(eof.F,2)+1-i));
                        end
                        h = plot(a2(1),eof.ref_time,fliplr(eof.PC));                        % plot the computet PC (fluplr to sort it)
                        for i = 1:length(h)
                            set(h(i),'color',color_scale(i,:));
                        end
                        if get(findobj('Tag','plotGrav_check_grid'),'Value')==1  % show grid if required
                            grid(a2(1),'on');                                     % on for left axes
                        else
                            grid(a2(2),'off');
                        end
                        if get(findobj('Tag','plotGrav_check_legend'),'Value') ==1  % show legend if required
                            l = legend(a2(1),eof.cur_legend);
                            set(l,'interpreter','none','FontSize',8);           % change font and interpreter (because channels contain spacial sybols like _)
                            legend(a2(2),'off');                                % legend for left axes      
                        else
                            legend(a2(1),'off');                                % turn of legends
                            legend(a2(2),'off');
                        end
                        if get(findobj('Tag','plotGrav_check_labels'),'Value')==1  % show labels if required
                            ylabel(a2(1),'EOF time series','FontSize',8);  % label only for left axes
                            ylabel(a2(2),[]);
                        else
                            ylabel(a2(1),[]);
                            ylabel(a2(2),[]);
                        end
                        % Set limits                                            % get current YLimits
                        ref_lim = get(a1(1),'XLim');                            % get current L1 X limits and use them a reference
                        xtick_value = linspace(ref_lim(1),ref_lim(2),9);                   % create new ticks
                        for i = 1:9
                            xtick_lable{i} = sprintf('%11.4f',xtick_value(i));              % tick labels (4 decimal places)
                        end
                        set(a2(1),'YLimMode','auto','XLim',ref_lim,'XTick',xtick_value,'XTickLabel',xtick_lable,'Visible','on'); % set X limits
                        rL1 = get(a2(1),'YLim'); 
                        set(a2(1),'YLimMode','auto','YTick',linspace(rL1(1),rL1(2),5)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')
                        set(a2(2),'Visible','off','XLim',ref_lim,'XTick',xtick_value,'XTickLabel',xtick_lable); % set new X ticks (left)
                        linkaxes([a2(1),a2(2)],'x');                            % link axes, just in case
                        plot_mode(2:3) = [1 0];
                        set(findobj('Tag','plotGrav_push_reset_view'),'UserData',plot_mode);% get plot_mode 

                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                        set(findobj('Tag','plotGrav_menu_compute_eof'),'UserData',eof);% store EOF results 
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                    end 
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
                
            case 'export_rec_time_series'
                %% Export reconstructed time series
                eof = get(findobj('Tag','plotGrav_menu_compute_eof'),'UserData');% get EOF results 
                if ~isempty(eof)
                    data_out = datevec(eof.ref_time);                       % convert time vector to amtrix
                    [name,path,filteridex] = uiputfile({'*.tsf'},'Select output file.'); % open ui dialog
                    if name == 0
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                    else
                        ch = 1;                                             % aux. variable (count channels)
                        for j = 1:size(eof.F,2)
                            cur_pc = sprintf('PC1-PC%1d',j);                % current PCs used for recontruction
                            Fr = eof.F*eof.EOF(:,end+1-i:end)*eof.EOF(:,end+1-i:end)'; % reconstruct data using only selected number of PCs
                            for i = 1:size(eof.F,2)
                                comment(ch,1:4) = {'plotGrav',cur_pc,sprintf('%s',char(eof.chan_list(i))),char(eof.unit_list(i))}; % tsf header
                                ch = ch + 1;
                                Fr(:,i) = Fr(:,i) + eof.mean_value(i);      % add subtracted mean value
                            end
                            data_out = horzcat(data_out,Fr);                % prepare for writting
                            clear Fr cur_pc
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing...');drawnow % status
                        plotGrav_writetsf(data_out,comment,[path,name],3);  % write output
                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                    end
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Compute EOF first.');drawnow % status
                end
                %% Export computed PCs
                eof = get(findobj('Tag','plotGrav_menu_compute_eof'),'UserData');% store EOF results 
                if ~isempty(eof)
                    data_out = [datevec(eof.ref_time),fliplf(eop.pc)];      % output for writting
                    [name,path,filteridex] = uiputfile({'*.tsf'},'Select output file.'); % open dialog
                    if name == 0
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                    else
                        for i = 1:size(eof.F,2)
                            cur_pc = sprintf('PC%1d',i);                    % current PC
                            comment(i,1:4) = {'plotGrav',cur_pc,sprintf('%s',char(eof.chan_list(i))),char(eof.unit_list(i))}; % tsf header
                            clear Fr cur_pc
                        end
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing...');drawnow % status
                        plotGrav_writetsf(data_out,comment,[path,name],3);  % write output 
                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                    end
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Compute EOF first.');drawnow % status
                end
            case 'export_eop_pattern'
               %% Export EOP patern
                eof = get(findobj('Tag','plotGrav_menu_compute_eof'),'UserData');% store EOF results 
                dataout = fliplr(eof.EOF);
                if ~isempty(eof)
                    [name,path,filteridex] = uiputfile({'*.txt'},'Select output file.'); % open dialog
                    if name == 0
                        set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Writing...');drawnow % status
                        fid = fopen([path,name],'w');
                        fprintf(fid,'%% plotGrav: Export EOP pattern\n');
                        fprintf(fid,'%%');
                        for i = 1:size(dataout,1)
                            fprintf(fid,'PC%1d\t',i);
                        end
                        fprintf(fid,'\n');
                        for i = 1:size(dataout,1)
                            for j = 1:size(dataout,2)
                                fprintf(fid,'%8.5f\t',dataout(i,j));
                            end
                            fprintf(fid,'\n');
                        end
                        fclose(fid);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                    end
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Compute EOF first.');drawnow % status
                end
            case 'fit_linear'
                %% Fit polynomial 1.degree
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.igrav,2)+1;
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            [out_par,out_sig,out_fit,out_res] = plotGrav_fit(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),'poly1');
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(i)); % add units
                            units_igrav(channel_number+1) = units_igrav(plot_axesL1.igrav(i)); % add units
                            channels_igrav(channel_number) = {sprintf('%s_fit_p1',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            channels_igrav(channel_number+1) = {sprintf('%s_fitRes_p1',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav(channel_number))),...
                                                                    false,false,false};
                            data_igrav(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_igrav(channel_number+1)),char(units_igrav(channel_number+1))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = out_fit; % add data = fit
                            data.igrav(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d pol1 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),channel_number,out_par(1),out_par(2),ty,tm,td,th,tmm);
                            fprintf(fid,'iGrav channel %d pol1 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.trilogi,2)+1;
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            [out_par,out_sig,out_fit,out_res] = plotGrav_fit(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),'poly1');
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            units_trilogi(channel_number+1) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s_fit_p1',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            channels_trilogi(channel_number+1) = {sprintf('%s_fitRes_p1',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi(channel_number))),...
                                                                    false,false,false};
                            data_trilogi(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_trilogi(channel_number+1)),char(units_trilogi(channel_number+1))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = out_fit;       % add data = fit
                            data.trilogi(:,channel_number+1) = out_res;     % add residauls
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d pol1 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f(%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),channel_number,out_par(1),out_par(2),ty,tm,td,th,tmm);
                            fprintf(fid,'TRiLOGi channel %d pol1 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % Ohter1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other1,2)+1;
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            [~,~,out_fit,out_res] = plotGrav_fit(time.other1,data.other1(:,plot_axesL1.other1(i)),'poly1');
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(i)); % add units
                            units_other1(channel_number+1) = units_other1(plot_axesL1.other1(i)); % add units
                            channels_other1(channel_number) = {sprintf('%s_fit_p1',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            channels_other1(channel_number+1) = {sprintf('%s_fitRes_p1',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1(channel_number))),...
                                                                    false,false,false};
                            data_other1(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other1(channel_number+1)),char(units_other1(channel_number+1))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = out_fit; % add data
                            data.other1(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d pol1 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),channel_number,out_par(1),out_par(2),ty,tm,td,th,tmm);
                            fprintf(fid,'Other1 channel %d pol1 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other2,2)+1;
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            [~,~,out_fit,out_res] = plotGrav_fit(time.other2,data.other2(:,plot_axesL1.other2(i)),'poly1');
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(i)); % add units
                            units_other2(channel_number+1) = units_other2(plot_axesL1.other2(i)); % add units
                            channels_other2(channel_number) = {sprintf('%s_fit_p1',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            channels_other2(channel_number+1) = {sprintf('%s_fitRes_p1',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2(channel_number))),...
                                                                    false,false,false};
                            data_other2(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other2(channel_number+1)),char(units_other2(channel_number+1))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = out_fit; % add data
                            data.other2(:,channel_number+1) = out_res; % add data
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d pol1 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),channel_number,out_par(1),out_par(2),ty,tm,td,th,tmm);
                            fprintf(fid,'Other2 channel %d pol1 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'fit_user_set'
                %% SUBTRACE polynomial X.degree
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Set coefficients of a polynomial (PN PN-1... P0)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 8 seconds for user input
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                    st = strsplit(st);                                      % split string
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.igrav,2)+1;
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            out_par = str2double(st);
                            out_fit = polyval(out_par,time.igrav);
                            out_res = data.igrav(:,plot_axesL1.igrav(i)) - out_fit;
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(i)); % add units
                            units_igrav(channel_number+1) = units_igrav(plot_axesL1.igrav(i)); % add units
                            channels_igrav(channel_number) = {sprintf('%s_fit_p%1d',char(channels_igrav(plot_axesL1.igrav(i))),length(out_par)-1)}; % add channel name
                            channels_igrav(channel_number+1) = {sprintf('%s_fitRes_p%1d',char(channels_igrav(plot_axesL1.igrav(i))),length(out_par)-1)}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav(channel_number))),...
                                                                    false,false,false};
                            data_igrav(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_igrav(channel_number+1)),char(units_igrav(channel_number+1))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = out_fit; % add data = fit
                            data.igrav(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d pol%1d fitted = %2.0f, used coefficients = ',plot_axesL1.igrav(i),length(out_par)-1,channel_number);
                            for c = 1:length(out_par)
                                fprintf(fid,'%10.8f, ',out_par(c));
                            end
                            fprintf(fid,'(%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            fprintf(fid,'iGrav channel %d pol%1d residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),length(out_par)-1,channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.trilogi,2)+1;
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            out_par = str2double(st);
                            out_fit = polyval(out_par,time.trilogi);
                            out_res = data.trilogi(:,plot_axesL1.trilogi(i)) - out_fit;
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            units_trilogi(channel_number+1) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s_fit_p%1d',char(channels_trilogi(plot_axesL1.trilogi(i))),length(out_par)-1)}; % add channel name
                            channels_trilogi(channel_number+1) = {sprintf('%s_fitRes_p%1d',char(channels_trilogi(plot_axesL1.trilogi(i))),length(out_par)-1)}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi(channel_number))),...
                                                                    false,false,false};
                            data_trilogi(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_trilogi(channel_number+1)),char(units_trilogi(channel_number+1))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = out_fit; % add data = fit
                            data.trilogi(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d pol%1d fitted = %2.0f, used coefficients = ',plot_axesL1.trilogi(i),length(out_par)-1,channel_number);
                            for c = 1:length(out_par)
                                fprintf(fid,'%10.8f, ',out_par(c));
                            end
                            fprintf(fid,' (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            fprintf(fid,'TRiLOGi channel %d pol%1d residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),length(out_par)-1,channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % Ohter1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other1,2)+1;
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            out_par = str2double(st);
                            out_fit = polyval(out_par,time.other1);
                            out_res = data.other1(:,plot_axesL1.other1(i)) - out_fit;
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(i)); % add units
                            units_other1(channel_number+1) = units_other1(plot_axesL1.other1(i)); % add units
                            channels_other1(channel_number) = {sprintf('%s_fit_p%1d',char(channels_other1(plot_axesL1.other1(i))),length(out_par)-1)}; % add channel name
                            channels_other1(channel_number+1) = {sprintf('%s_fitRes_p%1d',char(channels_other1(plot_axesL1.other1(i))),length(out_par)-1)}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1(channel_number))),...
                                                                    false,false,false};
                            data_other1(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other1(channel_number+1)),char(units_other1(channel_number+1))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = out_fit; % add data = fit
                            data.other1(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d pol%1d fitted = %2.0f, used coefficients = ',plot_axesL1.other1(i),length(out_par)-1,channel_number);
                            for c = 1:length(out_par)
                                fprintf(fid,'%10.8f, ',out_par(c));
                            end
                            fprintf(fid,' (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            fprintf(fid,'Other1 channel %d pol%1d residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),length(out_par)-1,channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other2,2)+1;
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            out_par = str2double(st);
                            out_fit = polyval(out_par,time.other2);
                            out_res = data.other2(:,plot_axesL1.other2(i)) - out_fit;
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(i)); % add units
                            units_other2(channel_number+1) = units_other2(plot_axesL1.other2(i)); % add units
                            channels_other2(channel_number) = {sprintf('%s_fit_p%1d',char(channels_other2(plot_axesL1.other2(i))),length(out_par)-1)}; % add channel name
                            channels_other2(channel_number+1) = {sprintf('%s_fitRes_p%1d',char(channels_other2(plot_axesL1.other2(i))),length(out_par)-1)}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2(channel_number))),...
                                                                    false,false,false};
                            data_other2(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other2(channel_number+1)),char(units_other2(channel_number+1))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = out_fit; % add data = fit
                            data.other2(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d pol%1d fitted = %2.0f, used coefficients = ',plot_axesL1.other2(i),length(out_par)-1,channel_number);
                            for c = 1:length(out_par)
                                fprintf(fid,'%10.8f, ',out_par(c));
                            end
                            fprintf(fid,' (%04d/%02d/%02d %02d:%02d)\n',ty,tm,td,th,tmm);
                            fprintf(fid,'Other2 channel %d pol%1d residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),length(out_par)-1,channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'fit_quadratic'
                %% Fit polynomial 2.degree
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.igrav,2)+1;
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),'poly2');
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(i)); % add units
                            units_igrav(channel_number+1) = units_igrav(plot_axesL1.igrav(i)); % add units
                            channels_igrav(channel_number) = {sprintf('%s_fit_p2',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            channels_igrav(channel_number+1) = {sprintf('%s_fitRes_p2',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav(channel_number))),...
                                                                    false,false,false};
                            data_igrav(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_igrav(channel_number+1)),char(units_igrav(channel_number+1))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = out_fit; % add data = fit
                            data.igrav(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d pol2 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),channel_number,out_par(1),out_par(2),out_par(3),ty,tm,td,th,tmm);
                            fprintf(fid,'iGrav channel %d pol2 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.trilogi,2)+1;
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),'poly2');
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            units_trilogi(channel_number+1) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s_fit_p2',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            channels_trilogi(channel_number+1) = {sprintf('%s_fitRes_p2',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi(channel_number))),...
                                                                    false,false,false};
                            data_trilogi(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_trilogi(channel_number+1)),char(units_trilogi(channel_number+1))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = out_fit;       % add data = fit
                            data.trilogi(:,channel_number+1) = out_res;     % add residauls
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d pol2 fitted = %2.0, estim. coefficients = %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),channel_number,out_par(1),out_par(2),out_par(3),ty,tm,td,th,tmm);
                            fprintf(fid,'TRiLOGi channel %d pol2 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % Ohter1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other1,2)+1;
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.other1,data.other1(:,plot_axesL1.other1(i)),'poly2');
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(i)); % add units
                            units_other1(channel_number+1) = units_other1(plot_axesL1.other1(i)); % add units
                            channels_other1(channel_number) = {sprintf('%s_fit_p2',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            channels_other1(channel_number+1) = {sprintf('%s_fitRes_p2',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1(channel_number))),...
                                                                    false,false,false};
                            data_other1(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other1(channel_number+1)),char(units_other1(channel_number+1))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = out_fit; % add data
                            data.other1(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d pol2 fitted = %2.0, estim. coefficients = %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),channel_number,out_par(1),out_par(2),out_par(3),ty,tm,td,th,tmm);
                            fprintf(fid,'Other1 channel %d pol2 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other2,2)+1;
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.other2,data.other2(:,plot_axesL1.other2(i)),'poly2');
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(i)); % add units
                            units_other2(channel_number+1) = units_other2(plot_axesL1.other2(i)); % add units
                            channels_other2(channel_number) = {sprintf('%s_fit_p2',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            channels_other2(channel_number+1) = {sprintf('%s_fitRes_p2',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2(channel_number))),...
                                                                    false,false,false};
                            data_other2(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other2(channel_number+1)),char(units_other2(channel_number+1))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = out_fit; % add data
                            data.other2(:,channel_number+1) = out_res; % add data
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d pol2 fitted = %2.0, estim. coefficients = %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),channel_number,out_par(1),out_par(2),out_par(3),ty,tm,td,th,tmm);
                            fprintf(fid,'Other2 channel %d pol2 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'fit_cubic'
                %% Fit polynomial 3.degree
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.igrav,2)+1;
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),'poly3');
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(i)); % add units
                            units_igrav(channel_number+1) = units_igrav(plot_axesL1.igrav(i)); % add units
                            channels_igrav(channel_number) = {sprintf('%s_fit_p3',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            channels_igrav(channel_number+1) = {sprintf('%s_fitRes_p3',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav(channel_number))),...
                                                                    false,false,false};
                            data_igrav(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_igrav(channel_number+1)),char(units_igrav(channel_number+1))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = out_fit; % add data = fit
                            data.igrav(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d pol3 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),channel_number,out_par(1),out_par(2),out_par(3),out_par(4),ty,tm,td,th,tmm);
                            fprintf(fid,'iGrav channel %d pol3 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.trilogi,2)+1;
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),'poly3');
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            units_trilogi(channel_number+1) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s_fit_p3',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            channels_trilogi(channel_number+1) = {sprintf('%s_fitRes_p3',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi(channel_number))),...
                                                                    false,false,false};
                            data_trilogi(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_trilogi(channel_number+1)),char(units_trilogi(channel_number+1))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = out_fit;       % add data = fit
                            data.trilogi(:,channel_number+1) = out_res;     % add residauls
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d pol3 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),channel_number,out_par(1),out_par(2),out_par(3),out_par(4),ty,tm,td,th,tmm);
                            fprintf(fid,'TRiLOGi channel %d pol3 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % Ohter1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other1,2)+1;
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.other1,data.other1(:,plot_axesL1.other1(i)),'poly3');
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(i)); % add units
                            units_other1(channel_number+1) = units_other1(plot_axesL1.other1(i)); % add units
                            channels_other1(channel_number) = {sprintf('%s_fit_p3',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            channels_other1(channel_number+1) = {sprintf('%s_fitRes_p3',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1(channel_number))),...
                                                                    false,false,false};
                            data_other1(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other1(channel_number+1)),char(units_other1(channel_number+1))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = out_fit; % add data
                            data.other1(:,channel_number+1) = out_res; % add residuals
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d pol3 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),channel_number,out_par(1),out_par(2),out_par(3),out_par(4),ty,tm,td,th,tmm);
                            fprintf(fid,'Other1 channel %d pol3 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2) && length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) == 1
                        channel_number = size(data.other2,2)+1;
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            [out_par,~,out_fit,out_res] = plotGrav_fit(time.other2,data.other2(:,plot_axesL1.other2(i)),'poly3');
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(i)); % add units
                            units_other2(channel_number+1) = units_other2(plot_axesL1.other2(i)); % add units
                            channels_other2(channel_number) = {sprintf('%s_fit_p3',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            channels_other2(channel_number+1) = {sprintf('%s_fitRes_p3',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2(channel_number))),...
                                                                    false,false,false};
                            data_other2(channel_number+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number+1,char(channels_other2(channel_number+1)),char(units_other2(channel_number+1))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = out_fit; % add data
                            data.other2(:,channel_number+1) = out_res; % add data
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d pol3 fitted = %2.0f, estim. coefficients = %10.8f, %10.8f, %10.8f, %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),channel_number,out_par(1),out_par(2),out_par(3),out_par(4),ty,tm,td,th,tmm);
                            fprintf(fid,'Other2 channel %d pol3 residuals = %2.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2(i),channel_number+1,ty,tm,td,th,tmm);
                            channel_number = channel_number + 1;            % next channel
                            clear out_par out_sig out_fit out_res
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'fit_constant'
                %% Fit polynomial 0.degree = subtract mean
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Fitting...');drawnow % status
                    
                    % iGrav data
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        channel_number = size(data.igrav,2)+1;
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            [out_par,~,~,out_res] = plotGrav_fit(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),'poly0');
                            units_igrav(channel_number) = units_igrav(plot_axesL1.igrav(i)); % add units
                            channels_igrav(channel_number) = {sprintf('%s-mean',char(channels_igrav(plot_axesL1.igrav(i))))}; % add channel name
                            data_igrav(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_igrav(channel_number)),char(units_igrav(channel_number))),...
                                                                    false,false,false};
                            data.igrav(:,channel_number) = out_res;         % add data = fit
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d = channel %2.0f - constant %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                channel_number,plot_axesL1.igrav(i),out_par,ty,tm,td,th,tmm);
                            clear out_res out_par
                            channel_number = channel_number + 1;            % next channel
                        end
                        set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                        set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                    % trilogi data
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        channel_number = size(data.trilogi,2)+1;
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            [out_par,~,~,out_res] = plotGrav_fit(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),'poly0');
                            units_trilogi(channel_number) = units_trilogi(plot_axesL1.trilogi(i)); % add units
                            channels_trilogi(channel_number) = {sprintf('%s-mean',char(channels_trilogi(plot_axesL1.trilogi(i))))}; % add channel name
                            data_trilogi(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_trilogi(channel_number)),char(units_trilogi(channel_number))),...
                                                                    false,false,false};
                            data.trilogi(:,channel_number) = out_res;       % add data = fit
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'TRiLOGi channel %d = channel %2.0f - constant %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                channel_number,plot_axesL1.trilogi(i),out_par,ty,tm,td,th,tmm);
                            clear out_res out_par
                            channel_number = channel_number + 1;            % next channel
                        end
                        set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_trilogi); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi); % update trilogi units
                        set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi); % update trilogi channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    
                    % Ohter1 data
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                        channel_number = size(data.other1,2)+1;
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            [out_par,~,~,out_res] = plotGrav_fit(time.other1,data.other1(:,plot_axesL1.other1(i)),'poly0');
                            units_other1(channel_number) = units_other1(plot_axesL1.other1(i)); % add units
                            channels_other1(channel_number) = {sprintf('%s-mean',char(channels_other1(plot_axesL1.other1(i))))}; % add channel name
                            data_other1(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other1(channel_number)),char(units_other1(channel_number))),...
                                                                    false,false,false};
                            data.other1(:,channel_number) = out_res; % add data
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other1 channel %d = channel %2.0f - constant %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                channel_number,plot_axesL1.other1(i),out_par,ty,tm,td,th,tmm);
                            clear out_res out_par
                            channel_number = channel_number + 1;            % next channel
                        end
                        set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',data_other1); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other1'),'UserData',units_other1); % update other1 units
                        set(findobj('Tag','plotGrav_edit_other1_path'),'UserData',channels_other1); % update other1 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                
                % other2 data
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        channel_number = size(data.other2,2)+1;
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            [out_par,~,~,out_res] = plotGrav_fit(time.other2,data.other2(:,plot_axesL1.other2(i)),'poly0');
                            units_other2(channel_number) = units_other2(plot_axesL1.other2(i)); % add units
                            channels_other2(channel_number) = {sprintf('%s-mean',char(channels_other2(plot_axesL1.other2(i))))}; % add channel name
                            data_other2(channel_number,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',channel_number,char(channels_other2(channel_number)),char(units_other2(channel_number))),...
                                                                    false,false,false};
                            data.other2(:,channel_number) = out_res; % add data
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'Other2 channel %d = channel %2.0f - constant %10.8f (%04d/%02d/%02d %02d:%02d)\n',...
                                channel_number,plot_axesL1.other2(i),out_par,ty,tm,td,th,tmm);
                            clear out_res out_par
                            channel_number = channel_number + 1;            % next channel
                        end
                        set(findobj('Tag','plotGrav_uitable_other2_data'),'Data',data_other2); % update table
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                        set(findobj('Tag','plotGrav_text_other2'),'UserData',units_other2); % update other2 units
                        set(findobj('Tag','plotGrav_edit_other2_path'),'UserData',channels_other2); % update other2 channels (names)
                        clear data time time_resolution                     % remove variables
                    end
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
            case 'correlation_matrix'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                start_time = [str2double(get(findobj('Tag','plotGrav_edit_time_start_year'),'String')),... % Get date of start year
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_month'),'String')),... % month
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_day'),'String')),...   % day
                    str2double(get(findobj('Tag','plotGrav_edit_time_start_hour'),'String')),0,0];% hour (minutes and seconds == 0)  
                
                end_time = [str2double(get(findobj('Tag','plotGrav_edit_time_stop_year'),'String')),... % Get date of end
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_month'),'String')),... % month
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_day'),'String')),...   % day
                    str2double(get(findobj('Tag','plotGrav_edit_time_stop_hour'),'String')),0,0];% hour (minutes and seconds == 0)
                
                eof.ref_time = [datenum(start_time):1/24:datenum(end_time)]'; % new time (hourly resolution)
                eof.F = [];
                eof.chan_list = [];
                eof.unit_list = [];
                if ~isempty(data)                                           % remove only if exists
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    % iGrav
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            temp = interp1(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.chan_list = [eof.chan_list,channels_igrav(plot_axesL1.igrav(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % trilogi
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            temp = interp1(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.chan_list = [eof.chan_list,channels_trilogi(plot_axesL1.trilogi(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % other1
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            temp = interp1(time.other1,data.other1(:,plot_axesL1.other1(i)),eof.ref_time); % interpolate current channel to ref_time
                            eof.chan_list = [eof.chan_list,channels_other1(plot_axesL1.other1(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % other2
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            temp = interp1(time.other2,data.other2(:,plot_axesL1.other2(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.chan_list = [eof.chan_list,channels_other2(plot_axesL1.other2(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp');                            % stack columns
                            clear temp
                        end
                    end
                    [row,column] = find(isnan(eof.F));                      % find NaNs
                    eof.F(row,:) = [];                                      % remove NaNs
                    [r_pers,p] = corrcoef(eof.F);                           % correlation matrix and p values
                    boot_num = 1000;
                    r_boots = bootstrp(boot_num,@corrcoef,eof.F);               % bootstrapping
                    t.estim = r_pers.*sqrt((size(eof.F,1)-2)./(1-r_pers.^2)); % estimated t value
                    t.crit = tinv(0.95,size(eof.F,1)-2);                    % critical t value
                    mversion = version;                                     % get matlab version
                    mversion = str2double(mversion(1:3));                   % to numeric
                    
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation matrix');
                    imagesc(r_pers);                                        % Plot correlation matrix
                    r = find(isnan(r_pers) | isinf(r_pers));
                    if ~isempty(r)
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                 % set axis and view
                    colorbar;                                               % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',8);                                      % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation p value (close to 0 => significant corr.)');
                    imagesc(p);                                             % Plot p value
                    r = find(isnan(p) | isinf(p));
                    if ~isempty(r)
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                 % set axis and view
                    colorbar;                                               % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',8);                                      % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    
                    figure('NumberTitle','off','Menu','none',...
                        'Name','plotGrav: correlation t test (>0 =>reject that there is no corr. (95%))');
                    imagesc(t.estim-t.crit);                                % plot t test difference 
                    r = find(isnan(t.estim-t.crit) | isinf(t.estim-t.crit));
                    if ~isempty(r)
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                 % set axis and view
                    colorbar;                                               % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',8);                                      % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    
                    figure('NumberTitle','off','Menu','none',...
                        'Name','plotGrav: correlation bootstrap histograms');
                    si = 1;                                                 % subplot index
                    for i = 1:size(r_pers,1)
                        for j = 1:size(r_pers,2)
                            subplot(size(r_pers,1),size(r_pers,2),si)
                            hist(r_boots(:,si),round(sqrt(boot_num)));      % show each bootstrap histrogram
                            title(sprintf('%s - %s',char(eof.chan_list(i)),char(eof.chan_list(j))),'FontSize',7,'interpreter','none');
                            xlabel('corr.','FontSize',6);
                            set(gca,'FontSize',7);
                            si = si + 1;
                        end
                    end
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
                
            case 'correlation_matrix_select'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                set(findobj('Tag','plotGrav_text_status'),'String','Select two points (like for zooming)...');drawnow % status
                [selected_x,~] = ginput(2);
                start_time = datevec(selected_x(1));
                end_time = datevec(selected_x(2));
                
                eof.ref_time = [datenum(start_time):1/24:datenum(end_time)]'; % new time (hourly resolution)
                eof.F = [];
                eof.chan_list = [];
                eof.unit_list = [];
                if ~isempty(data)                                           % remove only if exists
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                    channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                    channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
                    channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
                    channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    % iGrav
                    if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                        for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                            temp = interp1(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.chan_list = [eof.chan_list,channels_igrav(plot_axesL1.igrav(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % trilogi
                    if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                        for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                            temp = interp1(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.chan_list = [eof.chan_list,channels_trilogi(plot_axesL1.trilogi(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % other1
                    if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                        for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                            temp = interp1(time.other1,data.other1(:,plot_axesL1.other1(i)),eof.ref_time); % interpolate current channel to ref_time
                            eof.chan_list = [eof.chan_list,channels_other1(plot_axesL1.other1(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp);                            % stack columns
                            clear temp
                        end
                    end
                    
                    % other2
                    if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                        for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                            temp = interp1(time.other2,data.other2(:,plot_axesL1.other2(i)),eof.ref_time); % interpolate current channel to ref_timee
                            eof.chan_list = [eof.chan_list,channels_other2(plot_axesL1.other2(i))]; % add current channel name
                            eof.F = horzcat(eof.F,temp');                            % stack columns
                            clear temp
                        end
                    end
                    [row,column] = find(isnan(eof.F));                      % find NaNs
                    eof.F(row,:) = [];                                      % remove NaNs
                    [r_pers,p] = corrcoef(eof.F);                           % correlation matrix and p values
                    boot_num = 1000;
                    r_boots = bootstrp(boot_num,@corrcoef,eof.F);               % bootstrapping
                    t.estim = r_pers.*sqrt((size(eof.F,1)-2)./(1-r_pers.^2)); % estimated t value
                    t.crit = tinv(0.95,size(eof.F,1)-2);                    % critical t value
                    mversion = version;                                     % get matlab version
                    mversion = str2double(mversion(1:3));                   % to numeric
                    
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation matrix');
                    imagesc(r_pers);                                        % Plot correlation matrix
                    r = find(isnan(r_pers) | isinf(r_pers));
                    if ~isempty(r)
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                 % set axis and view
                    colorbar;                                               % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',8);                                      % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    
                    figure('NumberTitle','off','Menu','none','Name','plotGrav: correlation p value (close to 0 => significant corr.)');
                    imagesc(p);                                             % Plot p value
                    r = find(isnan(p) | isinf(p));
                    if ~isempty(r)
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                 % set axis and view
                    colorbar;                                               % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',8);                                      % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    
                    figure('NumberTitle','off','Menu','none',...
                        'Name','plotGrav: correlation t test (>0 =>reject that there is no corr. (95%))');
                    imagesc(t.estim-t.crit);                                % plot t test difference 
                    r = find(isnan(t.estim-t.crit) | isinf(t.estim-t.crit));
                    if ~isempty(r)
                        title('Warning: NaN or Inf values are depicted as -1');
                    end
                    axis square;view(0,90);                                 % set axis and view
                    colorbar;                                               % show colorbar
                    set(gca,'XTick',(1:1:size(eof.F,2)),'YTick',(1:1:size(eof.F,2)),... % set X and Y ticks
                        'XTickLabel',eof.chan_list,'YTickLabel',eof.chan_list,'Clim',[-1,1],...% Labels
                        'FontSize',8);                                      % font size
                    if mversion>=8.4
                        set(gca,'TickLabelInterpreter','none');
                    end
                    
                    figure('NumberTitle','off','Menu','none',...
                        'Name','plotGrav: correlation bootstrap histograms');
                    si = 1;                                                 % subplot index
                    for i = 1:size(r_pers,1)
                        for j = 1:size(r_pers,2)
                            subplot(size(r_pers,1),size(r_pers,2),si)
                            hist(r_boots(:,si),round(sqrt(boot_num)));      % show each bootstrap histrogram
                            title(sprintf('%s - %s',char(eof.chan_list(i)),char(eof.chan_list(j))),'FontSize',7,'interpreter','none');
                            xlabel('corr.','FontSize',6);
                            set(gca,'FontSize',7);
                            si = si + 1;
                        end
                    end
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
                %% EARTHQUAKES
            case 'show_earthquake'
                url = get(findobj('Tag','plotGrav_menu_show_earthquake'),'UserData');
                web(url);
            case 'plot_earthquake'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        set(findobj('Tag','plotGrav_edit_text_input'),'String',6);
                        set(findobj('Tag','plotGrav_text_status'),'String','Set minimum magnitude...');drawnow % status
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');
                        set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                        pause(5);
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        temp = [get(findobj('Tag','plotGrav_menu_plot_earthquake'),'UserData'),get(findobj('Tag','plotGrav_edit_text_input'),'String'),'&fmt=rss'];
                        xDoc = xmlread(temp);     % open xml/RSS document
                        allListitems = xDoc.getElementsByTagName('item');                           % look up all items
                        quake_name = {};                                                           % prepare variable
                        for k = 0:allListitems.getLength-1                                          % loop for all items
                           thisListitem = allListitems.item(k);                                     % get current item
                           thisList = thisListitem.getElementsByTagName('title');                   % search by 'title'
                           thisElement = thisList.item(0);                                          
                           quake_name{k+1,1} = {char(thisElement.getFirstChild.getData)};          % store title
                           if ~isempty(thisElement)                                                 % continue if some 'title' exists
                               thisList = thisListitem.getElementsByTagName('description');         % search by 'description'
                               thisElement = thisList.item(0);                                      
                               temp = char(thisElement.getFirstChild.getData);                      % get description
                               quake_time(k+1,1) = datenum(temp(1:20));                             % store time
                           end
                        end

                        a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                        a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                        a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                        data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                        data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                        data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                        data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                        plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                        plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                        plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                        plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                        plot_axesL2.igrav = find(cell2mat(data_igrav(:,2))==1); % get selected iGrav channels for L2
                        plot_axesL2.trilogi = find(cell2mat(data_trilogi(:,2))==1); % get selected TRiLOGi channels for L2
                        plot_axesL2.other1 = find(cell2mat(data_other1(:,2))==1); % get selected Other1 channels for L2
                        plot_axesL2.other2 = find(cell2mat(data_other2(:,2))==1); % get selected other2 channels for L2
                        plot_axesL3.igrav = find(cell2mat(data_igrav(:,3))==1); % get selected iGrav channels for L3
                        plot_axesL3.trilogi = find(cell2mat(data_trilogi(:,3))==1); % get selected TRiLOGi channels for L3
                        plot_axesL3.other1 = find(cell2mat(data_other1(:,3))==1); % get selected Other1 channels for L3
                        plot_axesL3.other2 = find(cell2mat(data_other2(:,3))==1); % get selected other2 channels for L3

                        if ~isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                            y = get(a1(1),'YLim');
                            x = get(a1(1),'XLim');
                            axes(a1(1));
                            for i = 1:length(quake_time)
                                if quake_time(i) > x(1) && quake_time(i) < x(2)
                                    plot([quake_time(i),quake_time(i)],y,'k--');
                                    text(quake_time(i),y(1)+range(y)*0.05,quake_name{i},'Rotation',90,'FontSize',8)
                                end
                            end
                            axes(a1(2));
                        end

                        if ~isempty([plot_axesL2.igrav,plot_axesL2.trilogi,plot_axesL2.other1,plot_axesL2.other2])
                            y = get(a2(1),'YLim');
                            x = get(a2(1),'XLim');
                            axes(a2(1));
                            for i = 1:length(quake_time)
                                if quake_time(i) > x(1) && quake_time(i) < x(2)
                                    plot([quake_time(i),quake_time(i)],y,'k--');
    %                                 text(quake_time(i),y(1)+range(y)*0.05,quake_name{i},'Rotation',90,'FontSize',7)
                                end
                            end
                            axes(a2(2));
                        end

                        if ~isempty([plot_axesL3.igrav,plot_axesL3.trilogi,plot_axesL3.other1,plot_axesL3.other2])
                            y = get(a3(1),'YLim');
                            x = get(a3(1),'XLim');
                            axes(a3(1));
                            for i = 1:length(quake_time)
                                if quake_time(i) > x(1) && quake_time(i) < x(2)
                                    plot([quake_time(i),quake_time(i)],y,'k--');
    %                                 text(quake_time(i),y(1)+range(y)*0.05,quake_name{i},'Rotation',90,'FontSize',7)
                                end
                            end
                        end
                        axes(a3(2));
                        set(findobj('Tag','plotGrav_edit_text_input'),'String',6);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select channel.');drawnow % status
                    end
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                end
                
                
                %% Remove Selected time interval
            case 'remove_interval_selected'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one channel!');drawnow % status
                    elseif length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        selected_x = sort([selected_x1,selected_x2]);       % sort = ascending
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            temp = data.igrav(:,plot_axesL1.igrav);         % get selected channel
                            r = find(time.igrav>selected_x(1) & time.igrav<selected_x(2)); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                temp(r) = NaN;                              % remove the points
                                data.igrav(:,plot_axesL1.igrav) = temp;     % update the data table
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'iGrav channel %d time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav,ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                            temp = data.trilogi(:,plot_axesL1.trilogi);         % get selected channel
                            r = find(time.trilogi>selected_x(1) & time.trilogi<selected_x(2));
                            if ~isempty(r)
                                temp(r) = NaN;
                                data.trilogi(:,plot_axesL1.trilogi) = temp;
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                plotGrav uitable_push
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'TRiLOGi channel %d time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi,ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                            temp = data.other1(:,plot_axesL1.other1);         % get selected channel
                            r = find(time.other1>selected_x(1) & time.other1<selected_x(2));
                            if ~isempty(r)
                                temp(r) = NaN;
                                data.other1(:,plot_axesL1.other1) = temp;
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                plotGrav uitable_push
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'Other1 channel %d time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1,ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                            temp = data.other2(:,plot_axesL1.other2);         % get selected channel
                            r = find(time.other2>selected_x(1) & time.other2<selected_x(2));
                            if ~isempty(r)
                                temp(r) = NaN;
                                data.other2(:,plot_axesL1.other2) = temp;
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                plotGrav uitable_push
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'Other2 channel %d time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.Other2,ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Selected time interval has been removed.');drawnow % status
                    end
                    fclose(fid);
                end
                case 'remove_interval_all'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one channel!');drawnow % status
                    elseif length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        selected_x = sort([selected_x1,selected_x2]);       % sort = ascending
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            r = find(time.igrav>selected_x(1) & time.igrav<selected_x(2)); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                data.igrav(r,:) = NaN;                          % update the data table
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
%                                 if ~isempty(data.trilogi)
%                                     r = find(time.trilogi>selected_x(1) & time.trilogi<selected_x(2)); % find points within the selected interval
%                                     if ~isempty(r)
%                                         data.trilogi(r,:) = NaN;
%                                         set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
%                                         plotGrav uitable_push
%                                     end
%                                 end
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'iGrav (all channels) time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                            r = find(time.trilogi>selected_x(1) & time.trilogi<selected_x(2));
                            if ~isempty(r)
                                data.trilogi(r,:) = NaN;
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                plotGrav uitable_push
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'TRiLOGi (all channels) time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                            r = find(time.other1>selected_x(1) & time.other1<selected_x(2));
                            if ~isempty(r)
                                data.other1(r,:) = NaN;
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                plotGrav uitable_push
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'Other1 (all channels) time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                            r = find(time.other2>selected_x(1) & time.other2<selected_x(2));
                            if ~isempty(r)
                                data.other2(r,:) = NaN;
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                plotGrav uitable_push
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'Other2 (all channels) time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                ty1,tm1,td1,th1,tmm1,ts1,ty2,tm2,td2,th2,tmm2,ts2,ty,tm,td,th,tmm);
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Selected time interval has been removed.');drawnow % status
                    end
                    fclose(fid);
                end
                %% Remove Selected step
            case 'remove_step_selected'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one channel!');drawnow % status
                    elseif length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            temp = data.igrav(:,plot_axesL1.igrav);         % get selected channel
                            r = find(time.igrav>=selected_x2); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                temp(r) = temp(r) - (selected_y2-selected_y1); % remove the step
                                data.igrav(:,plot_axesL1.igrav) = temp;     % update the data table
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'iGrav step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.igrav,ty1,tm1,td1,th1,tmm1,ts1,selected_y1,...
                                ty2,tm2,td2,th2,tmm2,ts2,selected_y2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                            temp = data.trilogi(:,plot_axesL1.trilogi);         % get selected channel
                            r = find(time.trilogi>=selected_x2); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                temp(r) = temp(r) - (selected_y2-selected_y1); % remove the step
                                data.trilogi(:,plot_axesL1.trilogi) = temp;     % update the data table
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'TRiLOGi step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.trilogi,ty1,tm1,td1,th1,tmm1,ts1,selected_y1,...
                                ty2,tm2,td2,th2,tmm2,ts2,selected_y2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                            temp = data.other1(:,plot_axesL1.other1);         % get selected channel
                            r = find(time.other1>=selected_x2); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                temp(r) = temp(r) - (selected_y2-selected_y1); % remove the step
                                data.other1(:,plot_axesL1.other1) = temp;     % update the data table
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'Other1 step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other1,ty1,tm1,td1,th1,tmm1,ts1,selected_y1,...
                                ty2,tm2,td2,th2,tmm2,ts2,selected_y2,ty,tm,td,th,tmm);
                        end
                        if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                            temp = data.other2(:,plot_axesL1.other2);         % get selected channel
                            r = find(time.other2>=selected_x2); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                temp(r) = temp(r) - (selected_y2-selected_y1); % remove the step
                                data.other2(:,plot_axesL1.other2) = temp;     % update the data table
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'Other2 step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                plot_axesL1.other2,ty1,tm1,td1,th1,tmm1,ts1,selected_y1,...
                                ty2,tm2,td2,th2,tmm2,ts2,selected_y2,ty,tm,td,th,tmm);
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Step has been removed.');drawnow % status
                    end
                    fclose(fid);
                end
                
            case 'remove_step_all'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    temp = sort(plot_axesL1.igrav);
                    if isempty(temp)
                        set(findobj('Tag','plotGrav_text_status'),'String','Gravity channel must be selected!');drawnow % status
                    elseif length(plot_axesL1.igrav) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    elseif temp(1) < 22 || temp(end) > 25
                        set(findobj('Tag','plotGrav_text_status'),'String','Gravity channel must be selected!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            r = find(time.igrav>=selected_x2); % find points within the selected interval
                            if ~isempty(r)                                  % continue only if some points have been found
                                data.igrav(r,22:25) =data.igrav(r,22:25) - (selected_y2-selected_y1); % remove the step
                                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                plotGrav uitable_push                       % reset view
                            end
                            clear temp r
                            [ty,tm,td,th,tmm] = datevec(now);
                            [ty1,tm1,td1,th1,tmm1,ts1] = datevec(selected_x1);
                            [ty2,tm2,td2,th2,tmm2,ts2] = datevec(selected_x2);
                            fprintf(fid,'iGrav step removed for all gravity channels : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                ty1,tm1,td1,th1,tmm1,ts1,selected_y1,...
                                ty2,tm2,td2,th2,tmm2,ts2,selected_y2,ty,tm,td,th,tmm);
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Step has been removed.');drawnow % status
                    end
                    fclose(fid);
                end
                    
                %% Remove Spikes
            case 'remove_3sd'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one channel!');drawnow % status
                    else
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                                temp = data.igrav(:,plot_axesL1.igrav(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>3*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.igrav(r,plot_axesL1.igrav(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                clear temp r
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'iGrav channel %d spikes > 3*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.igrav(i),ty,tm,td,th,tmm);
                            end	
                        end
                        if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                            for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                                temp = data.trilogi(:,plot_axesL1.trilogi(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>3*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.trilogi(r,plot_axesL1.trilogi(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                clear temp r
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'TRiLOGi channel %d spikes > 3*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.trilogi(i),ty,tm,td,th,tmm);
                            end	
                        end
                        if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                            for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                                temp = data.other1(:,plot_axesL1.other1(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>3*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.other1(r,plot_axesL1.other1(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'Other1 channel %d spikes > 3*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.other1(i),ty,tm,td,th,tmm);
                                clear temp r
                            end
                        end
                        if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                            for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                                temp = data.other2(:,plot_axesL1.other2(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>3*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.other2(r,plot_axesL1.other2(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'Other2 channel %d spikes > 3*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.other2(i),ty,tm,td,th,tmm);
                                clear temp r
                            end
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Spikes have been removed.');drawnow % status
                    end
                    fclose(fid);
                end
            case 'remove_2sd'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % remove only if exists
                    try
                        fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                    catch
                        fid = fopen('plotGrav_LOG_FILE.log','a');
                    end
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one channel!');drawnow % status
                    else
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            for i = 1:length(plot_axesL1.igrav)                 % compute for all selected channels
                                temp = data.igrav(:,plot_axesL1.igrav(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>2*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.igrav(r,plot_axesL1.igrav(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'iGrav channel %d spikes > 2*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.igrav(i),ty,tm,td,th,tmm);
                                clear temp r
                            end
                        end
                        if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                            for i = 1:length(plot_axesL1.trilogi)                 % compute for all selected channels
                                temp = data.trilogi(:,plot_axesL1.trilogi(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>2*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.trilogi(r,plot_axesL1.trilogi(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'TRiLOGi channel %d spikes > 2*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.trilogi(i),ty,tm,td,th,tmm);
                                clear temp r
                            end
                        end
                        if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                            for i = 1:length(plot_axesL1.other1)                 % compute for all selected channels
                                temp = data.other1(:,plot_axesL1.other1(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>2*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.other1(r,plot_axesL1.other1(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                clear temp r
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'Other1 channel %d spikes > 2*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.other1(i),ty,tm,td,th,tmm);
                            end
                        end
                        if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                            for i = 1:length(plot_axesL1.other2)                 % compute for all selected channels
                                temp = data.other2(:,plot_axesL1.other2(i));
                                temp = temp - nanmean(temp);
                                r = find(abs(temp)>2*nanstd(temp)); % find points within the selected interval
                                if ~isempty(r)                                  % continue only if some points have been found
                                    data.other2(r,plot_axesL1.other2(i)) = NaN; % remove the step
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated table
                                    plotGrav uitable_push                       % reset view
                                end
                                clear temp r
                                [ty,tm,td,th,tmm] = datevec(now);
                                fprintf(fid,'Other2 channel %d spikes > 2*standard deviation removed (%04d/%02d/%02d %02d:%02d)\n',...
                                    plot_axesL1.other2(i),ty,tm,td,th,tmm);
                            end
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Spikes have been removed.');drawnow % status
                    end
                    fclose(fid);
                end
                %% INSERT 
            case 'insert_rectangle'
                set(findobj('Tag','plotGrav_text_status'),'String','Lower left corner...');drawnow % status
                [select_x(1),select_y(1)] = ginput(1);
                set(findobj('Tag','plotGrav_text_status'),'String','Upper right corner...');drawnow % status
                [select_x(2),select_y(2)] = ginput(1);
                r = rectangle('Position',[select_x(1),select_y(1),abs(diff(select_x)),abs(diff(select_y))],'LineWidth',1);
                cur = get(findobj('Tag','plotGrav_insert_rectangle'),'UserData');
                cur = [cur,r];
                set(findobj('Tag','plotGrav_insert_rectangle'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
            case 'remove_rectangle'
                cur = get(findobj('Tag','plotGrav_insert_rectangle'),'UserData');
                if ~isempty(cur)                                           % continua only if data have been loaded
                    for c = 1:length(cur)
                        try
                            delete(cur(c));
                        end
                    end
                    set(findobj('Tag','plotGrav_insert_rectangle'),'UserData',[]);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No rectangles found.');drawnow % status
                end
            case 'remove_rectangle_last'
                cur = get(findobj('Tag','plotGrav_insert_rectangle'),'UserData');
                if ~isempty(cur)                                           % continua only if data have been loaded
                    delete(cur(end));
                    cur(end) = [];
                    set(findobj('Tag','plotGrav_insert_rectangle'),'UserData',cur);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No rectangles found.');drawnow % status
                end
                
            case 'insert_circle'
                set(findobj('Tag','plotGrav_text_status'),'String','Lower left corner...');drawnow % status
                [select_x(1),select_y(1)] = ginput(1);
                set(findobj('Tag','plotGrav_text_status'),'String','Upper right corner...');drawnow % status
                [select_x(2),select_y(2)] = ginput(1);
                r = rectangle('Position',[select_x(1),select_y(1),abs(diff(select_x)),abs(diff(select_y))],'Curvature',[1 1],...
                    'LineWidth',1);
                cur = get(findobj('Tag','plotGrav_insert_circle'),'UserData');
                cur = [cur,r];
                set(findobj('Tag','plotGrav_insert_circle'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
            case 'remove_circle'
                cur = get(findobj('Tag','plotGrav_insert_circle'),'UserData');
                if ~isempty(cur)                                           % continua only if data have been loaded
                    for c = 1:length(cur)
                        try
                            delete(cur(c));
                        end
                    end
                    set(findobj('Tag','plotGrav_insert_circle'),'UserData',[]);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No ellipse found.');drawnow % status
                end
            case 'remove_circle_last'
                cur = get(findobj('Tag','plotGrav_insert_circle'),'UserData');
                if ~isempty(cur)                                           % continua only if data have been loaded
                    delete(cur(end));
                    cur(end) = [];
                    set(findobj('Tag','plotGrav_insert_circle'),'UserData',cur);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No ellipse found.');drawnow % status
                end
                
            case 'insert_line'
                set(findobj('Tag','plotGrav_text_status'),'String','First point...');drawnow % status
                [select_x(1),select_y(1)] = ginput(1);
                set(findobj('Tag','plotGrav_text_status'),'String','Second point...');drawnow % status
                [select_x(2),select_y(2)] = ginput(1);
                r = plot(select_x,select_y,'LineWidth',1);
                set(r,'Color','k');
                cur = get(findobj('Tag','plotGrav_insert_line'),'UserData');
                cur = [cur,r];
                set(findobj('Tag','plotGrav_insert_line'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
            case 'remove_line'
                cur = get(findobj('Tag','plotGrav_insert_line'),'UserData');
                if ~isempty(cur)                                           % continue only if data have been loaded
                    for c = 1:length(cur)
                        try
                            delete(cur(c));
                        end
                    end
                    set(findobj('Tag','plotGrav_insert_line'),'UserData',[]);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No lines found.');drawnow % status
                end
            case 'remove_line_last'
                cur = get(findobj('Tag','plotGrav_insert_line'),'UserData');
                if ~isempty(cur)                                           % continue only if data have been loaded
                    delete(cur(end));
                    cur(end) = [];
                    set(findobj('Tag','plotGrav_insert_line'),'UserData',cur);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No lines found.');drawnow % status
                end
                
            case 'insert_text'
                set(findobj('Tag','plotGrav_text_status'),'String','Start writing...');drawnow % status
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');
                set(findobj('Tag','plotGrav_text_input'),'Visible','on');
                pause(5);
                set(findobj('Tag','plotGrav_text_status'),'String','Select position (centre)...');drawnow % status
                [select_x(1),select_y(1)] = ginput(1);
                r = text(select_x,select_y,get(findobj('Tag','plotGrav_edit_text_input'),'String'),'HorizontalAlignment','center',...
                        'FontSize',10,'FontWeight','bold');
                set(r,'Color','k');
                cur = get(findobj('Tag','plotGrav_insert_text'),'UserData');
                cur = [cur,r];
                set(findobj('Tag','plotGrav_insert_text'),'UserData',cur);
                set(findobj('Tag','plotGrav_text_status'),'String','Select channels.');drawnow % status
                set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');
                set(findobj('Tag','plotGrav_text_input'),'Visible','off');
            case 'remove_text'
                cur = get(findobj('Tag','plotGrav_insert_text'),'UserData');
                if ~isempty(cur)                                           % continua only if data have been loaded
                    for c = 1:length(cur)
                        try
                            delete(cur(c));
                        end
                    end
                    set(findobj('Tag','plotGrav_insert_text'),'UserData',[]);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No text found.');drawnow % status
                end
            case 'remove_text_last'
                cur = get(findobj('Tag','plotGrav_insert_text'),'UserData');
                if ~isempty(cur)                                           % continue only if data have been loaded
                    delete(cur(end));
                    cur(end) = [];
                    set(findobj('Tag','plotGrav_insert_text'),'UserData',cur);
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','No text found.');drawnow % status
                end
                %% Re-interpolated data (decimate/resample)
            case 'compute_decimate'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                if ~isempty(data)
                    set(findobj('Tag','plotGrav_text_status'),'String','Set new sampling interval (in seconds, e.g., 3600)');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(5);                                                   % wait 5 seconds for user input
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                    set(findobj('Tag','plotGrav_text_status'),'String','Starting interpolation...');drawnow % status
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    try
                        % iGrav
                        if ~isempty(data.igrav)
                           tn = [time.igrav(1):str2double(st)/86400:time.igrav(end)]'; % new time vector
                           dn(1:length(tn),1:size(data.igrav,2)) = NaN;     % declare new variable
                           for i = 1:size(data.igrav,2)
                               dn(:,i) = interp1(time.igrav,data.igrav(:,i),tn);
                           end
                           time.igrav = tn;clear tn                         % use new values + delete temp. variable
                           data.igrav = dn;clear dn
                        end
                        % TRiLOGi
                        if ~isempty(data.trilogi)
                           tn = [time.trilogi(1):str2double(st)/86400:time.trilogi(end)]'; % new time vector
                           dn(1:length(tn),1:size(data.trilogi,2)) = NaN;     % declare new variable
                           for i = 1:size(data.trilogi,2)
                               dn(:,i) = interp1(time.trilogi,data.trilogi(:,i),tn);
                           end
                           time.trilogi = tn;clear tn                         % use new values + delete temp. variable
                           data.trilogi = dn;clear dn
                        end
                        % Other1
                        if ~isempty(data.other1)
                           tn = [time.other1(1):str2double(st)/86400:time.other1(end)]'; % new time vector
                           dn(1:length(tn),1:size(data.other1,2)) = NaN;     % declare new variable
                           for i = 1:size(data.other1,2)
                               dn(:,i) = interp1(time.other1,data.other1(:,i),tn);
                           end
                           time.other1 = tn;clear tn                         % use new values + delete temp. variable
                           data.other1 = dn;clear dn
                        end
                        % Other2
                        if ~isempty(data.other2)
                           tn = [time.other2(1):str2double(st)/86400:time.other2(end)]'; % new time vector
                           dn(1:length(tn),1:size(data.other2,2)) = NaN;     % declare new variable
                           for i = 1:size(data.other2,2)
                               dn(:,i) = interp1(time.other2,data.other2(:,i),tn);
                           end
                           time.other2 = tn;clear tn                         % use new values + delete temp. variable
                           data.other2 = dn;clear dn
                        end
                        set(findobj('Tag','plotGrav_push_load'),'UserData',data); % store new variables
                        set(findobj('Tag','plotGrav_text_status'),'UserData',time); % store new time
                        set(findobj('Tag','plotGrav_text_status'),'String','All channels have been resampled');drawnow % status
                    catch
                        set(findobj('Tag','plotGrav_text_status'),'String','Could not perform interpolation...');drawnow % status
                    end
                else
                    set(findobj('Tag','plotGrav_text_status'),'String','Load data first');drawnow % status
                end
                %% Local linear fit
           case 'fit_linear_local'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % continue only if data loaded
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                        
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one iGrav channel!');drawnow % status
                    elseif length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point (start)...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point (stop)...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select extrapolation point...');drawnow % status
                        [selected_x3,selected_y3] = ginput(1);
                        selected_x = sort([selected_x1,selected_x2]);       % sort = ascending
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            r = find(time.igrav>selected_x(1) & time.igrav<selected_x(2)); % find points within the selected interval
                            r2 = find(time.igrav>min([selected_x1,selected_x2,selected_x3]) & time.igrav<max([selected_x1,selected_x2,selected_x3]));  % find points within the selected interval (extrapolation)
                            if ~isempty(r)                                  % continue only if some points have been found
                                ytemp = data.igrav(r,plot_axesL1.igrav);    % get selected channel + selected time interval
                                xtemp = time.igrav(r);                      % get selected time interval 
                                p = polyfit(xtemp(~isnan(ytemp)),ytemp(~isnan(ytemp)),1);
                                if ~isempty(r2)
                                    otemp = polyval(p,time.igrav(r2));
                                    axes(a1(1));
                                    plot(time.igrav(r2),otemp,'k');
                                    axes(a1(2));
                                end
                            end
                            clear temp r
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Linear fit for selected interval has been computed and plotted.');drawnow % status
                    end
                end 
                %% Local quadratic fit
           case 'fit_quadrat_local'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % continue only if data loaded
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                        
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one iGrav channel!');drawnow % status
                    elseif length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point (start)...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point (stop)...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select extrapolation point...');drawnow % status
                        [selected_x3,selected_y3] = ginput(1);
                        selected_x = sort([selected_x1,selected_x2]);       % sort = ascending
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            r = find(time.igrav>selected_x(1) & time.igrav<selected_x(2)); % find points within the selected interval
                            r2 = find(time.igrav>min([selected_x1,selected_x2,selected_x3]) & time.igrav<max([selected_x1,selected_x2,selected_x3]));  % find points within the selected interval (extrapolation)
                            if ~isempty(r)                                  % continue only if some points have been found
                                ytemp = data.igrav(r,plot_axesL1.igrav);    % get selected channel + selected time interval
                                xtemp = time.igrav(r);                      % get selected time interval 
                                p = polyfit(xtemp(~isnan(ytemp)),ytemp(~isnan(ytemp)),2);
                                if ~isempty(r2)
                                    otemp = polyval(p,time.igrav(r2));
                                    axes(a1(1));
                                    plot(time.igrav(r2),otemp,'k');
                                    axes(a1(2));
                                end
                            end
                            clear temp r
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Quadratic fit for selected interval has been computed and plotted.');drawnow % status
                    end
                end 
                %% Local cubic fit
           case 'fit_cubic_local'
                data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                if ~isempty(data)                                           % continue only if data loaded
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                    data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                    data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                    data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table

                    plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                    plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                    plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                    plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                        
                    set(findobj('Tag','plotGrav_text_status'),'String','Computing...');drawnow % status
                    
                    if isempty([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2])
                        set(findobj('Tag','plotGrav_text_status'),'String','Select one iGrav channel!');drawnow % status
                    elseif length([plot_axesL1.igrav,plot_axesL1.trilogi,plot_axesL1.other1,plot_axesL1.other2]) > 1
                        set(findobj('Tag','plotGrav_text_status'),'String','Select only one channel for L1!');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Select first point (start)...');drawnow % status
                        [selected_x1,selected_y1] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select second point (stop)...');drawnow % status
                        [selected_x2,selected_y2] = ginput(1);
                        set(findobj('Tag','plotGrav_text_status'),'String','Select extrapolation point...');drawnow % status
                        [selected_x3,selected_y3] = ginput(1);
                        selected_x = sort([selected_x1,selected_x2]);       % sort = ascending
                        if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav)
                            r = find(time.igrav>selected_x(1) & time.igrav<selected_x(2)); % find points within the selected interval
                            r2 = find(time.igrav>min([selected_x1,selected_x2,selected_x3]) & time.igrav<max([selected_x1,selected_x2,selected_x3]));  % find points within the selected interval (extrapolation)
                            if ~isempty(r)                                  % continue only if some points have been found
                                ytemp = data.igrav(r,plot_axesL1.igrav);    % get selected channel + selected time interval
                                xtemp = time.igrav(r);                      % get selected time interval 
                                p = polyfit(xtemp(~isnan(ytemp)),ytemp(~isnan(ytemp)),3);
                                if ~isempty(r2)
                                    otemp = polyval(p,time.igrav(r2));
                                    axes(a1(1));
                                    plot(time.igrav(r2),otemp,'k');
                                    axes(a1(2));
                                end
                            end
                            clear temp r
                        end
                    set(findobj('Tag','plotGrav_text_status'),'String','Cubic fit for selected interval has been computed and plotted.');drawnow % status
                    end
                end 
                %% SHOW PATHS
            case 'show_paths'
                path_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'String');
                path_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'String');
                file_tides = get(findobj('Tag','plotGrav_edit_tide_file'),'String');
                file_filter = get(findobj('Tag','plotGrav_edit_filter_file'),'String');
                path_webcam = get(findobj('Tag','plotGrav_edit_webcam_path'),'String');
                file_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'String');
                file_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'String');
                unzip_exe = get(findobj('Tag','plotGrav_menu_ftp'),'UserData');
                file_logfile = get(findobj('Tag','plotGrav_edit_logfile_file'),'String');
        
                p3 = figure('Resize','off','Menubar','none','ToolBar','none',...
                    'NumberTitle','off','Color',[0.941 0.941 0.941],...
                    'Name','plotGrav: paths/files settings');
                uicontrol(p3,'Style','Text','String','iGrav paht:','units','normalized',...
                        'Position',[0.02,0.89,0.13,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p3,'Style','Edit','String',path_igrav,'units','normalized','HorizontalAlignment','left',...
                          'Position',[0.17,0.90,0.8,0.06],'FontSize',9,'BackgroundColor','w','Enable','off');
                uicontrol(p3,'Style','Text','String','TRiLOGi:','units','normalized',...
                          'Position',[0.02,0.82,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p3,'Style','Edit','String',path_trilogi,'units','normalized',...
                          'Position',[0.17,0.83,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'HorizontalAlignment','left','Enable','off');
                uicontrol(p3,'Style','Text','String','Other1 file:','units','normalized',...
                          'Position',[0.02,0.75,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p3,'Style','Edit','String',file_other1,'units','normalized',...
                          'Position',[0.17,0.76,0.8,0.06],'FontSize',9,'BackgroundColor','w',...
                          'HorizontalAlignment','left','Enable','off');
                uicontrol(p3,'Style','Text','String','Other2 file:','units','normalized',...
                          'Position',[0.02,0.68,0.145,0.06],'FontSize',9,'HorizontalAlignment','left');
                uicontrol(p3,'Style','Edit','String',file_other2,'units','normalized',...
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
              %% Set Y axis limits
            case 'set_y_L1'
                try
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 8 seconds for user input
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    st = strsplit(st);                                      % split the user input (min max)
                    yl(1) = str2double(st(1));                              % convert string to double
                    yl(2) = str2double(st(2));                              % convert string to double
                    set(a1(1),'YLim',yl,'YTick',linspace(yl(1),yl(2),5));   % set new limits and ticks
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                end
            case 'set_y_R1'
                try
                    a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 8 seconds for user input
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    st = strsplit(st);                                      % split the user input (min max)
                    yl(1) = str2double(st(1));                              % convert string to double
                    yl(2) = str2double(st(2));                              % convert string to double
                    set(a1(2),'YLim',yl,'YTick',linspace(yl(1),yl(2),5));   % set new limits and ticks
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                end
                
            case 'set_y_L2'
                try
                    a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 8 seconds for user input
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    st = strsplit(st);                                      % split the user input (min max)
                    yl(1) = str2double(st(1));                              % convert string to double
                    yl(2) = str2double(st(2));                              % convert string to double
                    set(a2(1),'YLim',yl,'YTick',linspace(yl(1),yl(2),5));   % set new limits and ticks
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                end
            case 'set_y_R2'
                try
                    a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData'); % get axes two handle
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 8 seconds for user input
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    st = strsplit(st);                                      % split the user input (min max)
                    yl(1) = str2double(st(1));                              % convert string to double
                    yl(2) = str2double(st(2));                              % convert string to double
                    set(a2(2),'YLim',yl,'YTick',linspace(yl(1),yl(2),5));   % set new limits and ticks
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                end
            case 'set_y_L3'
                try
                    a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 8 seconds for user input
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    st = strsplit(st);                                      % split the user input (min max)
                    yl(1) = str2double(st(1));                              % convert string to double
                    yl(2) = str2double(st(2));                              % convert string to double
                    set(a3(1),'YLim',yl,'YTick',linspace(yl(1),yl(2),5));   % set new limits and ticks
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                end
            case 'set_y_R3'
                try
                    a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData'); % get axes three handle
                    set(findobj('Tag','plotGrav_text_status'),'String','Set limis (e.g. -10 10)...waiting 8 seconds');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                    set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                    pause(8);                                                   % wait 5 seconds for user input
                    st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    st = strsplit(st);                                      % split the user input (min max)
                    yl(1) = str2double(st(1));                              % convert string to double
                    yl(2) = str2double(st(2));                              % convert string to double
                    set(a3(2),'YLim',yl,'YTick',linspace(yl(1),yl(2),5));   % set new limits and ticks
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Could not set new y limits');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                end
            %% Simple regression analysis
            case 'regression_simple'
                try
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                    if ~isempty(data)                                       % continue only if data loaded
                        time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                        data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                        data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                        data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                        data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                        
                        plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                        plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                        plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                        plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                        
                        reg_mat = [];                                       % prepare variable for computation
                        j = 1;                                              % column of reg_mat
                        check = [plot_axesL1.igrav plot_axesL1.trilogi plot_axesL1.other1 plot_axesL1.other2]; % get selected channels
                        if numel(check) ~= 2                    
                            set(findobj('Tag','plotGrav_text_status'),'String','You can select only two channels (L1)...');drawnow % status
                        else
                            % iGrav
                            if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav) % only if some channel selected
                                for i = 1:length(plot_axesL1.igrav)         % find selected channels
                                    if ~exist('ref_time','var')             % create ref. time vector if not already created
                                        ref_time = time.igrav;
                                    end
                                    reg_mat(:,j) = interp1(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),ref_time); % interpolate current channel to ref_time
                                    j = j + 1;                              % next column
                                end
                            end
                            % trilogi
                            if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                                for i = 1:length(plot_axesL1.trilogi)      
                                    if ~exist('ref_time','var')
                                        ref_time = time.trilogi;
                                    end
                                    reg_mat(:,j) = interp1(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),ref_time); 
                                    j = j + 1;
                                end
                            end
                            % other1
                            if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                                for i = 1:length(plot_axesL1.other1)       
                                    if ~exist('ref_time','var')
                                        ref_time = time.other1;
                                    end
                                    reg_mat(:,j) = interp1(time.other1,data.other1(:,plot_axesL1.other1(i)),eof.ref_time); % interpolate current channel to ref_time
                                    j = j + 1;
                                end
                            end
                            % other2
                            if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                                for i = 1:length(plot_axesL1.other2)        
                                    if ~exist('ref_time','var')
                                        ref_time = time.other2;
                                    end
                                    reg_mat(:,j) = interp1(time.other2,data.other2(:,plot_axesL1.other2(i)),eof.ref_time); % interpolate current channel to ref_time
                                    j = j + 1;
                                end
                            end
                        end
                        r = find(isnan(sum(reg_mat,2)));                    % find NaNs
                        if ~isempty(r)
                            ref_time(r) = [];                               % remove NaNs
                            reg_mat(r,:) = [];
                        end
                        reg1 = regress(reg_mat(:,2),reg_mat(:,1));
                        figure('Name','plotGrav: regression (second vs. first)'); % open new figure
                        plot(ref_time,reg_mat(:,2),'k-',ref_time,reg_mat(:,1)*reg1,'r-');
                        title(sprintf('Regression coefficient = %10.8',reg1));  
                        legend('second','first*coeff.');
                        xlabel('time in matlab format');
                        clear reg1
                        reg2 = regress(reg_mat(:,1),reg_mat(:,2));
                        figure('Name','plotGrav: regression (first vs. second)'); % open new figure
                        plot(ref_time,reg_mat(:,1),'k-',ref_time,reg_mat(:,2)*reg2,'r-');
                        title(sprintf('Regression coefficient = %10.8',reg2));  
                        legend('first','second*coeff.');
                        xlabel('time in matlab format');
                            
                        set(findobj('Tag','plotGrav_text_status'),'String','Regression analysis has been computed.');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Regression has not been computed.');drawnow % message
                end
                
                %% Cross-Correlation
            case 'correlation_cross'
                try
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                    if ~isempty(data)                                       % continue only if data loaded
                        time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                        data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                        data_trilogi = get(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data'); % get the TRiLOGi table
                        data_other1 = get(findobj('Tag','plotGrav_uitable_other1_data'),'Data'); % get the Other1 table
                        data_other2 = get(findobj('Tag','plotGrav_uitable_other2_data'),'Data'); % get the Other2 table
                        
                        plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                        plot_axesL1.trilogi = find(cell2mat(data_trilogi(:,1))==1); % get selected TRiLOGi channels for L1
                        plot_axesL1.other1 = find(cell2mat(data_other1(:,1))==1); % get selected Other1 channels for L1
                        plot_axesL1.other2 = find(cell2mat(data_other2(:,1))==1); % get selected other2 channels for L1
                        
                        set(findobj('Tag','plotGrav_text_status'),'String','Set maximum lag (in seconds, e.g. 20)...waiting 5 seconds');drawnow % message
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % make input text visible
                        set(findobj('Tag','plotGrav_text_input'),'Visible','on');   % make input field visible
                        pause(5);                                                   % wait 8 seconds for user input
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        set(findobj('Tag','plotGrav_text_status'),'String','Cross-correlation computing...');drawnow % status
                        st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                    
                        reg_mat = [];                                       % prepare variable for computation
                        j = 1;                                              % column of reg_mat
                        check = [plot_axesL1.igrav plot_axesL1.trilogi plot_axesL1.other1 plot_axesL1.other2]; % get selected channels
                        if numel(check) ~= 2                    
                            set(findobj('Tag','plotGrav_text_status'),'String','You can select only two channels (L1)...');drawnow % status
                        else
                            % iGrav
                            if ~isempty(plot_axesL1.igrav) && ~isempty(data.igrav) % only if some channel selected
                                for i = 1:length(plot_axesL1.igrav)         % find selected channels
                                    if ~exist('ref_time','var')             % create ref. time vector if not already created
                                        ref_time = time.igrav;
                                    end
                                    reg_mat(:,j) = interp1(time.igrav,data.igrav(:,plot_axesL1.igrav(i)),ref_time); % interpolate current channel to ref_time
                                    j = j + 1;                              % next column
                                end
                            end
                            % trilogi
                            if ~isempty(plot_axesL1.trilogi) && ~isempty(data.trilogi)
                                for i = 1:length(plot_axesL1.trilogi)      
                                    if ~exist('ref_time','var')
                                        ref_time = time.trilogi;
                                    end
                                    reg_mat(:,j) = interp1(time.trilogi,data.trilogi(:,plot_axesL1.trilogi(i)),ref_time); 
                                    j = j + 1;
                                end
                            end
                            % other1
                            if ~isempty(plot_axesL1.other1) && ~isempty(data.other1)
                                for i = 1:length(plot_axesL1.other1)       
                                    if ~exist('ref_time','var')
                                        ref_time = time.other1;
                                    end
                                    reg_mat(:,j) = interp1(time.other1,data.other1(:,plot_axesL1.other1(i)),ref_time); % interpolate current channel to ref_time
                                    j = j + 1;
                                end
                            end
                            % other2
                            if ~isempty(plot_axesL1.other2) && ~isempty(data.other2)
                                for i = 1:length(plot_axesL1.other2)        
                                    if ~exist('ref_time','var')
                                        ref_time = time.other2;
                                    end
                                    reg_mat(:,j) = interp1(time.other2,data.other2(:,plot_axesL1.other2(i)),ref_time); % interpolate current channel to ref_time
                                    j = j + 1;
                                end
                            end
                        end
                        
                        max_lag = str2double(st);
                        if max_lag <500
                            step = 1;
                        elseif max_lag > 500 && max_lag<5000
                            step = 10;
                        else
                            step = 60;
                        end
                        lag = -max_lag:step:max_lag;
                        acor = lag.*0;
                        j = 1;
                        for i = -max_lag:step:max_lag
                            x1 = reg_mat(:,1);
                            x2 = interp1(ref_time+i/86400,reg_mat(:,2),ref_time);
                            r = find(isnan(x1+x2));                    % find NaNs
                            if ~isempty(r)
                                x1(r) = [];
                                x2(r) = [];
                            end
                            temp = corrcoef(x1,x2);
                            acor(j) = temp(1,2);
                            j = j + 1;
                            set(findobj('Tag','plotGrav_text_status'),'String',sprintf('Cross-correlation computing...(%3.0f%%)',(j/length(lag))*100));drawnow % status
                        end
                        figure('Name','plotGrav: cross-correlation'); % open new figure
                        ncor = interp1(lag,acor,-max_lag:step/50:max_lag,'spline');
                        plot(-max_lag:step/50:max_lag,ncor,'k-',lag,acor,'r.')
                        legend('fitted spline','computation points');
                        xlabel('lag');
                            
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        set(findobj('Tag','plotGrav_text_status'),'String','Cross-correlation has been computed.');drawnow % status
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Load data first.');drawnow % status
                    end
                catch
                    set(findobj('Tag','plotGrav_text_status'),'String','Cross-correlation has not been computed.');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                end
                %% GET Polar motion effect
            case 'get_polar'
                try
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    if ~isempty(data) && ~isempty(time.igrav)               % continue only if data loaded
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                        units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                        channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                        set(findobj('Tag','plotGrav_text_status'),'String','Latitude and Longitude (in deg, e.g. 49.1 12.8)...waiting 8 seconds');drawnow % message
                        set(findobj('Tag','plotGrav_edit_text_input'),'String','49.14490 12.87687');
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % turn off
                        set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                        pause(8);
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        set(findobj('Tag','plotGrav_text_status'),'String','Downloading/Computing EOP...');drawnow % status
                        ref_time = time.igrav;
                        st = get(findobj('Tag','plotGrav_edit_text_input'),'String'); % get user input
                        st = strsplit(st);
                        Lat = str2double(st(1));
                        Lon = str2double(st(2));
                        atmacs_url_link_loc = '';
                        atmacs_url_link_glo = '';  
                        [pol_corr,lod_corr,~,~,corr_check] = plotGrav_Atmacs_and_EOP(ref_time,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo);
                        c = length(channels_igrav);
                        if corr_check(1)+corr_check(2) == 2
                            % Polar motion
                            units_igrav(c+1) = {'nm/s^2'}; % add units
                            channels_igrav(c+1) = {'polar motion effect'}; % add channel name
                            data_igrav(c+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',c+1,char(channels_igrav(c+1)),char(units_igrav(c+1))),...
                                                                    false,false,false};
                            data.igrav(:,c+1) = -pol_corr;       % add data (convert correction to effect)
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d == polar motion effect (%04d/%02d/%02d %02d:%02d)\n',...
                                length(channels_igrav),ty,tm,td,th,tmm);
                            % LOD
                            units_igrav(c+2) = {'nm/s^2'}; % add units
                            channels_igrav(c+2) = {'LOD effect'}; % add channel name
                            data_igrav(c+2,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',c+2,char(channels_igrav(c+2)),char(units_igrav(c+2))),...
                                                                    false,false,false};
                            data.igrav(:,c+2) = -lod_corr;       % add data (convert correction to effect)
                            [ty,tm,td,th,tmm] = datevec(now);
                            fprintf(fid,'iGrav channel %d == length of day effect (%04d/%02d/%02d %02d:%02d)\n',...
                                length(channels_igrav),ty,tm,td,th,tmm);
                            
                            set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                            set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                            set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                            set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Polar motion and LOD effect computed.');drawnow % message
                        else
                            set(findobj('Tag','plotGrav_text_status'),'String','Polar motion and LOD effect NOT computed.');drawnow % message
                            fclose(fid);
                        end
                        
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Load (iGrav) data first.');drawnow % message
                    end 
                catch
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Polar motion and LOD effect NOT computed.');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                end        
                %% GET Atmacs data
            case 'get_atmacs'
                try
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    if ~isempty(data) && ~isempty(time.igrav)               % continue only if data loaded
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                        units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                        channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                        set(findobj('Tag','plotGrav_text_status'),'String','Set url for local part...waiting 8 seconds');drawnow % message
                        set(findobj('Tag','plotGrav_edit_text_input'),'String','http://atmacs.bkg.bund.de/data/results/lm/we_lm2_12km_19deg.grav');
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % turn off
                        set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                        pause(8);
                        atmacs_url_link_loc = get(findobj('Tag','plotGrav_edit_text_input'),'String');
                        set(findobj('Tag','plotGrav_text_status'),'String','Set url for global part...waiting 8 seconds');drawnow % message
                        set(findobj('Tag','plotGrav_edit_text_input'),'String','http://atmacs.bkg.bund.de/data/results/icon/we_icon384_19deg.grav');
                        pause(8);
                        atmacs_url_link_glo = get(findobj('Tag','plotGrav_edit_text_input'),'String');
                        set(findobj('Tag','plotGrav_text_status'),'String','iGrav pressure channel (for pressure in mBar)...waiting 5 seconds');drawnow % message
                        set(findobj('Tag','plotGrav_edit_text_input'),'String','2');
                        pause(5);
                        press_channel = get(findobj('Tag','plotGrav_edit_text_input'),'String');
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off'); 
                        set(findobj('Tag','plotGrav_text_input'),'Visible','off');
                        set(findobj('Tag','plotGrav_text_status'),'String','Downloading/Computing Atmacs...');drawnow % status
                        ref_time = time.igrav;
                        Lat = [];Lon = [];
                        [~,~,atmo_corr,pressure,corr_check] = plotGrav_Atmacs_and_EOP(ref_time,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo);
                        admittance_factor = str2double(get(findobj('Tag','plotGrav_edit_admit_factor'),'String'));  % get admittance factor
                        if corr_check(3) == 1
                            % Atmacs effect
                            units_igrav(length(channels_igrav)+1) = {'nm/s^2'}; % add units
                            channels_igrav(length(channels_igrav)+1) = {'Atmacs effect'}; % add channel name
                            data_igrav(length(channels_igrav),1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',length(channels_igrav),char(channels_igrav(length(channels_igrav))),char(units_igrav(length(channels_igrav)))),...
                                                                    false,false,false};
                            [ty,tm,td,th,tmm] = datevec(now);
                            if ~isempty(press_channel)                      % add residual effect if local pressure available
                                dp = data.igrav(:,str2double(press_channel)) - pressure/100;
                                data.igrav(:,length(channels_igrav)) = -atmo_corr + admittance_factor*dp;
                                fprintf(fid,'iGrav channel %d == Atmacs total effect including residual effect (admittance = %4.2f nm/s^2/hPa) (%04d/%02d/%02d %02d:%02d)\n',...
                                    length(channels_igrav),admittance_factor,ty,tm,td,th,tmm);
                            else
                                data.igrav(:,length(channels_igrav)) = -atmo_corr;       % add data (convert correction to effect)
                                fprintf(fid,'iGrav channel %d == Atmacs total effect without residaul effect (%04d/%02d/%02d %02d:%02d)\n',...
                                    length(channels_igrav),ty,tm,td,th,tmm);
                            end
                            % Atmacs pressure
                            units_igrav(length(channels_igrav)+1) = {'mBar'}; % add units
                            channels_igrav(length(channels_igrav)+1) = {'Atmacs pressure'}; % add channel name
                            data_igrav(length(channels_igrav),1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',length(channels_igrav),char(channels_igrav(length(channels_igrav))),char(units_igrav(length(channels_igrav)))),...
                                                                    false,false,false};
                            [ty,tm,td,th,tmm] = datevec(now);
                            data.igrav(:,length(channels_igrav)) = pressure/100; % add data 
                            fprintf(fid,'iGrav channel %d == Atmacs pressure (%04d/%02d/%02d %02d:%02d)\n',...
                                length(channels_igrav),ty,tm,td,th,tmm);
                            set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                            set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                            set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                            set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                            fclose(fid);
                            set(findobj('Tag','plotGrav_text_status'),'String','Atmacs effect computed.');drawnow % message
                        else
                            set(findobj('Tag','plotGrav_text_status'),'String','Atmacs NOT computed.');drawnow % message
                            fclose(fid);
                        end
                        
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Load (iGrav) data first.');drawnow % message
                    end 
                catch
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','Atmacs NOT computed.');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                end  
                %% ALGEBRA
            case 'simple_algebra'
                try
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data 
                    if ~isempty(data)               % continue only if data loaded
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        data_igrav = get(findobj('Tag','plotGrav_uitable_igrav_data'),'Data'); % get the iGrav table
                        units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
                        channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
                        plot_axesL1.igrav = find(cell2mat(data_igrav(:,1))==1); % get selected iGrav channels for L1
                        
                        set(findobj('Tag','plotGrav_text_status'),'String','Set expression (space separated, e.g. 23 - 26 = 23th-26th channel)');drawnow % message
                        set(findobj('Tag','plotGrav_edit_text_input'),'String','23 - 26');
                        set(findobj('Tag','plotGrav_edit_text_input'),'Visible','on');  % turn on
                        set(findobj('Tag','plotGrav_text_input'),'Visible','on');  
                        pause(8);
                        st0 = get(findobj('Tag','plotGrav_edit_text_input'),'String');   % get string
                        st = strsplit(st0);                                  % split string
                        
                        
                        if length(st) ~= 3
                            set(findobj('Tag','plotGrav_text_status'),'String','The expression must contain 2 channels and one operator.');drawnow % message
                        else
                            if ~isempty(data.igrav)
                                c = length(channels_igrav);                 % channel count
                                [ty,tm,td,th,tmm] = datevec(now);           % time for logfile
                                switch char(st(2))
                                    case '+'
                                        temp = data.igrav(:,str2double(st(1))) + data.igrav(:,str2double(st(3)));
                                        channels_igrav(c+1) = {sprintf('%s+%s',char(channels_igrav(str2double(st(1)))),char(channels_igrav(str2double(st(3)))))};
                                        units_igrav(c+1) = {sprintf('%s+%s',char(units_igrav(str2double(st(1)))),char(units_igrav(str2double(st(3)))))};
                                    case '-'
                                        temp = data.igrav(:,str2double(st(1))) - data.igrav(:,str2double(st(3)));
                                        channels_igrav(c+1) = {sprintf('%s-%s',char(channels_igrav(str2double(st(1)))),char(channels_igrav(str2double(st(3)))))};
                                        units_igrav(c+1) = {sprintf('%s-%s',char(units_igrav(str2double(st(1)))),char(units_igrav(str2double(st(3)))))};
                                    case '*'
                                        temp = data.igrav(:,str2double(st(1))).*data.igrav(:,str2double(st(3)));
                                        channels_igrav(c+1) = {sprintf('%s*%s',char(channels_igrav(str2double(st(1)))),char(channels_igrav(str2double(st(3)))))};
                                        units_igrav(c+1) = {sprintf('%s*%s',char(units_igrav(str2double(st(1)))),char(units_igrav(str2double(st(3)))))};
                                    case '/'
                                        temp = data.igrav(:,str2double(st(1)))./data.igrav(:,str2double(st(3)));
                                        channels_igrav(c+1) = {sprintf('%s/%s',char(channels_igrav(str2double(st(1)))),char(channels_igrav(str2double(st(3)))))};
                                        units_igrav(c+1) = {sprintf('%s/%s',char(units_igrav(str2double(st(1)))),char(units_igrav(str2double(st(3)))))};
                                    otherwise
                                        set(findobj('Tag','plotGrav_text_status'),'String','Not supported operator.');drawnow % message
                                        temp = [];
                                end
                                if ~isempty(temp)
                                    data.igrav(:,c+1) = temp;               % add to data
                                    data_igrav(c+1,1:7) = {false,false,false,... % add to table
                                                                sprintf('[%2d] %s (%s)',c+1,char(channels_igrav(c+1)),char(units_igrav(c+1))),...
                                                                    false,false,false}; 
                                    fprintf(fid,'iGrav channel %d = %s (%04d/%02d/%02d %02d:%02d)\n',c+1,st0,ty,tm,td,th,tmm);
                                    set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_igrav); % update table
                                    set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                                    set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav); % update iGrav units
                                    set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav); % update iGrav channels (names)
                                    fclose(fid);
                                    set(findobj('Tag','plotGrav_text_status'),'String','Computed.');drawnow % message
                                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn on
                                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                                end
                            end
                        end
                        
                    else
                        set(findobj('Tag','plotGrav_text_status'),'String','Load (iGrav) data first.');drawnow % message
                    end 
                catch
                    fclose(fid);
                    set(findobj('Tag','plotGrav_text_status'),'String','NOT computed.');drawnow % message
                    set(findobj('Tag','plotGrav_edit_text_input'),'Visible','off');  % turn off
                    set(findobj('Tag','plotGrav_text_input'),'Visible','off');  
                end  
            case 'reset_tables_sg030'
                channels_igrav = {'Grav-1','Grav-2','Baro-1','Grav-1_calib',...
                                    'Grav-1_filt','Grav-1_filt-tide/pol-atmo',...
                                    'Grav-1_filt-tide/pol-atmo-drift','tides','pol','atmo','drift'};
                units_igrav = {'V','V','mBar','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2'};
                % Store units/channels
                set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav);
                set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav);

                for i = 1:length(channels_igrav)
                    if i >= 22-18 && i <= 23-18                                           % by default on in L1
                        data_table_igrav(i,1:7) = {true,false,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false};
                    elseif i == 25-18                                                  % by default on in L2
                        data_table_igrav(i,1:7) = {false,true,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false};
                    else
                        data_table_igrav(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false};
                    end
                end
                set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_table_igrav,'UserData',data_table_igrav);clear data_table_igrav
            case 'reset_tables'
                channels_igrav = {'Grav','Baro-Press','Grav-Bal','TiltX-Bal','TiltY-Bal',...
                                    'Temp-Bal','Grav-Ctrl','TiltX-Ctrl','TiltY-Ctrl','Temp-Ctrl',...
                                    'Neck-T1','Neck-T2','Body-T','Belly-T','PCB-T','Aux-T','Dewar-Pwr',...
                                    'Dewar-Press','He-Level','GPS-Signal','TimeStamp','Grav_calib',...
                                    'Grav_filt','Grav_filt-tide/pol-atmo',...
                                    'Grav_filt-tide/pol-atmo-drift','tides','pol','atmo','drift'};
                channels_trilogi = {'TempExt','TempIn','TempCompIn','TempCompOut','TempRegIn',...
                                    'TempRegOut','HeGasPres','Vin','Mains','LowBat','UPSAlarm','FanTach',...
                                    'CompFault','IN6','IN7','IN8','OUT1','FanOn','HeGasValv','RefrigComp','Out5',...
                                    'DCPwrCntrl','EnclosHeater','FanSpdCntrl','T09-iG-Top','T10-iG-Upper',...
                                    'T11-iG-Mid','T12-iG-Bot','T13-iG-Head','T14-iG-Ambient','T15-iG-H2oSupply',...
                                    'T16-iG-H2oReturn','OUT1S','OUT2S','OUT3S','OUT4S','OUT5S','OUT6S','PIDValue','OUT8S'};
                units_igrav = {'V','mBar','V','V','V','V','V','W','W','V','K','K','K',...
                               'K','C','C','mW','PSI','Percent','bool','s','nm/s^2','nm/s^2','nm/s^2',...
                               'nm/s^2','nm/s^2','nm/s^2','nm/s^2','nm/s^2'};
                units_trilogi = {'DegC','DegC','DegC','DegC','DegC','DegC','KPa','DCV','Bool','Bool','Bool',...
                                'RPM','Bool','Bool','Bool','Bool','Bool','Bool','Bool','Bool','Bool','Bool',...
                                'Bool','PCNT','DegC','DegC','DegC','DegC','DegC','DegC','DegC','DegC',...
                                'Bool','Bool','Bool','Bool','Bool','Bool','PCNT','Bool'};
                % Store units/channels
                set(findobj('Tag','plotGrav_text_igrav'),'UserData',units_igrav);
                set(findobj('Tag','plotGrav_text_trilogi'),'UserData',units_trilogi);
                set(findobj('Tag','plotGrav_edit_igrav_path'),'UserData',channels_igrav);
                set(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData',channels_trilogi);

                for i = 1:length(channels_igrav)
                    if i >= 22 && i <= 23                                           % by default on in L1
                        data_table_igrav(i,1:7) = {true,false,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false};
                    elseif i == 25                                                  % by default on in L2
                        data_table_igrav(i,1:7) = {false,true,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false};
                    else
                        data_table_igrav(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_igrav(i)),char(units_igrav(i))),false,false,false};
                    end
                end
                set(findobj('Tag','plotGrav_uitable_igrav_data'),'Data',data_table_igrav,'UserData',data_table_igrav);clear data_table_igrav
                for i = 1:length(channels_trilogi)
                    if i >= 25 && i <= 29                                           % by default on in L3
                        data_table_trilogi(i,1:7) = {false,false,true,sprintf('[%2d] %s (%s)',i,char(channels_trilogi(i)),char(units_trilogi(i))),false,false,false};
                    elseif i == 39                                                   % by default on in R3
                        data_table_trilogi(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_trilogi(i)),char(units_trilogi(i))),false,false,true};
                    else
                        data_table_trilogi(i,1:7) = {false,false,false,sprintf('[%2d] %s (%s)',i,char(channels_trilogi(i)),char(units_trilogi(i))),false,false,false};
                    end
                end
                set(findobj('Tag','plotGrav_uitable_trilogi_data'),'Data',data_table_trilogi,'UserData',data_table_trilogi);clear data_table_trilogi
                set(findobj('Tag','plotGrav_uitable_other1_data'),'Data',{false,false,false,'NotAvailable',false,false,false}); % Other 1 table
                set(findobj( 'Tag','plotGrav_uitable_other2_data'),'Data',{false,false,false,'NotAvailable',false,false,false}); % Other 2 table
                time.igrav = [];time.trilogi = [];time.other1 = [];time.other2 = [];
                data.igrav = [];data.trilogi = [];data.other1 = [];data.other2 = [];
                set(findobj('Tag','plotGrav_text_status'),'UserData',time); % store the data 
                set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store time
                %% CORRECTION FILE
            case 'correction_file'
                [name,path] = uigetfile({'*.txt'},'Select Correction file');
                set(findobj('Tag','plotGrav_text_status'),'String','Select correction file.');drawnow % status
                if name == 0                                            % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','No correction file selected.');drawnow % status
                else
                    fileid = fullfile(path,name);
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data
                    time = get(findobj('Tag','plotGrav_text_status'),'UserData'); % load time
                    if ~isempty(data.igrav)                                 % continue only if exists
                        set(findobj('Tag','plotGrav_text_status'),'String','Correcting...');drawnow % status
                        try
                            fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a');
                        catch
                            fid = fopen('plotGrav_LOG_FILE.log','a');
                        end
                        try
                            in = load(fileid);
                            [ty,tm,td,th,tmm] = datevec(now); % for log file
                            channel = in(:,2);
                            x1 = datenum(in(:,3:8));
                            x2 = datenum(in(:,9:14));
                            y1 = in(:,15);
                            y2 = in(:,16);
                            for i = 1:size(in,1)
                                switch in(i,1)
                                    case 1                                      % remove step
                                        if channel(i) <= size(data.igrav,2)     % continue only if such channel exists
                                            r = find(time.igrav >= x2(i));      % find points within the selected interval
                                            if ~isempty(r)                      % continue only if some points have been found
                                                data.igrav(r,channel(i)) = data.igrav(r,channel(i)) - (y2(i)-y1(i)); % remove the step
                                                [ty,tm,td,th,tmm] = datevec(now); % for log file
                                                fprintf(fid,'iGrav step removed for channel %d : First point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f / %7.3f (%04d/%02d/%02d %02d:%02d)\n',...
                                                    channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),y1(i),...
                                                    in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),y2(i),ty,tm,td,th,tmm);
                                            end
                                        end
                                    case 2                                      % remove interval       
                                        r = find(time.igrav>x1(i) & time.igrav<x2(i)); % find points within the selected interval
                                        if ~isempty(r)                          % continue only if some points have been found
                                            data.igrav(r,channel(i)) = NaN;     % remove selected interval
                                            [ty,tm,td,th,tmm] = datevec(now);   % for log file
                                            fprintf(fid,'iGrav channel %d time interval removed: First point = %04d/%02d/%02d %02d:%02d:%02.0f, Second point = %04d/%02d/%02d %02d:%02d:%02.0f (%04d/%02d/%02d %02d:%02d)\n',...
                                                channel(i),in(i,3),in(i,4),in(i,5),in(i,6),in(i,7),in(i,8),...
                                                in(i,9),in(i,10),in(i,11),in(i,12),in(i,13),in(i,14),ty,tm,td,th,tmm);
                                        end
                                end
                            end
                            set(findobj('Tag','plotGrav_text_status'),'String','Data corrected.');drawnow % status
                            fprintf(fid,'Used correction file: %s (%04d/%02d/%02d %02d:%02d)\n',fileid,ty,tm,td,th,tmm);
                            set(findobj('Tag','plotGrav_push_load'),'UserData',data);   % store the updated data
                        catch
                            set(findobj('Tag','plotGrav_text_status'),'String','Could not correct iGrav data...');drawnow % status
                        end
                    end
                end
                %% CORRECTION FILE - show
            case 'correction_file_show'
                [name,path] = uigetfile({'*.txt'},'Select Correction file');
                set(findobj('Tag','plotGrav_text_status'),'String','Select correction file.');drawnow % status
                a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData'); % get axes one handle
                if name == 0                                            % If cancelled-> no input
                    set(findobj('Tag','plotGrav_text_status'),'String','No correction file selected.');drawnow % status
                else
                    fileid = fullfile(path,name);
                    data = get(findobj('Tag','plotGrav_push_load'),'UserData'); % load all data
                    if ~isempty(data.igrav)                                 % continue only if exists
                        set(findobj('Tag','plotGrav_text_status'),'String','Plotting...');drawnow % status
                        try
                            in = load(fileid);
                            channel = in(:,2);
                            x1 = datenum(in(:,3:8));
                            x2 = datenum(in(:,9:14));
                            y1 = in(:,15);
                            y2 = in(:,16); 
                            y = get(a1(1),'YLim');
                            for i = 1:size(in,1)
                                switch in(i,1)
                                    case 1                                      % remove step
                                        axes(a1(1));
                                        plot([x1(i),x1(i)],y,'k-');hold on
                                        text(x1(i),y(1)+range(y)*0.05,sprintf('Step channel %02d = %3.1f',channel(i),y2(i)-y1(i)),'Rotation',90,'FontSize',11,'VerticalAlignment','bottom')
                                        axes(a1(2));
                                    case 2                                      % remove interval      
%                                         axes(a1(1));
%                                         plot([x1(i),x2(i),x2(i),x1(i),x1(i)],[y(1),y(1),y(2),y(2),y(1)],'k--');
% %                                         text(mean(x1(1),x2(i)),y(1)+range(y)*0.05,sprintf('Interval',channel(i),y2(i)-y1(i)),'Rotation',90,'FontSize',8)
%                                         axes(a1(2));
                                end
                            end
                        catch
                            set(findobj('Tag','plotGrav_text_status'),'String','Could not load correction file...');drawnow % status
                        end
                    end
                end
                
    end                                                                         % nargin == 0

end