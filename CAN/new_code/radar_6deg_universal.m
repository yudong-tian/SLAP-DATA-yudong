%%
% uses sum and mean insteald of nansum and nanmean to avoid license restrictions
clear


% what polarizations to use, for speed 
do_hh = 1; 
do_vv = 1; 
do_vh = 0; 
do_hv = 0; 

% get flight date
flight_directory = pwd;
flight_day = str2double((flight_directory(10:11)));
flight_month = str2double((flight_directory(8:9)));
flight_year = str2double((flight_directory(4:7)));

% sometimes timestamp went to 1/1/1970

timeRadInit = datenum('10/1/2015 00:00:00');
timeRadFinal = datenum('11/30/2015 00:00:00');

% RDRRETURN_20151030T181002.mat
files = dir('RDRRETURN_*.mat');
%files = dir('RDRRETURN_20151030T185000.mat');
files_to_process = 1:length(files);
%%
sample_period = 500e-6; %sec
sample_period_days = sample_period/86400;

    % use SLAP Radar ground calibration data points from Albert 
    power_dBm_h = [-85:5:-50, -49:-45, -40:-30]';
    power_dBm_v = [-85:5:-50, -45, -40:-33]';
    
    cal_hpol_counts = [1; 3.2; 10.7; 33.5; 106; 335; 1062; 3342; 4190; 5270; 6620; ...
                       8270; 10470; 31700; 38500; 46700; 53280; 56060; 57800; ...
                       58820; 59520; 59970; 60260; 60470];

    cal_vpol_counts = [1; 4; 12.8; 39.25; 125.5; 398; 1255; 3960; ...
                       12380; 36300; 43800; 51440; 55040; 56980; ...
                       58200; 59000; 59536];

    power_mW_h = 10.^(power_dBm_h/10);
    power_mW_v = 10.^(power_dBm_v/10);

