%INSTALL Script to install nigeLab on first-time use.

if exist(fullfile(pwd,'installed.yaml'),'file')==0
   cd(fullfile(pwd,'+nigeLab','setup'));
   install_nigeLab;
   write_install_indicator(pwd,'flags');
   disp('nigeLab installed successfully!');
else
   disp('nigeLab has already been installed! Re-install skipped.');
end
   
function write_install_indicator(p,f)
%WRITE_INSTALL_INDICATOR Write indicator file to prevent multi-install
%
%  write_install_indicator(p,f);
%
% Inputs
%  p - Path of repository
%  f - Path of "flags" folder (should be folder in repository)
%
% Output
%  -- none --
%  Writes '.installed' file wherever `p` points, which can be checked on by
%  other things to make sure that `nigeLab` has actually been installed.

loc = fullfile(p,f);
if exist(loc,'dir')==0
   mkdir(loc);
end
fid = fopen(fullfile(loc,'installed.yaml'),'w');
fprintf(fid,[...
      'Installed: "%s" #Time when `install.m` completed.\n' ...
      'Repository_Folder: "%s" #Folder containing `+nigeLab`.\n' ...
   ],...
   string(datetime),p);
fclose(fid);
end