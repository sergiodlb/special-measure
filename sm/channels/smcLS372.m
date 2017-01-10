function val = smcLS372(ico, val, rate)
% driver for LakeShore 372 AC Resistance Bridge and Temperature Controller
% written by Sergio de la Barrera on 1/9/2017

global smdata;

switch ico(2) % channel
    case {1, 2, 3, 4, 5, 6, 7, 8}
        switch ico(3)
			case 0 % get: returns temperature in Kelvin and ignores error (part after second +/- sign)
%                 query(smdata.inst(ico(1)).data.inst, sprintf('RDGST? %d', ico(2)), '%s\n', '%s') % retrieves status of given channel; 000 means valid
                val = query(smdata.inst(ico(1)).data.inst, sprintf('RDGK? %d', ico(2)), '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end

    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end