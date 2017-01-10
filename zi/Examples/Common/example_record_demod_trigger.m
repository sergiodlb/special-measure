function [data, config] = example_record_demod_trigger(device_id, varargin)
% EXAMPLE_RECORD_DEMOD_TRIGGER Record data using a demodulator trigger via ziDAQ's record module
%
% NOTE This example can only be ran on a device with the MF (multi-frequency)
% option enabled. It is intended to be a completely stand-alone example that
% generates and captures it's own triggers. As such, it requires a simple
% feedback BNC cable between Signal Output 0 and Signal Input 0 of the device.
%
% USAGE DATA = EXAMPLE_RECORD_DEMOD_TRIGGER(DEVICE_ID)
%  
% Record demodulator sample data using a software trigger from ziDAQ's
% 'record' module from the device specified by DEVICE_ID, e.g., 'dev2006' or
% 'uhf-dev2006'.
%
% The record module implements software triggering analogously to the types of
% triggering found in spectroscopes.
% 
% This example generates a 'beat' in the demodulator signal in order to
% simulate 'events' in the demodulator data. Signal segments of these events
% are then recorded when the rising edge of the demodulator R value exceeds a
% certain threshold.
% 
% NOTE Additional configuration: Connect signal output 1 to signal input 1
% with a BNC cable.
%
% NOTE Please ensure that the ziDAQ folders 'Driver' and 'Utils' are in your
% Matlab path. To do this (temporarily) for one Matlab session please navigate
% to the ziDAQ base folder containing the 'Driver', 'Examples' and 'Utils'
% subfolders and run the Matlab function ziAddPath().  
% >>> ziAddPath;
%
% Use either of the commands:
% >>> help ziDAQ
% >>> doc ziDAQ 
% in the Matlab command window to obtain help on all available ziDAQ commands.
%
% Copyright 2008-2015 Zurich Instruments AG

clear ziDAQ;
    
if ~exist('device_id', 'var')
    error(['No value for device_id specified. The first argument to the ' ...
           'example should be the device ID on which to run the example, ' ...
           'e.g. ''dev2006'' or ''uhf-dev2006''.'])
end

% Check the ziDAQ MEX (DLL) and Utility functions can be found in Matlab's path.
if ~(exist('ziDAQ') == 3) && ~(exist('ziDevices', 'file') == 2)
    fprintf('Failed to either find the ziDAQ mex file or ziDevices() utility.\n')
    fprintf('Please configure your path using the ziDAQ function ziAddPath().\n')
    fprintf('This can be found in the API subfolder of your LabOne installation.\n');
    fprintf('On Windows this is typically:\n');
    fprintf('C:\\Program Files\\Zurich Instruments\\LabOne\\API\\MATLAB2012\\\n');
    return
end

% Determine the device identifier from it's ID.
device = lower(ziDAQ('discoveryFind', device_id));

% Get the device's default connectivity properties.
props = ziDAQ('discoveryGet', device);

% The maximum API level supported by this example.
apilevel_example = 5;
% The maximum API level supported by the device class, e.g., MF.
apilevel_device = props.apilevel;
% Ensure we run the example using a supported API level.
apilevel = min(apilevel_device, apilevel_example);
% See the LabOne Programming Manual for an explanation of API levels.

% Create a connection to a Zurich Instruments Data Server (a API session)
% using the device's default connectivity properties.
ziDAQ('connect', props.serveraddress, props.serverport, apilevel);

% Check that the device is visible to the Data Server.
if ~ismember(device, ziDevices())
    message = ['The specified device `', device, '` is not visible to the Data ', ...
               'Server. Please ensure the device is connected by using the LabOne ', ...
               'User Interface or ziControl (HF2 Instruments).'];
    error(message);
end

% Get the device type and its options (in order to set correct device-specific
% configuration).
devtype = ziDAQ('getByte', ['/' device '/features/devtype']);
options = ziDAQ('getByte', ['/' device '/features/options']);

