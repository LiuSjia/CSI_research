
function spotfi_file_runner(input_file_name)
    %% DEBUG AND OUTPUT VARIABLES-----------------------------------------------------------------%%
    globals_init()
    global DEBUG_BRIDGE_CODE_CALLING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get the full path to the currently executing file and change the
    % pwd to the folder this file is contained in...
    [current_directory, ~, ~] = fileparts(mfilename('fullpath'));
    cd(current_directory);
    % Paths for the csitool functions provided
    path('../../linux-80211n-csitool-supplementary/matlab', path);
    if DEBUG_BRIDGE_CODE_CALLING
        fprintf('The path: %s\n', path)
        fprintf('The pwd: %s\n', pwd)
    end
    if ~DEBUG_BRIDGE_CODE_CALLING
        close all
        clc
    end
    % data_files = {'test-data/line-of-sight-localization-tests--in-room/los-test-heater.dat'};
    % top_aoas = run(data_files);
    % top_aoas
    if nargin == 0 
        data_file = '../injection-monitor/.lgtm-monitor.dat';
    else
        %data_file = sprintf('../injection-monitor/%s', input_file_name);
        data_file = input_file_name;
    end
    fprintf('data_file: %s\n', data_file)
    %data_file = 'test-data/line-of-sight-localization-tests--in-room/los-test-heater.dat';
    top_aoas = run(data_file);
    output_file_name = '../injection-monitor/.lgtm-top-aoas';
    output_top_aoas(top_aoas, output_file_name);
    if DEBUG_BRIDGE_CODE_CALLING
        fprintf('Done Running!\n')
    end
end

%% Output the array of top_aoas to the given file as doubles
% top_aoas         -- The angle of arrivals selected as the most likely.
% output_file_name -- The name of the file to write the angle of arrivals to.
function output_top_aoas(top_aoas, output_file_name)
    output_file = fopen(output_file_name, 'wb');
    if (output_file < 0)
        error('Couldn''t open file %s', output_file_name);
    end
    top_aoas
    for ii = 1:size(top_aoas, 1)
        fprintf(output_file, '%g ', top_aoas(ii, 1));
    end
    fprintf(output_file, '\n');
    fclose(output_file);
end

function globals_init
    %% DEBUG AND OUTPUT VARIABLES-----------------------------------------------------------------%%
    % Debug Controls
    global DEBUG_PATHS
    global DEBUG_PATHS_LIGHT
    global NUMBER_OF_PACKETS_TO_CONSIDER
    global DEBUG_BRIDGE_CODE_CALLING
    DEBUG_PATHS = false;
    DEBUG_PATHS_LIGHT = false;
    NUMBER_OF_PACKETS_TO_CONSIDER = 10; % Set to -1 to ignore this variable's value
    DEBUG_BRIDGE_CODE_CALLING = false;
    
    % Output controls
    global OUTPUT_AOAS
    global OUTPUT_TOFS
    global OUTPUT_AOA_MUSIC_PEAK_GRAPH
    global OUTPUT_TOF_MUSIC_PEAK_GRAPH
    global OUTPUT_AOA_TOF_MUSIC_PEAK_GRAPH
    global OUTPUT_SELECTIVE_AOA_TOF_MUSIC_PEAK_GRAPH
    global OUTPUT_AOA_VS_TOF_PLOT
    global OUTPUT_SUPPRESSED
    global OUTPUT_PACKET_PROGRESS
    global OUTPUT_FIGURES_SUPPRESSED
    OUTPUT_AOAS = false;
    OUTPUT_TOFS = false;
    OUTPUT_AOA_MUSIC_PEAK_GRAPH = false;%true;
    OUTPUT_TOF_MUSIC_PEAK_GRAPH = false;%true;
    OUTPUT_AOA_TOF_MUSIC_PEAK_GRAPH = false;
    OUTPUT_SELECTIVE_AOA_TOF_MUSIC_PEAK_GRAPH = false;
    OUTPUT_AOA_VS_TOF_PLOT = false;
    OUTPUT_SUPPRESSED = true;
    OUTPUT_PACKET_PROGRESS = false;
    OUTPUT_FIGURES_SUPPRESSED = false; % Set to true when running in deployment from command line
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%% Runs the SpotFi test over the passed in data files which each 
% contain CSI data for many packets
% data_files -- a cell array of file paths to data files
function output_top_aoas = run(data_file)
    %% DEBUG AND OUTPUT VARIABLES-----------------------------------------------------------------%%
    % Debug Controls
    global NUMBER_OF_PACKETS_TO_CONSIDER
    
    % Output controls
    global OUTPUT_SUPPRESSED
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set physical layer parameters (frequency, subfrequency spacing, and antenna spacing
    
    % frequency = 5 * 10^9;
    % frequency = 5.785 * 10^9;

    frequency = 5.745 * 10^9;
    sub_freq_delta = (40 * 10^6) / 30;
	c = 3*10^8;
	lambda = c / frequency;
	antenna_distance = lambda / 2;

    % Read data file in
    if OUTPUT_SUPPRESSED
        fprintf('\n\nRunning on data file: %s\n', data_file)
    end
    csi_trace = read_bf_file(data_file); % cell array 
    % Extract CSI information for each packet
    if OUTPUT_SUPPRESSED
        fprintf('Have CSI for %d packets\n', length(csi_trace))
    end

    % Set the number of packets to consider, by default consider all
    num_packets = length(csi_trace);
    if NUMBER_OF_PACKETS_TO_CONSIDER ~= -1
        num_packets = NUMBER_OF_PACKETS_TO_CONSIDER;
    end
    if OUTPUT_SUPPRESSED
        fprintf('Considering CSI for %d packets\n', num_packets)
    end
    %% TODO: Remove after testing
    fprintf('csi_trace\n')
    fprintf('num_packets: %d\n', num_packets)
    sampled_csi_trace = csi_sampling(csi_trace, num_packets, ...
            1, length(csi_trace));
    
    output_top_aoas = spotfi(sampled_csi_trace, frequency, sub_freq_delta, antenna_distance);
end