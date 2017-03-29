function [val, rate] = smcKeithley2002(ico, val, rate)
% driver for Keithley 2002 Multimeter
% hacked together on 2016-11-07 by Sergio de la Barrera:

global smdata;

switch ico(2)
	case 1	% measure voltage or set constant voltage source
		switch ico(3)
			case 0
                fprintf(smdata.inst(ico(1)).data.inst, ':CONF:VOLT:DC');
                val = query(smdata.inst(ico(1)).data.inst,  ':READ?', '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end

	otherwise
		%error('Operation not supported');
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end
