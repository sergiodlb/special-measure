function data = hf2_example_zsync_poll()
% HF2_EXAMPLE_ZYSNC_POLL Poll data from two HF2s with synchronised timestamps
%
% USAGE sample = HF2_EXAMPLE_ZSYNC_POLL()
%
% Synchronise the timestamps from two HF2s using the HF2's ZSync capability
% and poll data using ziDAQServer's poll method.
%
% NOTE This example can only run on HF2 Series instruments and requires two
% HF2s connected to the same PC via USB. This example assumes that the HF2
% with the lowest serial number is the master and the HF2 with the next serial
% number is the slave. The serial number is the number contained in the
% device's ID, e.g., 'dev123'.  In order to correctly use the ZSync
% functionality, these HF2s must be configured and power-cycled as following:
%
%   1. Power-off both slave and master. Connect zsync cables between slave and
%   master. Attach both HF2s to host PC via USB.
%
%   2. Power-on the master device, wait until the LEDs stop blinking red on
%   the front-panel.
%
%   3. Power-on the slave device, wait until the LEDs stop blinking red on the
%   front-panel.
% 
% If the above fails, please restart the HF2's Data Server program `ziServer`
% and start again.
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
% in the Matlab command window to obtain help on all available ziDAQ commands
% or check the LabOne Programming Manual:
% 
%
% Copyright 2008-2015 Zurich Instruments AG

clear ziDAQ;

% Check ziDAQ's ziDevices (in the Utils/ subfolder) is in the path
if exist('ziDevices', 'file') ~= 2
    fprintf('Please configure your path using the ziDAQ function ziAddPath().\n')
    fprintf('This can be found in the API subfolder of your LabOne installation.\n');
    fprintf('On Windows this is typically:\n');
    fprintf('C:\\Program Files\\Zurich Instruments\\LabOne\\API\\MATLAB2012\\\n');
    return
end

% Create a connection to a server for the HF2
port = 8005;
% The maximum API level supported by this example.
apilevel_example = 1;
ziDAQ('connect', 'localhost', port, apilevel_example);

server_version = ziDAQ('getInt', '/zi/about/revision');
if server_version < 28460
  fprintf('ZSync requires at least HF2 Data Server (ziServer.exe) version r28460.\n')
  fprintf('Please update your LabOne installation, LabOne 15.01 or newer is required.\n')
  return
end

% Get the device's names (e.g. 'dev234')
devices = ziDevices();
if length(devices) ~= 2
  fprintf('Detected %d devices, this example requires 2 HF2 devices connected to the same host PC.\n', length(devices));
  return
end
if str2num(devices{1}(4:end)) < str2num(devices{2}(4:end))
  device_master = devices{1};
  device_slave = devices{2};
else
  device_slave = devices{1};
  device_master = devices{2};
end

fprintf('Will run the example using master device ''%s'' and slave device ''%s''.\n', device_master, device_slave)

data = run_example(device_master, device_slave);

end

function data = run_example(device_master, device_slave)

demod_rate = 2e3;

%% Create a base configuration: disable all outputs, demods and scopes
for device = {device_slave, device_master}
  ziDAQ('setDouble', ['/' device{1} '/demods/*/rate'], 0.0);
  ziDAQ('setInt', ['/' device{1} '/demods/*/trigger'], 0);
  ziDAQ('setInt', ['/' device{1} '/sigouts/*/enables/*'], 0);
  ziDAQ('setInt', ['/' device{1} '/scopes/*/trigchannel'], -1)
end

% The following configures the slave and master to use zsync. This must only
% be performed once and is valid until the devices are power-cycled. Note,
% that before performing this configuration via API, the devices must be
% attached and power-cycled as following:
% 1. Power-off both slave and master. Connect zsync cables between master
% ('ZSync Out') and master ('ZSync In'). Attach both HF2s to host PC via USB.
% 2. Power-on the master device, wait until the LEDs stop blinking red on
% the front-panel.
% 3. Power-on the slave device, wait until the LEDs stop blinking red on
% the front-panel.
ziDAQ('setInt', ['/' device_slave '/system/extclk'], 1);
ziDAQ('setInt', ['/' device_master '/system/extclk'], 0);
ziDAQ('sync')
ziDAQ('setInt', ['/' device_slave '/system/syncenable'], 1);
ziDAQ('setInt', ['/' device_master '/system/syncreset'], 1);
ziDAQ('sync')
ziDAQ('setInt', ['/' device_master '/system/syncreset'], 0);
ziDAQ('sync')

