function r = example_connect(device_id)
% EXAMPLE_CONNECT A simple example demonstrating how to connect to a Zurich Instruments device
%
% USAGE R = EXAMPLE_CONNECT(DEVICE_ID)
%  
% Connect to the Zurich Instruments device specified by DEVICE_ID, obtain a
% single demodulator sample and calculate its RMS amplitude R. DEVICE_ID
% should be a string, e.g., 'dev2006' or 'uhf-dev2006'.
%
% NOTE This is intended to be a simple example demonstrating how to connect
% to a Zurich Instruments device from ziPython. In most cases, data acquistion
% should use either ziDAQServer's poll() method or an instance of the
% ziDAQRecorder class.
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
% See also EXAMPLE_CONNECT_CONFIG, EXAMPLE_POLL.
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

r = run_example(device, devtype);
  
end

function r = run_example(device, devtype)
% RUN_EXAMPLE run the example on the specified device

% If the device is not an HF2 additionally enable the demodulator.
if length(regexp(devtype, 'HF2', 'match')) == 0
    ziDAQ('setInt', ['/' device '/demods/0/enable'], 1);
end
ziDAQ('setDouble', ['/' device '/demods/0/rate'], 1.0e3);

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% `getSample` command. Note: `sync` must be issued after waiting for the
% demodulator filter to settle above.
ziDAQ('sync');

% Get a single demodulator sample. Note, `poll` or other higher-level
% functionality should almost always be be used instead of `getSample`.
sample = ziDAQ('getSample', ['/' device '/demods/0/sample']);
r = abs(sample.x + j*sample.y);
fprintf('Measured RMS amplitude: %fV.\n', r)

end

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
