function [val, rate] = smcDS345(ico, val, rate)
% Driver for Stanford Research Systems DS345 arbitrary waveform generator using the SCPI interface
% Written by Sergio de la Barrera (sdlb@mit.edu) on Feb 25, 2021
% 	smcDS345([ico(1) ico(2) ico(3)], val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel on instrument 1 =
% 		ico(3): 0=read, 1=write(, 3=trig, 4=bufferreset, 5=sweepsetup)

global smdata;

switch ico(2)
	case 1 % frequency
		switch ico(3)
			case 0 % get
                val = query(smdata.inst(ico(1)).data.inst,  'FREQ?', '%s\n', '%f');
			case 1 % set
                fprintf(smdata.inst(ico(1)).data.inst, 'FREQ %f', val); % [Hz]
			otherwise
				error('Operation not supported');
        end
        
    case 2 % rms amplitude
		switch ico(3)
			case 0 % get
                val = query(smdata.inst(ico(1)).data.inst,  'AMPL? VR', '%s\n', '%fVR');
			case 1 % set
                fprintf(smdata.inst(ico(1)).data.inst, 'AMPL %fVR', val); % [V]
			otherwise
				error('Operation not supported');
        end
        
    case 3 % phase
		switch ico(3)
			case 0 % get
                val = query(smdata.inst(ico(1)).data.inst,  'PHSE?', '%s\n', '%f');
			case 1 % set
                fprintf(smdata.inst(ico(1)).data.inst, 'PHSE %f', val); % [degrees]
			otherwise
				error('Operation not supported');
        end

    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not implemented']);
end
