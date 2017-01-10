function data = example_zoomfft(device_id, varargin)
% EXAMPLE_ZOOMFFT Perform an FFT using ziDAQ's zoomFFT module
%
% USAGE DATA = EXAMPLE_ZOOMFFT(DEVICE_ID)
%  
% The following example demonstrates how to use ziDAQ's ZoomFFT
% module. DEVICE_ID should be a string, e.g., 'dev2006' or 'uhf-dev2006'.
%
% NOTE Additional configuration: Connect signal output 1 to signal input 1
% with a BNC cable.
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

data = run_example(device, devtype, options, varargin{:});
  
end


function data = run_example(device, devtype, options, varargin)

% Define parameters relevant to this example. Default values specified by the
% inputParser below are overwritten if specified as name-value pairs via the
% `varargin` input argument.
p = inputParser;
isnonnegscalar = @(x) isnumeric(x) && isscalar(x) && (x > 0);

% The value used for the ZoomFFT Module's 'zoomFFT/bit' parameter: This
% specifies the frequency resolution of the FFT; the number of lines of the
% FFT spectrum is 2^bits.
p.addParamValue('zoomfft_bit', 16, isnonnegscalar);

% The signal output mixer amplitude, [V].
p.addParamValue('amplitude', 0.1, @isnumeric);

p.parse(varargin{:});

% Define some other helper parameters.
demod_c = '0'; % demod channel, for paths on the device
demod_idx = str2double(demod_c)+1; % 1-based indexing, to access the data
out_c = '0'; % signal output channel
% Get the value of the instrument's default Signal Output mixer channel.
out_mixer_c = num2str(ziGetDefaultSigoutMixerChannel(devtype, options, str2num(out_c)));
in_c = '0'; % signal input channel
osc_c = '0'; % oscillator

time_constant = 8e-5; % [s]
demod_rate = 10e3;
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
ziDAQ('setDouble', ['/' device '/oscs/' osc_c '/freq'], 400e3); % [Hz]

% Wait for the demodulator filter to settle
pause(10*time_constant);

%% ZoomFFT settings
% Create a thread for the zoomFFT
h = ziDAQ('zoomFFT', 100);
% Device on which zoomFFT will be performed
ziDAQ('set', h, 'zoomFFT/device', device);
% Select standard FFT(x + iy)
ziDAQ('set', h, 'zoomFFT/mode', 0);
% Disable overlap mode
ziDAQ('set', h, 'zoomFFT/overlap', 0);
% Return absolute frequency
ziDAQ('set', h, 'zoomFFT/absolute', 1);
% Number of lines 2^bits
ziDAQ('set', h, 'zoomFFT/bit', p.Results.zoomfft_bit);
% Subscribe to the node from which data will be recorded
ziDAQ('subscribe', h, ['/' device '/demods/' demod_c '/sample']);

% Start the zoomFFT's module thread.
ziDAQ('execute', h);

data = [];
frequencies = nan(1, 2^p.Results.zoomfft_bit);
r = nan(1, 2^p.Results.zoomfft_bit);
filter_data = nan(1, 2^p.Results.zoomfft_bit);

figure(1); clf;
timeout = 60;
t0 = tic;
% Read and plot intermediate data until the zoomFFT has finished.
while ~ziDAQ('finished', h)
    pause(0.5);
    tmp = ziDAQ('read', h);
    fprintf('ZoomFFT progress %0.0f%%\n', ziDAQ('progress', h) * 100)
    % Using intermediate reads we can plot a continuous refinement of the ongoing
    % measurement. If not required it can be removed.
    if ziCheckPathInData(tmp, ['/' device '/demods/' demod_c '/sample'])
        sample = tmp.(device).demods(demod_idx).sample{1};
        if ~isempty(sample)
            data = tmp;
            % Get the FFT of the demodulator's magnitude from the zoomFFT's result.
            r = sample.r;
            % Frequency and filter data at which measurement points were taken
            frequencies = sample.grid;
            filter_data = sample.filter;
            valid = ~isnan(frequencies);
            fprintf('Number of lines: %d.\n', length(valid));
            plot_data(frequencies(valid), r(valid), filter_data(valid), p.Results.amplitude, '.-b');
            drawnow;
        end
    end
    if toc(t0) > timeout
       error('Timeout: Sweeper failed to finish after %f seconds.', timeout)
    end
end

% Read and process any remaining data returned by read().
tmp = ziDAQ('read', h);

% unsubscribe from the node; stop filling the data from that node to the
% internal buffer in the server
ziDAQ('unsubscribe', h, ['/' device '/demods/*/sample']);

if ziCheckPathInData(tmp, ['/' device '/demods/' demod_c '/sample'])
    sample = tmp.(device).demods(demod_idx).sample{1};
    if ~isempty(sample)
        data = tmp;
        % Get the FFT of the demodulator's magnitude from the zoomFFT's result.
        r = sample.r;
        % Frequency and filter data at which measurement points were taken
        frequencies = sample.grid;
        filter_data = sample.filter;
        fprintf('Number of lines: %d\n', length(frequencies));
        % Plot the final result.
        plot_data(frequencies, r, filter_data, p.Results.amplitude, '-b')
    end
end

end


function plot_data(frequencies, r, filter_data, sigout_amplitude, style)
% Plot data
clf
subplot(2, 1, 1)
s = plot(frequencies, 20*log10(r*2*sqrt(2)/sigout_amplitude), style);
set(s, 'LineWidth', 1)
set(s, 'Color', 'blue');
grid on
xlabel('Frequency [Hz]')
ylabel('Amplitude [dBV]')
subplot(2, 1, 2)
s = plot(frequencies, 20*log10((r./filter_data)*2*sqrt(2)/sigout_amplitude), style);
set(s, 'LineWidth', 1)
set(s, 'Color', 'blue');
grid on
xlabel('Frequency [Hz]')
ylabel('Amplitude [dBV] scaled with Filter')

end


% Local variables:
% matlab-indent-level: 4
% matlab-indent-function-body: nil
% End:
