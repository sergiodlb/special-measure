function scope_shots = example_scope(device_id)
% EXAMPLE_SCOPE record scope data using ziDAQServer's poll function
%
% USAGE SCOPE_SHOTS = EXAMPLE_SCOPE(DEVICE_ID)
%  
% Poll scope shots from the device specified by DEVICE_ID using ziDAQServer's
% blocking (synchronous) poll() method. DEVICE_ID should be a string, e.g.,
% 'dev2006' or 'uhf-dev2006'.
%
% NOTE This example can only be ran on instruments that support API Level 5
% and higher, e.g., UHFLI and MFLI. HF2 instruments are not supported, see the
% dedicated HF2 scope example hf2_example_scope().
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

% get the device type and its options (in order to set correct device-specific
% configuration)
devtype = ziDAQ('getByte', ['/' device '/features/devtype']);
options = ziDAQ('getByte', ['/' device '/features/options']);

if strfind(devtype, 'HF2')
    error('This example does not support HF2 instruments, see hf2_example_scope().');
end

if ziDAQ('getConnectionAPILevel') < 4
    error(['ziDAQServer is not using API Level 4. This example uses the ' ...
           'extended scope data structure introduced in API Level 4.']);
end

fprintf('Will run the example on an ''%s'' with options ''%s''.\n', ...
        devtype, regexprep(options, '\n', '|'));

scope_shots = run_example(device, devtype, options);

end


function scope_shots = run_example(device, devtype, options)

% Signal output mixer amplitude [V].
amplitude = 0.100;

out_c = '0';       % signal output channel
% Get the value of the instrument's default Signal Output mixer channel.
out_mixer_c = num2str(ziGetDefaultSigoutMixerChannel(devtype, options, str2num(out_c)));
in_c = '0';        % signal input channel
osc_c = '0';       % oscillator
scope_in_c = in_c; % scope input channel
frequency = 1.0e6;

% Create a base configuration: disable all outputs, demods and scopes
ziDAQ('setDouble', ['/' device '/demods/*/rate'], 0);
ziDAQ('setInt', ['/' device '/demods/*/trigger'], 0);
ziDAQ('setInt', ['/' device '/demods/*/enable'], 0);
ziDAQ('setInt', ['/' device '/sigouts/*/enables/*'], 0);
ziDAQ('setInt', ['/' device '/scopes/*/enable'], 0);

% Configure the device ready for this experiment

% Generate the output signal
ziDAQ('setInt', ['/' device '/sigouts/' out_c '/on'], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/range'], 1);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/*'], 0);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/' out_mixer_c], amplitude);
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/enables/' out_mixer_c], 1);

ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], frequency); % [Hz]

% Configure the signal inputs
ziDAQ('setInt', ['/' device '/sigins/' in_c '/imp50'], 1);
ziDAQ('setInt', ['/' device '/sigins/' in_c '/ac'], 0);
ziDAQ('sync'); % sync: Ensure sigin/sigout configuration has taken effect
               % before calculating autorange

