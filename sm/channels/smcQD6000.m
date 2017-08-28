function [val, rate] = smcQD6000(ico, val, rate)
% driver for Quantum Design PPMS Model 6000
% currently just to set/measure temperature
% 	smcQD6000([ico(1) ico(2) ico(3)], val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel on instrument 1 = TEMP
%                                     2 = PFIELD1SHOT*
%                                     3 = DFIELD1SHOT*
%                                     4 = HELVL
%                                      *while writing to these channels
%                                       has different functions, reading
%                                       either of them reads the current
%                                       magnetic field
% 		ico(3): 0=read, 1=write

% written by eugen.kammerloher@rwth-aachen.de
% adapted by ngoman@andrew.cmu.edu
% modified and extended by sergio@phys.cmu.edu
% - smget(...) seems to work consistently now for temperature, field, and
%   helium level; not sure why each must be read twice

global smdata;

switch ico(2)
	case 1	% temperature
        switch ico(3)
            case 0 % read temperature
                % should be: query(smdata.inst(ico(1)).data.inst, 'GETDAT? 1');
				% not sure why has to be read twice, but the first time it yeilds the value of last message
				% also not sure why TEMP comes through channel 2 instead of 1 as in manual
% 				query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2');
%                 response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2');
                
                response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2\n');
				parsed = sscanf(response, '%d,%f,%f;');
				val = parsed(3);
            case 1 % set temperature
                if nargin < 3
                    rate = 20.0; %[K/min]
                end
                formatSpec = 'TEMP %.4f 20.0 0';
                fprintf(smdata.inst(ico(1)).data.inst, formatSpec, val);
                pause(0.25)
                fprintf(smdata.inst(ico(1)).data.inst, formatSpec, val);
            otherwise
                error('Operation not supported');
        end    
    case 2	% persistent field (one-shot)
        switch ico(3)
            case 0 % read field
                % should be: query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2');
				% not sure why has to be read twice, but the first time it yeilds the value of last message
				% also not sure why TEMP comes through channel 4 instead of 2 as in manual
% 				query(smdata.inst(ico(1)).data.inst, 'GETDAT? 4');
%                 response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 4');
                
                response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 4\n');
				parsed = sscanf(response, '%d,%f,%f;');
				val = parsed(3);
%             case 1 % set persistent field
%                 %formatSpec = 'FIELD %6.2f %6.3f 0 0';
%                 formatSpec = 'FIELD %6.2f 11.0 0 0'; % FIXME - this is a hack until we can figure out two args for smset
%                 fprintf(smdata.inst(ico(1)).data.inst, formatSpec, val);
%                 pause(0.25)
%                 fprintf(smdata.inst(ico(1)).data.inst, formatSpec, val);
            otherwise
                error('Operation not supported');
        end
    case 3	% driven field (one-shot)
        switch ico(3)
            case 0 % read field
				% should be: query(smdata.inst(ico(1)).data.inst, 'GETDAT? 2');
				% not sure why has to be read twice, but the first time it yeilds the value of last message
				% also not sure why TEMP comes through channel 4 instead of 2 as in manual
% 				query(smdata.inst(ico(1)).data.inst, 'GETDAT? 4');
%                 response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 4');
                
                response = query(smdata.inst(ico(1)).data.inst, 'GETDAT? 4\n');
				parsed = sscanf(response, '%d,%f,%f;');
				val = parsed(3);
            case 1 % set driven field
                if nargin < 3
                    rate = 190; %[Oe/s]
                end
%                 formatSpec = 'FIELD %.4f 190 0 1';
                formatSpec = 'FIELD %.4f 20 0 1\n';
                fprintf(smdata.inst(ico(1)).data.inst, formatSpec, val);
            otherwise
                error('Operation not supported');
        end
        
    case 4 % helium level (read-only)
        switch ico(3)
            case 0 % read helium level
%                 % also appears to require reading twice
%                 query(smdata.inst(ico(1)).data.inst, 'LEVEL?');
%                 response = query(smdata.inst(ico(1)).data.inst, 'LEVEL?');
                
                response = query(smdata.inst(ico(1)).data.inst, 'LEVEL?\n');
                parsed = sscanf(response, '%f,%d;');
				val = parsed(1);
            case 1
                error('Helium level is READ-ONLY');
            otherwise
                error('Operation not supported');
        end
        
    otherwise
		%error('Operation not supported');
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end

end
