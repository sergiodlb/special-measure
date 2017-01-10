function data = hf2_example_scope(device_id, varargin)
% HF2_EXAMPLE_SCOPE obtain scope data from an HF2 using the poll command.
%
% DATA = HF2_EXAMPLE_SCOPE(DEVICE_ID)
%
% Connect to the Zurich Instruments device specified by DEVICE_ID via the Data
% Server, generate a sine wave on the signal outputs and obtain the waveform
% from the configured scope channel by polling data from the scope using
% ziDAQServer's blocking (synchronous) poll() command. DEVICE_ID should be a
% string specifying the instrument on which to run the example, e.g., 'dev118'
% or 'hf2-dev118'.
%
% DATA is a nested struct containing the data returned by poll, the scope
% shots are available in this struct in the array
% `data.(DEVICE_ID).scopes.wave`. Each entry in this array is a struct holding
% the data from each scope shot.
%
% REQUIRES a BNC cable between the signal input and output channels the scope
% is configured for.
% 
% DATA = HF2_EXAMPLE_SCOPE(DEVICE_ID, VARARGIN)
%
% Provide optional input arguments to the example via a MATLAB variable length
% input argument list, see the inline documentation in the run_example()
% function below for a description of the possible input arguments.
%
% NOTE This example can only be ran on HF2 Instruments.
%
% NOTE This example uses API level 1; users of other device classes are
% recommended to connect via API level 5, particularly when obtaining scope
% data.
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
           'e.g. ''dev118'' or ''hf2-dev118''.'])
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
apilevel_example = 1;
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
% configuration)
devtype = ziDAQ('getByte', ['/' device '/features/devtype']);
options = ziDAQ('getByte', ['/' device '/features/options']);

if isempty(strfind(devtype, 'HF2'))
    error('This example can only be ran on HF2 Instruments, device `%s` reports devtype `%s`.', device, devtype);
end

fprintf('Will run the example on `%s`, an `%s` with options `%s`.\n', device, ...
        devtype, regexprep(options, '\n' , '|'));

data = run_example(device, devtype, options, varargin{:});

end


function data = run_example(device, devtype, options, varargin)

%% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
p = inputParser;
isnonneg = @(x) isnumeric(x) && isscalar(x) && (x > 0);
scope_channels = [0, 1, 2, 3];
is_scope_channel = @(x) assert(ismember(x, scope_channels), ...
                               'Invalid value for scope_channel: %d. Valid values: %s.', x, mat2str(scope_channels));
% The scope's input channel; The value 2 corresponds to Signal Output 0.
p.addParamValue('scope_channel', 2, is_scope_channel);
% The threshold level to trigger the sending of scope shots from the device
% (in physical units, [V]). Important: This must be converted to a 16-bit
% signed integer when passed to the scope's `triglevel` parameter. See scope
% configuration below for more details.
p.addParamValue('trigger_level', 0.0, @isnumeric);
% The signal output range, [V].
p.addParamValue('amplitude', 0.5, @isnumeric);
% NOTE The Signal Output and Input ranges are relevant since they're required for
% correct scaling of the scope's wave node value.
% The length of time to accumulate subscribed data (by sleeping) before polling a second time [s].
p.addParamValue('sigout_range', 1.0, @isnumeric);
% The signal output mixer amplitude, [V].
p.addParamValue('sigin_range', 1.0, isnonneg);
p.parse(varargin{:});

if p.Results.trigger_level >= p.Results.amplitude
    warning(sprintf(['Specified trigger_level (%.3f V) >= signal output ' ...
                     'amplitude (%.3f V), scope will not be triggered when measuring ' ...
                     'via a simple feedback cable between signal inputs and signal ' ...
                     'outputs.'], p.Results.trigger_level, p.Results.amplitude));
end

