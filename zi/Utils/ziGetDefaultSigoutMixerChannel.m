function output_mixer_channel = ziGetDefaultSigoutMixerChannel(devtype, options, output_channel)
% ZIGETDEFAULTSIGOUTMIXERCHANNEL Return instrument's default signal output mixer channel 
%
% ZIGETDEFAULTSIGOUTMIXERCHANNEL(DEVTYPE, OPTIONS, OUTPUT_CHANNEL)
% 
% Return the instrument's default Signal Output mixer channel used by the
% hardware Signal Output channel specified by OUTPUT_CHANNEL. DEVTYPE is a
% byte array containing the value of the device node '/DEVN/features/devtype'
% and OPTIONS is a byte array containing the value of the device node
% '/DEVN/features/options'.
%
% NOTE For MFLI Instruments the output_channel input argument may be omitted;
% The MFLI only has one Signal Output channel.
%
% EXAMPLE 
%
% device_id = 'dev2006';
% % Determine the device identifier from it's ID.
% device = lower(ziDAQ('discoveryFind', device_id));
% 
% % Get the device's default connectivity properties.
% props = ziDAQ('discoveryGet', device);
% 
% % The maximum API level supported by this utility function.
% apilevel_utility_function = 5;
% % The maximum API level supported by the device class, e.g., MF.
% apilevel_device = props.apilevel;
% % Ensure we run this utility function using a supported API level.
% apilevel = min(apilevel_device, apilevel_example);
% % See the LabOne Programming Manual for an explanation of API levels.
% 
% % Create a connection to a Zurich Instruments Data Server (a API session)
% % using the device's default connectivity properties.
% ziDAQ('connect', props.serveraddress, props.serverport, apilevel);
% 
% % Get the device type and its options (in order to set correct device-specific
% % configuration).
% devtype = ziDAQ('getByte', ['/' device '/features/devtype']);
% options = ziDAQ('getByte', ['/' device '/features/options']);
% 
% output_channel = 0;  % 0-based indexing.
% mixer_channel = ziGetDefaultSigoutMixerChannel(devtype, options, output_channel)
%
% Copyright 2008-2015 Zurich Instruments AG
  
if ~exist('devtype', 'var')
  error('Required input argument `devtype` not specified.');
end

if ~exist('options', 'var')
  error('Required input argument `options` not specified.');
end

if ~exist('output_channel', 'var')
  if isempty(devtype, 'MFLI')
    error('Required input argument `output_channel` specified. This specifies the Signal Output HW channel.');
  else
    output_channel = 0;
  end
else
  if isempty(strfind(devtype, 'MFLI'))
    output_channels = [0, 1];
  else
    output_channels = [0];
  end
  assert(ismember(output_channel, output_channels), ...
         'Invalid value for output_channel: %d. Valid values: %s.', output_channel, mat2str(output_channels));  
end

% Define the output mixer channel based on the device type and its options.
if strfind(devtype, 'UHF') & isempty(strfind(options, 'MF'))
  if output_channel == 0
    output_mixer_channel = '3';
  else
    output_mixer_channel = '7';
  end
elseif strfind(devtype, 'HF2LI') & isempty(strfind(options, 'MF'))
  if output_channel == 0
    output_mixer_channel = '6';
  else
    output_mixer_channel = '7';
  end
elseif strfind(devtype, 'MFLI') & isempty(strfind(options, 'MD'))
    output_mixer_channel = '1';
else
  output_mixer_channel = '0';
end

end

