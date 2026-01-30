% =========================================================================
% Walabot Pipe Detection in Wall - Matlab Implementation
% =========================================================================
% Description: 
%   This script uses Walabot API to detect pipes inside walls using the
%   SHORT_RANGE_IMAGING profile which is specifically designed for
%   penetrative scanning in dielectric materials like walls.
%
% Hardware Required: Walabot Developer device
% Profile Used: PROF_SHORT_RANGE_IMAGING
% Coordinate System: Cartesian (X, Y, Z)
% =========================================================================

%% Clear workspace and initialize
clear all;
close all;
clc;

disp('==========================================================');
disp('   Walabot Pipe Detection System - Initialization');
disp('==========================================================');

%% Configuration Parameters for Wall Scanning
% Arena parameters (Cartesian coordinates in cm)
% X-axis: horizontal scanning range
xArenaMin = -3;      % cm (left side)
xArenaMax = 4;       % cm (right side)
xArenaRes = 0.5;     % cm (resolution)

% Y-axis: vertical scanning range  
yArenaMin = -6;      % cm (bottom)
yArenaMax = 4;       % cm (top)
yArenaRes = 0.5;     % cm (resolution)

% Z-axis: depth into the wall
zArenaMin = 3;       % cm (minimum depth - close to surface)
zArenaMax = 8;       % cm (maximum depth - deeper into wall)
zArenaRes = 0.5;     % cm (resolution)

% Sensitivity threshold for weak signal removal
sensitivityThreshold = 15;  % Adjust based on wall material and conditions

% Dielectric constant for wall material
% Common values: Drywall ≈ 2.5, Concrete ≈ 6-8, Wood ≈ 2-3
dielectricConstant = 2.5;   % Assuming standard drywall

%% Walabot API Setup
global API;

try
    % Load Walabot .NET Assembly
    disp('Loading Walabot API assembly...');
    asm = NET.addAssembly('C:\Program Files\Walabot\WalabotSDK\bin\WalabotAPI.NET.dll');
    
    % Import namespace
    import WalabotAPI_NET.*;
    
    % Create API instance
    API = WalabotAPI_NET.WalabotAPI();
    disp('✓ Walabot API loaded successfully');
    
catch ME
    error('Failed to load Walabot API: %s', ME.message);
end

%% Step 1: Set Settings Folder (Database Location)
try
    disp('Setting Walabot database folder...');
    API.SetSettingsFolder('C:\ProgramData\Walabot\WalabotSDK');
    disp('✓ Settings folder configured');
catch ME
    error('Failed to set settings folder: %s', ME.message);
end

%% Step 2: Connect to Walabot Device
try
    disp('Connecting to Walabot device...');
    API.ConnectAny();
    disp('✓ Connected to Walabot device');
catch ME
    error('Failed to connect to Walabot: %s. Make sure device is plugged in.', ME.message);
end

%% Step 3: Configure Scan Profile
try
    disp('Configuring SHORT_RANGE_IMAGING profile...');
    
    % Set profile for short-range penetrative scanning in dielectric materials
    PROF_SHORT_RANGE = WalabotAPI_NET.APP_PROFILE.PROF_SHORT_RANGE_IMAGING;
    API.SetProfile(PROF_SHORT_RANGE);
    disp('✓ Profile set to SHORT_RANGE_IMAGING');
    
catch ME
    API.Disconnect();
    error('Failed to set profile: %s', ME.message);
end

%% Step 4: Configure Arena (Scanning Volume)
try
    disp('Configuring scanning arena (Cartesian coordinates)...');
    
    % Set X-axis arena
    API.SetArenaX(xArenaMin, xArenaMax, xArenaRes);
    fprintf('  X-axis: [%.1f, %.1f] cm, resolution: %.1f cm\n', ...
            xArenaMin, xArenaMax, xArenaRes);
    
    % Set Y-axis arena
    API.SetArenaY(yArenaMin, yArenaMax, yArenaRes);
    fprintf('  Y-axis: [%.1f, %.1f] cm, resolution: %.1f cm\n', ...
            yArenaMin, yArenaMax, yArenaRes);
    
    % Set Z-axis arena
    API.SetArenaZ(zArenaMin, zArenaMax, zArenaRes);
    fprintf('  Z-axis: [%.1f, %.1f] cm, resolution: %.1f cm\n', ...
            zArenaMin, zArenaMax, zArenaRes);
    
    disp('✓ Arena configured successfully');
    
catch ME
    API.Disconnect();
    error('Failed to configure arena: %s', ME.message);
end

%% Step 5: Set Advanced Parameters
try
    disp('Setting advanced parameters...');
    
    % Set dielectric constant for wall material
    API.SetAdvancedParameter('DielectricConstant', dielectricConstant);
    fprintf('  Dielectric constant: %.1f\n', dielectricConstant);
    
    % Set sensitivity threshold
    API.SetThreshold(sensitivityThreshold);
    fprintf('  Sensitivity threshold: %.1f\n', sensitivityThreshold);
    
    disp('✓ Advanced parameters configured');
    
catch ME
    API.Disconnect();
    error('Failed to set advanced parameters: %s', ME.message);
end

