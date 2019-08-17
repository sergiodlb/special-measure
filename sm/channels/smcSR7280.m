function val = smcSR7280(ico, val, rate)
% driver for Signal Recovery/Ametek/Perkin Elmer 7280 DSP Lock-in Amplifier
% written by Sergio de la Barrera circa Aug 15, 2019

global smdata;

cmds = {'X.', % measure X channel in volts or amps
        'Y.', % measure Y channel in volts or amps
        'MAG.', % measure magnitude of X+iY in volts or amps
        'PHA.', % measure phase of X+iY in degrees
%         'XY.', % measure X and Y channels in volts or amps
        'OA.', % output amplitude
        'OF.', % internal oscillator frequency
        };

switch ico(2)
    case num2cell(1:4) % get-only commands
		switch ico(3)
			case 0
                val = query(smdata.inst(ico(1)).data.inst, cmds{ico(2)}, '%s\n', '%f');
			otherwise
				error('Operation not supported');
        end
    case num2cell(5:6) % set-or-get commands
		switch ico(3)
			case 0
                val = query(smdata.inst(ico(1)).data.inst, cmds{ico(2)}, '%s\n', '%f');
            case 1
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('%s %f', cmds{ico(2)}, val));
                spoll(smdata.inst(ico(1)).data.inst); % this is required for clearing the status byte from the register before the next command
        end
    case 7 % full-scale sensitivity (unit depends on voltage/current mode)
        switch ico(3)
			case 0 % can query directly
                val = query(smdata.inst(ico(1)).data.inst, 'SEN.', '%s\n', '%f');
            case 1 % but setting requires lookup table
                idx = sens_index(val);
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('SEN %d', idx));
                spoll(smdata.inst(ico(1)).data.inst); % this is required for clearing the status byte from the register before the next command
        end
    case 8 % perform auto-sensitivity operation
        switch ico(3)
			case 0
                error('Use SET only');
            case 1 % val is ignored
                fprintf(smdata.inst(ico(1)).data.inst, 'AS');
                spoll(smdata.inst(ico(1)).data.inst); % this is required for clearing the status byte from the register before the next command
        end
    case 9 % AC gain control
        switch ico(3)
			case 0
                idx = query(smdata.inst(ico(1)).data.inst, 'ACGAIN', '%s\n', '%d');
                val = lookup_gain(idx);
            case 1
                idx = gain_index(val);
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('ACGAIN %d', idx));
                spoll(smdata.inst(ico(1)).data.inst); % this is required for clearing the status byte from the register before the next command
        end
    case 10 % time constant
        switch ico(3)
			case 0  % can query directly
                val = query(smdata.inst(ico(1)).data.inst, 'TC.', '%s\n', '%f');
            case 1 % but setting requires lookup table
                idx = tc_index(val);
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('TC %d', idx));
                spoll(smdata.inst(ico(1)).data.inst); % this is required for clearing the status byte from the register before the next command
        end
    case 11 % toggle INT/EXT reference
        switch ico(3)
			case 0 % query
                val = query(smdata.inst(ico(1)).data.inst, 'IE', '%s\n', '%d');
            case 1
                if (val==0 || val==2)
                    fprintf(smdata.inst(ico(1)).data.inst, sprintf('IE %d', val));
                    spoll(smdata.inst(ico(1)).data.inst); % this is required for clearing the status byte from the register before the next command
                else
                    error('Choose 0-->internal, 1-->rear external TTL, 2-->front external reference');
                end
        end
    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end
end

function idx = sens_index(sensitivity)
    % converts a desired VOLTAGE sensitivity to nearest value (rounds up)
    % could use IMODE == 0 test (VOLTAGE MODE)
    x = [1, 2, 5];
    sensvals = [10e-9*x, 100e-9*x, 1e-6*x, 10e-6*x, 100e-6*x, 1e-3*x, 10e-3*x, 100e-3*x, 1]; % VOLTAGE MODE ONLY
    [~, idx] = min(abs(sensvals - sensitivity)); % handles floating-point errors
    idx = idx + 2; % lookup table starts at n=3 for some reason
end

function gain = lookup_gain(idx)
    % converts an index to the corresponding gain value
    gainvals = [0, 6, 14, 20, 26, 34, 40, 46, 54, 60, 66];
    gain = gainvals(idx+1);
end

function idx = gain_index(gain)
    % converts a desired gain to nearest value (rounds up)
    gainvals = [0, 6, 14, 20, 26, 34, 40, 46, 54, 60, 66];
    [~, idx] = min(abs(gainvals - gain)); % handles floating-point errors
    idx = idx - 1; % lookup table starts at n=0
end

function idx = tc_index(time)
    % converts a desired time constant to nearest value (rounds up)
    x = [1, 2, 5];
    times = [1e-6*x, 10e-6*x, 100e-6*x, 1e-3*x, 10e-3*x, 100e-3*x, 1*x, 10*x, 100*x, 1e3*x, 10e3*x, 100e3];
    [~, idx] = min(abs(times - time)); % handles floating-point errors
    idx = idx - 1; % lookup table starts at n=0
end