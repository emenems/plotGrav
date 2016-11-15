function plotGrav_printData(plot_id,output_file,output_resol,scrs,varargin)
%PLOTGRAV_PRINTDATA print plotted data
% Input:
%   plot_id     ... scalar switch:  1 = first plot, 
%                                   2 = first and second plot
%                                   3 = all three plots
%                                   4 = open new figure for editing
%   output_resol... DPI of output print (e.g., 300) 
%   output_file ... output file name (print to this file). If [], a dialog
%                   window will be called.
%   scrs        ... screen reasolution, e.g., [1,1,1920,1080]
%

%% Get required parameters
if isempty(scrs)
    scrs = get(0,'screensize');                                             % get monitor resolution if not given explicitaly. Plot is always fitted to screan size!! "What you see is what you get". See 'F2c' variable.
end
% First get user plot settings: font size and number of ticks, and axes
% handles (will be copied to new figure)
font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
a1 = get(findobj('Tag','plotGrav_check_grid'),'UserData');                  % get axes one handles
a2 = get(findobj('Tag','plotGrav_check_legend'),'UserData');                % get axes two handles
a3 = get(findobj('Tag','plotGrav_check_labels'),'UserData');                % get axes three handles
plot_mode = get(findobj('Tag','plotGrav_push_reset_view'),'UserData');      % get plot mode (tells which axis is visible)
% Get output full file name and file format switch
if plot_id == 4
    name = 'dummy';                                                         % Export to editable figure does not require name and filterindex
else
    if isempty(output_file)                                                 % Ask user to select the output file if not already set as input
        [name,path,filteridex] = uiputfile({'*.jpg';'*.eps';'*.tif'},'Select output file (extension: jpg, eps, tif))'); 
        output_file = fullfile(path,name);                                  % full output file name
    else
        name = 1;
        switch output_file(end-3:end)                                       % determine the filterindex only if output file not selected manually
            case '.jpg'
                filteridex = 1;
            case '.eps'
                filteridex = 2;
            case '.tif'
                filteridex = 3;
            otherwise
                filteridex = 9999;
        end
    end
end
if name == 0                                                                % If cancelled-> no output
    set(findobj('Tag','plotGrav_text_status'),'String','You must select an output file.');drawnow % status