% We will only plot data from the HF2s' Digital I/O (DIO) and as such do not
% need to configure the devices' HF inputs and outputs. The DIO data is
% delivered as the 'bits' field in demodulator samples; configure the
% demodulators to obtain demod data from the devices.
for device = {device_slave, device_master}
  ziDAQ('setDouble', ['/' device{1} '/demods/0/rate'], demod_rate);
% Enable the DIO
  ziDAQ('setInt', ['/' device{1} '/dios/0/drive'], 1)
end
% Set values of the DIO
ziDAQ('setInt', ['/' device_master '/dios/0/output'], 1)
ziDAQ('setInt', ['/' device_slave '/dios/0/output'], 0)

% Unsubscribe all streaming data
ziDAQ('unsubscribe', '*');

% Perform a global synchronisation between the device and the data server:
% Ensure that the settings have taken effect on the device before issuing the
% ``poll`` command and clear the API's data buffers to remove any old data.
ziDAQ('sync');

% Subscribe to the devices' demodulators
ziDAQ('subscribe', ['/' device_master '/demods/0/sample']);
ziDAQ('subscribe', ['/' device_slave '/demods/0/sample']);

% Poll command configuration
poll_length = 0.1; % [s]
poll_timeout = 100; % [ms]
poll_flag = 0; % set to 0: disable the dataloss indicator (or data imbetween
% the polls will be filled with NaNs)

%% Poll for data, it will return as much data as it can since the ``poll`` or ``sync``
data = ziDAQ('poll', poll_length, poll_timeout, poll_flag);

clockbase = double(ziDAQ('getInt', ['/' device_master '/clockbase']));

% Convert to double, timestamps and sample.bits is uint32.
timestamp_master = data.(device_master).demods(1).sample.timestamp;
timestamp_slave = data.(device_slave).demods(1).sample.timestamp;

% Poll will not necessarily return aligned demodulator data (by timestamp)
% when subscribed to multiple demodulators (even for the same device). Find
% the first timestamp where we have data from both devices; only plot the data
% where it is available for both device.
% NOTE If continually polling data via multiple calls to poll, it'd be more
% relevant to align the data between the individual poll commands; not to
% trim the data.
if timestamp_master(1) <= timestamp_slave(1)
  idx_start_slave = 1;
  idx_start_master = find(timestamp_master == timestamp_slave(1), 1, 'first');
else
  idx_start_slave = find(timestamp_slave == timestamp_master(1), 1, 'first');
  idx_start_master = 1;
end

if timestamp_master(end) > timestamp_slave(end)
  idx_end_slave = length(timestamp_slave);
  idx_end_master = find(timestamp_master == timestamp_slave(end), '1', 'last');
else
  idx_end_slave = find(timestamp_slave == timestamp_master(end), '1', 'last');
  idx_end_master = length(timestamp_master);
end

if isempty(idx_start_slave) | isempty(idx_start_master) | isempty(idx_end_slave) | isempty(idx_end_master)
  error('Failed to find matching timestamps in data. Misconfiguration or zysncing failed.')
end

t_master = double(timestamp_master)/clockbase;
t_slave = double(timestamp_slave)/clockbase;

figure(1); clf;
hold on; box on; grid on;
% We only plot the first bit of the DIO
plot(t_master(idx_start_master:idx_end_master), double(bitand(1, data.(device_master).demods(1).sample.bits(idx_start_master:idx_end_master))), 'r-x');
plot(t_slave(idx_start_slave:idx_end_slave), double(bitand(1, data.(device_slave).demods(1).sample.bits(idx_start_slave:idx_end_slave))), 'b-o');
ylim([-1, 2]);
legend('0th bit, DIO Master', '0th bit, DIO Slave');

end

% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
