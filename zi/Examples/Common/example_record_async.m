function data = example_record_async(device_id, varargin)
% EXAMPLE_RECORD_ASYNC Record data asyncronously using ziDAQ's record module
%
% USAGE DATA = EXAMPLE_RECORD_ASYNC(DEVICE_ID)
%  
% Record demodulator sample data asynchronously using ziDAQ's 'record' module
% from the device specified by DEVICE_ID, e.g., 'dev2006' or 'uhf-dev2006'.
% 
% The record module allows users to record data asynchronously, but also to
% record data using 'software triggers' which are analogous to the types of
% triggering found in spectroscopes.
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

fprintf('Will run the example on `%s`, an `%s` with options `%s`.\n', device, ...
        devtype, regexprep(options, '\n', '|'));

data = run_example(device, devtype, options);

end


function data = run_example(device, devtype, options, varargin)
  
% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
p = inputParser;
isnonneg = @(x) isnumeric(x) && isscalar(x) && (x > 0);
% The length of time we'll record data (asynchronously) [s].
p.addParamValue('recording_duration', 10.0, isnonneg);
% The signal output mixer amplitude, [V].
p.addParamValue('amplitude', 0.5, @isnumeric);
p.parse(varargin{:});

% Define some helper parameters.
demod_c = '0'; % demod channel
out_c = '0'; % signal output channel
% Get the value of the instrument's default Signal Output mixer channel.
out_mixer_c = num2str(ziGetDefaultSigoutMixerChannel(devtype, options, str2num(out_c)));
in_c = '0'; % signal input channel
osc_c = '0'; % oscillator
demod_idx = str2num(demod_c) + 1;  % 1-based indexing for Matlab
tc = 0.001; % [s]
demod_rate = 2e3;

% Create a base configuration: disable all outputs, demods and scopes
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
ziDAQ('setInt', ['/' device '/sigins/' in_c '/imp50'], 0);
ziDAQ('setInt', ['/' device '/sigins/' in_c '/ac'], 0);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/range'], 2);
ziDAQ('setInt', ['/' device '/sigouts/' out_c '/on'], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/range'], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/*'], 0);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/' out_mixer_c], p.Results.amplitude);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/enables/' out_mixer_c], 1);
if strfind(devtype, 'HF2')
    ziDAQ('setInt', ['/' device '/sigins/' in_c '/diff'], 0);
    ziDAQ('setInt', ['/' device '/sigouts/' out_c '/add'], 0);
end
ziDAQ('setDouble', ['/' device '/demods/*/phaseshift'], 0);
ziDAQ('setInt', ['/' device '/demods/*/order'], 8);
ziDAQ('setDouble', ['/' device '/demods/' demod_c '/rate'], demod_rate);
ziDAQ('setInt', ['/' device '/demods/' demod_c '/harmonic'], 1);
if length(regexp(devtype, 'MFLI|UHFLI', 'match')) > 0
    ziDAQ('setInt', ['/' device '/demods/' demod_c '/enable'], 1);
end
if strfind(options, 'MF')
% HF2IS and HF2LI multi-frequency option do not support the node oscselect.
    ziDAQ('setInt', ['/' device '/demods/*/oscselect'], str2double(osc_c));
    ziDAQ('setInt', ['/' device '/demods/*/adcselect'], str2double(in_c));
end
ziDAQ('setDouble', ['/' device '/demods/*/timeconstant'], tc);
ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], 400e3); % [Hz]

% Unsubscribe from any streaming data
ziDAQ('unsubscribe', '*');

% Wait for the demodulator filter to settle
pause(10*tc);

% Create a recorder thread
% The function call will return a handle to that recorder (thread)
h = ziDAQ('record', 1, int64(10000));
% Subscribe nodes to be recorded
% Set trigger parameter
ziDAQ('set', h, 'trigger/0/count', 1);
% Trigger type is 0 = continous recording
ziDAQ('set', h, 'trigger/0/type', 0);
ziDAQ('set', h, 'trigger/0/duration', 0.5);
ziDAQ('set', h, 'trigger/0/path', ['/' device '/demods/' demod_c '/sample'])
% Subscribe all nodes that should be recorded
ziDAQ('subscribe', h, ['/' device '/demods/' demod_c '/sample']);

% Now start the thread -> ready to be triggered
ziDAQ('execute', h);
pause(0.5)

figure(1); clf;
grid on; box on; hold on;
tic
while toc < p.Results.recording_duration
    data = ziDAQ('read', h);
    % Plot the data
    if ziCheckPathInData(data, ['/' device '/demods/' demod_c '/sample']);
        sample = data.(device).demods(demod_idx).sample{1};
        plot_sample(sample, '-k');
    end
    pause(0.1)
end

fprintf('Recording finished.\n')
ziDAQ('finish', h);  % Finish the recording.
ziDAQ('clear', h);  % Stop the module thread.

end

function plot_sample(sample, style)
% If we specified trigger criteria, we may get several trigger segments back
% so we use cells to address the individual segments
if sample.time.dataloss
    fprintf('Sample loss detected.');
end
r = abs(sample.x + j*sample.y);
t = sample.timestamp;
plot(t, r, style);
end

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
