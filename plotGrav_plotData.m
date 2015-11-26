function legend_save = plotGrav_plotData(plot_axes,ref_axes,switch_plot,data,plot_axesL,plot_axesR,line_width)
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
%                                           .igrav     
%                                           .trilogi
%                                           .other1
%                                           .other2
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
units_igrav = get(findobj('Tag','plotGrav_text_igrav'),'UserData');         % get iGrav units
channels_igrav = get(findobj('Tag','plotGrav_edit_igrav_path'),'UserData'); % get iGrav channels (names)
units_trilogi = get(findobj('Tag','plotGrav_text_trilogi'),'UserData');     % get TRiLOGi units
channels_trilogi = get(findobj('Tag','plotGrav_edit_trilogi_path'),'UserData'); % get TRiLOGi channels (names)
units_other1 = get(findobj('Tag','plotGrav_text_other1'),'UserData');       % get Other1 units
channels_other1 = get(findobj('Tag','plotGrav_edit_other1_path'),'UserData'); % get Other1 channels (names)
units_other2 = get(findobj('Tag','plotGrav_text_other2'),'UserData');       % get Other2 units
channels_other2 = get(findobj('Tag','plotGrav_edit_other2_path'),'UserData'); % get Other2 channels (names)
color_scale = get(findobj('Tag','plotGrav_text_nms2'),'UserData');          % get defined colors
zoom_in = get(findobj('Tag','plotGrav_push_zoom_in'),'UserData');           % zoom values
num_of_ticks_x = get(findobj('Tag','plotGrav_menu_num_of_ticks_x'),'UserData'); % get number of tick for y axis
num_of_ticks_y = get(findobj('Tag','plotGrav_menu_num_of_ticks_y'),'UserData'); % get number of tick for y axis
font_size = get(findobj('Tag','plotGrav_menu_set_font_size'),'UserData');   % get font size

