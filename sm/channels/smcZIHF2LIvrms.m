function val = smcZIHF2LIvrms(ico, val, ~)
% Driver for Zurich Intruments HF2LI lock-in amplifier
% - modified by Sergio de la Barrera to set and return real voltage values,
%   not a fraction of the output range, as was the case before
% - this version also sets and returns RMS output voltages, to match the
%   behavior of Stanford Research lock-in amplifiers
% - eliminated "capacitance bridge" channels, which are handled elsewhere
% - based on original work by Nick Goman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 	smcZIHF2LI([ico(1) ico(2) ico(3)], val, rate)

% ico(1) is the instrument's number on the rack,
% ico(2) is the node you want
% ico(3) is read (0) or write (1)

% Signal Inputs
    % Input 1
        % 1) Range
% Oscillator frequencies
    % 2) Oscillator 1
    % 3) Oscillator 2
% Demodulators
    % Demod 1
        % 4) Phase
        % 5) Time constant
        % 6) Sample X (read only)
        % 7) Sample Y (read only)
        % 8) Sample R (read only)
    % Demod 2
        %  9) Phase
        % 10) Time constant
        % 11) Sample X (read only)
        % 12) Sample Y (read only)
% Outputs
    % Output 1
        % Amplitude values
            % 13) Amplitude 1
        % Amplitudes on/off
            % 14) Amplitude 1
        % 15) Output on/off
        % 16) Range
    % Output 2
        % Amplitude values
            % 17) Amplitude 2
        % Amplitudes on/off
            % 18) Amplitude 2
        % 19) Output on/off
        % 20) Range
        % 21) [Write to balance bridge]
        % 22) [Read to get delta-C]
        
