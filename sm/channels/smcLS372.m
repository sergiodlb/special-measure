function val = smcLS372(ico, val, rate)
% driver for LakeShore 372 AC Resistance Bridge and Temperature Controller
% written by Sergio de la Barrera on 1/9/2017
% updated with additional control channels on 5/10/2017

global smdata;

switch ico(2) % channel
    case num2cell(1:16) % get temperature
        switch ico(3)
			case 0 % get: returns temperature in Kelvin and ignores error (part after second +/- sign)
                val = query(smdata.inst(ico(1)).data.inst, sprintf('RDGK? %d', ico(2)), '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end
    case 17 % set/get output mode
        switch ico(3)
			case 0 % get: output mode of sample heater (channel 0)
                val = query(smdata.inst(ico(1)).data.inst, 'OUTMODE? 0', '%s\n', '%s');

            otherwise
%                 fprintf(smdata.inst(ico(1)).data.inst, 'OUTMODE 0,', val);
				error('Operation not supported');
        end

    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end