switch switch_plot
    case 1
       %% Plot Left
        set(plot_axes(1),'Visible','on','YAxisLocation','left'); % make sure the left axes is visible and on the correct side
        set(plot_axes(2),'Visible','off','YAxisLocation','right'); % make sure the right axes is not visible and on the correct side
        cur_labelsL = [];                                                   % prepare variable for ylabelsLeft
        cur_legend = [];                                                    % prepare variabel for legend
        if ~isempty(plot_axesL.igrav) && ~isempty(data.igrav)               % plot igrav data if selected/loaded
            h1 = plot(plot_axes(1),time.igrav,data.igrav(:,plot_axesL.igrav));hold(plot_axes(1),'on') % hX = line specification/handle
            cur_labelsL = vertcat(cur_labelsL,units_igrav(plot_axesL.igrav));      % stack ylabels (only unique will be used at the end)
            cur_legend = vertcat(cur_legend,channels_igrav(plot_axesL.igrav));     % stack legend 
        else
            h1 = [];
        end
        if ~isempty(plot_axesL.trilogi) && ~isempty(data.trilogi)           % plot trilogi data if selected/loaded
            h2 = plot(plot_axes(1),time.trilogi,data.trilogi(:,plot_axesL.trilogi));hold(plot_axes(1),'on')
            cur_labelsL = vertcat(cur_labelsL,units_trilogi(plot_axesL.trilogi));
            cur_legend = vertcat(cur_legend,channels_trilogi(plot_axesL.trilogi));
        else
            h2 = [];
        end
        if ~isempty(plot_axesL.other1) && ~isempty(data.other1)             % plot other1 data if selected/loaded
            h3 = plot(plot_axes(1),time.other1,data.other1(:,plot_axesL.other1));hold(plot_axes(1),'on')
            cur_labelsL = vertcat(cur_labelsL,units_other1(plot_axesL.other1));
            cur_legend = vertcat(cur_legend,channels_other1(plot_axesL.other1));
        else
            h3 = [];
        end
        if ~isempty(plot_axesL.other2) && ~isempty(data.other2)             % plot other2 data if selected/loaded
            h4 = plot(plot_axes(1),time.other2,data.other2(:,plot_axesL.other2));hold(plot_axes(1),'on')
            cur_labelsL = vertcat(cur_labelsL,units_other2(plot_axesL.other2));
            cur_legend = vertcat(cur_legend,channels_other2(plot_axesL.other2));
        else
            h4 = [];
        end
        h = [h1',h2',h3',h4'];                                              % stack the line handles
        for c = 1:length(h)
            set(h(c),'color',color_scale(c,:),'LineWidth',line_width(1));   % change the color of each line + their width
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
        set(plot_axes(1),'Visible','off','YAxisLocation','left');           % turn of left axes
        set(plot_axes(2),'Visible','on','YAxisLocation','right','color','w'); % right axes visible and background  color white (otherwise no color)
        cur_labelsR = [];                                                   % prepare variable for ylabelsLeft
        cur_legend = [];                                                    % prepare variabel for legend
        if ~isempty(plot_axesR.igrav) && ~isempty(data.igrav)               % plot igrav data if selected/loaded
            h1 = plot(plot_axes(2),time.igrav,data.igrav(:,plot_axesR.igrav));hold(plot_axes(2),'on') % hX = line specification/handle
            cur_labelsR = vertcat(cur_labelsR,units_igrav(plot_axesR.igrav));
            cur_legend = vertcat(cur_legend,channels_igrav(plot_axesR.igrav));
        else
            h1 = [];
        end
        if ~isempty(plot_axesR.trilogi) && ~isempty(data.trilogi)           % plot trilogi data if selected/loaded
            h2 = plot(plot_axes(2),time.trilogi,data.trilogi(:,plot_axesR.trilogi));hold(plot_axes(2),'on')
            cur_labelsR = vertcat(cur_labelsR,units_trilogi(plot_axesR.trilogi));
            cur_legend = vertcat(cur_legend,channels_trilogi(plot_axesR.trilogi));
        else
            h2 = [];
        end
        if ~isempty(plot_axesR.other1) && ~isempty(data.other1)             % plot other1 data if selected/loaded
            h3 = plot(plot_axes(2),time.other1,data.other1(:,plot_axesR.other1));hold(plot_axes(2),'on')
            cur_labelsR = vertcat(cur_labelsR,units_other1(plot_axesR.other1));
            cur_legend = vertcat(cur_legend,channels_other1(plot_axesR.other1));
        else
            h3 = [];
        end
        if ~isempty(plot_axesR.other2) && ~isempty(data.other2)             % plot other2 data if selected/loaded
            h4 = plot(plot_axes(2),time.other2,data.other2(:,plot_axesR.other2));hold(plot_axes(2),'on')
            cur_labelsR = vertcat(cur_labelsR,units_other2(plot_axesR.other2));
            cur_legend = vertcat(cur_legend,channels_other2(plot_axesR.other2));
        else
            h4 = [];
        end
        h = [h1',h2',h3',h4'];                                              % stack the line handles
        for c = 1:length(h)
            set(h(c),'color',color_scale(c,:),'LineWidth',line_width(1));   % change the color of each line + width
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
        if ~isempty(plot_axesL.igrav) && ~isempty(data.igrav)               % plot igrav data if selected/loaded
            h1l = plot(plot_axes(1),time.igrav,data.igrav(:,plot_axesL.igrav));hold(plot_axes(1),'on') % hX = line specification/handle
            set(h1l,'LineWidth',line_width(1));                             % Unlike in previous code, the line width must be set for left and right plot separately
            cur_labelsL = vertcat(cur_labelsL,units_igrav(plot_axesL.igrav));
            cur_legendL = vertcat(cur_legendL,channels_igrav(plot_axesL.igrav));
        else
            h1l = [];
        end
        if ~isempty(plot_axesL.trilogi) && ~isempty(data.trilogi)           % plot trilogi data if selected/loaded
            h2l = plot(plot_axes(1),time.trilogi,data.trilogi(:,plot_axesL.trilogi));hold(plot_axes(1),'on')
            set(h2l,'LineWidth',line_width(1));                             % set line width for left and right plot separately
            cur_labelsL = vertcat(cur_labelsL,units_trilogi(plot_axesL.trilogi));
            cur_legendL = vertcat(cur_legendL,channels_trilogi(plot_axesL.trilogi));
        else
            h2l = [];
        end
        if ~isempty(plot_axesL.other1) && ~isempty(data.other1)             % plot other1 data if selected/loaded
            h3l = plot(plot_axes(1),time.other1,data.other1(:,plot_axesL.other1));hold(plot_axes(1),'on')
            set(h3l,'LineWidth',line_width(1));                             % set line width for left and right plot separately
            cur_labelsL = vertcat(cur_labelsL,units_other1(plot_axesL.other1));
            cur_legendL = vertcat(cur_legendL,channels_other1(plot_axesL.other1));
        else
            h3l = [];
        end
        if ~isempty(plot_axesL.other2) && ~isempty(data.other2)             % plot other2 data if selected/loaded
            h4l = plot(plot_axes(1),time.other2,data.other2(:,plot_axesL.other2));hold(plot_axes(1),'on')
            set(h4l,'LineWidth',line_width(1));                             % set line width for left and right plot separately
            cur_labelsL = vertcat(cur_labelsL,units_other2(plot_axesL.other2));
            cur_legendL = vertcat(cur_legendL,channels_other2(plot_axesL.other2));
        else
            h4l = [];
        end

        cur_legendR = [];
        cur_labelsR = [];                                                   % prepare variable for ylabelsLeft
        if ~isempty(plot_axesR.igrav) && ~isempty(data.igrav)               % plot igrav data if selected/loaded
            h1r = plot(plot_axes(2),time.igrav,data.igrav(:,plot_axesR.igrav));hold(plot_axes(2),'on') % hX = line specification/handle
            set(h1r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            cur_labelsR = vertcat(cur_labelsR,units_igrav(plot_axesR.igrav));
            cur_legendR = vertcat(cur_legendR,channels_igrav(plot_axesR.igrav));
        else
            h1r = [];
        end
        if ~isempty(plot_axesR.trilogi) && ~isempty(data.trilogi)           % plot trilogi data if selected/loaded
            h2r = plot(plot_axes(2),time.trilogi,data.trilogi(:,plot_axesR.trilogi));hold(plot_axes(2),'on')
            set(h2r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            cur_labelsR = vertcat(cur_labelsR,units_trilogi(plot_axesR.trilogi));
            cur_legendR = vertcat(cur_legendR,channels_trilogi(plot_axesR.trilogi));
        else
            h2r = [];
        end
        if ~isempty(plot_axesR.other1) && ~isempty(data.other1)             % plot other1 data if selected/loaded
            h3r = plot(plot_axes(2),time.other1,data.other1(:,plot_axesR.other1));hold(plot_axes(2),'on')
            set(h3r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            cur_labelsR = vertcat(cur_labelsR,units_other1(plot_axesR.other1));
            cur_legendR = vertcat(cur_legendR,channels_other1(plot_axesR.other1));
        else
            h3r = [];
        end
        if ~isempty(plot_axesR.other2) && ~isempty(data.other2)             % plot other2 data if selected/loaded
            h4r = plot(plot_axes(2),time.other2,data.other2(:,plot_axesR.other2));hold(plot_axes(2),'on')
            set(h4r,'LineWidth',line_width(2));                             % set line width for left and right plot separately
            cur_labelsR = vertcat(cur_labelsR,units_other2(plot_axesR.other2));
            cur_legendR = vertcat(cur_legendR,channels_other2(plot_axesR.other2));
        else
            h4r = [];
        end
        h = [h1l',h2l',h3l',h4l',...
             h1r',h2r',h3r',h4r'];                                          % stack the line handles (for right and left axes)
        for c = 1:length(h)
            set(h(c),'color',color_scale(c,:));                             % change the color of each line
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
        set(plot_axes(1),'YLimMode','auto','Visible','on','YAxisLocation','left','XLim',ref_lim,'XTick',xtick_value);
        set(plot_axes(2),'YLimMode','auto','Visible','on','YAxisLocation','right','color','none','XLim',ref_lim,'XTick',xtick_value,'XTickLabel',[]);
%         axes(plot_axes(2));                                                 % set R1 as current axes
        rL1 = get(plot_axes(1),'YLim');                                     % get current limits for left axes
        rR1 = get(plot_axes(2),'YLim');                                     % get current limits for right axes
        set(plot_axes(1),'YTick',linspace(rL1(1),rL1(2),num_of_ticks_y));
        set(plot_axes(2),'YTick',linspace(rR1(1),rR1(2),num_of_ticks_y));
        linkaxes([plot_axes(1),plot_axes(2)],'x');                          % link axes, just in case
        
end                                                                         % end switch

end                                                                         % end function