function val = smcAD9854arduino(ico, val, rate)
% driver for custom AC signal generator consisting of:
%   - two Analog Devices 9854 evaluation boards
%   - an Arduino Mini Pro which switches between boards and send SPI
%   - an optical USB isolator (doesn't affect driver)
%   - power supply, etc
% written by Sergio de la Barrera circa Aug 19, 2019
% see AD9850 manual for explanation of bit strings

global smdata;
vmax        = 0.120; %[V]
refclk      = 25; %[MHz]
sysclk      = 4*refclk*1e6; % max freq is sysclk/2
Nfreq       = 48; % phase accumulator resolution [bits]
Nphase      = 14; % phase offset register [bits]
Namp        = 12; % amplitude modulation register [bits]
endianness  = 'left-msb';
ac_box      = smdata.inst(ico(1)).data.inst;

if ico(3) == 1 % only SET operations are supported
    switch ico(2)
        case 1 % set frequency of both chips at once [Hz]
            FTW = de2bi(floor((val*2^Nfreq)/sysclk), Nfreq, endianness);
            fw1 = bi2de(FTW(1:8), endianness);
            fw2 = bi2de(FTW(9:16), endianness);
            fw3 = bi2de(FTW(17:24), endianness);
            fw4 = bi2de(FTW(25:32), endianness);
            fw5 = bi2de(FTW(33:40), endianness);
            fw6 = bi2de(FTW(41:48), endianness);
            fwrite(ac_box, [255, 254, 253, 12, 2, fw1, fw2, fw3, fw4, fw5, fw6]);
        case {2,3} % set phase shift [degrees]
            PTW = de2bi(floor(mod(val, 360)/360*2^Nphase), 16, endianness);
            pw1 = bi2de(PTW(1:8), endianness);
            pw2 = bi2de(PTW(9:16), endianness);
            if ico(2) == 2 % apply shift to chip 1
                fwrite(ac_box, [255, 254, 253, 1, 0, pw1, pw2, 0, 0, 0, 0]);
            else % apply shift to chip 2
                fwrite(ac_box, [255, 254, 253, 2, 0, pw1, pw2, 0, 0, 0, 0]);
            end
        case {4,5,6,7} % set output amplitude [V]
            if val > vmax
                val = vmax;
            elseif val < 0
                val = 0;
            end
            VTW = de2bi(floor(val/vmax*(2^Namp-1)), 16, endianness);
            vw1 = bi2de(VTW(1:8), endianness);
            vw2 = bi2de(VTW(9:16), endianness);
            switch ico(2)
                case 4; chip = 1; channel = 8;
                case 5; chip = 1; channel = 9; % DOESN'T WORK
                case 6; chip = 2; channel = 8;
                case 7; chip = 2; channel = 9; % DOESN'T WORK
            end
            fwrite(ac_box, [255, 254, 253, chip, channel, vw1, vw2, 0, 0, 0, 0])
        case 8 % master reset
            fwrite(ac_box, [255, 254, 253, 12, 55, 1, 2, 3, 4, 5, 6]);
        case 9 % control register, refclk
            fwrite(ac_box, [255, 254, 253, 12, 7, 16, 68, 0, 32, 0, 0]);
    otherwise
		error(['Channel ', num2str(ico(2)) ,' is not available']);
    end
else
    error('Operation not supported');
end
end