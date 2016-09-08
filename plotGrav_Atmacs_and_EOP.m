function [pol_corr,lod_corr,atmo_corr,pressure,corr_check] = plotGrav_Atmacs_and_EOP(ref_time,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo)
%FUNCTION PLOTGRAV_ATMACS_AND_EOP Polar motion, LOD and atmo correction
% This function computes the polar motion correction, length of day 
% correction and Atmacs atmospheric correction (add to time series to
% correct them). This function also predicts the polar motion effect!
% Prediction works only with time series starting 2003!
% 
% Input:
%   ref_time            ...     input time vector (in matlab format)
%   Lat                 ...     latitude of the gravimter (degrees)
%   Lon                 ...     longitude of the gravimter (degrees)
%   atmacs_url_link_loc ...     atmacs url to local component (lm). Set
%                               either one string or cell containing all
%                               urls. In such case, the downloaded time
%                               series will be concatenated. Set the links
%                               in chronological order! 
%                               If atmacs_url_link_loc is empty and
%                               atmacs_url_link_glo NOT then global model
%                               convering whole Earth is assumed to be
%                               used.
%   atmacs_url_link_glo ...     atmacs url to global componentet. Set
%                               either one string or cell containing all
%                               urls. In such case, the downloaded time
%                               series will be concatenated. Set the links
%                               in chronological order!
% 
% Output:
%   pol_corr            ...     polar motion correction (nm/s^2)
%   lod_corr            ...     length of day correction (nm/s^2)
%   atmo_corr           ...     atmacs atmospheric correction (nm/s^2)
%   pressure            ...     pressure (Pa) for computation of residual
%                               atmospheric effect.
%   corr_check          ...     correction check 1 == OK, 0 == not computed
%                               [pol,LOD,atmo];
% 
% Example:
%   ref_time = [datenum(2012,1,1,12,0,0)];
%   Lat = 49;
%   Lon = 12;
%   atmacs_url_link_loc = 'http://atmacs.bkg.bund.de/data/results/lm/we_lm2_12km_19deg.grav';
%   atmacs_url_link_glo = 'http://atmacs.bkg.bund.de/data/results/icon/we_icon384_19deg.grav';  
%   [pol_corr,lod_corr,atmo_corr,pressure,corr_check] = plotGrav_Atmacs_and_EOP(ref_time,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo);
% 
% 
%                                                   M.Mikolaj, 20.07.2015
%                                                   mikolaj@gfz-potsdam.de

%% Set constants
w = 72921151.467064/10^12;                                                  % angular velocity
R = 6371008;                                                                % radius of replacement sphere (m)

