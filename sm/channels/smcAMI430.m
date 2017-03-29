function val = smcAMI430(ico, val, rate)
% driver for American Magnetics Inc. Model 430  magnet power supply
% written by Sergio de la Barrera, sergio@phys.cmu.edu
% 	smcAMI430([ico(1) ico(2) ico(3)], val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel
% 		ico(3): 0=read, 1=write
% ----------- CHANNELS and MODIFICATIONS ----------
% 2017-02-26: added channel 1 --> FIELD
%             added channel 2 --> FTARG

global smdata;

switch ico(2) % channel
    case 1 % FIELD VALUE and TARGET
        switch ico(3)
            case 0 % get field value in default units
%                 % manual AMI430
%                 fprintf(AMI_serial_obj, 'FIELD:MAG?');
%                 disp(sprintf('Field value is %f %s', fscanf(AMI_serial_obj, '%f'), field_unit));
%                 
%                 % ppms
%                 query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2');
%                 response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2');
% 				parsed = sscanf(response, '%d,%f,%f;');
%                 
%                 % keithley
%                 fprintf(smdata.inst(ico(1)).data.inst, ':FORM:ELEM VOLT');
% 				val = query(smdata.inst(ico(1)).data.inst,  ':READ?', '%s\n', '%f');
                
                val = query(smdata.inst(ico(1)).data.inst, 'FIELD:MAG?', '%s\n', '%f');
            case 1 % SET FIELD TARGET
                fprintf(smdata.inst(ico(1)).data.inst, 'CONF:FIELD:TARG %f\n', val);

            otherwise
                error('Operation not supported');
        end
    case 2 % SEGMENT 1 RAMP RATE
        switch ico(3)
            case 0 % get seg 1 ramp rate
                val = query(smdata.inst(ico(1)).data.inst, 'RAMP:RATE:FIELD:1?', '%s\n', '%f,%f');
            case 1 % segment upper bounds hard coded --> seg 1: 9.1 T
                fprintf(smdata.inst(ico(1)).data.inst, 'CONF:RAMP:RATE:FIELD 1,%f,9.1\n', val);
            otherwise
                error('Operation not supported');
        end
    case 3 % SEGMENT 2 RAMP RATE
        switch ico(3)
            case 0 % get seg 2 ramp rate
                val = query(smdata.inst(ico(1)).data.inst, 'RAMP:RATE:FIELD:2?', '%s\n', '%f,%f');
            case 1 % segment upper bounds hard coded --> seg 2: 13.0 T
                fprintf(smdata.inst(ico(1)).data.inst, 'CONF:RAMP:RATE:FIELD 2,%f,13.0\n', val);
            otherwise
                error('Operation not supported');
        end
    case 4 % RAMP MODE
        switch ico(3)
            case 0
                error('RAMP is set-only; use STATE channel to query status');
            case 1 % RAMP NOW
                fprintf(smdata.inst(ico(1)).data.inst, 'RAMP\n');
            otherwise
                error('Operation not supported');
        end
    case 5 % PAUSE MODE
        switch ico(3)
            case 0
                error('PAUSE is set-only; use STATE channel to query status');
            case 1 % PAUSE RAMP NOW
                fprintf(smdata.inst(ico(1)).data.inst, 'PAUSE\n');
            otherwise
                error('Operation not supported');
        end
    case 6 % PERSISTENT SWITCH
        switch ico(3)
            case 0 % QUERY PSWITCH STATUS
                val = query(smdata.inst(ico(1)).data.inst, 'PS?', '%s\n', '%f');
            case 1
                error('Remote persistent switch operation not implemented; go to the lab!');
            otherwise
                error('Operation not supported');
        end
    case 7 % QUERY STATE
        switch ico(3)
            case 0 % QUERY RAMPING STATE
                val = query(smdata.inst(ico(1)).data.inst, 'STATE?', '%s\n', '%d');
                switch val
                    case 1
                        val = 'RAMPING TO TARGET FIELD/CURRENT';
                    case 2
                        val = 'HOLDING AT TARGET FIELD/CURRENT';
                    case 3
                        val = 'PAUSED';
                    case 4
                        val = 'RAMPING IN MANUAL-UP MODE';
                    case 5
                        val = 'RAMPING IN MANUAL-DOWN MODE';
                    case 6
                        val = 'ZEROING CURRENT';
                    case 7
                        val = 'QUENCH DETECTED';
                    case 8
                        val = 'AT ZERO CURRENT';
                    case 9
                        val = 'HEATING PERSISTENT SWTICH';
                    case 10
                        val = 'COOLING PERSISTENT SWTICH';
                end
            otherwise
                error('Operation not supported');
        end
    otherwise
        error('Channel not implemented');
end