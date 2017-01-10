function settings_path = ziGetDefaultSettingsPath()
% ZIGETDEFAULTSETTINGSPATH return the default path for LabOne settings files.
% 
% ZIGETDEFAULTSETTINGSPATH()
%
% Return a string containing the default path for LabOne settings files.
% 
% See also ZISAVESETTINGS, ZIGETDEFAULTSETTINGSPATH.

  timeout = 500;  % milliseconds
  h = ziDAQ('deviceSettings', timeout);
  settings_path = ziDAQ('get', h, 'devicesettings/path');
  settings_path = char(settings_path.path{1});
  ziDAQ('clear', h);

end