%%%%%%%%%%%%%%%% POLAR MOTION + LOD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read EOP Paris C04 data
try
    if isempty(Lat) || isempty(Lon)                                         % do not compute if no input
        corr_check(1:2) = 0;
        lod_corr = NaN;
        pol_corr = NaN;
    else
        url_link_pol = 'http://hpiers.obspm.fr/iers/eop/eopc04/eopc04_IAU2000.62-now';  % url to EOP data
        url_header = 673;                                                           % number of neader characters (not rows!)
        url_rows = 156;                                                             % number of characters in a row (now data columns!)
        str = urlread(url_link_pol);                                                    % get url string
        str = str(url_header:end);                                                  % cut off header
        str_mat = reshape(str,url_rows,length(str)/url_rows);                       % reshape to row oriented matrix

        %% Transform time
        year = str_mat(1:4,:)';                                                     % select year
        month = str_mat(6:8,:)';
        day = str_mat(9:12,:)';
        x_str = str_mat(20:30,:)';
        y_str = str_mat(31:41,:)';
        lod_str = str_mat(54:65,:)';
        time_eop(1:size(year,1),1) = NaN;                                           % prepare variables
        x(1:size(year,1),1) = NaN;
        y(1:size(year,1),1) = NaN;
        lod(1:size(year,1),1) = NaN;
        for li = 1:size(year,1)                                                     % convert strings to doubles
            time_eop(li,1) = datenum(str2double(year(li,:)),str2double(month(li,:)),str2double(day(li,:))); % time vector (in matlab format)
            x(li,1) = str2double(x_str(li,:));                                      % x pol
            y(li,1) = str2double(y_str(li,:));                                      % y pol
            lod(li,1) = str2double(lod_str(li,:));                                  % length of day
        end
        x = (x/3600)*pi/180;                                                        % convert to radians
        y = (y/3600)*pi/180;
        lod = lod*1000;                                                             % to ms
        domega = (-0.843994809*lod)/10^12;                                          % aux variable

        pol_corr = -1.16*R*w^2*sind(2*Lat)*(x*cosd(Lon) - y*sind(Lon))*10^9;        % polar motion CORRECTION
        lod_corr = 1.16*2*w*R*cosd(Lat)^2*domega*10^9;                              % LOD CORRECTION
        
        %% Predict polar motion (EOP have one month delay)
        if ref_time(end) > (now - 32)                                       % predict only if necesary 
            ref_time_fit = [now - 365*12:1:now]';                           % time for Polar motion prediction (longer time series so better fit parameters can be estimated)
            ref_pol_fit = interp1(time_eop,pol_corr,ref_time_fit);          % y-values for further fitting (must have same resolution as ref_time_fit)
            % Prepare date for matlab 'fit' function 
            mean_val_fit = mean(ref_pol_fit(~isnan(ref_pol_fit)));          % Remove mean as sine fitting will be used (sine oscilates arount 0).
            [xData, yData] = prepareCurveData(ref_time_fit,ref_pol_fit - mean_val_fit); 
            % fit 5 sine waves. This was obtained after manual expriment with 
            % real data (12 years) seeking minimum residual error. Obtained
            % Residuals (max error) < 7.1 nm/s^2, RMSE = 2.6 nm/s^2. 
            ft = fittype('sin5');  
            opts = fitoptions(ft);
    %         opts = fitoptions('Method','NonlinearLeastSquares');          % additional fit options (R2014b). 
            opts.Display = 'Off';
            try
                [fitresult, ~] = fit(xData,yData,ft,opts);                  % In some matlab versions, 'fit', in others 'Fit'=> try out.
            catch error_message
                if strcmp(error_message.identifier,'MATLAB:dispatcher:InexactCaseMatch')
                    [fitresult, ~] = Fit(xData,yData,ft,opts);
                end
            end
            out_fit = feval(fitresult,ref_time_fit);                        % covert estimated parameters back to time series
            % Adjust the fit to input time (shift to fit/merge the
            % last value)
            pol_corr = vertcat(yData(1:end-1),out_fit(ref_time_fit >= xData(end)) - (out_fit(ref_time_fit == xData(end)) - yData(end)));
            % Re-interpolate to new resolution (iGrav)
            pol_corr = interp1(ref_time_fit,pol_corr,ref_time)+mean_val_fit;
        else
            pol_corr = interp1(time_eop,pol_corr,ref_time);
        end
                    
        %% Interpolate LOD to output time 
        % No prediction (too complicated and effect too small)
        lod_corr = interp1(time_eop,lod_corr,ref_time);
        corr_check(1:2) = 1;
        clear year month day x y lod domega str str_mat x_str y_str w R li lod_str url_link url_header url_rows
    end
catch
    corr_check(1:2) = 0;
    lod_corr = NaN;
    pol_corr = NaN;