else
    set(findobj('Tag','plotGrav_text_status'),'String','Printing...');drawnow % status
    %% Prepare new figure
    switch plot_id                                                          % switch between plot IDs
        case 1                                                              % First plot (only L1 and R1)
            figure_position = [50 50 (scrs(3)-50*2)*(1-0.185), (scrs(4)-50*3)*0.35]; % Depending on muber of plots, the height of the printing figure varies (=*0.33, to avoid printing white empty areas)
                                                                            % Compare to plotGrav figure, the width is reduces taking the width of 'ui-tables' into account (1-0.2)
            a1_position = [0.1,0.1,0.8,0.8];                                % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'. Is used for both L1 and R1
            a2_position = [];a3_position = [];                              % Empty means, it will not be created
            visible = 'off';toolbar = 'none';menubar = 'none';              
        case 2
            figure_position = [50 50 (scrs(3)-50*2)*(1-0.185), (scrs(4)-50*3)*0.69]; % Depending on muber of plots, the height of the printing figure varies (=*0.66, to avoid printing white empty areas)
            a1_position = [0.1,0.54,0.8,0.40];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            a2_position = [0.1,0.07,0.8,0.40];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            a3_position = [];
            visible = 'off';toolbar = 'none';menubar = 'none';
        case 3
            figure_position = [50 50 (scrs(3)-50*2)*(1-0.185), (scrs(4)-50*3)*1.00]; % Depending on muber of plots, the height of the printing figure varies (=*1.0, to avoid printing white empty areas)
            a1_position = [0.1,0.69,0.8,0.27];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            a2_position = [0.1,0.37,0.8,0.27];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            a3_position = [0.1,0.05,0.8,0.27];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            visible = 'off';toolbar = 'none';menubar = 'none';
        case 4
            figure_position = [50 50 (scrs(3)-50*2)*(1-0.185), (scrs(4)-50*3)*1.00]; % Depending on muber of plots, the height of the printing figure varies (=*1.0, to avoid printing white empty areas)
            a1_position = [0.1,0.69,0.8,0.27];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            a2_position = [0.1,0.37,0.8,0.27];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            a3_position = [0.1,0.05,0.8,0.27];                               % Axes position/size. Depends of nuber of plots. Use used to re-scale the axes to 'figure_position'
            visible = 'on';toolbar = 'auto';menubar = 'figure';
    end
    F2c = figure('Position',figure_position,...                             % create new invisible window for printing. Use position/size with respect to number of plots
        'Resize','on','Menubar',menubar,'ToolBar',toolbar,...                % 
        'NumberTitle','off','Color',[0.941 0.941 0.941],...
        'Name','plotGrav: gravity time series','visible',visible);
    try
        %% Copy plots to new figure
        % This function only copies the existing plots (visible via plotGrav
        % GUI) to new figure that is then printed.
        if plot_mode(1) > 0                                                 % Check if something is plotted in the first plot
            a1c(1) = copyobj(a1(1),F2c);                                    % copy axes to the new figure (only if something is plotted)
            a1c(2) = copyobj(a1(2),F2c);                                    % copy axes to the new figure (only if something is plotted)
            set(a1c(1),'units','normalized','Position',a1_position);        % scale the axes to new figure (has diferent size compare to plotGrav GUI)
            set(a1c(2),'units','normalized','Position',a1_position);
            rL1 = get(a1c(1),'YLim');                                       % Get current limits for re-setting YTicks
            set(a1c(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));     % set Y Ticks, for unknown reason, this must by done this way.      
            % Create legend (is not copied automatically)
            if get(findobj('Tag','plotGrav_check_legend'),'Value') == 1 % copy only if selected by user
                temp = get(findobj('Tag','plotGrav_menu_print_one'),'UserData'); % get legend
                l = legend(a1c(1),temp{1});                                     % set left legend
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest'); % set font 
                l = legend(a1c(2),temp{2});                                     % set legend on right
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast'); % set font
            end
        end
        if plot_mode(2) > 0 && ~isempty(a2_position)                        % Continue only if something is plotted in second plot + user requires plotting second plot
            a2c(1) = copyobj(a2(1),F2c);
            a2c(2) = copyobj(a2(2),F2c);
            set(a2c(1),'units','normalized','Position',a2_position);        
            set(a2c(2),'units','normalized','Position',a2_position);        
            rL1 = get(a2c(1),'YLim'); 
            set(a2c(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));  
            temp = get(findobj('Tag','plotGrav_menu_print_two'),'UserData'); 
            if get(findobj('Tag','plotGrav_check_legend'),'Value') == 1
                l = legend(a2c(1),temp{1});                             
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest'); 
                l = legend(a2c(2),temp{2});                             
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast'); 
            end
        end
        if plot_mode(3) > 0 && ~isempty(a3_position)                        % Continue only if something is plotted in third plot + user requires plotting third plot
            a3c(1) = copyobj(a3(1),F2c);
            a3c(2) = copyobj(a3(2),F2c);
            set(a3c(1),'units','normalized','Position',a3_position);
            set(a3c(2),'units','normalized','Position',a3_position);
            rL1 = get(a3c(1),'YLim'); 
            set(a3c(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));     
            temp = get(findobj('Tag','plotGrav_menu_print_three'),'UserData');
            if get(findobj('Tag','plotGrav_check_legend'),'Value') == 1
                l = legend(a3c(1),temp{1}); 
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest');
                l = legend(a3c(2),temp{2});
                set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast');
            end
        end

        %% Final Print
        set(F2c,'paperpositionmode','auto');                                % the printed file will have the same dimensions as figure
        if plot_id ~=4                                                      % The following code is not relevant for 'editable figure' option
            try
                fid = fopen(get(findobj('Tag','plotGrav_edit_logfile_file'),'String'),'a'); % Open logfile (if exists)
            catch
                fid = fopen('plotGrav_LOG_FILE.log','a');
            end
            % Write to logfile
            [ty,tm,td,th,tmm] = datevec(now);
            fprintf(fid,'Data plotted: %s (%04d/%02d/%02d %02d:%02d)\n',...
                output_file,ty,tm,td,th,tmm);
            fclose(fid);                                                    % Close logfile
            if isempty(output_resol)
                output_resol = 300;                                         % By default, all plots are printed with 300 DPI
            end
            % Switch between output formats: print the file with respect to
            % selected output format.
            switch filteridex
                case 1                                                      % jpg
                    print(F2c,'-djpeg',sprintf('-r%d',round(output_resol)),output_file);                    
                case 2                                                      % eps
                    print(F2c,'-depsc',sprintf('-r%d',round(output_resol)),output_file);
                case 3                                                       % no compression tiff
                    print(F2c,'-dtiffn',output_file);
            end
            close(F2c)                                                      % close the window only if not printed, i.e., has not been exported to editable figure
        end
        set(findobj('Tag','plotGrav_text_status'),'String','The figure has been printed.');drawnow % status
    catch
        set(findobj('Tag','plotGrav_text_status'),'String','Figure NOT printed.');drawnow % status
    end
end

end % Function