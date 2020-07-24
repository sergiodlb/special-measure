function val = smcSR844(ic, val)
% driver for Stanford Research 844 high frequency lock-in amplifier
% written by Sergio de la Barrera circa Nov 11, 2019
%
% [val, rate] = smcSR844(ic, val)
%
% ------------ CHANNELS -------------
% 1: X, 2: Y, 3: R, 4: phase, 5: freq
% 6: sensitivity
% 7: time constant

global smdata;

cmds = {'OUTP 1', 'OUTP 2', 'OUTP 3', 'OUTP 5', 'FREQ', 'SENS', 'OFLT'};

switch ic(3) % action
    case 1 % set
        if ic(2) == 6
            val = SR830sensindex(val);
        elseif ic(2) == 7
            val = SR830tcindex(val);
        end
        fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
    case 0 % get
        val = query(smdata.inst(ic(1)).data.inst, sprintf('%s? %s',...
            cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), '%s\n', '%f');
        if ic(2) == 6
            val = SR830sensvalue(val);
        elseif ic(2) == 7
            val = SR830tcvalue(val);
        end

    otherwise
        error('Operation not supported');
end

function val = SR830sensvalue(sensindex)
% converts an index to the corresponding sensitivity value for the SR830
% lockin.
x = [100e-9 300e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1];
val = sensvals(sensindex+1);

function sensindex = SR830sensindex(sensval)
% converts a sensitivity to a corresponding index that can be sent to the
% SR830 lockin.  rounds up (sens = 240 will become 500)
x = [100e-9 300e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1];
sensindex = find(sensvals >= sensval,1)-1;

function val = SR830tcvalue(tcindex)
% converts an index to the corresponding sensitivity value for the SR830
% lockin.
x = [100e-6 300e-6];
tcvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x];
val = tcvals(tcindex+1);

function tcindex = SR830tcindex(tcval)
% converts a time constant to a corresponding index that can be sent to the
% SR830 lockin.  rounds up (tc = 240 will become 300)
x = [100e-6 300e-6];
tcvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x];
tcindex = find(tcvals >= tcval,1)-1;
        
