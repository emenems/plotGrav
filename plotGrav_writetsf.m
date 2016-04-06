function plotGrav_writetsf(data,comment,fileout,decimal)
%WRITETSF write *.tsf file
% Function serves for the writing to tsf format
%
% Input:
%   data   ...  matrix with time and data columns. data(1:6,:) =
%               datevec(time).
%   comment...  cell area representing Site/Instrument/Observation/units
%               comment = {'Site','Instrument','Observation1','units1';
%               'Site','Instrument',Observation2','units2';...}
%               comment indexing: comment(1,1) = 'Site',...
%               if comment == [], default values are used
%   fileout...  output file name (eg 'SU_SG052_2011_CORMIN.tsf')
%   decimal...  number of decimal places (between 1 and 5)
%
% Output:
%   []
% 
% Example:
%   writetsf(data,{'Site','Instrument','Observation1','units1'},'Out.tsf',2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% M. Mikolaj 22/11/2011 %%%%

if nargin == 3
    decimal = 3;
end
vypis = fopen(fileout,'w'); 
fprintf(vypis,'[TSF-file] v01.0\n\n');
switch decimal
    case 1
        fprintf(vypis,'[UNDETVAL] 9999.9\n\n');
    case 2
        fprintf(vypis,'[UNDETVAL] 9999.99\n\n');
    case 3
        fprintf(vypis,'[UNDETVAL] 9999.999\n\n');
    case 4
        fprintf(vypis,'[UNDETVAL] 9999.9999\n\n');
    otherwise
        fprintf(vypis,'[UNDETVAL] 9999.99999\n\n');
end
fprintf(vypis,'[TIMEFORMAT] DATETIME\n\n');
cas = datenum(data(:,1:6));
increment = (cas(2)-cas(1))*86400;
% if max(abs(diff(diff(cas))))*86400 > 0.001
%     disp('Warning: the input data set is not evenly spaced');
% end
fprintf(vypis,'[INCREMENT] %6.0f\n\n',increment);                           % new time resolution
fprintf(vypis,'[CHANNELS]\n');
ss = size(data,2)-6;
if ~isempty(comment) && size(comment,1) == ss
    for st = 1:size(comment,1)
        fprintf(vypis,'  %s:%s:%s\n',char(comment(st,1)),char(comment(st,2)),char(comment(st,3)));
    end
    fprintf(vypis,'\n[UNITS]\n');
    for st = 1:size(comment,1)
        fprintf(vypis,'  %s\n',char(comment(st,4)));
    end
else
    while ss >= 1
        fprintf(vypis,'  Site:Instrument:measurements\n');
        ss = ss - 1;
    end
    ss = size(data,2)-6;
    fprintf(vypis,'\n[UNITS]\n');
    while ss >= 1
        fprintf(vypis,'  ?\n');
        ss = ss - 1;
    end
end
switch decimal
    case 1
        data(isnan(data)) = 9999.9;
    case 2
        data(isnan(data)) = 9999.99;
    case 3
        data(isnan(data)) = 9999.999;
    case 4
        data(isnan(data)) = 9999.9999;
    otherwise
        data(isnan(data)) = 9999.99999;
end
fprintf(vypis,'\n[COMMENT]\n\n');
cas = datenum(data(:,1:6));
casi = cas(1):increment/86400:cas(end);
fprintf(vypis,'[COUNTINFO] %10.0f\n\n',length(casi));
fprintf(vypis,'[DATA]\n');
ss = size(data,2)-6;
r = size(data,1);
% Round time
minute_temp = data(:,5);
second_temp = round(data(:,6));
ms = find(second_temp>=60);
if ~isempty(ms)
    minute_temp(ms) = minute_temp(ms) + round(second_temp(ms)/60);
    data(ms,6) = 0;
end
ms = find(minute_temp>=60);
if ~isempty(ms)
    data(ms,4) = data(ms,4) + round(minute_temp(ms)/60);
    data(ms,5) = 0;
end

% Prepare output format
switch decimal
    case 1
        out_format = '%12.1f';
    case 2
        out_format = '%12.2f';
    case 3
        out_format = '%12.3f';
    case 4
        out_format = '%12.4f';
    otherwise
        out_format = '%12.5f';
end
for j = 2:size(data,2)-6
    out_format = [out_format,' %8.1f'];
end
for i = 1:r
    % Write date
    fprintf(vypis,'%4d %02d %02d %02d %02.0f %02.0f ',...
                data(i,1),data(i,2),data(i,3),data(i,4),data(i,5),data(i,6));
    % Write remaining columns
    fprintf(vypis,out_format,data(i,7:end));
    % Move to new row
    fprintf(vypis,'\n');
end

fclose(vypis);
end