function val = smcFunction(ic, val, rate)
% Implement an arbitrary function on any other channels
% For example, if you want to scan B-field by equal 1/B interval values, do
% the following:
% smdata.inst(ind).data.dependence={'B'};
% smdata.inst(ind).data.formula={@(x) 1/x};
% smaddchannel('Function', 'VAR1', 'rcpB', [-10,10,Inf,1]);
% Now if you do smset('rcpB',0.1), B will be set to 10 automatically (if
% not exceeding its limit values

global smdata
ind = ic(1);
ch = ic(2);

if ic(3)==0
    val = smdata.inst(ind).data.values(ch);
else
    % Set new values
    smdata.inst(ind).data.values(ch) = val;
    values = smdata.inst(ind).data.values;
    newval = zeros(1, length(smdata.inst(ind).data.dependences));
    for i=1:length(smdata.inst(ind).data.dependences)
        func=smdata.inst(ind).data.formula{i};
        switch(nargin(func))
            case 1
                newval(i) = func(values(1));
            case 2
                newval(i) = func(values(1),values(2));
            case 3
                newval(i) = func(values(1),values(2),values(3));
            case 4
                newval(i) = func(values(1),values(2),values(3),values(4));
            case 5
                newval(i) = func(values(1),values(2),values(3),values(4),values(5));
            case 6
                newval(i) = func(values(1),values(2),values(3),values(4),values(5),values(6));
            case 7
                newval(i) = func(values(1),values(2),values(3),values(4),values(5),values(6),values(7));
            otherwise
                newval(i) = func(values(1),values(2),values(3),values(4),values(5),values(6),values(7),values(8));
        end
        channel=smchanlookup(smdata.inst(ind).data.dependences{i});
        if newval(i)<smdata.channels(channel).rangeramp(1) || newval(i)>smdata.channels(channel).rangeramp(2)
            fprintf('Out of range\n');
            return;
        end
    end
    for i=1:length(smdata.inst(ind).data.dependences)
        fprintf('%s=%f, ', smdata.inst(ind).data.dependences{i}, newval(i));
    end
    fprintf('\n');
    smset(smdata.inst(ind).data.dependences, newval);
end
end