if (length(regexp(devtype, 'UHFLI|MFLI', 'match')) > 0) && ...
        (length(regexp(options, 'MF|MD', 'match')) == 0)
    error(['This example requires either an HF2, UHF with MF or an MFLI with MD ' ...
           'option installed. Device `%s` reports devtype `%s` and options ' ...
           '`%s`.'], device, devtype, options);
end

fprintf('Will run the example on `%s`, an `%s` with options `%s`.\n', device, ...
        devtype, regexprep(options, '\n' , '|'));

[data, config] = run_example(device, devtype, options, varargin{:});

end


function [data, config] = run_example(device, devtype, options, varargin)

% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
%
% NOTE The possible choice of the parameters:
% - demod_rate (and the number of demods enabled=^length(demod_idx)), 
% - event_frequency (the number of triggers we record per second), 
% are highly constrained by the performance of the PC where the Data Server
% and Matlab API client are running. The values of the parameters set here are
% conservative. Much higher values can be obtained on state-of-the-art PCs
% (e.g., 400e3 demod_rate (2 or 3 demods) and event_frequency 5000 for UHF).
% Whilst experimenting with parameter values, it's advisable to monitor CPU
% load and memory usage.
p = inputParser;
isnonnegscalar = @(x) isnumeric(x) && isscalar(x) && (x > 0);
isnonnegvector = @(x) isnumeric(x) && isvector(x) && all(x > 0);
% The indices of the demodulators to record for the experiment, 1-based
% indexing.
p.addParamValue('demod_idx', [1, 2], isnonnegvector);
% Pick a suitable (although conservative) demodulator rate based on the device
% class.
if strfind(devtype, 'UHF')
    default_demod_rate = 100e3;
else
    default_demod_rate = 56e3;
end
p.addParamValue('demod_rate', default_demod_rate, isnonnegscalar);
p.addParamValue('event_frequency', 100, isnonnegscalar);
p.addParamValue('trigger_count', 1000, isnonnegscalar);
p.parse(varargin{:});

% More parameters relevant to this example, some of which we derive from the
% inputParser parameters. We package them in a struct for convenience.
config = struct();

% The value later used for the SW Trigger's 'trigger/0/duration' parameter:
% This is the duration in seconds of signal segment to record: Let's record
% half the duration of each beat.
config.trigger_duration = 0.5/p.Results.event_frequency;  % [s]

% The value later used for the SW Trigger's 'trigger/0/delay' parameter: This
% specifies the delay in seconds to wait before recording the signal after the
% point in the time when the trigger is activated. A negative value indicates
% a pretrigger time.
config.trigger_delay = -0.125/p.Results.event_frequency;  % [s]

% Signal output mixer amplitude, [V]. The trigger threshold must be based on
% this.
amplitude = 0.100;

% The value later used for the SW Trigger's 'trigger/0/level' parameter: This
% specifieds threshold level required to trigger an event.
config.trigger_level = 0.45*amplitude/sqrt(2.);

fprintf('Event frequency (beat freqency): %.1f\n', p.Results.event_frequency);

% Define some other helper parameters.
config.demod_idx = p.Results.demod_idx;
config.device = device;
config.clockbase = double(ziDAQ('getInt', ['/' device '/clockbase']));

% demod_idx is used to access the data in Matlab arrays and are therefore
% 1-based indexed. Node paths on the HF2/UHF use 0-based indexing.
config.demod_c = zeros(size(p.Results.demod_idx));
for ii=p.Results.demod_idx
    config.demod_c(ii) = num2str(p.Results.demod_idx(ii)-1, '%0d');
end

out_c = '0';
in_c = '0';

% create a base configuration: disable all outputs, demods and scopes
ziDAQ('setDouble', ['/' device '/demods/*/rate'], 0.0);
ziDAQ('setInt', ['/' device '/demods/*/trigger'], 0);
ziDAQ('setInt', ['/' device '/sigouts/*/enables/*'], 0);
if length(regexp(devtype, 'MFLI|UHFLI', 'match')) > 0
% Additionally disable all demodulators.
    ziDAQ('setInt', ['/' device '/demods/*/enable'], 0);
    ziDAQ('setInt', ['/' device '/scopes/*/enable'], 0);
elseif strfind(devtype, 'HF2')
    ziDAQ('setInt', ['/' device '/scopes/*/trigchannel'], -1)
