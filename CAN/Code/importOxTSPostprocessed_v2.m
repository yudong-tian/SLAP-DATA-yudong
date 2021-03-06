function importOxTSPostprocessed_April_2015(filename, startRow, endRow)
tic
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [DATEUTC,TIMEUTC,TIMEFROMSTARTS,POSLATDEG,POSLONDEG,POSALTM,DISTANCEM,VELNORTHMS,VELEASTMS,VELDOWNMS,VELFORWARDMS,VELLATERALMS,SPEED3DMS,ACCELXMS,ACCELYMS,ACCELZMS,ACCELFORWARDMS,ACCELLATERALMS,ACCELDOWNMS,ANGLEHEADINGDEG,ANGLEPITCHDEG,ANGLEROLLDEG,ANGLESLIPDEG,ANGLETRACKDEG,CURVATURE1M,ANGLERATEXDEGS,ANGLERATEYDEGS,ANGLERATEZDEGS,ANGLERATEFORWARDDEGS,ANGLERATELATERALDEGS,ANGLERATEDOWNDEGS,ANGLEGRADIENTDEG]
%   = IMPORTFILE(FILENAME) Reads data from text file FILENAME for the
%   default selection.
%
%   [DATEUTC,TIMEUTC,TIMEFROMSTARTS,POSLATDEG,POSLONDEG,POSALTM,DISTANCEM,VELNORTHMS,VELEASTMS,VELDOWNMS,VELFORWARDMS,VELLATERALMS,SPEED3DMS,ACCELXMS,ACCELYMS,ACCELZMS,ACCELFORWARDMS,ACCELLATERALMS,ACCELDOWNMS,ANGLEHEADINGDEG,ANGLEPITCHDEG,ANGLEROLLDEG,ANGLESLIPDEG,ANGLETRACKDEG,CURVATURE1M,ANGLERATEXDEGS,ANGLERATEYDEGS,ANGLERATEZDEGS,ANGLERATEFORWARDDEGS,ANGLERATELATERALDEGS,ANGLERATEDOWNDEGS,ANGLEGRADIENTDEG]
%   = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW
%   through ENDROW of text file FILENAME.
%
% Example:
%   [DateUTC,TimeUTC,TimeFromStarts,PosLatdeg,PosLondeg,PosAltm,Distancem,VelNorthms,VelEastms,VelDownms,VelForwardms,VelLateralms,Speed3Dms,AccelXms,AccelYms,AccelZms,AccelForwardms,AccelLateralms,AccelDownms,AngleHeadingdeg,AnglePitchdeg,AngleRolldeg,AngleSlipdeg,AngleTrackdeg,Curvature1m,AngleRateXdegs,AngleRateYdegs,AngleRateZdegs,AngleRateForwarddegs,AngleRateLateraldegs,AngleRateDowndegs,AngleGradientdeg]
%   = importfile('150401_172619.csv',2, 1601311);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2015/04/06 14:42:39

%% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Format string for each line of text:
%   column1: date strings (%s)
%	column2: date strings (%s)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
%   column9: double (%f)
%	column10: double (%f)
%   column11: double (%f)
%	column12: double (%f)
%   column13: double (%f)
%	column14: double (%f)
%   column15: double (%f)
%	column16: double (%f)
%   column17: double (%f)
%	column18: double (%f)
%   column19: double (%f)
%	column20: double (%f)
%   column21: double (%f)
%	column22: double (%f)
%   column23: double (%f)
%	column24: double (%f)
%   column25: double (%f)
%	column26: double (%f)
%   column27: double (%f)
%	column28: double (%f)
%   column29: double (%f)
%	column30: double (%f)
%   column31: double (%f)
%	column32: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Convert the contents of column with dates to serial date numbers using date format string (datenum).
dataArray{1} = datenum(dataArray{1}, 'dd mmm yyyy');
dataArray{2} = datenum(dataArray{2}, 'HH:MM:SS.FFF');

%% Allocate imported array to column variable names
DateUTC = dataArray{:, 1};
TimeUTC = dataArray{:, 2};
% TimeFromStarts = dataArray{:, 3};
PosLatdeg = dataArray{:, 4};
PosLondeg = dataArray{:, 5};
PosAltm = dataArray{:, 6};
% Distancem = dataArray{:, 7};
VelNorthms = dataArray{:, 8};
VelEastms = dataArray{:, 9};
VelDownms = dataArray{:, 10};
% VelForwardms = dataArray{:, 11};
% VelLateralms = dataArray{:, 12};
% Speed3Dms = dataArray{:, 13};
% AccelXms = dataArray{:, 14};
% AccelYms = dataArray{:, 15};
% AccelZms = dataArray{:, 16};
% AccelForwardms = dataArray{:, 17};
% AccelLateralms = dataArray{:, 18};
% AccelDownms = dataArray{:, 19};
AngleHeadingdeg = dataArray{:, 20};
AnglePitchdeg = dataArray{:, 21};
AngleRolldeg = dataArray{:, 22};
% AngleSlipdeg = dataArray{:, 23};
AngleTrackdeg = dataArray{:, 24};
% Curvature1m = dataArray{:, 25};
% AngleRateXdegs = dataArray{:, 26};
% AngleRateYdegs = dataArray{:, 27};
% AngleRateZdegs = dataArray{:, 28};
% AngleRateForwarddegs = dataArray{:, 29};
% AngleRateLateraldegs = dataArray{:, 30};
% AngleRateDowndegs = dataArray{:, 31};
% AngleGradientdeg = dataArray{:, 32};

gpstime = DateUTC + TimeUTC - floor(TimeUTC);

[filepath, filename, ext] = fileparts(filename);
save(fullfile(filepath, strcat('OXTSPOSTPROCESSED_', filename, '_2.mat')),'gpstime', 'PosLatdeg', 'PosLondeg', 'PosAltm', 'VelNorthms', 'VelEastms', 'VelDownms', 'AngleHeadingdeg', 'AnglePitchdeg', 'AngleRolldeg', 'AngleTrackdeg');


%% Clear temporary variables
clearvars delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me dateFormats rawNumericColumns rawCellColumns R;

elapsed = toc;
disp(['Elapsed time to read ' filename ext ': ' num2str(elapsed) ' sec.']);