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
                if ~isscalar(val) % if LS372 returns [48    57    44    48    13    10] or other array
                    cprintf('red', 'Warning: GPIB read error --> %s\n', val);
                    val = nan;
                elseif isempty(val) % if LS372 returns []
                    cprintf('red', 'Warning: GPIB read error --> []\n');
                    val = nan;
                end
			otherwise
				error('Operation not supported');
        end
    case 17 % OUTMODE set/get output mode
        switch ico(3)
			case 0 % get: output mode of sample heater (channel 0)
                % format is: <mode>,<input/channel>,<powerup enable>,<polarity>,<filter>,<delay>
                val = query(smdata.inst(ico(1)).data.inst, 'OUTMODE? 0', '%s\n', '%g,%g,%g,%g,%g,%g');
            otherwise
                % val = 0 will turn output (heating) OFF, val = 1 will turn closed loop PID ON
                % format is: <output>,<mode>,<input/channel>,<powerup enable>,<polarity>,<filter>,<delay>
                % <output> Specifies which output to configure:
                %   0 = sample heater, 1 = output 1 (warm-up heater), 2 = output 2 (analog/still).
                % <mode> Specifies the control mode. Valid entries:
                %   O = Off
                %   1 = Monitor Out
                %   2 = Open Loop (Manual)
                %   3 = Zone
                %   4 = Still
                %   5 = Closed Loop (PID)
                %   6 = Warm up 
                % <input> Specifies which input or channel to control from:
                %   0 = none, A (control input), 1 to 16 (measurement input).
                % <powerup enable> Specifies whether the output remains on or shuts off after power cycle. Valid entries: 0 = powerup enable off, 1 = powerup enable on.
                % <polarity> Specifies output polarity: 0 = unipolar, 1 = bipolar.
                %   (Not applicable to output 1 warm-up heater.
                % <filter> Specifies controlling on unfiltered or filtered readings:
                %   0 = unfiltered, 1 = filtered.
                % <delay> Delay in seconds for setpoint change during Autoscanning: 1 to 255.
                if val > 0
                    fprintf(smdata.inst(ico(1)).data.inst, 'OUTMODE 0,5,9,1,0,0,002');
                else
                    fprintf(smdata.inst(ico(1)).data.inst, 'OUTMODE 0,0,9,1,0,0,002');
                end
        end
    case 18 % SETP change setpoint
        switch ico(3)
            case 0 % get setpoint
                val = query(smdata.inst(ico(1)).data.inst, 'SETP? 0', '%s\n', '%f');
            otherwise % change setpoint
                fprintf(smdata.inst(ico(1)).data.inst, 'SETP 0,%f', val);
        end
    case 19 % RANGE change heater range
        switch ico(3)
            case 0 % get heater range
                % meaning of output is:  0 = off, 1 = 31.6 µA, 2 = 100 µA, 3 = 316 µA,
                %   4 = 1.00 mA, 5 = 3.16 mA, 6 = 10.0 mA, 7 = 31.6 mA, 8 = 100 mA
                val = query(smdata.inst(ico(1)).data.inst, 'RANGE? 0', '%s\n', '%f');
            otherwise % change heater range
                fprintf(smdata.inst(ico(1)).data.inst, 'RANGE 0,%f\n', val);
        end
    case 20 % PID settings
        % PID Closed Loop PID Parameter Command
        % Input PID <output>,<P value>,<I value>,<D value>[term]
        % Format n,+nnnnnn,+nnnnnn,+nnnnnn
        % <output> 0 = sample heater, 1 = output 1 (warm-up heater).
        % <P value> The value for control loop Proportional (gain): 0.0 to 1000.
        % <I value> The value for control loop Integral (reset): 0 to 10000.
        % <D value> The value for control loop Derivative (rate): 0 to 2500.
        % Remarks Setting resolution is less than 6 digits indicated. If <output> is not specified, 0 (sample
        % heater) is assumed for backwards compatibility.
        % Example PID 10,100,20,0[term]— P = 10, I = 100 s, and D = 20 s.
        %
        % PID? Closed Loop PID Parameter Query
        % Input PID? <output>[term]
        % Format n
        % <output> 0 = sample heater, 1 = output 1 (warm-up heater).
        % Returned <P value>,<I value>,<D value>[term]
        % Format +nnnnnn,+nnnnnn,+nnnnnn (refer to command for description)
        % Remarks Setting resolution is less than 6 digits indicated. If <output> is not specified, 0 (sample
        % heater) is assumed for backwards compatibility.
        error('Remote control of PID not yet implemented');
    case 21 % RAMP setpoint ramping
        switch ico(3)
            case 0 % get ramp ON/OFF; ignore ramp rate
                % returns: <off/on>,<rate value>
                out = query(smdata.inst(ico(1)).data.inst, 'RAMP? 0', '%s\n', '%f,%f');
                val = out(1);
            otherwise % turn setpoint ramping ON/OFF, leave rate alone
                out = query(smdata.inst(ico(1)).data.inst, 'RAMP? 0', '%s\n', '%f,%f');
                if val > 0
                    fprintf(smdata.inst(ico(1)).data.inst, 'RAMP 0,1,%f\n', out(2));
                else
                    fprintf(smdata.inst(ico(1)).data.inst, 'RAMP 0,0,%f\n', out(2));
                end
        end
    case 22 % RAMP-RATE settings
        switch ico(3)
            case 0 % get ramp rate; ignore ramp ON/OFF
                % returns: <off/on>,<rate value>
                out = query(smdata.inst(ico(1)).data.inst, 'RAMP? 0', '%s\n', '%f,%f');
                val = out(2);
            otherwise % change setpoint ramp rate, leave ON/OFF state alone
                out = query(smdata.inst(ico(1)).data.inst, 'RAMP? 0', '%s\n', '%f,%f');
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('RAMP 0,%f,%f\n', out(1), val));
        end
        % could implement RAMPST as well later:
        % RAMPST? Setpoint Ramp Status Query
        % Input RAMPST? <output>[term]
        % Format n
        % <output> 0 = sample heater, 1 = output 1 (warm-up heater).
        % Returned <ramp status>[term]
        % Format n
        % <ramp status> 0 = Not ramping, 1 = Setpoint is ramping.
        % Remarks If <output> is not specified, 0 (sample heater) is assumed for backwards compatibility
    case 23 % AUTOSCAN
        switch ico(3)
            case 0 % determine if AUTOSCAN is ON/OFF
                % returns: <input/channel>,<autoscan>
                val = query(smdata.inst(ico(1)).data.inst, 'SCAN?', '%s\n', '%f,%f');
