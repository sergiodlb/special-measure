function val = smcLS336(ico, val, rate)
% driver for LakeShore 336 Temperature Controller
% written by Sergio de la Barrera on 2017-02-23

global smdata;

switch ico(2) % channel
    case {1, 2, 3, 4}
        switch ico(3)
			case 0 % get: returns temperature in Kelvin
                channels = 'abcd';
                val = query(smdata.inst(ico(1)).data.inst, sprintf('KRDG? %s', channels(ico(2))), '%s\n', '%f');

			otherwise
				error('Operation not supported');
        end
    case {5, 6, 7, 8}
        switch ico(3)
			case 0 % get: returns sum of status bit weighting
                channels = 'xxxxabcd';
                val = query(smdata.inst(ico(1)).data.inst, sprintf('RDGST? %s', channels(ico(2))), '%s\n', '%d');
                % bit weighting:
                %   0 --> valid reading
                %   1 --> invalid reading
                %   16 --> temp underrange
                %   32 --> temp overrange
                %   64 --> sensor units zero
                %   128 --> sensor units overrange

			otherwise
				error('Operation not supported');
        end

    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end