function filename_fullpath = example_save_device_settings_simple(device_id, varargin)
% EXAMPLE_SAVE_DEVICE_SETTINGS_SIMPLE Save and load device settings to and from file using utility functions
%
% USAGE example_save_device_settings_simple(DEVICE_ID)
%  
% Connect to a Zurich Instruments instrument, save the instrument's settings
% to file, toggle the signal output enable and reload the settings
% file. Specify the device to run the example on via by DEVICE_ID, e.g.,
% 'dev2006' or 'uhf-dev2006'.
%
% This example demonstrates the use of the Utility functions ziSaveSettings()
% and ziLoadSettings(). These functions will block until saving/loading has
% finished (i.e., they are synchronous functions). Since this is the desired
% behaviour in most cases, these utility functions are the recommended way to
% save and load settings.
% 
% If an asynchronous interface for saving and loading settings is required,
% please refer to the `example_save_device_settings_expert'. Which
% demonstrates how to directly use the ziDeviceSettings module.
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

filename_fullpath = run_example(device, varargin{:});
  
end


function filename_fullpath = run_example(device, varargin)

% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
p = inputParser;
% The xml file (without extension) to save instrument settings to.
default_filename_fullpath = [datestr(now, 'yyyymmdd_HHMM') '_settings.xml'];
p.addParamValue('filename_fullpath', default_filename_fullpath, @isstr);
p.parse(varargin{:});

toggleDeviceSetting(device);

fprintf('Saving settings...\n');
ziSaveSettings(device, p.Results.filename_fullpath);
fprintf('Saved file: ''%s''.\n', p.Results.filename_fullpath);

toggleDeviceSetting(device);

fprintf('Loading settings...\n');
ziLoadSettings(device, p.Results.filename_fullpath);
fprintf('Done.\n');

filename_fullpath = p.Results.filename_fullpath;

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