global capdata;
switch ico(2)
    % Signal Inputs
    % Input 1
    case 1 % Range
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/sigins/0/range');
            case 1
                ziDAQ('setDouble', '/dev1012/sigins/0/range', val);
        end
        
    % Oscillator frequencies
    case 2 % Oscillator 1
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/oscs/0/freq');
            case 1
                ziDAQ('setDouble', '/dev1012/oscs/0/freq', val);
        end
    case 3 % Oscillator 2
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/oscs/1/freq');
            case 1
                ziDAQ('setDouble', '/dev1012/oscs/1/freq', val);
        end
        
    % Demodulators
    % Demod 1
    case 4 % Phase shift relative to reference oscillator (degrees)
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/demods/0/phaseshift');
            case 1
                ziDAQ('setDouble', '/dev1012/demods/0/phaseshift', val);
        end
    case 5 % Time constant
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/demods/0/timeconstant');
            case 1
                ziDAQ('setDouble', '/dev1012/demods/0/timeconstant', val);
        end
    case 6 % Sample X
        data = ziDAQ('getSample', '/dev1012/demods/0/sample/');
        val = data.x;
    case 7 % Sample Y
        data = ziDAQ('getSample', '/dev1012/demods/0/sample/');
        val = data.y;
    case 8 % Sample R
        % this did not do what you would expect in Nick's version, so I have de-activated it
        error('requested channel not supported');        
        
    % Demod 2
    case 9 % Phase shift relative to reference oscillator (degrees)
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/demods/1/phaseshift');
            case 1
                ziDAQ('setDouble', '/dev1012/demods/1/phaseshift', val);
        end
    case 10 % Time constant
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/demods/1/timeconstant');
            case 1
                ziDAQ('setDouble', '/dev1012/demods/1/timeconstant', val);
        end
    case 11 % Sample X
        data = ziDAQ('getSample', '/dev1012/demods/1/sample/');
        val = data.x;
    case 12 % Sample Y
        data = ziDAQ('getSample', '/dev1012/demods/1/sample/');
        val = data.y;

        
    % Output Amplitudes / Signal Outputs
    % Output 1
    % Amplitude values
    case 13 % Output 1, amp 1
        % first get the range
        out_range = ziDAQ('getDouble', '/dev1012/sigouts/0/range');
        switch ico(3)
            case 0
                % get the voltage fraction and multiply by range
                vmult = ziDAQ('getDouble', '/dev1012/sigouts/0/amplitudes/0'); % fraction of range, Vpp
                val = vmult*out_range/sqrt(2); % this is the returned output value as Vrms
            case 1
                % converted from Vrms to Vpp
                Vpp = val*sqrt(2);
                
                % next, determine the required range
                if Vpp <= 10e-3         % use 10 mV range
                    req_range = 10e-3;
                elseif Vpp <= 100e-3	% use 100 mV range
                    req_range = 100e-3;
                elseif Vpp <= 1         % use 1 V range
                    req_range = 1;
                else                    % use 10 V range
                    req_range = 10;
                end

                % set voltage based on computed fraction of range
                vpp = Vpp/req_range;
                if req_range > out_range % set voltage fraction first and THEN change to higher range
                    ziDAQ('setDouble', '/dev1012/sigouts/0/amplitudes/0', vpp);
                    ziDAQ('setDouble', '/dev1012/sigouts/0/range', req_range);  % avoids jumping to a larger intermediate voltage than intended
                else % set range first and THEN change voltage
                    ziDAQ('setDouble', '/dev1012/sigouts/0/range', req_range);  % can safely adjust range first
                    ziDAQ('setDouble', '/dev1012/sigouts/0/amplitudes/0', vpp); % in case vpp_new > vpp_old
                end                
        end
        
    % Amplitudes on (1) or off (0)
    case 14 % Output 1, amp 1
        switch ico(3)
            case 0
                val = ziDAQ('getInt', '/dev1012/sigouts/0/enables/0');
            case 1
                ziDAQ('setInt', '/dev1012/sigouts/0/enables/0', val);
        end 
    case 15 % Output on (1) or off (0)
        switch ico(3)
            case 0
                val = ziDAQ('getInt', '/dev1012/sigouts/0/on');
            case 1
                ziDAQ('setInt', '/dev1012/sigouts/0/on', val);
        end
     case 16 % Range (0.01, 0.1, 1, or 10)
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/sigouts/0/range');
            case 1
                ziDAQ('setDouble', '/dev1012/sigouts/0/range', val);
        end
        
    % Output 2
    % Amplitude values
    case 17 % Output 2, amp 2
        % first get the range
        out_range = ziDAQ('getDouble', '/dev1012/sigouts/1/range');
        switch ico(3)
            case 0
                % get the voltage fraction and multiply by range
                vmult = ziDAQ('getDouble', '/dev1012/sigouts/1/amplitudes/1'); % fraction of range, Vpp
                val = vmult*out_range/sqrt(2); % this is the returned output value as Vrms
            case 1
                % converted from Vrms to Vpp
                Vpp = val*sqrt(2);
                
                % next, determine the required range
                if Vpp <= 10e-3         % use 10 mV range
                    req_range = 10e-3;
                elseif Vpp <= 100e-3	% use 100 mV range
                    req_range = 100e-3;
                elseif Vpp <= 1         % use 1 V range
                    req_range = 1;
                else                    % use 10 V range
                    req_range = 10;
                end

                % set voltage based on computed fraction of range
                vpp = Vpp/req_range;
                if req_range > out_range % set voltage fraction first and THEN change to higher range
                    ziDAQ('setDouble', '/dev1012/sigouts/1/amplitudes/1', vpp);
                    ziDAQ('setDouble', '/dev1012/sigouts/1/range', req_range);  % avoids jumping to a larger intermediate voltage than intended
                else % set range first and THEN change voltage
                    ziDAQ('setDouble', '/dev1012/sigouts/1/range', req_range);  % can safely adjust range first
                    ziDAQ('setDouble', '/dev1012/sigouts/1/amplitudes/1', vpp); % in case vpp_new > vpp_old
                end                
        end
        
    % Amplitudes on (1) or off (0)
    case 18 % Output 2, amp 2
        switch ico(3)
            case 0
                val = ziDAQ('getInt', '/dev1012/sigouts/1/enables/1');
            case 1
                ziDAQ('setInt', '/dev1012/sigouts/1/enables/1', val);
        end
        
    case 19 % Output on (1) or off (0)
        switch ico(3)
            case 0
                val = ziDAQ('getInt', '/dev1012/sigouts/1/on');
            case 1
                ziDAQ('setInt', '/dev1012/sigouts/1/on', val);
        end
    case 20 % Range (0.01, 0.1, 1, or 10)
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/sigouts/1/range');
            case 1
        ziDAQ('setDouble', '/dev1012/sigouts/1/range', val);
        end
    
    otherwise
        error('requested channel not supported');
end
end