function scope_shots = uhf_example_scope_offset(device_id)
% UHF_EXAMPLE_SCOPE_OFFSET record scope data using ziDAQServer's poll function
%
% USAGE SCOPE_SHOTS = UHF_EXAMPLE_SCOPE_SCOPE_OFFSET(DEVICE_ID)
%  
% Poll scope shots from the device specified by DEVICE_ID data using
% ziDAQServer's blocking (synchronous) poll() method. DEVICE_ID should be a
% string, e.g., 'dev2006' or 'uhf-dev2006'.
%
% NOTE This example can only be ran on UHF Instruments with the DIG option enabled.
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

if isempty(strfind(devtype, 'UHF'))
    error('This example can only be ran on UHF Instruments, device `%s` reports `%s`.', device, devtype);
end

if isempty(strfind(options, 'DIG'))
    error('This example can only be ran on UHF Instruments with the DIG option enabled, device `%s` reports options `%s`.', device, options);
end

if ziDAQ('getConnectionAPILevel') < 5
    error(['ziDAQServer is not using API Level >=5. This example uses the ' ...
           '''channeloffset'' scope data structure field introduced in API ' ...
           'Level 5.']);
end

fprintf('Will run the example on an ''%s'' with options ''%s''.\n', ...
        devtype, regexprep(options, '\n', '|'));

amplitude = 0.5; % [V]
scope_shots = run_example(device, devtype, options, amplitude);
test_example(device, scope_shots, amplitude);

end


function scope_shots = run_example(device, devtype, options, amplitude)

out_c = '0';       % signal output channel
in_c = '0';        % signal input channel
osc_c = '0';       % oscillator
scope_in_c = in_c; % scope input channel
frequency = 1.0e6;

% define the output mixer channel based on the device type and its options
if strfind(devtype, 'UHF') & isempty(strfind(options, 'MF'))
    out_mixer_c = '3';
else
    out_mixer_c = '0';
end

% % create a base configuration: disable all outputs, demods and scopes
% ziDAQ('setDouble', ['/' device '/demods/*/rate'], 0);
% ziDAQ('setInt', ['/' device '/demods/*/trigger'], 0);
% ziDAQ('setInt', ['/' device '/demods/*/enable'], 0);
% ziDAQ('setInt', ['/' device '/sigouts/*/enables/*'], 0);
% ziDAQ('setInt', ['/' device '/scopes/*/enable'], 0);

% configure the device ready for this experiment
ziDAQ('setInt', ['/' device '/sigins/' in_c '/imp50'], 1);
ziDAQ('setInt', ['/' device '/sigins/' in_c '/ac'], 0);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/range'], 2*amplitude);

% ziDAQ('setInt', ['/' device '/sigouts/' out_c '/on'], 1);
% ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/range'], 1);
% ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/*'], 0);
% ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/' out_mixer_c], amplitude);
% ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/enables/' out_mixer_c], 1);
% 
ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], frequency); % [Hz]

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
ziDAQ('setInt',    ['/' device '/scopes/0/channels/' scope_in_c '/bwlimit'], 0);
% 'channels/0/inputselect' : the input channel for the scope
%   0 - signal input 1
%   1 - signal input 2
%   2,3 - trigger 1, 2 (front)
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
ziDAQ('setInt',    ['/' device '/scopes/0/channels/' scope_in_c '/inputselect'], 80);
% 'channels/0/limitlower' and 'channels/0/limitupper' : specify lower and
% upper limits of the scope's input value. When 'channels/0/inputselect' is a
% non-hardware channel, the user can specify an appropriate range in which to
% record the data from the channel in order to obtain the highest accuracy.
ziDAQ('setDouble', ['/' device '/scopes/0/channels/' scope_in_c '/limitlower'], 0.30);
ziDAQ('setDouble', ['/' device '/scopes/0/channels/' scope_in_c '/limitupper'], 0.40);
% 'trigenable' : enable the scope's trigger (boolean).
ziDAQ('setInt',    ['/' device '/scopes/0/trigenable'], 0);
% 'time' : timescale of the wave
ziDAQ('setDouble',  ['/' device '/scopes/0/time'], 0);
% 'single' : only get a single scope shot.
%   0 - take continuous shots
%   1 - take a single shot
ziDAQ('setInt',    ['/' device '/scopes/0/single'], 1);

% Unsubscribe from any streaming data
ziDAQ('unsubscribe', '*');

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old data.
ziDAQ('sync');

% Subscribe to the scope's data
ziDAQ('subscribe', ['/' device '/scopes/0/wave']);

% 'enable' : enable the scope
ziDAQ('setInt',    ['/' device '/scopes/0/enable'], 1);

% Poll data
poll_length = 1.0; % [s]
poll_timeout = 500; % [ms]
data_no_trig = ziDAQ('poll', poll_length, poll_timeout);

% Disable the scope
ziDAQ('setInt',    ['/' device '/scopes/0/enable'], 0);

% Unsubscribe from any streaming data
ziDAQ('unsubscribe', '*');

limitlower = ziDAQ('getDouble', ['/' device '/scopes/0/channels/' scope_in_c '/limitlower']);
fprintf('limitlower: %.5f\n', limitlower);
limitupper = ziDAQ('getDouble', ['/' device '/scopes/0/channels/' scope_in_c '/limitupper']);
fprintf('limitupper: %.5f\n', limitupper);
fullrange = ziDAQ('getDouble', ['/' device '/scopes/0/channels/' scope_in_c '/fullscale']);
fprintf('fullrange: %.5f\n', fullrange);

% Plot the scope data with triggering disabled
figure(1); clf;
grid on; box on; hold on;
title('\bf Scope shots');
xlabel('t (us)');
ylabel('Amplitude (V)');
if ziCheckPathInData( data_no_trig, ['/' device '/scopes/0/wave']);
  scope_shots = data_no_trig.(device).scopes(1).wave;
  fprintf('Number of scope shots with triggering disabled: %d\n', length(scope_shots));
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
    % Scale and offset the the scope data using the ``channelscaling'' and
    % ``channeloffset'' fields of the scope data structure to obtain physical
    % values for the recorded scope data
    fprintf('Channel offset: %.3e\n', scope_shots(ii).channeloffset(scope_in_c+1));
    fprintf('Channel scaling: %.5e\n', scope_shots(ii).channelscaling(scope_in_c+1));
    wave = scope_shots(ii).channeloffset(scope_in_c+1) + scope_shots(ii).channelscaling(scope_in_c+1)*double(scope_shots(ii).wave(scope_in_c+1, :));
    fprintf('mean(wave): %.5f\n', mean(wave));
    if ~scope_shots(ii).flags && (length(wave) == totalsamples)
      plot(1e6*t, wave, 'color', c(ii, :));
    end
  end
end

function test_example(device, scope_shots, amplitude)
  assert(length(scope_shots) > 0, 'No scope shots recorded. Connect BNC cable from Signal Output 1 to Signal Input 1?')
end