%% Step 6: Set Dynamic Filter (No filter for static pipe detection)
try
    disp('Setting dynamic imaging filter...');
    
    % Use no filter since we're detecting static objects (pipes)
    FILTER_NONE = WalabotAPI_NET.FILTER_TYPE.FILTER_TYPE_NONE;
    API.SetDynamicImageFilter(FILTER_NONE);
    disp('✓ Filter set to NONE (static object detection)');
    
catch ME
    API.Disconnect();
    error('Failed to set filter: %s', ME.message);
end

%% Step 7: Start Walabot System
try
    disp('Starting Walabot system...');
    API.Start();
    disp('✓ Walabot system started');
catch ME
    API.Disconnect();
    error('Failed to start Walabot: %s', ME.message);
end

%% Step 8: Calibrate System
try
    disp('Starting calibration (this may take a few seconds)...');
    disp('  Please ensure the wall area is clear of your hand/body');
    
    API.StartCalibration();
    
    % Wait for calibration to complete
    calibrationComplete = false;
    while ~calibrationComplete
        [status, calibrationProgress] = API.GetStatus();
        
        if status == WalabotAPI_NET.APP_STATUS.STATUS_CALIBRATING
            fprintf('  Calibration progress: %.0f%%\r', calibrationProgress);
        elseif status == WalabotAPI_NET.APP_STATUS.STATUS_SCANNING
            calibrationComplete = true;
            fprintf('\n✓ Calibration completed successfully\n');
        end
        
        pause(0.1);
    end
    
catch ME
    API.Stop();
    API.Disconnect();
    error('Failed during calibration: %s', ME.message);
end

%% Step 9: Main Detection Loop
disp('==========================================================');
disp('   Starting Pipe Detection - Press Ctrl+C to stop');
disp('==========================================================');

% Create figure for visualization
figure('Name', 'Walabot Pipe Detection', 'NumberTitle', 'off', ...
       'Position', [100, 100, 1200, 500]);

detectionCount = 0;

try
    while true
        detectionCount = detectionCount + 1;
        
        % Step 9a: Trigger scan
        API.Trigger();
        
        % Step 9b: Get imaging targets (pipes)
        targets = API.GetImagingTargets();
        numTargets = length(targets);
        
        % Step 9c: Get raw image slice for visualization
        [sizeX, sizeY, sliceDepth, power] = API.GetRawImageSlice();
        
        % Step 9d: Process and display results
        clf;
        
        % Subplot 1: Display detected targets information
        subplot(1, 2, 1);
        axis off;
        
        textStr = sprintf('=== Pipe Detection Results ===\n');
        textStr = [textStr sprintf('Scan #%d\n\n', detectionCount)];
        textStr = [textStr sprintf('Number of targets detected: %d\n\n', numTargets)];
        
        if numTargets > 0
            for i = 1:numTargets
                target = targets(i);
                
                % Extract target information
                targetType = char(target.type);
                xPos = target.xPosCm;
                yPos = target.yPosCm;
                zPos = target.zPosCm;
                width = target.widthCm;
                amplitude = target.amplitude;
                angle = target.angleDeg;
                
                textStr = [textStr sprintf('--- Target #%d ---\n', i)];
                textStr = [textStr sprintf('Type: %s\n', targetType)];
                textStr = [textStr sprintf('Position (X,Y,Z): (%.1f, %.1f, %.1f) cm\n', ...
                                          xPos, yPos, zPos)];
                textStr = [textStr sprintf('Width: %.1f cm\n', width)];
                textStr = [textStr sprintf('Angle: %.1f°\n', angle)];
                textStr = [textStr sprintf('Signal Amplitude: %.2f\n\n', amplitude)];
            end
        else
            textStr = [textStr 'No pipes detected in current scan.\n'];
            textStr = [textStr 'Try adjusting threshold or moving sensor.\n'];
        end
        
        textStr = [textStr sprintf('\nSlice Depth: %.1f cm\n', sliceDepth)];
        textStr = [textStr sprintf('Peak Power: %.2f\n', power)];
        
        text(0.1, 0.95, textStr, 'VerticalAlignment', 'top', ...
             'FontName', 'Courier', 'FontSize', 10, ...
             'Interpreter', 'none');
        
        % Subplot 2: Visualize raw image slice (if available)
        subplot(1, 2, 2);
        title('Raw Image Slice (X-Y Plane)');
        xlabel('X Position (pixels)');
        ylabel('Y Position (pixels)');
        
        % Note: The actual rasterImage data would need to be retrieved
        % This is a placeholder showing the concept
        text(0.5, 0.5, 'Raw Image Slice Visualization', ...
             'HorizontalAlignment', 'center');
        
        % Update display
        drawnow;
        
        % Small pause to control update rate
        pause(0.2);
    end
    
catch ME
    if strcmp(ME.identifier, 'MATLAB:interruption')
        disp('Detection stopped by user');
    else
        fprintf('Error during detection: %s\n', ME.message);
    end
end

%% Step 10: Cleanup
disp('==========================================================');
disp('   Shutting down Walabot system...');
disp('==========================================================');

try
    API.Stop();
    disp('✓ Walabot stopped');
catch
    warning('Error stopping Walabot');
end

try
    API.Disconnect();
    disp('✓ Disconnected from Walabot');
catch
    warning('Error disconnecting from Walabot');
end

try
    API.Clean();
    disp('✓ API cleaned up');
catch
    warning('Error cleaning up API');
end

disp('==========================================================');
disp('   Pipe Detection System Terminated Successfully');
disp('==========================================================');
