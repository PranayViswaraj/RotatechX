% Enhanced Fetal Monitoring and Visualization System
% Combines realistic ultrasound rendering with comprehensive monitoring
% Optimized layout with improved spacing and alignment

% Clear workspace and close figures
clear all;
close all;
clc;

%% Parameters for the simulation
fs = 100;                   % Sampling frequency (Hz)
simulationTime = 60;        % Total simulation time (seconds)
displayUpdateRate = 0.1;    % Display update interval (seconds)

% Fetal parameters
gestationalAge = 28;        % Gestational age in weeks
fetal_size = 0.25;          % Approximate size of fetus (m)
initial_position = [0, 0, 0.1]; % Initial position (x, y, z) in meters
head_position = 'downward'; % Initial head position
current_state = 'normal';   % Current movement state

% Maternal and Fetal Oxygen parameters
maternal_base = 97;         % Average maternal SpO₂
fetal_base_ratio = 0.75;    % Fetal oxygen level as a percentage of maternal
variation = 3;              % ±3% variation
maternal_oxygen = [];
fetal_oxygen = [];

% Heart Rate parameters
maternalHR = 75;            % Average maternal heart rate (BPM)
fetalHR = 140;              % Average fetal heart rate (BPM)
maternalHR_history = [];
fetalHR_history = [];

% Load sample ultrasound data (or generate synthetic data if not available)
try
    % Attempt to load pre-saved ultrasound image data
    load('fetal_ultrasound_data.mat');
    hasRealData = true;
catch
    % Generate synthetic ultrasound data
    hasRealData = false;
    disp('Generating synthetic ultrasound data...');
    % Create basic shapes for fetus
    [x, y] = meshgrid(-1:0.02:1, -1:0.02:1);
    head_radius = 0.3;
    body_length = 0.6;
    
    % Generate base ultrasound texture
    noise = randn(size(x)) * 0.3;
    background = exp(-(x.^2 + y.^2) / 0.8) * 0.5;
    
    % Create head and body
    head = exp(-((x).^2 + (y-0.4).^2) / head_radius^2);
    body = exp(-((x).^2 + (y+0.2).^2) / (body_length^2));
    
    % Combine with noise for ultrasound look
    ultrasound_base = (head * 0.8 + body * 0.7) .* (noise * 0.3 + 0.7) .* background;
    
    % Create frames for animation
    num_frames = 20;
    ultrasound_frames = cell(1, num_frames);
    for i = 1:num_frames
        % Add slight variations for movement
        movement = sin(x*10 + i/3) .* cos(y*8 + i/2) * 0.05;
        ultrasound_frames{i} = ultrasound_base + movement;
    end
end

% Create figure for live display - Adjust position and size for better layout
fig = figure('Position', [50, 50, 1800, 1000], 'Color', 'k', 'Name', 'Enhanced Fetal Monitoring System');

%% Simulation loop
t = 0;
timestamp = datestr(now, 'dd-mmm-yy HH:MM:SS');
movement_history = [];
kick_count = 0;
last_state = '';
last_head_position = '';

% Arrays to store movement data for plotting
time_data = [];
movement_data = [];
kick_times = [];
current_frame = 1;