end
%%%%%%%%%%%%%%%%%%%% ATMACS CORRECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    %% Read Atmacs data
    if isempty(atmacs_url_link_loc) && isempty(atmacs_url_link_glo)          % do not compute if no input
        corr_check(3) = 0;
        atmo_corr = NaN;
        pressure = NaN;
    % Read Global model data only (ICON), i.e. one file contain all
    % required time series
    elseif isempty(atmacs_url_link_loc) && ~isempty(atmacs_url_link_glo)
        url_header = 1;                                                     % number of header characters (not rows!)
        url_rows = 64;                                                      % number of characters in a row (now data columns!)
        % Run loop for all input links. The time series will be than
        % concatenated. First though, check if user set one url link 
        % (=> not a cell) or number of links as cell 
        if ~iscell(atmacs_url_link_glo)
            % Convert to cell so it can be used in following loop (= go
            % through all links in the cell array)
            atmacs_url_link_glo = {atmacs_url_link_glo};
        end
        % Declare vector for appending
        time_total = [];
        l_total = [];
        g_total = [];
        d_total = [];
        p_total = [];
        for i = 1:length(atmacs_url_link_glo)
            % get url string
            str = urlread(atmacs_url_link_glo{i});   
            % cut off header (useful only if only if url_header ~= 1)
            str = str(url_header:end);         
            % reshape to row oriented matrix
            str_mat = reshape(str,url_rows,length(str)/url_rows);   
            % Get/extract all columns
            year = str_mat(1:4,:)';
            month = str_mat(5:6,:)';
            day = str_mat(7:8,:)';
            hour = str_mat(9:10,:)';
            p_str = str_mat(12:25,:)';
            l_str = str_mat(26:38,:)';
            g_str = str_mat(39:50,:)';
            d_str = str_mat(51:63,:)';
            % Declare variables
            time_glo(1:size(year),1) = NaN;
            p(1:size(year),1) = NaN;
            l(1:size(year),1) = NaN;
            g(1:size(year),1) = NaN;
            d(1:size(year),1) = NaN;
            % convert strings to doubles
            for li = 1:size(year,1)    
                % time vector (in matlab format)
                time_glo(li,1) = datenum(str2double(year(li,:)),str2double(month(li,:)),str2double(day(li,:)),str2double(hour(li,:)),0,0); 
                % pressure in Pa!
                p(li,1) = str2double(p_str(li,:));     
                % local part (m/s^2)
                l(li,1) = str2double(l_str(li,:)); 
                % global part (m/s^2)
                g(li,1) = str2double(g_str(li,:));   
                % Deformation part
                d(li,1) = str2double(d_str(li,:));   
            end
            % Concatenate
            if isempty(time_total) % for the first data set
                time_total = time_glo;
                l_total = l;
                g_total = g;
                d_total = d;
                p_total = p;
            else
                % Check date (for overlapping or missing data)
                r = find(time_total(end) == time_glo);
                % No such time exist => check how big is the gap
                if isempty(r)
                    time_diff = time_total(end) - time_glo(1);
                    time_res = time_total(end) - time_total(end-1);
                    % If the missing data is > then model resolution insert
                    % NaN (for further interpolation). Multiply by 2 to
                    % take increase of resolution into account
                    if (time_diff*-1 > time_res*2) && (time_diff < 0)
                        time_total = vertcat(time_total,time_total(end)+time_res,time_glo);
                        l_total = vertcat(l_total,NaN,l);
                        g_total = vertcat(g_total,NaN,g);
                        d_total = vertcat(d_total,NaN,d);
                        p_total = vertcat(p_total,NaN,p);
                    elseif (time_diff*-1 <= time_res*2) && (time_diff < 0)
                        time_total = vertcat(time_total,time_glo);
                        l_total = vertcat(l_total,l);
                        g_total = vertcat(g_total,g);
                        d_total = vertcat(d_total,d);
                        p_total = vertcat(p_total,p);
                    elseif time_diff > 0
                        % In case the current time series starts before
                        % already loaded + no overlapping
                        time_total = vertcat(time_total,time_total(end)+time_res);
                        l_total = vertcat(l_total,NaN);
                        g_total = vertcat(g_total,NaN);
                        d_total = vertcat(d_total,NaN);
                        p_total = vertcat(p_total,NaN);
                    end  
                else
                    % In case overlapping exist, check for offsets
                    l_diff = l_total(end) - l(r);
                    g_diff = g_total(end) - g(r);
                    d_diff = d_total(end) - d(r);
                    p_diff = p_total(end) - p(r);
                    % Apply offsets
                    time_total = vertcat(time_total,time_glo(r+1:end));
                    l_total = vertcat(l_total,l(r+1:end)+l_diff);
                    g_total = vertcat(g_total,g(r+1:end)+g_diff);
                    d_total = vertcat(d_total,d(r+1:end)+d_diff);
                    p_total = vertcat(p_total,p(r+1:end)+p_diff);
                end
            end
            clear l_diff g_diff d_diff p_diff l g d p time_glo year month day hour g_str d_str l_str p_str str str_mat li
        end
        % Add all effects + interpolate to ref time vecotr + convert to nm/s^2
        atmo_corr = interp1(time_total,l_total+g_total+d_total,ref_time)*1e+9;
        % Interpolate pressure vector
        pressure = interp1(time_total,p_total,ref_time);
        corr_check(3) = 1;
    % Read Global and local data
    else
        url_header = 1;                                                             % number of header characters (not rows!)
        url_rows = 51;                                                              % number of characters in a row (now data columns!)
        % Run loop for all input links. The time series will be than
        % concatenated. First though, check if user set one url link 
        % (=> not a cell) or number of links as cell 
        if ~iscell(atmacs_url_link_loc)
            % Convert to cell so it can be used in following loop (= go
            % through all links in the cell array)
            atmacs_url_link_loc = {atmacs_url_link_loc};
        end
        % Do the same with Global links
        if ~iscell(atmacs_url_link_glo)
            atmacs_url_link_glo = {atmacs_url_link_glo};
        end
        % Declare vector for appending
        time_total_loc = [];
        time_total_glo = [];
        l_total = [];
        r_total = [];
        p_total = [];
        d_total = [];
        g_total = [];
        for i = 1:length(atmacs_url_link_loc)
            % get url string
            str = urlread(atmacs_url_link_loc{i});                                         
            str = str(url_header:end);
            str_mat = reshape(str,url_rows,length(str)/url_rows);
            year = str_mat(1:4,:)';                                                     
            month = str_mat(5:6,:)';
            day = str_mat(7:8,:)';
            hour = str_mat(9:10,:)';
            p_str = str_mat(12:25,:)';
            l_str = str_mat(26:38,:)';
            r_str = str_mat(39:50,:)';
            % Prepare variables
            time_loc(1:size(year),1) = NaN;
            p(1:size(year),1) = NaN;
            l(1:size(year),1) = NaN;
            r(1:size(year),1) = NaN;
            % Convert to doubles
            for li = 1:size(year,1) 
                % time vector (in matlab format)
                time_loc(li,1) = datenum(str2double(year(li,:)),str2double(month(li,:)),str2double(day(li,:)),str2double(hour(li,:)),0,0); 
                % pressure (Pa)
                p(li,1) = str2double(p_str(li,:));   
                % local part (m/s^2)
                l(li,1) = str2double(l_str(li,:));
                % regional part (m/s^2)
                r(li,1) = str2double(r_str(li,:));                                      
            end
            % Concatenate
            if isempty(time_total_loc) % for the first data set
                time_total_loc = time_loc;
                l_total = l;
                r_total = r;
                p_total = p;
            else
                % Check date (for overlapping or missing data)
                rf = find(time_total_loc(end) == time_loc);
                % No such time exist => check how big is the gap
                if isempty(rf)
                    time_diff = time_total_loc(end) - time_loc(1);
                    time_res = time_total_loc(end) - time_total_loc(end-1);
                    % If the missing data is > then model resolution insert
                    % NaN (for further interpolation). Multiply by 2 to
                    % take increase of resolution into account
                    if (time_diff*-1 > time_res*2) && (time_diff < 0)
                        time_total_loc = vertcat(time_total_loc,time_total_loc(end)+time_res,time_loc);
                        l_total = vertcat(l_total,NaN,l);
                        r_total = vertcat(r_total,NaN,r);
                        p_total = vertcat(p_total,NaN,p);
                    elseif (time_diff*-1 <= time_res*2) && (time_diff < 0)
                        time_total_loc = vertcat(time_total_loc,time_loc);
                        l_total = vertcat(l_total,l);
                        r_total = vertcat(r_total,r);
                        p_total = vertcat(p_total,p);
                    elseif time_diff > 0
                        % In case the current time series starts before
                        % already loaded + no overlapping
                        time_total_loc = vertcat(time_total_loc,time_total_loc(end)+time_res);
                        l_total = vertcat(l_total,NaN);
                        r_total = vertcat(r_total,NaN);
                        p_total = vertcat(p_total,NaN);
                    end  
                else
                    % In case overlapping exist, check for offsets
                    l_diff = l_total(end) - l(rf);
                    r_diff = r_total(end) - r(rf);
                    p_diff = p_total(end) - p(rf);
                    % Apply offsets
                    time_total_loc = vertcat(time_total_loc,time_loc(rf+1:end));
                    l_total = vertcat(l_total,l(rf+1:end)+l_diff);
                    r_total = vertcat(r_total,r(rf+1:end)+r_diff);
                    p_total = vertcat(p_total,p(rf+1:end)+p_diff);
                end
            end
            clear year month day hour p_str l_str r_str str str_mat li l r p rf time_diff time_res time_loc
        end
        % Interpolate output pressure
        pressure = interp1(time_total_loc,p_total,ref_time);

        % Read Atmacs Global data
        url_header = 1;
        url_rows = 37;
        for i = 1:length(atmacs_url_link_glo)
            % get url string
            str = urlread(atmacs_url_link_glo{i}); 
            str = str(url_header:end);
            str_mat = reshape(str,url_rows,length(str)/url_rows);
            year = str_mat(1:4,:)';
            month = str_mat(5:6,:)';
            day = str_mat(7:8,:)';
            hour = str_mat(9:10,:)';
            g_str = str_mat(11:24,:)';
            d_str = str_mat(25:36,:)';
            % Prepare variables
            time_glo(1:size(year),1) = NaN;
            g(1:size(year),1) = NaN;
            d(1:size(year),1) = NaN;
            % Convert to doubles
            for li = 1:size(year,1)                                                     % convert strings to doubles
                time_glo(li,1) = datenum(str2double(year(li,:)),str2double(month(li,:)),str2double(day(li,:)),str2double(hour(li,:)),0,0); % time vector (in matlab format)
                g(li,1) = str2double(g_str(li,:));                                      % global attraction (m/s^2)
                d(li,1) = str2double(d_str(li,:));                                      % deformation part part (m/s^2)
            end
            % Concatenate
            if isempty(time_total_glo) % for the first data set
                time_total_glo = time_glo;
                g_total = g;
                d_total = d;
            else
                % Check date (for overlapping or missing data)
                rf = find(time_total_glo(end) == time_glo);
                % No such time exist => check how big is the gap
                if isempty(rf)
                    time_diff = time_total_glo(end) - time_glo(1);
                    time_res = time_total_glo(end) - time_total_glo(end-1);
                    % If the missing data is > then model resolution insert
                    % NaN (for further interpolation). Multiply by 2 to
                    % take increase of resolution into account
                    if (time_diff*-1 > time_res*2) && (time_diff < 0)
                        time_total_glo = vertcat(time_total_glo,time_total_glo(end)+time_res,time_glo);
                        g_total = vertcat(g_total,NaN,g);
                        d_total = vertcat(d_total,NaN,d);
                    elseif (time_diff*-1 <= time_res*2) && (time_diff < 0)
                        time_total_glo = vertcat(time_total_glo,time_glo);
                        g_total = vertcat(g_total,g);
                        d_total = vertcat(d_total,d);
                    elseif time_diff > 0
                        % In case the current time series starts before
                        % already loaded + no overlapping
                        time_total_glo = vertcat(time_total_glo,time_total_glo(end)+time_res);
                        g_total = vertcat(g_total,NaN);
                        d_total = vertcat(d_total,NaN);
                    end  
                else
                    % In case overlapping exist, check for offsets
                    g_diff = g_total(end) - g(rf);
                    d_diff = d_total(end) - d(rf);
                    % Apply offsets
                    time_total_glo = vertcat(time_total_glo,time_glo(rf+1:end));
                    g_total = vertcat(g_total,g(rf+1:end)+g_diff);
                    d_total = vertcat(d_total,d(rf+1:end)+d_diff);
                end
            end
            clear g_diff d_diffg d g time_glo year month day hour g_str d_str str str_mat li time_diff time_res rf time_glo
        end
        % Add all effects + interpolate to output time vector + convert to
        % nm/s^2 
        atmo_corr = (interp1(time_total_loc,l_total+r_total,ref_time) + ...
                     interp1(time_total_glo,g_total+d_total,ref_time))*1e+9;
        corr_check(3) = 1;
    end
catch
    corr_check(3) = 0;
    pressure = NaN;
    atmo_corr = NaN;
end

end




