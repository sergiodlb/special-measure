function filename_full_path = example_save_device_settings_expert(device_id, varargin)
% EXAMPLE_SAVE_DEVICE_SETTINGS_EXPERT Save and load device settings to and from file with ziDAQ's devicesettings module
%
% USAGE example_save_device_settings_expert(device_id)
%
% Demonstrate how to save and load Zurich Instruments device settings
% asynchronously using the ziDeviceSettings class from the device specified by
% DEVICE_ID, e.g., 'dev2006' or 'uhf-dev2006'.
%
% Connect to a Zurich Instruments instrument, save the instrument's settings
% to file, toggle the signal output enable and reload the settings file.
%
% NOTE This example is intended for experienced users who require a
% non-blocking (asynchronous) interface for loading and saving settings. In
% general, the utility functions ziSaveSettings() and ziLoadSettings() are
% more appropriate; see `example_save_device_settings_simple'.
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
        devtype, regexprep(options, '\n' , '|'));

filename_full_path = run_example(device, varargin{:});
  
end


function filename_full_path = run_example(device, varargin)

% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
p = inputParser;
% The xml file (without extension) to save instrument settings to.
default_filename_noext = [datestr(now, 'yyyymmdd_HHMM') '_settings'];
p.addParamValue('filename_noext', default_filename_noext, @isstr);
% The directory to save the settings file. Use current working directory as default.
p.addParamValue('directory', './', @isstr);
p.parse(varargin{:});

% Create a handle to access the deviceSettings thread
h = ziDAQ('deviceSettings', 500);
ziDAQ('set', h, 'devicesettings/device', device);

toggleDeviceSetting(device);

fprintf('Saving settings...\n');
ziDAQ('set', h, 'devicesettings/command', 'save');
ziDAQ('set', h, 'devicesettings/filename', p.Results.filename_noext);
% Set the path to '.' to save to the current directory. Note: this
% example/m-file will have to be executed in a folder where you have write access.
ziDAQ('set', h, 'devicesettings/path', p.Results.directory);

ziDAQ('execute', h);
while ~ziDAQ('finished', h)
  pause(0.2);
end

data = ziDAQ('get', h, 'devicesettings/path');
% Like all other module paths, 'devicesettings/path' can be obtained via
% subscribe()/poll(), in which case all paths set during the poll duration
% would be returned by get(). Therefore data.path is a cell array; take the
% last element in the cell aray and then convert from a byte array to a
% string.
path = char(data.path{end});
filename_full_path = fullfile(path, [p.Results.filename_noext '.xml']);
fprintf('Saved file: ''%s''.\n', filename_full_path);

toggleDeviceSetting(device);

fprintf('Loading settings...\n');
ziDAQ('set', h, 'devicesettings/command', 'load');
ziDAQ('set', h, 'devicesettings/filename', p.Results.filename_noext);

ziDAQ('execute', h);
while ~ziDAQ('finished', h)
  pause(0.2);
end
fprintf('Done.\n');
ziDAQ('clear', h);
end


function toggleDeviceSetting(device)
path = ['/' device '/sigouts/0/on'];
on = ziDAQ('getInt', path);
if (on)
    on = 0;
else
    on = 1;
end
fprintf('Toggling ''%s''.\n', path);
ziDAQ('setInt', path, on);
ziDAQ('sync');
end

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
