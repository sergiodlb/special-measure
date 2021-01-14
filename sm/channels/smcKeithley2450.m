function [val, rate] = smcKeithley2450(ico, val, rate)
% driver for Keithley 2450 SourceMeter using SCPI interface
% (not SCPI2400 legacy mode)
% written by Sergio de la Barrera (sdlb@mit.edu)
% 	smcKeithley2450([ico(1) ico(2) ico(3)], val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel on instrument 1 =VOLT
%                                     2 =CURRENT, 
%									  3 =COMPLIANCE
%                                     4 =ISSOURCEVOLT
%                                     5 =OUTPUTON
% 		ico(3): 0=read, 1=write(, 3=trig, 4=bufferreset, 5=sweepsetup)

% measurement range is determined by instrument, presumebly slow
% no ramps/triggering implimented, consult smcdmm.m
% no ...
% only dc voltage/current measure/source

global smdata;

switch ico(2)
	case 1	% measure voltage or set constant voltage source
		switch ico(3)
			case 0
                source_mode = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(source_mode, 'VOLT')
                    % readback mode: we are requesting source value, not
                    % sense value, so don't change measurement modes
                    val = query(smdata.inst(ico(1)).data.inst, ':READ? "defbuffer1", SOUR', '%s\n', '%f');
                    % whether this returns an actual measured value or just
                    % the set point value depends on the result of:
                    % query(smdata.inst(ico(1)).data.inst, ':SOUR:VOLT:READ:BACK?', '%s\n', '%s')
                else
                    % measurement mode: sourcing I, measuring V
                    val = query(smdata.inst(ico(1)).data.inst,  ':MEAS:VOLT?', '%s\n', '%f'); % same as below but in one command
%                 fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FUNC "VOLT"');
%                 val = query(smdata.inst(ico(1)).data.inst,  ':MEAS?', '%s\n', '%f');
                end
			case 1
                fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:VOLT %f', val);
			otherwise
				error('Operation not supported');
		end

	case 2	% measure current or set constant current on source
		switch ico(3)
			case 0
                source_mode = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(source_mode, 'CURR')
                    % readback mode: we are requesting source value, not
                    % sense value, so don't change measurement modes
                    val = query(smdata.inst(ico(1)).data.inst, ':READ? "defbuffer1", SOUR', '%s\n', '%f');
                    % whether this returns an actual measured value or just
                    % the set point value depends on the result of:
                    % query(smdata.inst(ico(1)).data.inst, ':SOUR:CURR:READ:BACK?', '%s\n', '%s')
                else
                    % measurement mode: sourcing V, measuring I
                    val = query(smdata.inst(ico(1)).data.inst,  ':MEAS:CURR?', '%s\n', '%f'); % same as below but in one command
%                 fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FUNC "CURR"');
%                 val = query(smdata.inst(ico(1)).data.inst,  ':MEAS?', '%s\n', '%f');
                end
			case 1
                fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:CURR %f', val);
			otherwise
				error('Operation not supported');
		end

	case 3 % compliance level = limit level of sensed output
		switch ico(3)
			case 0
				source_mode = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(source_mode, 'VOLT')
					limit_mode = 'ILIM';
				else
					limit_mode = 'VLIM';
                end
                
				% query limit level
				val = query(smdata.inst(ico(1)).data.inst,  [':SOUR:' source_mode ':' limit_mode ':LEV?'], '%s\n', '%f');
			case 1
                error('Operation not supported'); % the below code is not 100% working
                
				source_mode = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(source_mode, 'VOLT')
					limit_mode = 'ILIM';
				else
					limit_mode = 'VLIM';
                end

                fprintf(smdata.inst(ico(1)).data.inst, [':SOUR:' source_mode ':' limit_mode ':LEV %f'], val);
			otherwise
				error('Operation not supported');
		end

	case 4 % get 1 if sourcing voltage. Set 1 to source voltage (0 for current)
		switch ico(3)
			case 0 % instrument outputs VOLT, CURR
				val = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(val, 'VOLT')
					val = 1;
				else
					val = 0;
                end

			case 1
                if val == 1
					cmd = 'VOLT';
				else
					cmd = 'CURR';
                end
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:FUNC %s', cmd);

			otherwise
				error('Operation not supported');
		end

	case 5 % get 1 if output is on. Set 1 to set output on (0 for off)
		switch ico(3)
			case 0 % instruments outputs 1 for ON, 0 for OFF
				val = query(smdata.inst(ico(1)).data.inst,  ':OUTP:STAT?', '%s\n', '%d');
                
			case 1
                if (val == 1)
					cmd = 'ON';
				else
					cmd = 'OFF';
                end
				fprintf(smdata.inst(ico(1)).data.inst, ':OUTP:STAT %s', cmd);

			otherwise
				error('Operation not supported');
        end
        
    case 6 % not implemented for 2450
        switch ico(3)
            case 0 % get resistance
                error('Operation not supported');
%                 % switch Ohm mode to manual
%                 fprintf(smdata.inst(ico(1)).data.inst, ':SENS:RES:MODE MAN')
%                 % slow but simple
% 				fprintf(smdata.inst(ico(1)).data.inst, ':SENS:RES:RANG:AUTO ON');
% 				% set remote output format to resistance only
% 				fprintf(smdata.inst(ico(1)).data.inst, ':FORM:ELEM RES');
% 				val = query(smdata.inst(ico(1)).data.inst,  ':READ?', '%s\n', '%f');
                
            case 1
                error('Cannot set measured resistance');
            otherwise
                error('Operation not supported');
                
        end

    case 7 % set or get source voltage range
		switch ico(3)
            case 0 % set range (Keithley selects minimum range inclusive of given value)
                val = query(smdata.inst(ico(1)).data.inst,  ':SOUR:VOLT:RANG?', '%s\n', '%f');
			case 1 % get present voltage source range
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:VOLT:RANGE %f', val);
			otherwise
				error('Operation not supported');
        end

	otherwise
		% LIST OF OTHER COMMANDS (NOT IMPLEMENTED):
        % get value: 1=ON=4-wire mode, 0=OFF=2-wire mode
%         val = query(smdata.inst(ico(1)).data.inst,  'SYST:RSEN?', '%s\n', '%d');
        % cancel remote; restore SourceMeter front panel operation
%         fprintf(smdata.inst(ico(1)).data.inst, ':SYST:LOC');
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end
