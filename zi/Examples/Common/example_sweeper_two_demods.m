function data = example_sweeper_two_demods(device_id, varargin)
% EXAMPLE_SWEEPER_TWO_DEMODS Perform a frequency sweep saving data from 2 demodulators using ziDAQ's sweep module
%
% USAGE DATA = EXAMPLE_SWEEPER_TWO_DEMODS(DEVICE_ID)
%  
% Perform a frequency sweep and gather samples from two demodulators
% (measuring the first and second harmonics). DEVICE_ID should be a
% string, e.g., 'dev2006' or 'uhf-dev2006'.
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

if ~isempty(strfind(devtype, 'MFLI')) && isempty(strfind(options, 'MD'))
    error(['This example requires either an HF2, UHF or an MFLI with MD ' ...
           'option installed. Device `%s` reports devtype `%s` and options ' ...
           '`%s`.'], device, devtype, options);
end

fprintf('Will run the example on `%s`, an `%s` with options `%s`.\n', device, ...
        devtype, regexprep(options, '\n' , '|'));

data = run_example(device, devtype, options, varargin{:});
  
end


function data = run_example(device, devtype, options, varargin)

% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.

p = inputParser;
isnonnegscalar = @(x) isnumeric(x) && isscalar(x) && (x > 0);

% The value used for the Sweeper's 'sweep/samplecount' parameter: This
% specifies the number of points that will be swept (i.e., the number of
% frequencies swept in a frequency sweep).
p.addParamValue('sweep_samplecount', 100, isnonnegscalar);

% The signal output mixer amplitude, [V].
p.addParamValue('amplitude', 0.1, @isnumeric);

p.parse(varargin{:});

if strfind(devtype, 'MFLI')
    demod_idx = [1, 2]; % 1-based indexing
elseif strfind(devtype, 'HF2IS')
    demod_idx = [1, 2]; % 1-based indexing
else
    demod_idx = [1, 5]; % 1-based indexing
end


% Define some other helper parameters.
% demod_idx uses 1-based indexing, a helper to access the data
demod_c = zeros(size(demod_idx));
for d=1:length(demod_idx)
  % demod_c, demod channel, 0-based indexing for paths on the device
  demod_c(d) = num2str(demod_idx(d)-1, '%0d');
end
out_c = '0'; % signal output channel
% Get the value of the instrument's default Signal Output mixer channel.
out_mixer_c = num2str(ziGetDefaultSigoutMixerChannel(devtype, options, str2num(out_c)));
in_c = '0'; % signal input channel
osc_c = '0'; % oscillator

tc = 0.007; % [s]
demod_rate = 13e3;
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
ziDAQ('setInt', ['/' device '/sigins/' in_c '/ac'], 1);
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
ziDAQ('setInt', ['/' device '/demods/*/order'], 4);
for d=demod_c
  ziDAQ('setDouble', ['/' device '/demods/' d '/rate'], demod_rate);
  if length(regexp(devtype, 'MFLI|UHFLI', 'match')) > 0
    ziDAQ('setInt', ['/' device '/demods/' d '/enable'], 1);
  end
end
% set the first demodulator channel to measure the 1st harmonic
ziDAQ('setInt', ['/' device '/demods/' demod_c(1) '/harmonic'], 1);
% set the second demodulator channel to measure the 2nd harmonic
ziDAQ('setInt', ['/' device '/demods/' demod_c(2) '/harmonic'], 2);

if length(regexp(options, 'MD|MF', 'match')) > 0
% HF2IS and HF2LI multi-frequency option do not support the node oscselect.
    for d=demod_c
        ziDAQ('setInt', ['/' device '/demods/' d '/oscselect'], str2double(osc_c));
        ziDAQ('setInt', ['/' device '/demods/' d '/adcselect'], str2double(in_c));
    end
end
ziDAQ('setDouble', ['/' device '/demods/*/timeconstant'], tc);
ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], 400e3); % [Hz]

%% Sweeper settings
% Create a thread for the sweeper 
timeout = 500; % milliseconds
h = ziDAQ('sweep', timeout);
% Device on which sweeping will be performed
ziDAQ('set', h, 'sweep/device', device);
% Sweeping setting is the frequency of the output signal
ziDAQ('set', h, 'sweep/gridnode', ['oscs/' osc_c '/freq']);
% Start frequency = 1 kHz
ziDAQ('set', h, 'sweep/start', 1e3);
% Stop frequency
if strfind(devtype, 'MFLI')
    stop = 500e3;
else
    stop = 10e6;
