function [val, rate] = smcSR860(ic, val, rate, ctrl)
% [val, rate] = smcSR860(ic, val, rate, ctrl)
% ctrl: sync (each sample triggered)
%       trig external trigger starts acq.
% 1: X, 2: Y, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 7:10: AUX input 1-4, 11:14: Aux output 1:4
% 15,16: stored data, length determined by datadim
% 17: sensitivity
% 18: time constant
% 19: sync filter on/off
% (added by Sergio) 20: "snap" get X, Y simultaneously, returns 'X, Y'

global smdata;

cmds = {'OUTP 0', 'OUTP 1', 'OUTP 2', 'OUTP 3', 'FREQ', 'SLVL', ...
    'OAUX 1', 'OAUX 2', 'OAUX 3', 'OAUX 4', 'AUXV 1', 'AUXV 2', 'AUXV 3', 'AUXV 4' ...
    ,'','','SCAL', 'OFLT', 'SYNC', 'SNAP 0,1'};

switch ic(2) % Channel
    case {15, 16} % stored data, length determined by datadim
        switch ic(3)
            case 0  % get              
                npts = smdata.inst(ic(1)).datadim(ic(2), 1);
                while 1
                    navail = query(smdata.inst(ic(1)).data.inst, 'SPTS?', '%s\n', '%d');
                    if navail >= npts + smdata.inst(ic(1)).data.currsamp;
                        break;
                    else
                        pause(0.8 * (npts + smdata.inst(ic(1)).data.currsamp - navail) ...
                            * smdata.inst(ic(1)).data.sampint);
                    end
                end
                
                fprintf(smdata.inst(ic(1)).data.inst, 'TRCB? %d, %d, %d', ...
                    [ic(2)-14, smdata.inst(ic(1)).data.currsamp+[0, npts]]);
                val = fread(smdata.inst(ic(1)).data.inst, npts, 'single');
                smdata.inst(ic(1)).data.currsamp =  smdata.inst(ic(1)).data.currsamp + npts;
                
            case 3
                fprintf(smdata.inst(ic(1)).data.inst, 'STRT');

            case 4
                fprintf(smdata.inst(ic(1)).data.inst, 'REST');
                smdata.inst(ic(1)).data.currsamp = 0;
                pause(.1); %needed to give instrument time before next trigger.
                % anything much shorter leads to delays.
                
            case 5
                if nargin > 4 && strfind(ctrl, 'sync')
                    n = 14;
                else
                    n = round(log2(rate)) + 4;
                    rate = 2^-(4-n);
                    % allow ext trig?
                    if n < 0 || n > 13
                        error('Samplerate not supported by SR860');
                    end
                end
                %if strfind(ctrl, 'trig')
                fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 1; TSTR 1; SRAT %i', n);
                %else
                %    fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 1; TSTR 0; SRAT %i', n);
                %end
                pause(.1);
                smdata.inst(ic(1)).data.currsamp = 0;

                smdata.inst(ic(1)).data.sampint = 1/rate;
                smdata.inst(ic(1)).datadim(15:16, 1) = val;

            otherwise
                error('Operation not supported');
                
        end
        
    otherwise
        switch ic(3) % action
            case 1 % set
                if ic(2)==17
                    val = SR860sensindex(val);
                elseif ic(2)==18
                    val = SR860tauindex(val);
                end
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
            case 0 % get
                % SNAP does not work using below code due to format of SNAP
                % output, which is comma-delimited string, not '%s\n %f'
                val = query(smdata.inst(ic(1)).data.inst, sprintf('%s? %s',...
                    cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), '%s\n', '%f');
                if ic(2)==17
                    val = SR860sensvalue(val);
                elseif ic(2)==18
                    val = SR860tauvalue(val);
                end

            otherwise
                error('Operation not supported');
        end
end

function val = SR860sensvalue(sensindex)
% converts an index to the corresponding sensitivity value for the SR860
% lockin.
x = [5e-9 2e-9 1e-9];
sensvals = [1e0 1e8*x 1e7*x 1e6*x 1e5*x 1e4*x 1e3*x 1e2*x 1e1*x x];
val = sensvals(sensindex+1);

function sensindex = SR860sensindex(sensval)
% converts a sensitivity to a corresponding index that can be sent to the
% SR860 lockin.  rounds up (sens = 240 will become 500)
x = [5e-9 2e-9 1e-9];
sensvals = [1e0 1e8*x 1e7*x 1e6*x 1e5*x 1e4*x 1e3*x 1e2*x 1e1*x x];
[~, sensvalsindex] = min(abs(sensvals - sensval)); % this is much better; handles floating-point errors
sensindex = sensvalsindex - 1;

function val = SR860tauvalue(tauindex)
% converts an index to the corresponding sensitivity value for the SR860
% lockin.
x = [1e-6 3e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x 1e10*x];
val = tauvals(tauindex+1);

function tauindex = SR860tauindex(tauval)
% converts a time constant to a corresponding index that can be sent to the
% SR860 lockin.  rounds up (tau = 240 will become 300)
x = [1e-6 3e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x 1e10*x];
% tauindex = find(tauvals >= tauval,1)-1;
[~, tauvalsindex] = min(abs(tauvals - tauval)); % this is much better; handles floating-point errors
tauindex = tauvalsindex - 1;
        