%% Define some other derived and helper parameters.
switch p.Results.scope_channel
% Select the instrument hardware Signal Output and Input channels to configure
% based on the configured scope channel.
  case {0, 2}
    % Use Signal Output/Inputs 0
    out_c = '0';  % Signal output channel
    in_c = '0';  % Signal input channel
  case {1, 3}
    % Use Signal Output/Inputs 1
    out_c = '1';  % Signal output channel
    in_c = '1';  % Signal input channel
  otherwise
    error('Invalid scope channel: %d.\n', p.Results.scope_channel);
end
% Get the value of the instrument's default Signal Output mixer channel.
out_mixer_c = num2str(ziGetDefaultSigoutMixerChannel(devtype, options, str2num(out_c)));
osc_c = '0';  % The instrument's oscillator channel to use.

frequency = 1.0e6;

%% Create a base configuration: disable all outputs, demods and scopes
ziDAQ('setDouble', ['/' device '/demods/*/rate'], 0.0);
ziDAQ('setInt', ['/' device '/demods/*/trigger'], 0);
ziDAQ('setInt', ['/' device '/sigouts/*/enables/*'], 0);
ziDAQ('setInt', ['/' device '/scopes/*/trigchannel'], -1);

% The scope's sampling rate is configured by specifying the ``time`` node
% (/devN/scopes/0/time). The rate is equal to 210e6/2**time, where 210e6
% is the HF2 ADC's sampling rate (^=clockbase, /devX/clockbase). time is
% an integer in range(0, 16).
%
% Since the length of a scope shot is fixed (2048) on an HF2, specifying
% the rate also specifies the time duration of a scope shot, 
% t_shot=2048*1./rate=2048*2**time/210e6.
SCOPE_SHOT_LENGTH = 2048;

% Therefore, if we would like to obtain (at least) 10 periods of the
% signal generated by Oscillator 1, we need to set the scope's time
% parameter as following:
clockbase = double(ziDAQ('getInt', ['/' device '/clockbase'])); % 210e6 for HF2
desired_t_shot = 10/frequency;
scope_time = ceil(max([0, log2(clockbase*desired_t_shot/SCOPE_SHOT_LENGTH)]));
if scope_time > 15
  scope_time = 15;
  warning(['Can''t not obtain scope durations of %.3f s, scope shot duration ' ...
           'will be %.3f.'], desired_t_shot, 2048*2^scope_time/clockbase);
end
fprintf('Will set /%s/scopes/0/time to %d.\n', device, scope_time);

%% Configure the HF2
% Output settings
ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/range'], p.Results.sigout_range);
ziDAQ('setInt', ['/' device '/sigouts/*/enables/*'], 0);
ziDAQ('setDouble', ['/' device '/sigouts/*/amplitudes/*'], 0.000);

ziDAQ('setDouble', ['/' device '/sigouts/' out_c '/amplitudes/' out_mixer_c], p.Results.amplitude/p.Results.sigout_range);
ziDAQ('setInt', ['/' device '/sigouts/' out_c '/enables/' out_mixer_c], 1);
ziDAQ('setInt', ['/' device '/sigouts/' out_c '/add'], 0);
ziDAQ('setInt', ['/' device '/sigouts/' out_c '/on'], 1);

% Input settings
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/range'], p.Results.sigin_range);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/ac'], 1);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/diff'], 0);
ziDAQ('setDouble', ['/' device '/sigins/' in_c '/imp50'], 0);

% Oscillator settings
ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], frequency);

% Scope settings
ziDAQ('setInt', ['/' device '/scopes/0/channel'], p.Results.scope_channel);
% Trigger scope shots using the scope' input channel
ziDAQ('setInt', ['/' device '/scopes/0/trigchannel'], p.Results.scope_channel);
% NOTE The scope 'triglevel' parameter is not defined using the physical units
% of the scope input channel; It is defined according to values of the data
% returned by the scope. Scope shots consist of values which are 16-bit signed
% integers and the trigger level is defined as integer accordingly in the
% range [-2^15, 2^15].
scope_triglevel = p.Results.trigger_level*2^15;
ziDAQ('setDouble', ['/' device '/scopes/0/triglevel'], scope_triglevel);