%                 val = query(smdata.inst(ico(1)).data.inst, 'INSET? 9', '%s\n', '%s');
            otherwise % toggle AUTOSCAN ON/OFF using default settings
                if val > 0
                    fprintf(smdata.inst(ico(1)).data.inst, 'SCAN 9,1\n'); % turn autoscan ON
%                     fprintf(smdata.inst(ico(1)).data.inst, 'INSET 9,1,003,003,29,1\n'); % set probe parameters to default
                else
                    fprintf(smdata.inst(ico(1)).data.inst, 'SCAN 9,0\n'); % turn autoscan OFF (will read channel 9 continuously)
%                     fprintf(smdata.inst(ico(1)).data.inst, 'INSET 9,1,003,003,29,1\n'); % set probe parameters to fast read settings
                end
            % *** chaning INSET settings seems not to be necessary, but here is the syntax for reference
            % Input INSET <input/channel>,<disabled/enabled>,<dwell>,<pause>,<curve number>,<tempco>[term]
            % Format nn,n,nnn,nnn,nn,n
            % <input/channel> Specifies which input or channel to configure:
            %   A (control input), 1 to 16 (measurement input), 0 = all channels (measurement input).
            % <disabled/enabled> Specifies whether the input/channel is disabled or enabled:
            %   0 = disabled, 1 = enabled.
            % <dwell> Specifies a value for the autoscanning dwell time:
            %   1 to 200 s. Not applicable for <input/channel> = A (control input).
            % <pause> Specifies a value for the change pause time: 3 to 200 s.
            % <curve number> Specifies which curve the channel uses: 0 = no curve, 1 to 59 = standard/user curves.
            % <tempco> Sets the temperature coefficient that will be used for
            %   temperature control if no curve is selected: 1 = negative, 2 = positive
        end
    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end