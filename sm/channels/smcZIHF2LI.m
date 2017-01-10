function val = smcZIHF2LI(ico, val, ~)
% Driver for Zurich Intruments HF2LI lock-in amplifier
% This is the abridged version. The full version is
% \Goman Work\smcZIHF2LI.m

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
    case 4 % Phase (degrees)
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
        data = ziDAQ('getSample', '/dev1012/demods/0/sample/');
        %pause(0.1);
        Rlist = zeros([1 50]);
        for i = 1:50
            data = ziDAQ('getSample', '/dev1012/demods/0/sample/');
            % The measured voltage is 1/1.005 times the output Vrms
            % That is, it's 1 / (1.005 * sqrt(2)) times the output Vpp
            % So the output is really 1.005 * sqrt(2) * the measured input
            Rlist(1, i) = 1.005 * sqrt(2) * sqrt((data.x)^2 + (data.y)^2);
        end
        val = mean(Rlist);
        
    % Demod 2
    case 9 % Phase (degrees)
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
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/sigouts/0/amplitudes/0');
            case 1
                ziDAQ('setDouble', '/dev1012/sigouts/0/amplitudes/0', val);
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
        switch ico(3)
            case 0
                val = ziDAQ('getDouble', '/dev1012/sigouts/1/amplitudes/1');
            case 1
                ziDAQ('setDouble', '/dev1012/sigouts/1/amplitudes/1', val);
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
    case 21 % Balance the bridge
        switch ico(3)
            case 0
                val = 0;
            case 1
                capdata = struct('C', 0, 'Vc', 0.01, 'dVc', 0.99, ...
                    'Vr', 0.01, 'dVr', 0.99, 'Vd', 0.1, ...
                    'Kr1', 0, 'Kc1', 0, 'Kr2', 0, 'Kc2', 0, 'Vc0', 0);
                
                smset('Output 2 amp 2', capdata.Vd);
                
                % Measure input at different outputs
                [L11, L21] = measureXYsm(capdata.Vc, capdata.Vr);
                [L12, L22] = measureXYsm(capdata.Vc, capdata.Vr + capdata.dVr);
                [L13, L23] = measureXYsm(capdata.Vc + capdata.dVc, capdata.Vr);
                
                % The algorithmic part
                capdata.Kr1 = (L12 - L11) / capdata.dVr;
                capdata.Kc1 = (L13 - L11) / capdata.dVc;
                capdata.Kr2 = (L22 - L21) / capdata.dVr;
                capdata.Kc2 = (L23 - L21) / capdata.dVc;
                P = (1 - (capdata.Kc1 * capdata.Kr2) / (capdata.Kr1 * capdata.Kc2))^(-1);
                capdata.Vr0 = capdata.Vr + (P / capdata.Kr1) * ...
                    ((capdata.Kc1 / capdata.Kc2) * L21 - L11);
                capdata.Vc0 = capdata.Vc + (P / capdata.Kc2) * ...
                    ((capdata.Kr2 / capdata.Kr1) * L11 - L21);
                 capdata.C = abs(capdata.Vc0) / capdata.Vd;
                
                R = sqrt(capdata.Vc0^2 + capdata.Vr0^2);
                phase = 180 - atand(capdata.Vr0 / capdata.Vc0);
                smset('Output 1 amp 1', R);
                smset('Demod 1 phase', phase);
        end
    case 22 % Get capacitance
        switch ico(3)
            case 0
                data = ziDAQ('getSample', '/dev1012/demods/1/sample/');
                L1prime = data.x;
                L2prime = data.y;
%                 Vr0prime = Vr0 + (capdata.Kc2 * L1prime - ...
%                     capdata.Kc1 * L2prime) / (capdata.Kc1 * ...
%                     capdata.Kr2 - capdata.Kr1 * capdata.Kc2);
                Vc0prime = capdata.Vc0 + (capdata.Kr1 * L2prime - ...
                    capdata.Kr2 * L1prime) / (capdata.Kc1 * ...
                    capdata.Kr2 - capdata.Kr1 * capdata.Kc2);
                Cprime = abs(Vc0prime) / capdata.Vd;
                val = Cprime - capdata.C; % delta-C
        end
    otherwise
        error('Channels are numbered 1-21.');
end
end