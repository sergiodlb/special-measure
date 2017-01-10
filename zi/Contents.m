% ziDAQ : The LabOne Matlab API for interfacing with Zurich Instruments Devices
%
% FILES
%   ziAddPath  - add the LabOne Matlab drivers, utilities and examples to 
%                Matlab's Search Path for the current session
%   README.txt - a README briefly describing how to get started with ziDAQ
%
% DIRECTORIES
%   Driver/    - contains Matlab driver for interfacing with Zurich Instruments
%                devices
%   Utils/     - contains some utility functions for common tasks
%   Examples/  - contains examples for performing measurements on Zurich
%                Instruments devices
%
% DRIVER
%   Driver/ziDAQ.m          - ziDAQ command reference documentation.
%   Driver/ziDAQ.mex*       - ziDAQ API driver
%
% UTILS
%   Utils/ziAutoConnect     - create a connection to a Zurich Instruments
%                             server
%   Utils/ziAutoDetect      - return the ID of a connected device (if only one
%                             device is connected)
%   Utils/ziDevices         - return a cell array of connected Zurich Instruments
%                             devices
%   Utils/ziCheckPathInData - check whether a node is present in data and non-empty
%
% EXAMPLES/COMMON - Examples that will run on any Zurich Instruments Device
%   example_connect                     - A simple example to demonstrate how to 
%                                         connect to a Zurich Instruments device
%   example_connect_config              - Connect to and configure a Zurich 
%                                         Instruments device
%   example_poll                        - Record demodulator data using 
%                                         ziDAQServer's synchronous poll function
%   example_record_async                - Record data asyncronously using ziDAQ's 
%                                         record module
%   example_record_demod_trigger        - Record demodulator data upon a rising
%                                         edge trigger via ziDAQ's record module
%   example_record_digital_trigger      - Record data using a digital trigger via 
%                                         ziDAQ's record module
%   example_save_device_settings_simple - Save and load device settings
%                                         synchronously using ziDAQ's utility
%                                         functions
%   example_save_device_settings_expert - Save and load device settings 
%                                         asynchronously with ziDAQ's 
%                                         devicesettings module
%   example_sweeper                     - Perform a frequency sweep using ziDAQ's 
%                                         sweep module
%   example_sweeper_rstddev_fixedbw     - Perform a frequency sweep plotting the
%                                         stddev in demodulator output R using
%                                         ziDAQ's sweep module
%   example_sweeper_two_demods          - Perform a frequency sweep saving data
%                                         from 2 demodulators using ziDAQ's sweep
%                                         module
%   example_zoomfft                     - Perform an FFT using ziDAQ's zoomFFT
%                                         module
%
% EXAMPLES/UHF - Examples specific to the UHF Series
%   uhf_example_boxcar              - Record boxcar data using ziDAQServer's 
%                                     synchronous poll function
%   uhf_example_scope               - Record scope data using ziDAQServer's 
%                                     synchronous poll function
%   uhf_example_scope_offset        - Record digitizer data using ziDAQServer's 
%                                     synchronous poll function
%
% EXAMPLES/HF2 - Examples specific to the HF2 Series
%   hf2_example_autorange             - determine and set an appropriate range
%                                       for a sigin channel
%   hf2_example_poll_hardware_trigger - Poll demodulator data in combination 
%                                       with a HW trigger
%   hf2_example_scope                 - Record scope data using ziDAQServer's 
%                                       synchronous poll function
%   hf2_example_zsync_poll            - Synchronous demodulator sample timestamps 
%                                       from multiple HF2s via the Zsync feature
