% =========================================================================
% AERO 2326 SPACE MECHANICS - PROJECT 2
% ISS PASS TRACKER - TELEMETRY FEED DESIGN (TRUE ORBITAL DATA)
% Location: Taman Melati, Malaysia
% =========================================================================

clear; clc; close all;

%% 1. Automatically Create the ISS TLE Data File
tleFileName = 'iss_tle.txt';
fid = fopen(tleFileName, 'w');
fprintf(fid, 'ISS (ZARYA)\n');
fprintf(fid, '1 25544U 98067A   26170.52331575  .00014389  00000-0  25916-3 0  9998\n');
fprintf(fid, '2 25544  51.6394  11.5144 0005123  35.1255  53.2555 15.49432155573427\n');
fclose(fid);

%% 2. Define the Timeframe (3 Weeks from June 19, 2026)
startTime = datetime(2026, 6, 19, 0, 0, 0, 'TimeZone', 'Asia/Kuala_Lumpur');
stopTime = startTime + days(21);
sampleTime = 60; 

%% 3. Create Scenario and Ground Station
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Taman Melati Ground Station
gs = groundStation(sc, 3.2235, 101.7245, ...
    'Altitude', 50, ...
    'Name', 'Taman Melati', ...
    'MinElevationAngle', 10); 

%% 4. Load Satellite and Calculate Access
iss = satellite(sc, tleFileName, 'Name', 'ISS');
ac = access(gs, iss);
intervals = accessIntervals(ac);

%% 5. Generate the Formatted Report
if isempty(intervals)
    disp('No visible passes found.');
else
    % =====================================================================
    % TELEMETRY-STYLE DESIGN
    % =====================================================================
    fprintf('\n================================================================================\n');
    fprintf('                          [ ISS TRACKING ]\n');
    fprintf('================================================================================\n');
    fprintf(' PROJECT    : AERO 2326 SPACE MECHANICS\n');
    fprintf(' ANALYST    : EMILY, AZZEHRA, ALYEA\n');
    fprintf(' STATION    : TAMAN MELATI (LATITUDE: 3.22°N | LONGITUDE: 101.72°E)\n');
    fprintf(' TARGET     : ISS (ZARYA)\n');
    fprintf('================================================================================\n\n');
    
    fprintf(' [START TIME MYT]       [END TIME MYT]         [ELEV °]   [AZ IN °]  [AZ OUT °]\n');
    fprintf(' --------------------------------------------------------------------------------\n');
    
    % Loop through every pass found
    for i = 1:height(intervals)
        
        % Extract and format the times
        startLocal = intervals.StartTime(i);
        startLocal.TimeZone = 'Asia/Kuala_Lumpur';
        endLocal = intervals.EndTime(i);
        endLocal.TimeZone = 'Asia/Kuala_Lumpur';
        
        strStart = datestr(startLocal, 'dd-mmm-yyyy HH:MM:SS');
        strEnd   = datestr(endLocal, 'dd-mmm-yyyy HH:MM:SS');
        
        % Calculate the exact angles using a FOR LOOP to avoid the "scalar" error
        trackingTimes = startLocal:seconds(10):endLocal;
        numSteps = length(trackingTimes);
        
        az = zeros(1, numSteps);
        el = zeros(1, numSteps);
        
        for k = 1:numSteps
            [az(k), el(k), ~] = aer(gs, iss, trackingTimes(k));
        end
        
        % Extract the true simulated data
        maxElev = max(el);
        startAz = az(1);
        endAz   = az(end);
        
        % Print the formatted row with perfectly aligned spacing
        fprintf(' %-22s %-22s %-10.1f %-10.1f %.1f\n', ...
            strStart, strEnd, maxElev, startAz, endAz);
    end
    fprintf(' --------------------------------------------------------------------------------\n\n');
end

% Clean up the TLE file
if exist(tleFileName, 'file')
    delete(tleFileName);
end