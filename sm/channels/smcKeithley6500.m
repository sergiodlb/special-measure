function [val, rate] = smcKeithley6500(ico, val, rate)
% driver for Keithley 6500 Multimeter
% hacked together on 2018-08-07 by Sergio de la Barrera

global smdata;

switch ico(2)
	case 1	% measure voltage 
		switch ico(3)
			case 0
                val = query(smdata.inst(ico(1)).data.inst,  ':MEAS:VOLT:DC?', '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end
    case 2	% measure current
		switch ico(3)
			case 0
                val = query(smdata.inst(ico(1)).data.inst,  ':MEAS:CURR:DC?', '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end
      
        
	otherwise
		%error('Operation not supported');
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end
