function sample = example_poll(device_id, varargin)
% EXAMPLE_POLL Record demodulator data using ziDAQServer's synchronous poll function
%
% USAGE DATA = EXAMPLE_POLL(DEVICE_ID)
%
% Poll demodulator sample data from the device specified by DEVICE_ID using
% ziDAQServer's poll method. DEVICE_ID should be a string, e.g., 'dev2006' or
% 'uhf-dev2006'.
%
% ziDAQServer's poll method allows the user to obtain ('poll') demodulator
% data. Data can be obtained continuously in a loop. If asynchronous data
% recording is necessary please see example_record_async.m which uses the
% ziDAQRecord module.
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

sample = run_example(device, devtype, options, varargin{:});

end

function sample = run_example(device, devtype, options, varargin)

%% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
p = inputParser;
isnonneg = @(x) isnumeric(x) && isscalar(x) && (x > 0);
% The length of time we'll record data (synchronously) in the first poll [s].
p.addParamValue('poll_duration', 1.0, isnonneg);
% The length of time to accumulate subscribed data (by sleeping) before polling a second time [s].
p.addParamValue('sleep_duration', 1.0, isnonneg);
% The signal output mixer amplitude, [V].
p.addParamValue('amplitude', 0.5, @isnumeric);
p.parse(varargin{:});


%% Define some other helper parameters.
demod_c = '0'; % demod channel, for paths on the device
demod_idx = str2double(demod_c) + 1; % 1-based indexing, to access the data
out_c = '0'; % signal output channel
% Get the value of the instrument's default Signal Output mixer channel.
out_mixer_c = num2str(ziGetDefaultSigoutMixerChannel(devtype, options, str2num(out_c)));
in_c = '0'; % signal input channel
osc_c = '0'; % oscillator

time_constant = 0.001; % [s]
demod_rate = 2e3;
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
ziDAQ('setInt', ['/' device '/sigins/' in_c '/imp50'], 0);
ziDAQ('setInt', ['/' device '/sigins/' in_c '/ac'], 0);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/range'], 2.0*p.Results.amplitude);
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
ziDAQ('setDouble', ['/' device '/demods/*/timeconstant'], time_constant);
ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], 30e5); % [Hz]

% unsubscribe all streaming data
ziDAQ('unsubscribe', '*');

% pause to get a settled lowpass filter
pause(10*time_constant);

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old
% data. Note: ``sync`` must be issued after waiting for the demodulator filter
% to settle above.
ziDAQ('sync');

% subscribe to the demodulator sample
ziDAQ('subscribe', ['/' device '/demods/' demod_c '/sample']);

% poll data for poll_duration seconds
poll_timeout = 500;
data = ziDAQ('poll', p.Results.poll_duration, poll_timeout);

figure(1); clf;
grid on; box on; hold on;
if ziCheckPathInData(data, ['/' device '/demods/' demod_c '/sample']);
    sample = data.(device).demods(demod_idx).sample;
    t0 = sample.timestamp(1);
    plot_sample(sample, device, t0, 'b-');
else
    sample = [];
end

% Wait 2 seconds and poll data for 0.01 seconds.
% NOTE we get all the data from the buffer since the last poll command (much
% more data than 0.01 seconds)!
pause(p.Results.sleep_duration);
poll_timeout = 0;
data2 = ziDAQ('poll', 0.01, poll_timeout);
if ziCheckPathInData(data2, ['/' device '/demods/' demod_c '/sample']);
    sample2 = data2.(device).demods(demod_idx).sample;
    if ~exist('t0', 'var')
        t0 = sample2.timestamp(1);
    end
    plot_sample(sample2, device, t0, 'k-');
    legend('poll 1', 'poll 2');
end

% unsubscribe from all paths
ziDAQ('unsubscribe', '*');

end

function plot_sample(sample, device, t0, style)
if sample.time.dataloss
    fprintf('Warning: Sample loss detected.');
end
r = sqrt(sample.x.^2 + sample.y.^2);
% convert timestamps from ticks to seconds via the device's clockbase
% (the ADC's sampling rate), specify reference start time via t0.
clockbase = double(ziDAQ('getInt', ['/' device '/clockbase']));
t = (double(sample.timestamp) - double(t0))/clockbase;
fprintf('Poll returned %.3f seconds of data\n', t(end)-t(1));
plot(t, r, style);
end

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