% Important: Toggle `autorange' in order to obtain the best bit resolution of
% the current signal on the signal inputs.
ziDAQ('setInt', ['/' device '/sigins/' in_c '/autorange'], 1);
ziDAQ('sync'); % sync: Ensure value has taken effect on device before continuing
% /dev*/sigins/n/autorange stays 1 until an appropriate range has been
% configured by the device, wait until the autorange routing on the device has
% finished.
tic;
t0 = toc;
timeout = 10.0;  % seconds
autorange_path = ['/' device '/sigins/' in_c '/autorange'];
while ziDAQ('getInt', autorange_path) == 1
  pause(0.05);
  tNow = toc;
  if tNow - t0 > timeout;
    warning('Timeout after enabling `%s` \n.', autorange_path);
    break;
  end
end  

% NOTE we don't need any demodulator data for this example, but we still
% configure the frequency of the signal on out_mixer_c
if strfind(options, 'MF')
    ziDAQ('setInt', ['/' device '/demods/' out_mixer_c '/oscselect'], str2double(osc_c));
end

% Configure the scope via the /device/scopes/0 branch
% 'length' : the length of the scope shot
ziDAQ('setDouble', ['/' device '/scopes/0/length'],  32.0e3);
% 'channel' : select the scope channel(s) to enable.
%  Bit-encoded as following:
%   1 - enable scope channel 0
%   2 - enable scope channel 1
%   3 - enable both scope channels (requires DIG option)
% NOTE we are only interested in one scope channel: scope_in_c and leave the
% other channel unconfigured
ziDAQ('setInt',    ['/' device '/scopes/0/channel'], str2double(scope_in_c)+1);
% 'channels/0/bwlimit' : bandwidth limit the scope data. Enabling bandwidth
% limiting avoids antialiasing effects due to subsampling when the scope
% sample rate is less than the input channel's sample rate.
%  Bool:
%   0 - do not bandwidth limit
%   1 - bandwidth limit
ziDAQ('setInt',    ['/' device '/scopes/0/channels/' scope_in_c '/bwlimit'], 1);
% 'channels/0/inputselect' : the input channel for the scope
%   0 - signal input 1 
%   1 - signal input 2
%   2, 3 - trigger 1, 2 (front)
%   8-9 - auxiliary inputs 1-2
%   The following inputs are additionally available with the DIG option
%   10-11 - oscillator phase from demodulator 3-7
%   16-23 - demodulator 0-7 x value
%   32-39 - demodulator 0-7 y value
%   48-55 - demodulator 0-7 R value
%   64-71 - demodulator 0-7 Phi value
%   80-83 - pid 0-3 out value
%   96-97 - boxcar 0-1
%   112-113 - cartesian arithmetic unit 0-1
%   128-129 - polar arithmetic unit 0-1
%   144-147 - pid 0-3 shift value
ziDAQ('setInt',    ['/' device '/scopes/0/channels/' scope_in_c '/inputselect'], str2double(in_c));
% 'time' : timescale of the wave
ziDAQ('setDouble',  ['/' device '/scopes/0/time'], 0);
% 'single' : only get a single scope shot.
%   0 - take continuous shots
%   1 - take a single shot
ziDAQ('setInt',    ['/' device '/scopes/0/single'], 0);
% 'trigenable' : enable the scope's trigger (boolean).
%   0 - take continuous shots
%   1 - take a single shot
ziDAQ('setInt',    ['/' device '/scopes/0/trigenable'], 0);

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old data.
ziDAQ('sync');

% 'enable' : enable the scope
ziDAQ('setInt',    ['/' device '/scopes/0/enable'], 1);

% Unsubscribe from any streaming data
ziDAQ('unsubscribe', '*');

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old data.
ziDAQ('sync');

% Subscribe to the scope's data
ziDAQ('subscribe', ['/' device '/scopes/0/wave']);

% First, poll data without triggering enabled
poll_length = 1.0; % [s]
poll_timeout = 500; % [ms]
data_no_trig = ziDAQ('poll', poll_length, poll_timeout);

% Disable the scope
ziDAQ('setInt',    ['/' device '/scopes/0/enable'], 0);

% Now configure the scope's trigger to get aligned data
% 'trigenable' : enable the scope's trigger (boolean).
ziDAQ('setInt',    ['/' device '/scopes/0/trigenable'], 1);
% Specify the trigger channel, we choose the same as the scope input
ziDAQ('setInt',    ['/' device '/scopes/0/trigchannel'], str2double(in_c));
% Trigger on rising edge?
ziDAQ('setInt',    ['/' device '/scopes/0/trigrising'], 1);
% Trigger on falling edge?
ziDAQ('setInt',    ['/' device '/scopes/0/trigfalling'], 0);
% Set the trigger threshold level
ziDAQ('setDouble', ['/' device '/scopes/0/triglevel'], 0.00);
% Set hysteresis triggering threshold to avoid triggering on noise
% 'trighysteresis/mode' : 
%  0 - absolute, use an absolute value ('trighysteresis/absolute')
%  1 - relative, use a relative value (trighysteresis/relative') of the trigchannel's input range
ziDAQ('setDouble',    ['/' device '/scopes/0/trighysteresis/mode'], 1);
ziDAQ('setDouble',    ['/' device '/scopes/0/trighysteresis/relative'], 0.1); % 0.1=10%

% Set the hold off time inbetween triggers
ziDAQ('setDouble',    ['/' device '/scopes/0/trigholdoff'], 0.025);
% Set trigpredelay; start recording from when the trigger is activated
ziDAQ('setDouble',    ['/' device '/scopes/0/trigpredelay'], 0.0);

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old data.
ziDAQ('sync');

% 'enable' : enable the scope
ziDAQ('setInt',    ['/' device '/scopes/0/enable'], 1);

% Subscribe to the scope's data
ziDAQ('subscribe', ['/' device '/scopes/0/wave']);

% Poll data
poll_length = 1.0; % [s]
poll_timeout = 500; % [ms]
data_trig = ziDAQ('poll', poll_length, poll_timeout);

% Unsubscribe from any streaming data
ziDAQ('unsubscribe', '*');

% Plot the scope data with triggering disabled
if ziCheckPathInData(data_no_trig, ['/' device '/scopes/0/wave']);
  figure(1); clf;
  grid on; box on; hold on;
  title('\bf Scope shots (trigger disabled)');
  xlabel('t (us)');
  ylabel('Amplitude (V)');
  scope_shots_no_trig = data_no_trig.(device).scopes(1).wave;
  fprintf('Number of scope shots with triggering disabled: %d\n', length(scope_shots_no_trig));
  plot_scope_shots(scope_shots_no_trig, str2num(scope_in_c));
end

% Plot the scope data with triggering enabled
if ziCheckPathInData(data_trig, ['/' device '/scopes/0/wave']);
  figure(2); clf;
  grid on; box on; hold on;
  title('\bf Scope shots (triggering enabled)');
  xlabel('t (us)');
  ylabel('Amplitude (V)');
  scope_shots = data_trig.(device).scopes(1).wave;
  fprintf('Number of scope shots with triggering enabled: %d\n', length(scope_shots));
  plot_scope_shots(scope_shots, str2num(scope_in_c));
else
  scope_shots = [];
end

end

function plot_scope_shots(scope_shots, scope_in_c)
  num_shots = length(scope_shots);
  c = hsv(num_shots);
  for ii=1:num_shots
    totalsamples = double(scope_shots(ii).totalsamples);
    t = linspace(0, scope_shots(ii).dt*totalsamples, totalsamples);
    % Scale the scope data using ``channelscaling'' field of the scope data
    % structure to obtain physical values for the recorded scope data
    wave = scope_shots(ii).channelscaling(scope_in_c+1)*double(scope_shots(ii).wave(scope_in_c+1, :));
    if ~scope_shots(ii).flags && (length(wave) == totalsamples)
      plot(1e6*t, wave, 'color', c(ii, :));
    end
  end
end