end

% configure the device ready for this experiment
ziDAQ('setInt', ['/' device '/sigins/' in_c '/imp50'], 1);
ziDAQ('setInt', ['/' device '/sigins/' in_c '/ac'], 0);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/range'], 2);
ziDAQ('setInt', ['/' device '/sigouts/' out_c '/on'], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/range'], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/*'], 0);
if strfind(devtype, 'HF2')
    ziDAQ('setInt', ['/' device '/sigins/' in_c '/diff'], 0);
    ziDAQ('setInt', ['/' device '/sigouts/' out_c '/add'], 0);
end
ziDAQ('setDouble', ['/' device '/demods/*/phaseshift'], 0);
for d=config.demod_c
    ziDAQ('setDouble', ['/' device '/demods/' d '/rate'], p.Results.demod_rate);
end
% Ensure the configuration has taken effect before reading back the value actually set.
ziDAQ('sync');
demod_rate_set = ziDAQ('getDouble', ['/' device '/demods/' config.demod_c(1) '/rate']);

ziDAQ('setInt', ['/' device '/demods/*/harmonic'], 1);
if length(regexp(devtype, 'MFLI|UHFLI', 'match')) > 0
    for d=config.demod_c
        ziDAQ('setInt', ['/' device '/demods/' d '/enable'], 1);
    end
end
ziDAQ('setInt', ['/' device '/demods/*/adcselect'], str2double(in_c));  % requires MF option
ziDAQ('setInt', ['/' device '/demods/*/oscselect'], 0);  % requires MF option

% Generate the beat.
ziDAQ('setInt', ['/' device '/demods/0/oscselect'], 0);
ziDAQ('setInt', ['/' device '/demods/1/oscselect'], 1);  % requires MF option
ziDAQ('setDouble', ['/' device '/oscs/*/freq'], 400e3);  % [Hz]
ziDAQ('setDouble', ['/' device '/oscs/1/freq'], 400e3 + p.Results.event_frequency);  % [Hz]
% We require 2 Signal Output mixer channels to signals of two frequencies in
% order to generate the beat.
if ~isempty(strfind(devtype, 'HF2LI')) && isempty(strfind(options, 'MF'))
    out_mixer_c_0 = '6';
    out_mixer_c_1 = '7';
else
    out_mixer_c_0 = '0';
    out_mixer_c_1 = '1';
end
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/' out_mixer_c_0], amplitude);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/' out_mixer_c_1], amplitude);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/enables/' out_mixer_c_0], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/enables/' out_mixer_c_1], 1);
order = 4;
ziDAQ('setInt', ['/' device '/demods/*/order'], order);
% A small timeconstant is required to see the interference between the
% demodulators
timeconstant = bw2tc(demod_rate_set/2, order);
ziDAQ('setDouble', ['/' device '/demods/0/timeconstant'], timeconstant);
timeconstant = bw2tc(10e3, order);
ziDAQ('setDouble', ['/' device '/demods/1/timeconstant'], timeconstant);
timeconstant = bw2tc(p.Results.event_frequency, order);
ziDAQ('setDouble', ['/' device '/demods/2/timeconstant'], timeconstant);
for i=1:length(config.demod_c)
    timeconstants_set(i) = ziDAQ('getDouble', ['/' device '/demods/' config.demod_c(i) '/timeconstant']);
end

% Unsubscribe from any streaming data
ziDAQ('unsubscribe', '*');
% Flush all the buffers.
ziDAQ('sync'); 

% Wait for the demodulator filter to settle
pause(20*max(timeconstants_set));

% Create a recorder thread, the return argument is a handle to the recorder
% (thread).
record_buffer_length = 0.2;  % This should be larger than trigger_duration
record_timeout = 1000;
record_flags = 1;  % Fill holes in data upon sampleloss
h = ziDAQ('record', record_buffer_length, record_timeout, record_flags);