end
ziDAQ('set', h, 'sweep/stop', stop);
% sweep_samplecount measurement points (for sweep_samplecount different
% frequencies input signal Parameters will be recorded)
ziDAQ('set', h, 'sweep/samplecount', p.Results.sweep_samplecount);
% Single sweep 
ziDAQ('set', h, 'sweep/loopcount', 1);
% Logarithmic sweep mode
ziDAQ('set', h, 'sweep/xmapping', 1);
% Binary scan type 
ziDAQ('set', h, 'sweep/scan', 1);
% We don't require a fixed sweep/settling/time since there is no DUT involved
% in this example's setup (only a simple feedback cable) so set this to
% zero. We need only wait for the filter response to settle, specified via
% sweep/settling/inaccuracy.
ziDAQ('set', h, 'sweep/settling/time', 0);
% The sweep/settling/inaccuracy' parameter defines the settling time the
% sweeper should wait before changing a sweep parameter and recording the next
% sweep data point. The settling time is calculated from the specified
% proportion of a step response function that should remain. The value
% provided here, 0.001, is appropriate for fast and reasonably accurate
% amplitude measurements. For precise noise measurements it should be set to
% ~100n.
% Note: The actual time the sweeper waits before recording data is the maximum
% time specified by sweep/settling/time and defined by
% sweep/settling/inaccuracy.
ziDAQ('set', h, 'sweep/settling/inaccuracy', 0.001);
% Minimum time to record and average data is 50 time constants.
ziDAQ('set', h, 'sweep/averaging/tc', 50);
% Minimal number of samples that we want to record and average is 100. Note,
% the number of samples used for averaging will be the maximum number of
% samples specified by either sweep/averaging/tc or sweep/averaging/sample.
ziDAQ('set', h, 'sweep/averaging/sample', 100);
% Use automatic bandwidth control for each measurement
ziDAQ('set', h, 'sweep/bandwidthcontrol', 0);
% For fixed bandwidth, set sweep/bandwidthcontrol to 1 and specify a bandwidth
% via
% ziDAQ('set', h, 'sweep/bandwidth', 100);

% Subscribe to the nodes from which data will be recorded
for d=demod_c
  ziDAQ('subscribe', h, ['/' device '/demods/' d '/sample']);
end

% Start sweeping
ziDAQ('execute', h);

data = [];
frequencies = nan(1, p.Results.sweep_samplecount);
r = nan(length(demod_c), p.Results.sweep_samplecount);
theta = nan(length(demod_c), p.Results.sweep_samplecount);
clf;

figure(1); clf;
timeout = 60;
t0 = tic;
% Read and plot intermediate data until the sweep has finished.
while ~ziDAQ('finished', h)
    pause(1);
    tmp = ziDAQ('read', h);
    fprintf('Sweep progress %0.0f%%\n', ziDAQ('progress', h) * 100);
    % Using intermediate reads we can plot a continuous refinement of the ongoing
    % measurement. If not required it can be removed.
    if ziCheckPathInData(tmp, ['/' device '/demods/' demod_c '/sample'])
        if ~isempty(tmp.(device).demods(demod_idx(1)).sample{1}) && ...
                ~isempty(tmp.(device).demods(demod_idx(2)).sample{1})
            data = tmp;

            % Get the magnitude and phase of demodulator from the sweeper result.
            sample = data.(device).demods(demod_idx(1)).sample{1};
            r(1, :) = sample.r;
            theta(1, :) = sample.phase;

            sample = data.(device).demods(demod_idx(2)).sample{1};
            r(2, :) = sample.r;
            theta(2, :) = sample.phase;

            % Frequency values at which measurement points were taken
            frequencies = sample.grid;
            valid = ~isnan(frequencies);
            plot_data(frequencies(valid), r(:, valid), theta(:, valid), p.Results.amplitude, '.-')
            drawnow;
        
        end
    end
    if toc(t0) > timeout
        error('Timeout: Sweeper failed to finish after %f seconds.', timeout)
    end
end

% now read the data. This command can also be executed during the waiting.
tmp = ziDAQ('read', h);

% unsubscribe from the node; stop filling the data from that node to the
% internal buffer in the server
ziDAQ('unsubscribe', h, ['/' device '/demods/*/sample']);

% Process any remainging data returned by read().
if ziCheckPathInData(tmp, ['/' device '/demods/' demod_c '/sample'])
    if ~isempty(tmp.(device).demods(demod_idx(1)).sample{1}) && ...
            ~isempty(tmp.(device).demods(demod_idx(2)).sample{1})
        data = tmp;

        % Get the magnitude and phase of demodulator from the sweeper result.
        sample = data.(device).demods(demod_idx(1)).sample{1};
        r(1, :) = sample.r;
        theta(1, :) = sample.phase;

        sample = data.(device).demods(demod_idx(2)).sample{1};
        r(2, :) = sample.r;
        theta(2, :) = sample.phase;

        % Frequency values at which measurement points were taken
        frequencies = sample.grid;
        valid = ~isnan(frequencies);
        plot_data(frequencies(valid), r(:, valid), theta(:, valid), p.Results.amplitude, '.-')
        drawnow;
    
    end
end

end


function plot_data(frequencies, r, theta, amplitude, style)
% Plot data
clf
subplot(2, 1, 1)
s = semilogx(frequencies, 20*log10(r(1, :)*2*sqrt(2)/amplitude), style);
hold on;
set(s, 'LineWidth', 1.5)
set(s, 'Color', 'black');
s = semilogx(frequencies, 20*log10(r(2, :)*2*sqrt(2)/amplitude), style);
set(s, 'Color', 'blue');
grid on
legend('1st harmonic', '2nd harmonic', 'Location', 'best');
xlabel('Frequency [Hz]')
ylabel('Amplitude [dBV]')
subplot(2, 1, 2)
s = semilogx(frequencies, theta(1, :)*180/pi, style);
hold on;
set(s, 'LineWidth', 1.5)
set(s, 'Color', 'black');
% s = semilogx(frequencies, theta(2, :)*180/pi, style);
% set(s, 'Color', 'blue');
grid on
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
end


% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