% only need power in dBm values before the radar return saturates. The
% cal_hpol_counts are only given before saturation so the number of valid data
% points of power_mW corresponds to the first n (= length(cal_hpol_counts) data points
power_mW_hpol = power_mW_h(1:length(cal_hpol_counts));

% same goes for v-pol
power_mW_vpol = power_mW_h(1:length(cal_vpol_counts));


noiseFloor_h = cal_hpol_counts(1);
noiseFloor_v = cal_vpol_counts(1);

saturationLimit_h = cal_hpol_counts(end);
saturationLimit_v = cal_vpol_counts(end);

% noise Floor and saturation Limit are intrinsically used since the
% interpolated method used to convert from raw counts to mW is a piecewise
% linear fit which turns raw count values outside the calibration range
% into NaN power values.

rangeGateDistance = 300; % meters

% initialize variables
f = 1262500000; % Hz
c = 299792458; % m/s
Pt = 10^(47/10);
%YDT Gt = 17.7^(47/10);
Gt = 10^(17.7/10); 
Gr = Gt;

radar_factor =  Pt * Gt * ( c^2 / (4*pi*f)^2 ) * 1/(4*pi) * Gr;

alpha = 1.33;
phi = 40;

tau = 1e-6;
theta_ah = 13.4;
theta_av = 13.1;

% beam width information by polarization from SLAP documentation
beam_width_h_pol = 20.5;
beam_width_v_pol = 19.5;

% load azimuthal scan angle data
load AzData
azAll = 360 - azAll;

indMot = find(timeMotAll >= timeRadInit & timeMotAll < timeRadFinal );
timeMot = timeMotAll(indMot);
az = azAll(indMot);

load step_all

%% only use GPS receiver data for time period of interest

% must pre-process GPS data in excel file using importOxTSPostprocessed_v2.m
% into a matlab .mat file first!!!
oxfile = dir('OXTS*.mat');
load(oxfile(1).name)

% 17 second offset (converted to fraction of day)
% between the OxTS which is in GPS time and the rest of the
% data which is in UTC time
timeGeo = gpstime + 17/86400;

timeGeoInd = find(timeGeo >= timeRadInit & timeGeo < timeRadFinal );
timeGeoSlice = timeGeo(timeGeoInd);
lat = PosLatdeg(timeGeoInd);
lon = PosLondeg(timeGeoInd);
alt = PosAltm(timeGeoInd); % meters
roll = AngleRolldeg(timeGeoInd);
pitch = AnglePitchdeg(timeGeoInd);
hdg = AngleHeadingdeg(timeGeoInd);
trk = AngleTrackdeg(timeGeoInd);

%% precalculate altitude above ground level (AGL)
%ned_vals = findElevData(lat,lon);

ned_vals = 238;   %m, from Albert Wu's code
AGL = alt - ned_vals;

%%
for k = files_to_process
    files(k).name
    timestr = files(k).name(end-9:end-6)
    
    % load time, radar_h, and radar_v data
    load(files(k).name)
    timeRad = time;
    
    %% call to function to "repair" time tags
    
        % For 2015 data, the time tags are much better. However, they need to be
        % recreated still because of hardware issues that cause the time tags to
        % not continuously increase every once in a while. The instrument is
        % still scanning so this is a valid fix.
   %YDT may not need any more
   %YDT     time_new = time(1):0.0005/86400:(time(1)+((length(time)-1)*0.0005/86400));
   %YDT     timeRad = time_new';
                
      % interpolate step attenuator data for 2015 flight data using previous neighbor method
        step_h_pol = interp1(step_time,step_h,timeRad, 'previous');
        step_v_pol = interp1(step_time,step_v,timeRad, 'previous');

    %% interpolate GPS data and azimuth scan angle data to Rad time tag frequency
    
    % interpolate az angles to Rad time frequency using timeRad as new index
    az_interp = interp1(timeMot,az,timeRad);
    
    % now interpolate OxTS components using timeGeoSlice as the original
    % index and timeRad as the interpolating index
    AGL_interp = interp1(timeGeoSlice, AGL, timeRad);
    pitch_interp = interp1(timeGeoSlice, pitch, timeRad);
    roll_interp = interp1(timeGeoSlice, roll, timeRad);
    trk_interp = interp1(timeGeoSlice, trk, timeRad);
    hdg_interp = interp1(timeGeoSlice, hdg, timeRad);
    lonexpanded = interp1(timeGeoSlice, lon, timeRad);
    latexpanded = interp1(timeGeoSlice, lat, timeRad);
    
    % use SLAP's incidence angle, which changes with roll angle, to determine
    % the elevation angle
    elev_angle = phi - roll_interp .* sind(az_interp);
    
    % use SLAP's given elevation angle to determine surface radius, srad, from
    % nadir to location of observation
    surface_radius=tand(elev_angle).*AGL_interp;
    
    % precalculate slant range
    slant = AGL_interp./ cosd(elev_angle);
    
    % calculate complete az angle from true north. The azimuth offset = 0 in the SLAP measurements.
    az_all = az_interp + hdg_interp;% + az_offset;
    
    % radius of earth in meters
    r_earth = 6371e3;
    
    % determine x and y offset from nadir (directly below the aircraft)
    % of each observation based on azimuth angle of SLAP at time of
    % observation.
    
    yoff = surface_radius .* cosd(az_all); % meters
    xoff = surface_radius .* sind(az_all); % meters
    
    % convert x and y offset into lat-lon offset, then add to current lat-lon coordinates.
    lat_interp = yoff  .* 360./(2*pi*r_earth) + latexpanded ;	%pixel absolute x location (longitude)
    % horizontal offset values in degrees depend on latitude on Earth
    lon_interp = xoff  .* 360./(2*pi*r_earth.*cosd(latexpanded )) + lonexpanded ;	%pixel absolute y location (latitude)
    
    %% get sigma0 data for h and v pol at six degree scan angle averages
    
    % determine which data corresponds to co-pol and which corresponds to
    % cross-pol using the PCM vector.
    
    pcm_sep = bitget(pcm,3);
    % if the PCM has a 0 in its 4s bit, it's H transmitting.
    % if it has a 1 in its 4s bit, it's V transmitting.
    % the nomenclature is as follows: indstart_xy where x is the transmit pol
    % and y is the receive pol

    vind = pcm_sep == 1;  % Albert's algorithm

    radar_hh(~vind, :) = radar_h(~vind, :);
    radar_vv(vind, :)  = radar_v(vind, :);

    radar_step_hh(~vind) =  step_h_pol( ~vind );
    radar_step_vv(vind) = step_v_pol( vind);

    radar_hv(vind, :)  = radar_h( vind, :);
    radar_vh(~vind, :)  = radar_v( ~vind, :);

    radar_step_hv(vind)  = step_h_pol( vind);
    radar_step_vh(~vind) = step_v_pol( ~vind);

    % increment = 134;% ~= 6 deg in scan angle
    increment = 132;% ~= 6 deg in scan angle    YDT: make it multiple of 4 
    
    numlines = floor(length(az_all)/increment);
    
    % initialize variables
    [azavg, latavg, lonavg, mean_hh, mean_vv, mean_hv, mean_vh, altavg, trkavg, rollavg, hdgavg, timeavg] = deal(zeros(numlines-1,1));
    
    'before j loop  ...'
    %keyboard
    for j = 1:numlines-1
        % get radar data points for each range bin
        ind = (increment*(j-1)+1):increment*j;

        data_hh = radar_hh(ind, :);
        data_vv = radar_vv(ind, :);

        data_step_hh = radar_step_hh( ind );
        data_step_vv = radar_step_vv( ind );

        data_hv  = radar_hv( ind, :);
        data_vh  = radar_vh( ind, :);

        data_step_hv  = radar_step_hv( ind);
        data_step_vh  = radar_step_vh( ind);
        
        % use middle of current 6 degree data set indices for
        % geolocation and scan angle values
        indmid = ind(floor(length(ind)/2));
        
        latavg(j) = lat_interp(indmid);
        lonavg(j) = lon_interp(indmid);
        altavg(j) = AGL_interp(indmid);
        trkavg(j) = trk_interp(indmid);
        hdgavg(j) = hdg_interp(indmid);
        rollavg(j) = roll_interp(indmid);
        timeavg(j) = timeRad(indmid);
        azavg(j) = az_all(indmid);
        
        % initialize sigma0 values for 4 pol combinations for this 6 deg avg data set (=66 data points)
        [sigma0hh, sigma0vv, sigma0hv, sigma0vh] = deal(zeros(size(data_vv,1),1));
        
        % initialize  radar footprint for H-pol
        footprintm = (slant(indmid).*tand(beam_width_h_pol/2))./cosd(elev_angle(indmid));
        area_h = pi .* footprintm^2;
        
        % initialize  radar footprint for V-pol
        footprintm = (slant(indmid)*tand(beam_width_v_pol/2))./cosd(elev_angle(indmid));
        area_v = pi .* footprintm^2;
        
       % vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
       if do_hh
       %% This section calculates HH sigma0
        for i = 1:size(data_hh,1)

                % determine indices of counts above the noise floor
                indCountsWithinBounds = find(data_hh(i,:)> noiseFloor_h);
                % if there is no radar return data above the noise floor, the
                % code skips data point and leaves sigma0h's default value of 0
                if ~isempty(indCountsWithinBounds)
                    % get data points above the noise floor
                    usefulCounts = data_hh(i,indCountsWithinBounds);
                    
                    % distance from range gate 1 to each range gate with usable
                    % radar return data
                    surface_ranges = (indCountsWithinBounds-1) * rangeGateDistance;
                    % determine total surface distance
                    surfaceDistance = surface_radius(indmid) + surface_ranges;
                    % range from SLAP (at altitude) to each range gate is determined by the
                    % Pythagorean thereom.
                    R = sqrt ( surfaceDistance.^2 + altavg(j).^2);
                    
                    % interpolate counts values to determine power in mW
                    powerReceived_h_pol = interp1(cal_hpol_counts, power_mW_h, double(usefulCounts) );

                    %YDT  rewrote 
                    % % convert power from mW to dBm to be able to add step atten
                    % powerReceived_h_pol = 10*log10(powerReceived_h_pol);
                    % % factor in step attenuator data
                    % powerReceived_h_pol = powerReceived_h_pol + data_step_hh(i);
                    % % convert power from dBm to mW
                    % powerReceived_h_pol = 10.^(powerReceived_h_pol/10);

                    powerReceived_h_pol = powerReceived_h_pol* 10.^(data_step_hh(i)./10);
                    
                    % equation in linear (mW) space to solve for sigma
                    sumPandR = sum(powerReceived_h_pol.*R.^4);
                    %sigma_hh = sumPandR / ( Pt * Gt * ( c^2 / (4*pi*f)^2 ) * 1/(4*pi) * Gr);
                    %YDT rewrote for performance
                    sigma_hh = sumPandR / radar_factor; 
                    
                    % sum non-nan values of (sigma/area) to get sigma0 in mW
                    sigma0hh(i) =  10*log10(  sum(sigma_hh./area_h) );
                end
           end % i
       end
       % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

       % vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
       if do_hv 
           %% This section calculates HV sigma0
           for i = 1:size(data_hv,1)
                % determine indices of counts above the noise floor
                indCountsWithinBounds = find(data_hv(i,:)> noiseFloor_h);
                % if there is no radar return data above the noise floor, the
                % code skips data point and leaves sigma0h's default value of 0
                if ~isempty(indCountsWithinBounds)
                    % get data points above the noise floor
                    usefulCounts = data_hh(i,indCountsWithinBounds);
                    
                    % distance from range gate 1 to each range gate with usable
                    % radar return data
                    surface_ranges = (indCountsWithinBounds-1) * rangeGateDistance;
                    % determine total surface distance
                    surfaceDistance = surface_radius(indmid) + surface_ranges;
                    % range from SLAP (at altitude) to each range gate is determined by the
                    % Pythagorean thereom.
                    R = sqrt ( surfaceDistance.^2 + altavg(j).^2);
                    
                    % interpolate counts values to receive pol to determine power in mW
                    powerReceived_v_pol = interp1(cal_vpol_counts, power_mW_v, double(usefulCounts) );
                    
                    %YDT rewrote for performance 
                    % % convert power from mW to dBm to be able to add step atten
                    % powerReceived_v_pol = 10*log10(powerReceived_v_pol);
                    % % factor in step attenuator data
                    % powerReceived_v_pol = powerReceived_v_pol + data_step_hv(i);
                    % convert power from dBm to mW
                    %  powerReceived_v_pol = 10.^(powerReceived_v_pol/10);

                    powerReceived_v_pol = powerReceived_v_pol* 10.^(data_step_hv(i)./10);


                    % equation in linear (mW) space to solve for sigma
                    sumPandR = sum(powerReceived_v_pol.*R.^4);
                    %YDT sigma_hv = sumPandR / ( Pt * Gt * ( c^2 / (4*pi*f)^2 ) * 1/(4*pi) * Gr);
                    sigma_hv = sumPandR / radar_factor; 
                    
                    % sum non-nan values of (sigma/area) to get sigma0 in mW.
                    % must divide by receiving pol footprint area.
                    sigma0hv(i) =  10*log10( sum(sigma_hv./area_v));
                end
           end % i 
       end
       % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

       % vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
       if do_vv 
           %% This section calculates VV sigma0
           for i = 1:size(data_vv,1)

                % determine indices of counts above the noise floor
                indCountsWithinBounds = find(data_vv(i,:)> noiseFloor_v);
                % if there is no radar return data above the noise floor, the
                % code skips data point and leaves sigma0vv's default value of 0
                if ~isempty(indCountsWithinBounds)
                    % get data points above the noise floor
                    usefulCounts = data_vv(i,indCountsWithinBounds);
                    
                    % distance from range gate 1 to each range gate with usable
                    % radar return data
                    surface_ranges = (indCountsWithinBounds-1) * rangeGateDistance;
                    % add these two to determine total surface distance
                    surfaceDistance = surface_radius(indmid) + surface_ranges;
                    % range from SLAP to each range gate is determined by the
                    % Pythagorean thereom.
                    R = sqrt ( surfaceDistance.^2 + altavg(j).^2);
                    
                    % interpolate counts values to determine power in mW\
                    powerReceived_v_pol = interp1(cal_vpol_counts, power_mW_v, double(usefulCounts) );
                    
                    %YDT rewrote 
                    % % convert power from mW to dBm to be able to add step atten
                    % powerReceived_v_pol = 10*log10(powerReceived_v_pol);
                    % % factor in step attenuator data
                    % powerReceived_v_pol = powerReceived_v_pol + data_step_vv(i);
                    % % convert power from dBm to mW
                    % powerReceived_v_pol = 10.^(powerReceived_v_pol/10);

                    powerReceived_v_pol = powerReceived_v_pol* 10.^(data_step_vv(i)./10);

                    % equation in linear (mW) space to solve for sigma
                    sumPandR = sum(powerReceived_v_pol.*R.^4);
                    %YDT sigma_vv = sumPandR / ( Pt * Gt * ( c^2 / (4*pi*f)^2 ) * 1/(4*pi) * Gr);
                    sigma_vv = sumPandR / radar_factor; 
                    
                    % sum non-nan values of (sigma/area) to get sigma0 in mW
                    sigma0vv(i) =  10*log10( sum(sigma_vv./area_v));
                end
           end % i 
       end
       % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

       % vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
       if do_vh 
           for i = 1:size(data_vh,1)

                % determine indices of counts above the noise floor
                indCountsWithinBounds = find(data_vh(i,:)> noiseFloor_v);
                % if there is no radar return data above the noise floor, the
                % code skips data point and leaves sigma0vv's default value of 0
                if ~isempty(indCountsWithinBounds)
                    % get data points above the noise floor
                    usefulCounts = data_vh(i,indCountsWithinBounds);
                    
                    % distance from range gate 1 to each range gate with usable
                    % radar return data
                    surface_ranges = (indCountsWithinBounds-1) * rangeGateDistance;
                    % add these two to determine total surface distance
                    surfaceDistance = surface_radius(indmid) + surface_ranges;
                    % range from SLAP to each range gate is determined by the
                    % Pythagorean thereom.
                    R = sqrt ( surfaceDistance.^2 + altavg(j).^2);
                    
                    % interpolate counts values to receive pol to determine power in mW
                    
                    powerReceived_h_pol = interp1(cal_hpol_counts, power_mW_h, double(usefulCounts) );
                    
                    %YDT rewrote for performance  
                    % % convert power from mW to dBm to be able to add step atten
                    % powerReceived_h_pol = 10*log10(powerReceived_h_pol);
                    % % factor in step attenuator data
                    % powerReceived_h_pol = powerReceived_h_pol + data_step_vh(i);
                    % % convert power from dBm to mW
                    % powerReceived_h_pol = 10.^(powerReceived_h_pol/10);

                    powerReceived_h_pol = powerReceived_h_pol* 10.^(data_step_vh(i)./10);
                    
                    % equation in linear (mW) space to solve for sigma
                    sumPandR = sum(powerReceived_h_pol.*R.^4);
                    %sigma_vh = sumPandR / ( Pt * Gt * ( c^2 / (4*pi*f)^2 ) * 1/(4*pi) * Gr);
                    sigma_vh = sumPandR / radar_factor; 
                    
                    % sum non-nan values of (sigma/area) to get sigma0 in mW
                    % must divide by receiving pol footprint area.
                    sigma0vh(i) = 10*log10( sum(sigma_vh./area_h));
                end
           end % i 
       end
       % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

        % get six degree scan angle average of sigma0 for h and v pol
        mean_hh(j) = mean(sigma0hh);
        mean_hv(j) = mean(sigma0hv);
        mean_vh(j) = mean(sigma0vh);
        mean_vv(j) = mean(sigma0vv);
    end
    %%%%%%%%%%% j loop done

    'j loop done ...'
     %keyboard
    
    % save data for future processing
    save(['6deg_', files(k).name(1:end-4), '.mat'], 'mean_hh', 'mean_vv', 'latavg', ...
              'lonavg', 'altavg', 'mean_hv', 'mean_vh','hdgavg', 'rollavg', ...
              'trkavg', 'timeavg', 'azavg')

end   % file loop 

quit