ziDAQ('setDouble', ['/' device '/scopes/0/trigholdoff'], 0.1);
% Turn on bandwidth limiting: avoid antialiasing effects due to subsampling
% when the scope sample rate is less than the input channel's sample rate.
ziDAQ('setInt', ['/' device '/scopes/0/bwlimit'], 1);
ziDAQ('setInt', ['/' device '/scopes/0/time'], scope_time); % set the sampling rate
         
% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old data.
ziDAQ('sync');

% Subscribe to the scope wave
path = ['/' device '/scopes/0/wave'];
ziDAQ('subscribe', path);

% Poll command configuration
poll_duration = 1.0; % [s]
poll_timeout = 500; % [ms]
poll_flag = 0; % set to 0: disable the dataloss indicator (or data imbetween
               % the polls will be filled with NaNs)

%% Poll for data, it will return as much data as it can since the ``poll`` or ``sync``
data = ziDAQ('poll', poll_duration, poll_timeout, poll_flag);

% Unsubscribe from streaming scope waves.
ziDAQ('unsubscribe', path);
% Disable the scope.
ziDAQ('setInt', ['/' device '/scopes/*/trigchannel'], -1)
         
% Check poll returned the expected subscribed data.
assert(ziCheckPathInData(data, path), 'Path ``%s`` not in polled data', path);
% Note, data could be empty if no data arrived, e.g., if the scope was
% disabled or it did not trigger.

% The scope data polled from the node /devN/scopes/0/wave, here ``shots``, is
% an array of struct. The length of ``shots`` is the number of scope shots
% that were returned by poll().
shots = data.(device).scopes.wave;
fprintf('poll() returned %i scope shots.\n', length(shots));
assert(length(shots) >= 0, 'No scope shots in %s from polled data.', path);

% In order to obtain the physical value of the wave we need to scale by the
% scaling of the scope input signal. This is defined by the signal
% input/output range accordingly. We divide by 2^15 since the scope shot
% consists of values which are 16-bit signed integers.
scale = inf;
switch p.Results.scope_channel
  case {0, 1}
    sigins_range_set = ziDAQ('getDouble', ['/' device '/sigins/' in_c '/range']);
    scale = sigins_range_set/(2^15);
  case {2, 3}
    sigouts_range_set = ziDAQ('getDouble', ['/' device '/sigouts/' out_c '/range']);
    scale = sigouts_range_set/(2^15);
  otherwise
    error('Invalid scope channel: %d.\n', p.Results.scope_channel);
end

min_val = double(min(shots(1).wave));
max_val = double(max(shots(1).wave));

fprintf('Maximum value of first shot: %+d (int16), scaled: %+.3f V.\n', min_val, scale*min_val);
fprintf('Minimum value of first shot: %+d (int16), scaled: %+.3f V.\n', max_val, scale*max_val);
fprintf('Peak-to-peak amplitude of first shot: %+.3f V.\n', scale*(max_val - min_val));

figure(1); clf;
grid on;
box on;
hold on;
h = nan(1, length(shots) + 1);  % Plot handles.
for i=1:length(shots)
    t = linspace(0, shots(i).dt*length(shots(i).wave), length(shots(i).wave));
    h(i) = plot(t, scale*double(shots(i).wave));
end
h(end) = plot(get(gca, 'xlim'), [p.Results.trigger_level, p.Results.trigger_level], '--k', 'LineWidth', 2);
legend([h(1), h(end)], {'Scope shots', 'Scope Trigger Level'});
title(sprintf('Polled scope shots (Number of shots=%d)', length(shots)));
xlabel('Time (s)');
ylabel('Amplitude (V)');
  
end

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
