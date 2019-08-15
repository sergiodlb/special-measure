function val = smcHP34401A(ico, val, rate)
% driver for HP34401A Digital Multimeter
% written by Sergio de la Barrera circa Aug 15, 2019

global smdata;

switch ico(2)
	case 1	% measure DC voltage
		switch ico(3)
			case 0
                % measure voltage using MEAS
                val = query(smdata.inst(ico(1)).data.inst,  ':MEAS:VOLT:DC?', '%s\n', '%f');
                
%                 % measure voltage using CONF
%                 fprintf(smdata.inst(ico(1)).data.inst, ':CONF:VOLT:DC');
%                 val = query(smdata.inst(ico(1)).data.inst,  ':READ?', '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end
    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end
