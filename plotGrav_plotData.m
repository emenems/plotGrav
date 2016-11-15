function legend_save = plotGrav_plotData(plot_axes,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width,plot_type)
%PLOTGRAV_PLOTDATA plot iGrav/Trilogi/Other data
% This function works only with connection to plotGrav GUI!
%
% Input:
%   plot_axes     ...     axes for plotting (vector [left, right])
%   ref_axes      ...     reference axes, used to set X limits (scalar)
%                         if empty, plot_axes will be used.
%   switch_plot   ...     switch between left and right axes
%                         1 ... left axes
%                         2 ... right axes
%                         3 ... both axes (similar to plotyy)
%   data          ...     data for plot (matlab array containing:
%                                           .data_a   
%                                           .data_b
%                                           .data_c
%                                           .data_d
%   plot_axesL    ...     matlab array containing channel numbers for each 
%                         data source (see 'data' variable) to be plotted 
%                         on the left axes
%   plot_axesR    ...     matlab array containing channel numbers for each 
%                         data source (see 'data' variable) to be plotted 
%                         on the right axes
%   line_width    ...     line width. scalar or vector used to set the line
%                         width for current plot (all lines in plot, not
%                         each line separately). Scalar for left or right
%                         plot or vector if both plotted.
%   plot_type     ...     plot type: 1 = standard 'plot', 2 = bar plot, 3 =
%                         area plot, 4 = step, 5 = stairs.
%                         Input is a vector for Left and Right axes
%
% Output:
%   legend_save   ...     cell are containing legend for the left and right
%                         axes
% 
% Example:
%   plotGrav_plotData(a1,[],1,data,plot_axesL,plot_axesR);
% 
% 
%                                                      M.Mikolaj, 19.9.2015

%% Get data
time = get(findobj('Tag','plotGrav_text_status'),'UserData');               % load time
units_data_a = get(findobj('Tag','plotGrav_text_data_a'),'UserData');         % get iGrav units
channels_data_a = get(findobj('Tag','plotGrav_edit_data_a_path'),'UserData'); % get iGrav channels (names)
units_data_b = get(findobj('Tag','plotGrav_text_data_b'),'UserData');     % get TRiLOGi units
channels_data_b = get(findobj('Tag','plotGrav_edit_data_b_path'),'UserData'); % get TRiLOGi channels (names)
units_data_c = get(findobj('Tag','plotGrav_text_data_c'),'UserData');       % get Other1 units
channels_data_c = get(findobj('Tag','plotGrav_edit_data_c_path'),'UserData'); % get Other1 channels (names)
units_data_d = get(findobj('Tag','plotGrav_text_data_d'),'UserData');       % get Other2 units
channels_data_d = get(findobj('Tag','plotGrav_edit_data_d_path'),'UserData'); % get Other2 channels (names)
color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');          % get defined colors
zoom_in = get(findobj('Tag','plotGrav_push_zoom_in'),'UserData');           % zoom values
num_of_ticks_x = get(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData'); % get number of tick for y axis
num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size
nth = get(findobj('Tag','plotGrav_menu_set_data_points'),'UserData'); 		% plot only each nth data. By default 1 = all data points.

switch switch_plot
    case 1
       %% Plot Left
        set(plot_axes(1),'Visible','on','YAxisLocation','left','FontSize',font_size); % make sure the left axes is visible and on the correct side
        set(plot_axes(2),'Visible','off','YAxisLocation','right','FontSize',font_size); % make sure the right axes is not visible and on the correct side
        cur_labelsL = [];                                                   % prepare variable for ylabelsLeft
        cur_legend = [];                                                    % prepare variabel for legend
        if ~isempty(plot_axesL.data_a) && ~isempty(data.data_a)               % plot data_a data if selected/loaded
            switch plot_type(1)
                case 2
                    h1 = bar(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a),1);hold(plot_axes(1),'on') % hX = line specification/handle
                case 3
                    h1 = area(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                case 4
                    h1 = stem(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                case 5
                    h1 = stairs(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                otherwise
                    h1 = plot(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_a(plot_axesL.data_a),[1,length(plot_axesL.data_a)]));      % stack ylabels (only unique will be used at the end)
            cur_legend = horzcat(cur_legend,reshape(channels_data_a(plot_axesL.data_a),[1,length(plot_axesL.data_a)]));      % stack legend 
        else
            h1 = [];
        end
        if ~isempty(plot_axesL.data_b) && ~isempty(data.data_b)           % plot data_b data if selected/loaded
            switch plot_type(1)
                case 2
                    h2 = bar(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b),1);hold(plot_axes(1),'on')
                otherwise
                    h2 = plot(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b));hold(plot_axes(1),'on')
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_b(plot_axesL.data_b),[1,length(plot_axesL.data_b)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_b(plot_axesL.data_b),[1,length(plot_axesL.data_b)]));
        else
            h2 = [];
        end
        if ~isempty(plot_axesL.data_c) && ~isempty(data.data_c)             % plot data_c data if selected/loaded
            switch plot_type(1)
                case 2
                    h3 = bar(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c),1);hold(plot_axes(1),'on')
                case 3
                    h3 = area(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on')
                case 4
                    h3 = stem(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on')
                case 5
                    h3 = stairs(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on')
                otherwise
                    h3 = plot(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on')
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_c(plot_axesL.data_c),[1,length(plot_axesL.data_c)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_c(plot_axesL.data_c),[1,length(plot_axesL.data_c)]));
        else
            h3 = [];
        end
        if ~isempty(plot_axesL.data_d) && ~isempty(data.data_d)             % plot data_d data if selected/loaded
            switch plot_type(1)
                case 2
                    h4 = bar(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d),1);hold(plot_axes(1),'on')
                case 3
                    h4 = area(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on')
                case 4
                    h4 = stem(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on')
                case 5
                    h4 = stairs(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on')
                otherwise
                    h4 = plot(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on')
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_d(plot_axesL.data_d),[1,length(plot_axesL.data_d)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_d(plot_axesL.data_d),[1,length(plot_axesL.data_d)]));
        else
            h4 = [];
        end
        h = [h1(:)',h2(:)',h3(:)',h4(:)'];                                              % stack the line handles
        for c = 1:length(h)
            switch plot_type(1)
                case 2
                    set(h(c),'FaceColor',color_scale(c,:),'EdgeColor','none');
                case 3
                    set(h(c),'FaceColor',color_scale(c,:),'EdgeColor',color_scale(c,:),'LineWidth',line_width(1));
                otherwise
                    set(h(c),'color',color_scale(c,:),'LineWidth',line_width(1));   % change the color of each line + their width
            end
        end
        if get(findobj('Tag','plotGrav_check_grid'),'Value')==1             % show grid if required
            grid(plot_axes(1),'on');                                        % on for left axes
            grid(plot_axes(2),'off');                                       % of for right axes
        else
            grid(plot_axes(1),'off');
            grid(plot_axes(2),'off');
        end
        if get(findobj('Tag','plotGrav_check_labels'),'Value')==1           % show labels if required
            ylabel(plot_axes(1),unique(cur_labelsL),'FontSize',font_size);          % label only for left axes
            ylabel(plot_axes(2),[]);
        else
            ylabel(plot_axes(1),[]);
            ylabel(plot_axes(2),[]);
        end
        if get(findobj('Tag','plotGrav_check_legend'),'Value') ==1          % show legend if required
            l = legend(plot_axes(1),cur_legend);
            set(l,'interpreter','none','FontSize',font_size);               % change font and interpreter (because channels contain spacial sybols like _)
            legend(plot_axes(2),'off');                                     % legend for left axes      
        else
            legend(plot_axes(1),'off');                                     % turn of legends
            legend(plot_axes(2),'off');
        end
        legend_save{1} = cur_legend;
        legend_save{2} = [];
        clear cur_labelsL cur_labelsR h h1 h2 h3 h4 cur_legend              % remove used variables
        
        % Set limits                                                        % get current XLimits
        if ~isempty(ref_axes)
            ref_lim = get(ref_axes(1),'XLim');                              % get reference limits
        else
            ref_lim = get(plot_axes(1),'XLim');                             % get current x limits and use them a reference
        end
        if ~isempty(zoom_in)
            ref_lim = zoom_in;
        end
        xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);                   % create new ticks
        set(plot_axes(1),'YLimMode','auto','XLim',ref_lim,'XTick',xtick_value); % set X limits
        rL1 = get(plot_axes(1),'YLim'); 
        set(plot_axes(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y)); % set Y limits (for unknown reason, this must by done after X limits and 'YLimMode','auto')
        set(plot_axes(2),'Visible','off','XLim',ref_lim,'XTick',xtick_value); % set new X ticks (left)
        linkaxes([plot_axes(1),plot_axes(2)],'x');                          % link axes, just in case
        
    case 2
       %% Plot Right 
        set(plot_axes(1),'Visible','off','YAxisLocation','left','FontSize',font_size);           % turn of left axes
        set(plot_axes(2),'Visible','on','YAxisLocation','right','color','w','FontSize',font_size); % right axes visible and background  color white (otherwise no color)
        cur_labelsR = [];                                                   % prepare variable for ylabelsLeft
        cur_legend = [];                                                    % prepare variabel for legend
        if ~isempty(plot_axesR.data_a) && ~isempty(data.data_a)               % plot data_a data if selected/loaded
            switch plot_type(2)
                case 2
                    h1 = bar(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a),1);hold(plot_axes(2),'on') % hX = line specification/handle
                case 3
                    h1 = area(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                case 4
                    h1 = stem(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                case 5
                    h1 = stairs(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                otherwise
                    h1 = plot(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_a(plot_axesR.data_a),[1,length(plot_axesR.data_a)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_a(plot_axesR.data_a),[1,length(plot_axesR.data_a)]));
        else
            h1 = [];
        end
        if ~isempty(plot_axesR.data_b) && ~isempty(data.data_b)           % plot data_b data if selected/loaded
            switch plot_type(2)
                case 2
                    h2 = bar(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b),1);hold(plot_axes(2),'on')
                case 3
                    h2 = area(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on')
                case 4
                    h2 = stem(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on')
                case 5
                    h2 = stairs(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on')
                otherwise
                    h2 = plot(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on')
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_b(plot_axesR.data_b),[1,length(plot_axesR.data_b)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_b(plot_axesR.data_b),[1,length(plot_axesR.data_b)]));
        else
            h2 = [];
        end
        if ~isempty(plot_axesR.data_c) && ~isempty(data.data_c)             % plot data_c data if selected/loaded
            switch plot_type(2)
                case 2
                    h3 = bar(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c),1);hold(plot_axes(2),'on')
                case 3
                    h3 = area(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on')
                case 4
                    h3 = stem(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on')
                case 5
                    h3 = stairs(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on')
                otherwise
                    h3 = plot(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on')
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_c(plot_axesR.data_c),[1,length(plot_axesR.data_c)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_c(plot_axesR.data_c),[1,length(plot_axesR.data_c)]));
        else
            h3 = [];
        end
        if ~isempty(plot_axesR.data_d) && ~isempty(data.data_d)             % plot data_d data if selected/loaded
            switch plot_type(2)
                case 2
                    h4 = bar(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d),1);hold(plot_axes(2),'on')
                case 3
                    h4 = area(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on')
                case 4
                    h4 = stem(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on')
                case 5
                    h4 = stairs(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on')
                otherwise
                    h4 = plot(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on')
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_d(plot_axesR.data_d),[1,length(plot_axesR.data_d)]));
            cur_legend = horzcat(cur_legend,reshape(channels_data_d(plot_axesR.data_d),[1,length(plot_axesR.data_d)]));
        else
            h4 = [];
        end
        h = [h1(:)',h2(:)',h3(:)',h4(:)'];                                  % stack the line handles
        for c = 1:length(h)
            switch plot_type(2)
                case 2
                    set(h(c),'FaceColor',color_scale(c,:),'EdgeColor','none');
                case 3
                    set(h(c),'FaceColor',color_scale(c,:),'EdgeColor',color_scale(c,:),'LineWidth',line_width(1));
                otherwise
                    set(h(c),'color',color_scale(c,:),'LineWidth',line_width(1));   % change the color of each line + their width
            end
        end
        if get(findobj('Tag','plotGrav_check_grid'),'Value')==1             % show grid if required
            grid(plot_axes(2),'on');                                        % grid only for right axes
            grid(plot_axes(1),'off');
        else
            grid(plot_axes(2),'off');  
            grid(plot_axes(1),'off');                                      
        end
        if get(findobj('Tag','plotGrav_check_labels'),'Value')==1           % show labels if required
            ylabel(plot_axes(2),unique(cur_labelsR),'FontSize',font_size);          % use only unique labels/units
            ylabel(plot_axes(1),[]);
        else
            ylabel(plot_axes(2),[]);                                        % turn of labels
            ylabel(plot_axes(1),[]);
        end
        if get(findobj('Tag','plotGrav_check_legend'),'Value') ==1 % show legend if required
            l = legend(plot_axes(2),cur_legend);
            set(l,'interpreter','none','FontSize',font_size);
            legend(plot_axes(1),'off');
        else
            legend(plot_axes(2),'off');
            legend(plot_axes(1),'off');
        end
        legend_save{2} = cur_legend;
        legend_save{1} = [];
        clear cur_labelsR cur_labelsR h h1 h2 h3 h4 cur_legend  % remove used variables
        
        % Set limits                                                        % get current XLimits
        if ~isempty(ref_axes)
            ref_lim = get(ref_axes(1),'XLim');                              % get reference limits
        else
            ref_lim = get(plot_axes(2),'XLim');                             % get current x limits and use them a reference
        end
        if ~isempty(zoom_in)
            ref_lim = zoom_in;
        end
        xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);                   % create new ticks
        set(plot_axes(2),'YLimMode','auto','XLim',ref_lim,'XTick',xtick_value);
        rR1 = get(plot_axes(2),'YLim');    
        set(plot_axes(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y));
        set(plot_axes(1),'Visible','off','XLim',ref_lim,'XTick',xtick_value); % set new X ticks (right)
        linkaxes([plot_axes(1),plot_axes(2)],'x');                          % link axes, just in case
        
    case 3
        %% Plot Left and Right
        cur_labelsL = [];                                                   % prepare variable for ylabelsLeft
        cur_legendL = [];                                                   % prepare variabel for legend
        if ~isempty(plot_axesL.data_a) && ~isempty(data.data_a)               % plot data_a data if selected/loaded
            switch plot_type(1)
                case 2
                    h1l = bar(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a),1);hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h1l,'EdgeColor','none');
                case 3
                    h1l = area(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h1l,'LineWidth',line_width(1),'EdgeColor','none');
                case 4
                    h1l = stem(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h1l,'LineWidth',line_width(1));
                case 5
                    h1l = stairs(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h1l,'LineWidth',line_width(1));
                otherwise
                    h1l = plot(plot_axes(1),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesL.data_a));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h1l,'LineWidth',line_width(1));                             % Unlike in previous code, the line width must be set for left and right plot separately
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_a(plot_axesL.data_a),[1,length(plot_axesL.data_a)]));
            cur_legendL = horzcat(cur_legendL,reshape(channels_data_a(plot_axesL.data_a),[1,length(plot_axesL.data_a)]));
        else
            h1l = [];
        end
        if ~isempty(plot_axesL.data_b) && ~isempty(data.data_b)           % plot data_b data if selected/loaded
            switch plot_type(1)
                case 2
                    h2l = bar(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b),1);hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h2l,'EdgeColor','none');
                case 3
                    h2l = area(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h2l,'LineWidth',line_width(1),'EdgeColor','none'); 
                case 4
                    h2l = stem(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h2l,'LineWidth',line_width(1)); 
                case 5
                    h2l = stairs(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h2l,'LineWidth',line_width(1)); 
                otherwise
                    h2l = plot(plot_axes(1),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesL.data_b));hold(plot_axes(1),'on')
                    set(h2l,'LineWidth',line_width(1));                             % set line width for left and right plot separately
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_b(plot_axesL.data_b),[1,length(plot_axesL.data_b)]));
            cur_legendL = horzcat(cur_legendL,reshape(channels_data_b(plot_axesL.data_b),[1,length(plot_axesL.data_b)]));
        else
            h2l = [];
        end
        if ~isempty(plot_axesL.data_c) && ~isempty(data.data_c)             % plot data_c data if selected/loaded
            switch plot_type(1)
                case 2
                    h3l = bar(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c),1);hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h3l,'EdgeColor','none');
                case 3
                    h3l = area(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h3l,'LineWidth',line_width(1),'EdgeColor','none');
                case 4
                    h3l = stem(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h3l,'LineWidth',line_width(1));
                case 5
                    h3l = stairs(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h3l,'LineWidth',line_width(1));
                otherwise
                    h3l = plot(plot_axes(1),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesL.data_c));hold(plot_axes(1),'on')
                    set(h3l,'LineWidth',line_width(1));                             % set line width for left and right plot separately
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_c(plot_axesL.data_c),[1,length(plot_axesL.data_c)]));
            cur_legendL = horzcat(cur_legendL,reshape(channels_data_c(plot_axesL.data_c),[1,length(plot_axesL.data_c)]));
        else
            h3l = [];
        end
        if ~isempty(plot_axesL.data_d) && ~isempty(data.data_d)             % plot data_d data if selected/loaded
            switch plot_type(1)
                case 2
                    h4l = bar(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d),1);hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h4l,'EdgeColor','none');
                case 3
                    h4l = area(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h4l,'LineWidth',line_width(1),'EdgeColor','none');
                case 4
                    h4l = stem(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h4l,'LineWidth',line_width(1));
                case 5
                    h4l = stairs(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on') % hX = line specification/handle
                    set(h4l,'LineWidth',line_width(1));
                otherwise
                    h4l = plot(plot_axes(1),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesL.data_d));hold(plot_axes(1),'on')
                    set(h4l,'LineWidth',line_width(1));                             % set line width for left and right plot separately
            end
            cur_labelsL = horzcat(cur_labelsL,reshape(units_data_d(plot_axesL.data_d),[1,length(plot_axesL.data_d)]));
            cur_legendL = horzcat(cur_legendL,reshape(channels_data_d(plot_axesL.data_d),[1,length(plot_axesL.data_d)]));
        else
            h4l = [];
        end

        cur_legendR = [];
        cur_labelsR = [];                                                   % prepare variable for ylabelsLeft
        if ~isempty(plot_axesR.data_a) && ~isempty(data.data_a)               % plot data_a data if selected/loaded
            switch plot_type(2)
                case 2
                    h1r = bar(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a),1);hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h1r,'EdgeColor','none');
                case 3
                    h1r = area(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h1r,'LineWidth',line_width(2),'EdgeColor','none');
                case 4
                    h1r = stem(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h1r,'LineWidth',line_width(2));
                case 5
                    h1r = stairs(plot_axes(2),time.data_a(1:nth:end),data.data_a(1:nth:end,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h1r,'LineWidth',line_width(2));
                otherwise
                    h1r = plot(plot_axes(2),time.data_a,data.data_a(:,plot_axesR.data_a));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h1r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_a(plot_axesR.data_a),[1,length(plot_axesR.data_a)]));
            cur_legendR = horzcat(cur_legendR,reshape(channels_data_a(plot_axesR.data_a),[1,length(plot_axesR.data_a)]));
        else
            h1r = [];
        end
        if ~isempty(plot_axesR.data_b) && ~isempty(data.data_b)           % plot data_b data if selected/loaded
            switch plot_type(2)
                case 2
                    h2r = bar(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b),1);hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h2r,'EdgeColor','none');
                case 3
                    h2r = area(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h2r,'LineWidth',line_width(2),'EdgeColor','none');
                case 4
                    h2r = stem(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h2r,'LineWidth',line_width(2));
                case 5
                    h2r = stairs(plot_axes(2),time.data_b(1:nth:end),data.data_b(1:nth:end,plot_axesR.data_b));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h2r,'LineWidth',line_width(2));
                otherwise
                    h2r = plot(plot_axes(2),time.data_b,data.data_b(:,plot_axesR.data_b));hold(plot_axes(2),'on')
                    set(h2r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_b(plot_axesR.data_b),[1,length(plot_axesR.data_b)]));
            cur_legendR = horzcat(cur_legendR,reshape(channels_data_b(plot_axesR.data_b),[1,length(plot_axesR.data_b)]));
        else
            h2r = [];
        end
        if ~isempty(plot_axesR.data_c) && ~isempty(data.data_c)             % plot data_c data if selected/loaded
            switch plot_type(2)
                case 2
                    h3r = bar(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c),1);hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h3r,'EdgeColor','none');
                case 3
                    h3r = area(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h3r,'LineWidth',line_width(2),'EdgeColor','none'); 
                case 4
                    h3r = stem(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h3r,'LineWidth',line_width(2)); 
                case 5
                    h3r = stairs(plot_axes(2),time.data_c(1:nth:end),data.data_c(1:nth:end,plot_axesR.data_c));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h3r,'LineWidth',line_width(2)); 
                otherwise
                    h3r = plot(plot_axes(2),time.data_c,data.data_c(:,plot_axesR.data_c));hold(plot_axes(2),'on')
                    set(h3r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_c(plot_axesR.data_c),[1,length(plot_axesR.data_c)]));
            cur_legendR = horzcat(cur_legendR,reshape(channels_data_c(plot_axesR.data_c),[1,length(plot_axesR.data_c)]));
        else
            h3r = [];
        end
        if ~isempty(plot_axesR.data_d) && ~isempty(data.data_d)             % plot data_d data if selected/loaded
            switch plot_type(2)
                case 2
                    h4r = bar(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d),1);hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h4r,'EdgeColor','none');
                case 3
                    h4r = area(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h4r,'LineWidth',line_width(2),'EdgeColor','none');
                case 4
                    h4r = stem(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h4r,'LineWidth',line_width(2));
                case 5
                    h4r = stairs(plot_axes(2),time.data_d(1:nth:end),data.data_d(1:nth:end,plot_axesR.data_d));hold(plot_axes(2),'on') % hX = line specification/handle
                    set(h4r,'LineWidth',line_width(2));
                otherwise
                    h4r = plot(plot_axes(2),time.data_d,data.data_d(:,plot_axesR.data_d));hold(plot_axes(2),'on')
                    set(h4r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            end
            cur_labelsR = horzcat(cur_labelsR,reshape(units_data_d(plot_axesR.data_d),[1,length(plot_axesR.data_d)]));
            cur_legendR = horzcat(cur_legendR,reshape(channels_data_d(plot_axesR.data_d),[1,length(plot_axesR.data_d)]));
        else
            h4r = [];
        end
        h = [h1l(:)',h2l(:)',h3l(:)',h4l(:)',...
             h1r(:)',h2r(:)',h3r(:)',h4r(:)'];                                          % stack the line handles (for right and left axes)
        for c = 1:length(h)
            try 
                set(h(c),'FaceColor',color_scale(c,:),'EdgeColor','none');
            catch
                set(h(c),'color',color_scale(c,:));   % change the color of each line + their width
            end
        end
        if get(findobj('Tag','plotGrav_check_grid'),'Value')==1             % show grid if required
            grid(plot_axes(1),'on');
            grid(plot_axes(2),'off');                                       % off, left and right are identical (see below = 'XTick')
        else
            grid(plot_axes(1),'off');
            grid(plot_axes(2),'off');
        end
        if get(findobj('Tag','plotGrav_check_labels'),'Value')==1           % show labels if required
            ylabel(plot_axes(1),unique(cur_labelsL),'FontSize',font_size);
            ylabel(plot_axes(2),unique(cur_labelsR),'FontSize',font_size);
        else
            ylabel(plot_axes(2),[]);
            ylabel(plot_axes(1),[]);
        end
        if get(findobj('Tag','plotGrav_check_legend'),'Value') ==1          % show legend if required
            l = legend(plot_axes(1),cur_legendL);                           % left legend
            set(l,'interpreter','none','FontSize',font_size,'Location','NorthWest');
            l = legend(plot_axes(2),cur_legendR);                           % legend on right
            set(l,'interpreter','none','FontSize',font_size,'Location','NorthEast');
        else
            legend(plot_axes(2),'off');
            legend(plot_axes(1),'off');
        end
        legend_save{1} = cur_legendL;
        legend_save{2} = cur_legendR;
        clear cur_labelsR cur_labelsR h h1 h2 h3 h4 cur_legendL cur_legendR  % remove used variables

        % Set limits                                                        % get current XLimits
        if ~isempty(ref_axes)
            ref_lim = get(ref_axes(1),'XLim');                              % get reference limits
        else
            ref_lim = get(plot_axes(2),'XLim');                             % get current x limits and use them a reference
        end
        if ~isempty(zoom_in)
            ref_lim = zoom_in;
        end
        xtick_value = linspace(ref_lim(1),ref_lim(2),num_of_ticks_x);                   % create new ticks
        set(plot_axes(1),'YLimMode','auto','Visible','on','YAxisLocation','left','XLim',ref_lim,'XTick',xtick_value,'FontSize',font_size);
        set(plot_axes(2),'YLimMode','auto','Visible','on','YAxisLocation','right','color','none','XLim',ref_lim,'XTick',xtick_value,'XTickLabel',[],'FontSize',font_size);
%         axes(plot_axes(2));                                                 % set R1 as current axes
        rL1 = get(plot_axes(1),'YLim');                                     % get current limits for left axes
        rR1 = get(plot_axes(2),'YLim');                                     % get current limits for right axes
        set(plot_axes(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));
        set(plot_axes(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y));
        linkaxes([plot_axes(1),plot_axes(2)],'x');                          % link axes, just in case
        
end                                                                         % end switch

end                                                                         % end function