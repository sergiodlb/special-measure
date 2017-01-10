LabOne Matlab Driver, Utilities and Examples
© Zurich Instruments AG

This folder contains the necessary files to perform measurements with your
Zurich Instruments device Instrument under Matlab. It contains the following
subfolders and files:

- "README.txt", this file
- "Driver", a subfolder containing the matlab driver interface (mex file)
   and a help file
- "Examples", a subfolder containing UHF, HF2 and Common folders, which
   contain some instrument-specific and instrument-independent examples
- "Utils", a subfolder containing some ziDAQ-based utility functions
- "ziAddPath.m", a matlab function that adds the "Driver", "Examples" and
  "Utils" subdirectories to Matlab's Search Path for the current Matlab
   session

* Running one of the provided examples

In order to run one of the examples in one of the "Examples" subdirectories
please perform the following steps:
- Start the instrument and make sure that the correct Data Server is running
  (task manager on windows)
- On the Instrument, connect Signal Output1 to the Signal Input1 by means of a
  BNC cable
- Start Matlab
- Navigate to this folder in Matlab
- Run the Matlab function ziAddPath.m with the call "ziAddPath"
- Start an example by calling the example by name in Matlab with your device
  ID as the only input argument, e.g.,
  >> example_poll('dev123')

In the Matlab command window you should get messages similar to the following:
>> ziAddPath
Added ziDAQ's Driver, Utilities and Examples directories to Matlab's path
for this session
To make this configuration persistent across Matlab sessions add the following
line to your Matlab startup.m file:
run('C:\Program Files\Zurich Instruments\LabOne\API\MATLAB2012/ziAddPath');
>> example_poll('dev123')  % Change device ID as appropriate
ziDAQ version Apr 15 2014 accessing server localhost.
Measured rms amplitude 0.348972V (expected: 0.353553V)

* Getting help

You may use "help ziDAQ" or "doc ziDAQ" in Matlab to get more information on
the commands.

Please refer to the LabOne Programming Manual for more information, it is
available in your LabOne installation: Click the Windows Start Button, then
navigate to:
Zurich Instruments -> Documentation -> LabOne Programming Manual