%% Configure the recorder
% The number of triggers to capture (if not running in endless mode).
ziDAQ('set', h, 'trigger/0/count', p.Results.trigger_count);
ziDAQ('set', h, 'trigger/endless', 0);
%   type:
%     NO_TRIGGER = 0
%     EDGE_TRIGGER = 1
%     DIGITAL_TRIGGER = 2
%     PULSE_TRIGGER = 3
%     TRACKING_TRIGGER = 4
ziDAQ('set', h, 'trigger/0/type', 1);
% Specify the demodulator sample path to trigger on
ziDAQ('set', h, 'trigger/0/path', ['/' device '/demods/' config.demod_c(1) '/sample'])
%   edge:
%     POS_EDGE = 1
%     NEG_EDGE = 2
%     BOTH_EDGE = 3
ziDAQ('set', h, 'trigger/0/edge', 1)
ziDAQ('set', h, 'trigger/0/duration', config.trigger_duration);
ziDAQ('set', h, 'trigger/0/bitmask', 1)
ziDAQ('set', h, 'trigger/0/bits', 1)
ziDAQ('set', h, 'trigger/0/delay', config.trigger_delay)
ziDAQ('set', h, 'trigger/0/retrigger', 0)
ziDAQ('set', h, 'trigger/0/holdoff/time', 0.0)
ziDAQ('set', h, 'trigger/0/holdoff/count', 0)
ziDAQ('set', h, 'trigger/0/level', config.trigger_level)
% The hysterisis is effectively a second criteria (if non-zero) for triggering
% and makes triggering more robust in noisy signals. When the trigger `level`
% is violated, then the signal must return beneath (for positive trigger edge)
% the hysteresis value in order to trigger.
ziDAQ('set', h, 'trigger/0/hysteresis', 0.1*config.trigger_level)
%   source:
%     X_SOURCE = 0
%     Y_SOURCE = 1
%     R_SOURCE = 2
%     ANGLE_SOURCE = 3
%     FREQUENCY_SOURCE = 4
%     PHASE_SOURCE = 5
%     AUXIN0_SOURCE = 6
%     AUXIN1_SOURCE = 7
ziDAQ('set', h, 'trigger/0/source', 2)

%% Subscribe to the demodulators
% fliplr: Subscribe in descending order so that we subscribe to the trigger
% demdulator last (demod 0). This way we will not start acquiring data on the
% trigger demod before we subscribe to other demodulators. 
for d=fliplr(config.demod_c)
    ziDAQ('subscribe', h, ['/' device '/demods/' d '/sample']);
end

% Prepare a figure for plotting
figure(1); clf;
box on; grid on; hold on;
xlabel('\bf Time (relative to trigger position) [s]');
ylabel('\bf Signal');

fprintf('Num samples per signal segment: %d\n', demod_rate_set*config.trigger_duration);

%% Start recording
% now start the thread -> ready to be triggered
ziDAQ('execute', h);

timeout = 20; % [s]
num_triggers = 0;
n = 0;
t0 = tic;
tRead = tic;
dt_read = 0.250;
while ~ziDAQ('finished', h)
    pause(0.05);
    % Perform an intermediate readout of the data. the data between reads is
    % not acculmulated in the module - it is cleared, so that the next time
    % you do a read you (should) only get the triggers that came inbetween the
    % two reads.
    if toc(tRead) > dt_read
        data = ziDAQ('read', h);
        fprintf('Performed an intermediate read() of recorded data (time since last read %.3f s).\n', toc(tRead));
        fprintf('Recorder progress (acquired %d of total %d triggers): %.1f%%\n', num_triggers, p.Results.trigger_count, 100*ziDAQ('progress', h));
        tRead = tic;
        if ziCheckPathInData(data, ['/' device '/demods/' config.demod_c(1) '/sample'])
            num_triggers = num_triggers + check_data(data, config);
            % Do some other processing and save data...
            % ...
        end
    end
    % Timeout check
    if toc(t0) > timeout
        % If for some reason we're not obtaining triggers quickly enough, the
        % following command will force the end of the recording.
        if num_triggers == 0
            ziDAQ('finish', h);
            ziDAQ('clear', h);
            error('Failed to record any triggers before timeout (%d seconds). Missing feedback cable between sigout 0 and sigin 0?', timeout);
        else
            fprintf('Recorded %d triggers. Loop timeout (%.2f s) before acquiring %d triggers\n');
            fprintf('Increase loop `timeout` to record more.\n', num_triggers, timeout, p.Results.trigger_count);
        end
    end
