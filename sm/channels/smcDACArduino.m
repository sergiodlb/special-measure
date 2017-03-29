function [val, rate] = smcQD6000(ico, val, rate)
% driver for DC voltage supply Arduino box
% currently just to set/measure temperature
% 	smcQD6000([ico(1) ico(2) ico(3)], val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel on instrument
% 		ico(3): 0=read, 1=write

% written by ngoman@andrew.cmu.edu

global smdata;

switch ico(3)
    case 0 % read voltage
        val = getvoltageDC(ico(2));
    case 1 % set voltage
        setvoltageDC(ico(2), val);
    otherwise
        error('Operation not supported');
end

end