while t < simulationTime
    % Clear the figure for update
    clf;
    
    % Simulate movement and state
    if rand < 0.05  % Random state changes
        states = {'normal', 'kicking', 'moving'};
        weights = [0.7, 0.15, 0.15];  % More likely to be in normal state
        cumweights = cumsum(weights);
        r = rand;
        state_idx = find(r <= cumweights, 1, 'first');
        current_state = states{state_idx};
        
        % If state changed to kicking, increment counter
        if strcmp(current_state, 'kicking') && ~strcmp(last_state, 'kicking')
            kick_count = kick_count + 1;
            kick_times(end+1) = t;
        end
    end
    
    % Random head position changes (less frequent)
    if rand < 0.01
        if strcmp(head_position, 'downward')
            head_position = 'upward';
        else
            head_position = 'downward';
        end
    end
    
    % Record state if changed for display
    if ~strcmp(current_state, last_state) || ~strcmp(head_position, last_head_position)
        movement_history = [movement_history; {t, current_state, head_position}];
        last_state = current_state;
        last_head_position = head_position;
    end
    
    % Calculate current position based on state
    switch current_state
        case 'kicking'
            % Simulate kicking motion
            displacement = 0.02 * sin(2*pi*2*t) * [rand, rand, rand];
            movement_intensity = 0.8 + 0.2*sin(2*pi*2*t);
        case 'moving'
            % Simulate general movement
            displacement = 0.01 * sin(2*pi*1*t) * [rand, rand, rand];
            movement_intensity = 0.5 + 0.1*sin(2*pi*1*t);
        otherwise
            % Normal subtle movement
            displacement = 0.005 * sin(2*pi*0.5*t) * [rand, rand, rand];
            movement_intensity = 0.2 + 0.05*sin(2*pi*0.5*t);
    end
    
    current_position = initial_position + displacement;
    
    % Store data for plotting
    time_data(end+1) = t;
    movement_data(end+1) = movement_intensity;
    
    % Generate new oxygen data
    maternal_value = maternal_base + (rand - 0.5) * 2 * variation;
    fetal_value = (maternal_value * fetal_base_ratio) + (rand - 0.5) * 2 * variation;
    
    % Store oxygen readings
    maternal_oxygen(end+1) = maternal_value;
    fetal_oxygen(end+1) = fetal_value;
    
    % Generate heart rate data (influenced by movement)
    maternal_hr_variation = 3;
    fetal_hr_variation = 5;
    
    % Add more variation if kicking
    if strcmp(current_state, 'kicking')
        fetal_hr_variation = 8;
    end
    
    current_maternal_hr = maternalHR + (rand - 0.5) * 2 * maternal_hr_variation;
    current_fetal_hr = fetalHR + (rand - 0.5) * 2 * fetal_hr_variation;
    
    % Store heart rate data
    maternalHR_history(end+1) = current_maternal_hr;
    fetalHR_history(end+1) = current_fetal_hr;
    
    % Keep only the most recent data points
    if length(time_data) > 600
        time_data = time_data(end-599:end);
        movement_data = movement_data(end-599:end);
        maternal_oxygen = maternal_oxygen(end-599:end);
        fetal_oxygen = fetal_oxygen(end-599:end);
        maternalHR_history = maternalHR_history(end-599:end);
        fetalHR_history = fetalHR_history(end-599:end);
    end
    
    %% IMPROVED LAYOUT - FIXED SPACING AND ALIGNMENT

    % Create a clean 4x4 grid with clear positioning
    % The key improvement is to set fixed positions with consistent margins
    
    %% Ultrasound Visualization (top left)
    subplot('Position', [0.05, 0.55, 0.40, 0.40]);
    
    % Display either real or synthetic ultrasound image
    if hasRealData
        % Use pre-loaded real ultrasound data
        current_frame = mod(current_frame, size(ultrasound_data, 3)) + 1;
        ultrasound_image = ultrasound_data(:,:,current_frame);
    else
        % Use synthetic ultrasound data with movement
        current_frame = mod(current_frame, num_frames) + 1;
        ultrasound_image = ultrasound_frames{current_frame};
        
        % Add effects based on current state
        if strcmp(current_state, 'kicking')
            % Add "kick" artifact
            kick_x = round(size(ultrasound_image, 2)/2 + 10*sin(t*5));
            kick_y = round(size(ultrasound_image, 1)/2 + 20);
            kick_radius = 10;
            [kX, kY] = meshgrid(1:size(ultrasound_image, 2), 1:size(ultrasound_image, 1));
            kick_effect = exp(-((kX-kick_x).^2 + (kY-kick_y).^2) / kick_radius^2) * 0.5;
            ultrasound_image = ultrasound_image + kick_effect;
        end
    end
    
    % Apply ultrasound-like post-processing
    ultrasound_image = min(max(ultrasound_image, 0), 1); % Clamp values
    
    % Display the ultrasound image
    imagesc(ultrasound_image);
    colormap(gray);
    
    % Add ultrasound-style overlay elements with improved spacing
    hold on;
    
    % Add scale markers on the side with less crowding (8 instead of 10)
    for i = 1:8
        y_pos = i * size(ultrasound_image, 1) / 8;
        plot([5, 15], [y_pos, y_pos], 'w-', 'LineWidth', 1);
    end
    
    % Add gestational age and other info - moved up for better visibility
    title(['Fetal Ultrasound (' num2str(gestationalAge) ' weeks)'], 'Color', 'w', 'FontSize', 14);
    
    % Add depth scale with better spacing between elements
    text(size(ultrasound_image, 2)-40, 20, 'Depth', 'Color', 'w', 'FontSize', 10);
    for i = 1:5
        y_pos = i * size(ultrasound_image, 1) / 5;
        text(size(ultrasound_image, 2)-35, y_pos, [num2str(i*2) ' cm'], 'Color', 'w', 'FontSize', 8, 'HorizontalAlignment', 'right');
    end
    
    % Add status indicators - better positioning
    status_color = [0, 1, 0]; % Green for normal
    if strcmp(current_state, 'kicking')
        status_text = 'FETAL KICK DETECTED';
        status_color = [1, 0, 0]; % Red for kicking
    elseif strcmp(current_state, 'moving')
        status_text = 'Movement Detected';
        status_color = [1, 1, 0]; % Yellow for moving
    else
        status_text = 'Normal';
    end
    
    % Add status text with better positioning - centered for prominence
    text(size(ultrasound_image, 2)/2, 25, status_text, 'Color', status_color, 'FontSize', 14, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % Add anatomical markers based on current state - well spaced
    if strcmp(head_position, 'downward')
        % Mark head position (cephalic)
        text(size(ultrasound_image, 2)/2, size(ultrasound_image, 1)/4, 'H', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    else
        % Mark head position (breech)
        text(size(ultrasound_image, 2)/2, 3*size(ultrasound_image, 1)/4, 'H', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    % Add heart position marker
    heart_x = size(ultrasound_image, 2)/2 + 10*sin(t);
    heart_y = size(ultrasound_image, 1)/2;
    plot(heart_x, heart_y, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
    
    % Add timestamp and machine info with better spacing
    text(10, size(ultrasound_image, 1)-25, timestamp, 'Color', 'w', 'FontSize', 8);
    text(10, size(ultrasound_image, 1)-10, 'TI-BAND Obstetric US', 'Color', 'w', 'FontSize', 8);
    
    % Remove axis ticks for cleaner look
    axis off;
    hold off;
    
    %% Movement Activity Graph (top right) - fixed position
    subplot('Position', [0.50, 0.70, 0.45, 0.25]);
    plot(time_data, movement_data, 'g-', 'LineWidth', 2);
    hold on;
    
    % Plot kick events with better positioning
    for kick_t = kick_times
        if kick_t >= min(time_data) && kick_t <= max(time_data)
            plot([kick_t, kick_t], [0, 1], 'r:', 'LineWidth', 1);
            % Position the kick marker 'K' with enough space
            text(kick_t, 0.92, 'K', 'Color', 'r', 'FontSize', 10, 'HorizontalAlignment', 'center');
        end
    end
    
    % Add grid and labels - increased font size for better readability
    grid on;
    xlabel('Time (s)', 'Color', 'w', 'FontSize', 11);
    ylabel('Movement Intensity', 'Color', 'w', 'FontSize', 11);
    title('Fetal Movement Activity', 'Color', 'w', 'FontSize', 13);
    axis([max(0, t-30), max(30, t), 0, 1]);
    
    % Set colors
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3, 0.3, 0.3]);
    hold off;
    
    %% Dedicated Fetal Heart Rate Graph (middle row, first column)
    subplot('Position', [0.05, 0.35, 0.40, 0.15]);
    % Plot fetal heart rate with thicker line and better visibility
    plot(fetalHR_history, '-r', 'LineWidth', 2.5);
    hold on;
    
    % Add reference lines for normal fetal HR ranges
    plot([1, length(fetalHR_history)], [130, 130], 'r:', 'LineWidth', 1);
    plot([1, length(fetalHR_history)], [150, 150], 'r:', 'LineWidth', 1);
    
    % Highlight with points for emphasis
    plot(length(fetalHR_history), fetalHR_history(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    
    % Add current value text - positioned to avoid overlap
    text(length(fetalHR_history)-10, fetalHR_history(end)+3, sprintf('%.1f BPM', fetalHR_history(end)), ...
        'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Add grid and labels
    grid on;
    title('Fetal Heart Rate', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('BPM', 'Color', 'r', 'FontSize', 12);
    xlabel('Time', 'Color', 'w', 'FontSize', 10);
    
    % Set axis limits for better visualization
    ylim([120, 160]);
    
    % Set colors
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'r', 'GridColor', [0.3, 0.3, 0.3]);
    hold off;
    
    %% Dedicated Fetal Oxygen Graph (middle row, second column)
    subplot('Position', [0.05, 0.15, 0.40, 0.15]);
    % Plot fetal oxygen with thicker line and better visibility
    plot(fetal_oxygen, '-b', 'LineWidth', 2.5);
    hold on;
    
    % Add reference lines for normal fetal oxygen ranges
    plot([1, length(fetal_oxygen)], [70, 70], 'b:', 'LineWidth', 1);
    plot([1, length(fetal_oxygen)], [80, 80], 'b:', 'LineWidth', 1);
    
    % Highlight with points for emphasis
    plot(length(fetal_oxygen), fetal_oxygen(end), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    
    % Add current value text - positioned to avoid overlap
    text(length(fetal_oxygen)-10, fetal_oxygen(end)+2, sprintf('%.1f%%', fetal_oxygen(end)), ...
        'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Add grid and labels
    grid on;
    title('Fetal Oxygen Saturation', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('SpO₂ (%)', 'Color', 'b', 'FontSize', 12);
    xlabel('Time', 'Color', 'w', 'FontSize', 10);
    
    % Set axis limits for better visualization
    ylim([65, 85]);
    
    % Set colors
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'b', 'GridColor', [0.3, 0.3, 0.3]);
    hold off;
    
    %% Color Doppler visualization (middle row, right)
    subplot('Position', [0.50, 0.35, 0.45, 0.30]);
    
    % Create a simulated Doppler image
    [x, y] = meshgrid(-1:0.02:1, -1:0.02:1);
    
    % Create anatomical structures
    vessel1 = exp(-((x+0.2).^2 + (y-0.2).^2) / 0.05);
    vessel2 = exp(-((x-0.2).^2 + (y-0.2).^2) / 0.05);
    vessel3 = exp(-((x).^2 + (y+0.3).^2) / 0.08);
    
    % Base grayscale image
    gray_image = exp(-(x.^2 + y.^2) / 0.8) * 0.7 + randn(size(x)) * 0.1;
    
    % Create Doppler overlay
    doppler_flow = zeros(size(x,1), size(x,2), 3);
    
    % Add blue Doppler for flow away from transducer
    flow1 = vessel1 * (0.8 + 0.2*sin(t*4));
    doppler_flow(:,:,3) = flow1 * (0.8 + 0.2*sin(t*5));
    
    % Add red Doppler for flow towards transducer
    flow2 = vessel2 * (0.7 + 0.3*sin(t*3));
    doppler_flow(:,:,1) = flow2;
    
    % Create yellow for high velocity (combining red and green)
    flow3 = vessel3 * (0.6 + 0.4*sin(t*6));
    doppler_flow(:,:,1) = doppler_flow(:,:,1) + flow3;
    doppler_flow(:,:,2) = flow3;
    
    % Combine grayscale and Doppler
    rgb_image = repmat(gray_image, [1 1 3]);
    doppler_mask = sum(doppler_flow, 3) > 0.1;
    doppler_mask = repmat(doppler_mask, [1 1 3]);
    combined_image = rgb_image .* ~doppler_mask + doppler_flow .* doppler_mask;
    
    % Display the Doppler image
    imagesc(combined_image);
    
    % Add vascular labels with better spacing
    hold on;
    text(size(combined_image,2)*0.25, size(combined_image,1)*0.2, 'AAO', 'Color', 'w', 'FontSize', 10);
    text(size(combined_image,2)*0.75, size(combined_image,1)*0.2, 'MPA', 'Color', 'w', 'FontSize', 10);
    text(size(combined_image,2)*0.5, size(combined_image,1)*0.7, 'DAO', 'Color', 'w', 'FontSize', 10);
    text(size(combined_image,2)*0.15, size(combined_image,1)*0.4, 'SVC', 'Color', 'w', 'FontSize', 10);
    
    % Add arrows to show flow direction - improved positioning
    quiver(size(combined_image,2)*0.25, size(combined_image,1)*0.25, 5, 5, 'w', 'LineWidth', 1);
    quiver(size(combined_image,2)*0.75, size(combined_image,1)*0.25, -5, 5, 'w', 'LineWidth', 1);
    
    % Add orientation markers - better spacing
    text(15, 20, 'R', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    text(size(combined_image,2)-25, 20, 'L', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    
    title('Fetal Cardiovascular Doppler', 'Color', 'w', 'FontSize', 14);
    axis off;
    hold off;
    
    %% Maternal monitoring (bottom left)
    subplot('Position', [0.50, 0.15, 0.45, 0.15]);
    % Combined maternal metrics plot
    
    % First axis for heart rate
    yyaxis left;
    plot(maternalHR_history, '-g', 'LineWidth', 2);
    ylabel('Heart Rate (BPM)', 'Color', 'g', 'FontSize', 10);
    ylim([65 85]);
    
    % Second axis for oxygen
    yyaxis right;
    plot(maternal_oxygen, '-c', 'LineWidth', 2);
    ylabel('SpO₂ (%)', 'Color', 'c', 'FontSize', 10);
    ylim([90 100]);
    
    % Add current values with vertical spacing
    text(5, 69, sprintf('HR: %.1f BPM', maternalHR_history(end)), 'Color', 'g', 'FontSize', 10, 'FontWeight', 'bold');
    text(5, 75, sprintf('SpO₂: %.1f%%', maternal_oxygen(end)), 'Color', 'c', 'FontSize', 10, 'FontWeight', 'bold');
    
    % Add grid and title
    grid on;
    title('Maternal Vital Signs', 'Color', 'w', 'FontSize', 14);
    xlabel('Time', 'Color', 'w', 'FontSize', 10);
    
    % Set colors
    set(gca, 'Color', 'k', 'XColor', 'w', 'GridColor', [0.3, 0.3, 0.3]);
    
    %% Information Panel (bottom right) - redesigned with fixed spacing
    subplot('Position', [0.05, 0.02, 0.90, 0.11]);
    axis([0 1 0 1]);
    set(gca, 'Color', 'k');
    hold on;
    
    % Display fetal monitoring information with improved spacing
    title('Fetal Assessment Summary', 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Left column - Clear vertical spacing
    text(0.05, 0.85, 'CURRENT STATUS:', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.05, 0.65, ['Movement: ' current_state], 'Color', status_color, 'FontSize', 11, 'FontWeight', 'bold');
    text(0.05, 0.45, ['Head Position: ' head_position], 'Color', 'w', 'FontSize', 11);
    text(0.05, 0.25, ['Kicks Detected: ' num2str(kick_count)], 'Color', 'r', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Calculate activity level
    recent_activity = mean(movement_data(max(1, end-100):end));
    activity_text = 'LOW';
    activity_color = [0, 1, 0];
    
    if recent_activity > 0.6
        activity_text = 'HIGH';
        activity_color = [1, 0, 0];
    elseif recent_activity > 0.3
        activity_text = 'MEDIUM';
        activity_color = [1, 1, 0];
    end
    
    text(0.25, 0.65, ['Activity Level: ' activity_text], 'Color', activity_color, 'FontSize', 11, 'FontWeight', 'bold');
    
    % Center column
    text(0.45, 0.85, 'FETAL VITALS:', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.45, 0.65, sprintf('HR: %.1f BPM', fetalHR_history(end)), 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.45, 0.45, sprintf('SpO₂: %.1f%%', fetal_oxygen(end)), 'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Calculate biophysical profile components (simplified)
    if recent_activity > 0.4
        bpp_movement = 2;
    else
        bpp_movement = 0;
    end
    
    if strcmp(current_state, 'kicking')
        bpp_tone = 2;
    else
        bpp_tone = 0;
    end
    
    if rand > 0.3
        bpp_breathing = 2;
    else
        bpp_breathing = 0;
    end
    
    bpp_fluid = 2;  % Assuming normal
    
    if abs(fetalHR_history(end) - 140) < 10
        bpp_hr = 2;
    else
        bpp_hr = 0;
    end
    
    bpp_total = bpp_movement + bpp_tone + bpp_breathing + bpp_fluid + bpp_hr;
    
    % Right column
    text(0.70, 0.85, 'FETAL ASSESSMENT:', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.70, 0.65, ['Gestational Age: ' num2str(gestationalAge) ' weeks'], 'Color', 'w', 'FontSize', 11);
    text(0.70, 0.45, ['Biophysical Profile: ' num2str(bpp_total) '/10'], 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Add estimated fetal weight
    efwGrams = gestationalAge * 100 - 500;  % Simple estimation
    text(0.70, 0.25, ['Est. Fetal Weight: ' num2str(efwGrams) ' g'], 'Color', 'w', 'FontSize', 11);
    
    % Add fetal presentation
    if strcmp(head_position, 'downward')
        presentation = 'Cephalic';
    else
        presentation = 'Breech';
    end
    text(0.90, 0.65, ['Presentation: ' presentation], 'Color', 'w', 'FontSize', 11);
    
    % Session info
    text(0.90, 0.45, sprintf('Session time: %.1f s', t), 'Color', 'w', 'FontSize', 11);
    text(0.90, 0.25, sprintf('Data points: %d', length(time_data)), 'Color', 'w', 'FontSize', 11);
    
    % Add timestamp at bottom
    text(0.5, 0.05, timestamp, 'Color', 'w', 'FontSize', 9, 'HorizontalAlignment', 'center');
    
    axis off;
    hold off;
    
    % Display relevant data in the command window
    fprintf('Time: %.1fs | Movement: %s | Maternal SpO₂: %.1f%% | Fetal SpO₂: %.1f%% | Maternal HR: %.1f BPM | Fetal HR: %.1f BPM\n', ...
        t, current_state, maternal_oxygen(end), fetal_oxygen(end), maternalHR_history(end), fetalHR_history(end));
    
    % Update the figure
    drawnow;
    
    % Advance the frame counter
    current_frame = current_frame + 1;
    
    % Increment time
    pause(displayUpdateRate);
    t = t + displayUpdateRate;
end

%% Helper functions for ultrasound processing

% Function to add speckle noise to ultrasound image
function out_img = addSpeckleNoise(img, amount)
    if nargin < 2
        amount = 0.2;
    end
end