end
tEnd = toc(t0);

ziDAQ('unsubscribe', h, ['/' device '/demods/*/sample']);
ziDAQ('clear', h);

end

function num_triggers = check_data(data, config)
%CHECK_DATA check data for sampleloss and plot some triggers for feedback

device = config.device;
demod_idx = config.demod_idx;

% We use cell arrays to address the individual segments from each trigger
num_triggers = length(data.(device).demods(demod_idx(1)).sample);
if num_triggers == 0
    return
end
fprintf('Data contains %d data segments (triggers).\n', num_triggers);
sampleloss = check_segments_for_sampleloss(data, config);
if any(sampleloss)
    fprintf('Warning: Sampleloss detected in %d triggers.\n', sum(sampleloss));
    if sum(sampleloss) == num_triggers
        error('Error all triggers contained sampleloss.\n');
    end
else
    fprintf('No sampleloss detected.\n');
end

figure(1); cla;
plot_style = {'r-', 'b-', 'g-', 'k-'};
num_triggers_plotted = 0;
for i=1:num_triggers
    if num_triggers_plotted >= 100;
        % Only plot first 100 valid triggers.
        break;
    end
    if sampleloss(i)
        continue
    end
    t_start = [];
    for d=1:length(config.demod_c)
        % Convert timestamps from ticks to seconds via the device's clockbase
        % (the ADC's sampling rate)
        t0 = double(data.(device).demods(demod_idx(d)).sample{i}.timestamp(1))/config.clockbase;
        t_start = [t_start t0];
    end
    t_start = min(t_start);
    for d=1:length(config.demod_c)
        t = double(data.(device).demods(demod_idx(d)).sample{i}.timestamp)/config.clockbase;
        R = sqrt(data.(device).demods(demod_idx(d)).sample{i}.x.^2 + data.(device).demods(demod_idx(d)).sample{i}.y.^2);
        s(d) = plot(t - t_start + config.trigger_delay, R, plot_style{d});
        set(s(d), 'LineWidth', 1.2);
    end
    num_triggers_plotted = num_triggers_plotted + 1;
end
plot(get(gca, 'xlim'), [config.trigger_level, config.trigger_level], '--k');
plot([0.0, 0.0], get(gca, 'ylim'), '--k');
plot([config.trigger_delay, config.trigger_delay], get(gca, 'ylim'), '--k');

num_demods = length(config.demod_c);
title(sprintf('\\bf %d signal segments from %d demodulators', num_triggers_plotted, num_demods))

end


function sampleloss = check_segments_for_sampleloss(data, config)
num_triggers = length(data.(config.device).demods(config.demod_idx(1)).sample);
sampleloss = logical(zeros(1, num_triggers));
for i=1:num_triggers
    for d=config.demod_idx
        % Check if any data is invalid. Unfortunately, sampleloss indicators not
        % implemented on software trigger yet.
        if any(isnan(data.(config.device).demods(config.demod_idx(d)).sample{i}.x)) | ...
                any(isnan(data.(config.device).demods(config.demod_idx(d)).sample{i}.y))
            sampleloss(i) = (1 | sampleloss(i));
        end
        if isempty(data.(config.device).demods(config.demod_idx(d)).sample{i}.timestamp)
            sampleloss(i) = (1 | sampleloss(i));
        end
    end
end
end


function timeConstant = bw2tc(bw, order)
  scale = 0.0;
  switch order
    case 1
      scale = 1.0;
    case 2
      scale = 0.643594;
    case 3
      scale = 0.509825;
    case 4
      scale = 0.434979;
    case 5
      scale = 0.385614;
    case 6
      scale = 0.349946;
    case 7
      scale = 0.322629;
    case 8
      scale = 0.300845;
    otherwise
      error('bw2tc Error: Order (%d) must be between 1 and 8!\n', order);
  end
  timeConstant= scale/(2*pi*bw);
end % function = bw2tc()

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:

