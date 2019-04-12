%% SM instrument initialization
clear all;
close all;
instrreset;
global smdata;

%% Add ZI HF2LI lock-in to rack
ind = smloadinst('ZIHF2LIvrms');
ziDAQ('connect');
smdata.inst(ind).name = 'ZI'; 

% add channels
smaddchannel('ZI', 'DEMOD1SAMPX', 'ZI.1X');
smaddchannel('ZI', 'DEMOD1SAMPY', 'ZI.1Y');
smaddchannel('ZI', 'DEMOD1PHASE', 'ZI.1phase');
smaddchannel('ZI', 'DEMOD1TC', 'ZI.1timeConstant');

smaddchannel('ZI', 'DEMOD2SAMPX', 'ZI.2X');
smaddchannel('ZI', 'DEMOD2SAMPY', 'ZI.2Y');
smaddchannel('ZI', 'DEMOD2PHASE', 'ZI.2phase');
smaddchannel('ZI', 'DEMOD2TC', 'ZI.2timeConstant');

smaddchannel('ZI', 'OSC1F', 'ZI.1freq');
smaddchannel('ZI', 'OUT1AMP1', 'ZI.OUT1AMP1');
smaddchannel('ZI', 'OUT1RANGE', 'ZI.OUT1RANGE');

smaddchannel('ZI', 'OSC2F', 'ZI.2freq');
smaddchannel('ZI', 'OUT2AMP2', 'ZI.OUT2AMP2');
smaddchannel('ZI', 'OUT2RANGE', 'ZI.OUT2RANGE');