function val = smcIPS12010GPIB(ico, val, rate)
% driver for Oxford IPS120-10  magnet power supply
% written by Sergio de la Barrera, sdlb@mit.edu
% essentially a heavily modified version of smcIPS12010GPIB.m
% 	smcIPS12010([ico(1) ico(2) ico(3)], val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel
% 		ico(3): 0=read, 1=write
%       val   : usually the field value to set
%       rate  : usually the sweep rate in [T/min] (*note this is different from smcIPS12010GPIB.m, which used [T/s])
% ----------- CHANNELS and MODIFICATIONS ----------
% 2019-10-18: existing channel 1 --> FIELD
%             existing channel 2 --> SETP
%
% ----------- CHANGELOG for smcIPS12010GPIB.m ---------
% Driver for IPS12010 (GPIB version)
% settings for GPIB:
% usually board index is 0, address is 25
% can change Timeout to 1
% 6/27/2012: modified to automatically reset GPIB comm parameters with each
%           invocation.  Much safer.
%           
% 1/18/2010: modified to close and open magnet if behavior is sluggish
%           currently uses tic/toc instead of cputime because of bad
%           behavior of cputime on MX400 computer.
% 4/9/2010: added ramp support (set ramprate < 0, and use
%   scan.loops(1).trigfn.fn=@smatrigfn.  using GUI, setting
%   smscan.loops(1).trigfn.autoset=1 is enough.
% ------------------------------------------------------

global smdata;
tic;

% parameters
default_rate = 0.5; %[T/min]
max_rate     = 0.5; %[T/min]
B_tolerance  = 1e-4; %[T] the finite-precision tolerance of the magnet power supply

if ico(3) == 0 % user did not specify rate
    rate = default_rate;
end

% reset GPIB comm parameters
magnet = smdata.inst(ico(1)).data.inst;
set(magnet,'EOIMode','off');
set(magnet,'EOSCharCode','CR');
set(magnet,'EOSMode','read');

switch ico(2) % channel
    case 1 % [standard] Magnet going to set point, then holding at set point
        switch ico(3)
            case 1 % set persistent field
                % check ramp rate
                if abs(rate) > max_rate %[T/min]
                    error('Magnet ramp rate too high')
                end
                
                % get magnet status
                fprintf(magnet, '%s\r', 'X');
                state = fscanf(magnet);
                
                % put instrument in remote mode
                fprintf(magnet, '%s\r', 'C3'); fscanf(magnet);
                
                if rate < 0 % not sure what this is about (ramp mode?)
                    % set to hold
                    fprintf(magnet, '%s\r', 'A0'); fscanf(magnet);
                end
                
                % set the rate
                fprintf(magnet, '%s\r', ['T' num2str(abs(rate))]); fscanf(magnet);
                
                if state(9) == '2' || state(9) == '0' % magnet persistent at field or persistent at zero
                    % read current persistent field value
                    curr = NaN;
                    while isnan(curr)
                        fprintf(magnet, '%s\r', 'R18');
                        curr = fscanf(magnet, '%*c%f');
                    end
                    persistentsetpoint = curr;
                    
                    if abs(curr - val) > B_tolerance % only go through trouble if we're not at the target field
                        % match power supply to persistent field
                        % turn off switch heater to be safe
                        fprintf(magnet, '%s\r', 'H0'); fscanf(magnet);
                        pause_message('ensuring heater switch OFF', 3);

                        % make the persistent field value the setpoint
                        fprintf(magnet, '%s\r', ['J' num2str(persistentsetpoint)]); fscanf(magnet);

                        % go to setpoint
                        fprintf('ramping power supply to match persistent field\n')
                        fprintf(magnet, '%s\r', 'A1'); fscanf(magnet);

                        % wait until persistent field value is reached
                        fprintf(magnet, '%s\r', 'R7');
                        currstring = fscanf(magnet);
                        currentfield = str2double(currstring(2:end));
                        while abs(currentfield - persistentsetpoint) > B_tolerance
%                             pause_message('checking power supply current', 5);
                            pause(5);
                            fprintf(magnet, '%s\r', 'R7'); currstring = fscanf(magnet);
                            currentfield = str2double(currstring(2:end));
                        end
                        
                        % pause to stabilize
                        pause_message('pausing to stabilize', 10);

                        % switch on heater
                        fprintf(magnet, '%s\r', 'H1'); fscanf(magnet);
                        pause_message('turning heater switch ON', 15);
                        
                        % set the field target (ramps immediately)
                        fprintf('changing field set point\n')
                        fprintf(smdata.inst(ico(1)).data.inst, '%s\r', ['J' num2str(val)]);
                        fscanf(smdata.inst(ico(1)).data.inst);
                        
                        if rate > 0
                            % go to target field
                            fprintf(smdata.inst(ico(1)).data.inst, '%s\r', 'A1');
                            fscanf(smdata.inst(ico(1)).data.inst);

                            % wait until persistent field value is reached
                            ramp_time = abs(val-curr)/abs(rate)*60;
                            pause_message('ramping field', ramp_time);
                            
                            % check field
                            fprintf(magnet, '%s\r', 'R7'); currstring = fscanf(magnet);
                            currentfield = str2double(currstring(2:end));
                            while abs(currentfield - val) > B_tolerance
                                pause_message('checking field value', 10);
                                fprintf(magnet, '%s\r', 'R7'); currstring = fscanf(magnet);
                                currentfield = str2double(currstring(2:end));
                            end
                            fprintf('field at %.4g T\n', currentfield)

                            % pause to stabilize
                            pause_message('pausing to stabilize', 10);

                            % turn off switch heater
                            fprintf(magnet, '%s\r', 'H0'); fscanf(magnet);
                            pause_message('turning heater switch OFF', 15);

                            % set leads to zero
                            fprintf(magnet, '%s\r', 'A2'); fscanf(magnet);
                            pause_message('ramping power supply to zero', 10);
                            
                            % check
                            fprintf(magnet, '%s\r', 'R7');
                            currstring = fscanf(magnet);
                            currentfield = str2double(currstring(2:end));
                            while currentfield ~= 0
                                pause_message('checking power supply current', 3);
                                fprintf(magnet, '%s\r', 'R7'); currstring = fscanf(magnet);
                                currentfield = str2double(currstring(2:end));
                            end
                            
                            % hold
                            fprintf(magnet, '%s\r', 'A0'); fscanf(magnet);  % return to hold mode
                            fprintf('holding (done)\n')
                            val = 0;  
                        else
                            % what is this??
                            val = abs(val-curr)/abs(rate);
                        end
                    end
                        
                else % driven mode (heat switch already ON)
                    error('driven mode not tested')
                    
                    % read the current field value
                    curr = NaN;
                    while isnan(curr)
                        fprintf(magnet, '%s\r', 'R7');
                        curr = fscanf(magnet, '%*c%f');
                    end

                    % set the field target
                    fprintf('changing field set point\n');
                    fprintf(magnet, '%s\r', ['J' num2str(val)]);
                    fscanf(magnet);
                    
                    val = abs(val-curr)/abs(rate);
                    
                    if rate > 0
        
                        % go to target field
                        fprintf(magnet, '%s\r', 'A1');
                        fscanf(magnet);
                      
                        elapsedtime=toc;
                        if elapsedtime>2
                            fclose(magnet);
                            fopen(magnet);
                        end
                    end
                end
                
            case 0 % read the current field value
                 fprintf(magnet, '%s\r', 'X');
                 state = fscanf(magnet);
                 val = NaN;
                 while isnan(val)
                    if state(9) == '2'
                        fprintf(magnet, '%s\r', 'R18');
                    else
                        fprintf(magnet, '%s\r', 'R7');
                    end
                    val = fscanf(magnet, '%*c%f');
                 end
                 

                elapsedtime=toc;
                if elapsedtime>2
                    fclose(magnet);
                    fopen(magnet);
                    fprintf('timeout --> closed and re-opened communication with IPS120-10\n');
                end
                
            case 3 % trigger
                error('trigger mode not tested')
                
                % go to target field
                fprintf(magnet, '%s\r', 'A1'); fscanf(magnet);
                
            otherwise
                error('Operation not supported');
        end
        
    otherwise
        error('Channel not programmed');

end
end

function pause_message(message, seconds)
    % print a waiting message with countdown
    fprintf(message);
    fprintf(' (');
    remstrlen = 0;
    for t = 0:seconds-1
        remaining = seconds - t;
        remstring = sprintf('%g)', remaining);
        if remstrlen > 0
            fprintf(repmat('\b', 1, remstrlen));
        end
        remstrlen = length(remstring);
        fprintf(remstring);
        pause(1);
    end
    fprintf(repmat('\b', 1, remstrlen+2));
    fprintf('\n');
end

