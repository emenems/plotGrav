function [pol_corr,lod_corr,atmo_corr,pressure,corr_check] = plotGrav_Atmacs_and_EOP(ref_time,Lat,Lon,atmacs_url_link_loc,atmacs_url_link_glo)
%FUNCTION PLOTGRAV_ATMACS_AND_EOP Polar motion, LOD and atmo correction
% This function computes the polar motion correction, length of day 
% correction and Atmacs atmospheric correction (add to time series to
% correct them).
% 
% Input:
%   ref_time            ...     input time vector (in matlab format)
%   Lat                 ...     latitude of the gravimter (degrees)
%   Lon                 ...     longitude of the gravimter (degrees)
%   atmacs_url_link_loc ...     atmacs url to local component (lm)
%   atmacs_url_link_glo ...     atmacs url to global component (icon384)
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
        pol_corr = interp1(time_eop,pol_corr,ref_time);
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
    %% Read Atmacs Local data
    if isempty(atmacs_url_link_loc) || isempty(atmacs_url_link_glo)          % do not compute if no input
        corr_check(3) = 0;
        atmo_corr = NaN;
        pressure = NaN;
    else
        url_header = 1;                                                             % number of neader characters (not rows!)
        url_rows = 51;                                                              % number of characters in a row (now data columns!)
        str = urlread(atmacs_url_link_loc);                                         % get url string
        str = str(url_header:end);                                                  % cut off header
        str_mat = reshape(str,url_rows,length(str)/url_rows);                       % reshape to row oriented matrix
        year = str_mat(1:4,:)';                                                     % select year
        month = str_mat(5:6,:)';
        day = str_mat(7:8,:)';
        hour = str_mat(9:10,:)';
        p_str = str_mat(12:25,:)';
        l_str = str_mat(26:38,:)';
        r_str = str_mat(39:50,:)';
        % Prepare variables
        time_loc(1:size(year),1) = NaN;
        pressure(1:size(year),1) = NaN;
        l(1:size(year),1) = NaN;
        r(1:size(year),1) = NaN;
        % Convert to doubles
        for li = 1:size(year,1)                                                     % convert strings to doubles
            time_loc(li,1) = datenum(str2double(year(li,:)),str2double(month(li,:)),str2double(day(li,:)),str2double(hour(li,:)),0,0); % time vector (in matlab format)
            pressure(li,1) = str2double(p_str(li,:));                               % pressure (Pa)
            l(li,1) = str2double(l_str(li,:));                                      % local part (m/s^2)
            r(li,1) = str2double(r_str(li,:));                                      % regional part (m/s^2)
        end
        pressure = interp1(time_loc,pressure,ref_time);
        clear year month day hour p_str l_str r_str url_link url_header url_rows str str_mat li

        %% Read Atmacs Global data
        url_header = 1;                                                             % number of neader characters (not rows!)
        url_rows = 37;                                                              % number of characters in a row (now data columns!)
        str = urlread(atmacs_url_link_glo);                                         % get url string
        str = str(url_header:end);                                                  % cut off header
        str_mat = reshape(str,url_rows,length(str)/url_rows);                       % reshape to row oriented matrix
        year = str_mat(1:4,:)';                                                     % select year
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
        atmo_corr = (interp1(time_loc,l,ref_time) + ...
                     interp1(time_loc,r,ref_time) + ...
                     interp1(time_glo,g,ref_time) + ...
                     interp1(time_glo,d,ref_time))*1e+9;                            % add all effects + convert to nm/s^2
        corr_check(3) = 1;
        clear year month day hour g_str d_str time_glo g d l r url_link url_header url_rows str str_mat li
    end
catch
    corr_check(3) = 0;
    pressure = NaN;
    atmo_corr = NaN;
end

end




