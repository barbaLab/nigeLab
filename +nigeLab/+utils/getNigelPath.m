function nigelPath = getNigelPath(pathMode,nigelPath_)
%GETNIGELPATH  Returns the path to nigeLab
%
%  nigelPath = nigeLab.utils.getNigelPath();
%  --> On UNIX:      returns NIGELPATH_
%  --> On Windows:   parses nigelPath from mfilename and uses non-UNC path
%
%  nigelPath = nigeLab.utils.getNigelPath('UNC');
%  --> On UNIX:      returns NIGELPATH_
%  --> On Windows:   parses nigelPath from mfilename and uses UNC path
%
%  Optionally can add `nigelPath_` argument for Mac compatibility

%% Import getUNCPath
import nigeLab.utils.getUNCPath

%% Both unix and Windows Matlab allow '/' in file and path char arrays:
if nargin < 2
   nigelPath_ = '//kumc.edu/data/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/ePhys_packages';
end
if nargin < 1
   pathMode = '';
end

%% Returns the path to nigelab.
nigelPath = mfilename('fullpath');
nigelPath = strrep(nigelPath,'\','/');
nigelPath = strsplit(nigelPath,'/');
if isempty(nigelPath{1})
   nigelPath{1}='/';
end
% Base of repo is "3 levels" up (end-3):
nigelPath = fullfile(nigelPath{1:end-3});

switch upper(pathMode)
   case 'UNC'
      if isunix
         nigelPath = nigelPath_;
      else
         nigelPath = getUNCPath(nigelPath);
      end
      
   case ''
      return;
      
   otherwise
      error(['nigeLab:' mfilename ':UnexpectedString'],...
         'Unexpected case: %s (should be ''UNC'' or '''')\n',pathMode);
end

end

%% This version saves the path to a file. May be useful in the future
% function [ nigelPath ] = getNigelPath(mode,defNigelPath)
%
% NIGELPATH_ = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Scripts_Circuits\Communal_Code\ePhys_packages';
%
% NIGELPATHFILE = fullfile(nigeLab.defaults.Tempdir,'nigelPath');
% if nargin <1
%     mode = '';
%
%     if exist(NIGELPATHFILE,'file')
%         fid = fopen(NIGELPATHFILE);
%         defNigelPath = fread(fid,defNigelPath);
%         fclose(fid);
%     else
%         defNigelPath = getPathFromMfilename();
%     end
% elseif nargin < 2
%
%     if exist(NIGELPATHFILE,'file')
%         fid = fopen(NIGELPATHFILE);
%         defNigelPath = fread(fid,defNigelPath);
%         fclose(fid);
%     else
%         defNigelPath = getPathFromMfilename();
%     end
% end
%
% fid = fopen(NIGELPATHFILE);
% nigelPath = fwrite(fid,defNigelPath);
% fclose(fid);
%
% %% Returns the path to nigelab, corrected in case of UNC request
% if strcmp(mode,'UNC')
%     if isunix
%         nigelPath = NIGELPATH_;
%     else
%         nigelPath = nigeLab.utils.getUNCPath(nigelPath);
%     end
% end
%
% end
%
% function path = getPathFromMfilename()
%     nigelPath_ = mfilename('fullpath');
%     nigelPath_ = strsplit(nigelPath_,filesep);
%     if isempty(nigelPath_{1})% alread UNC
%         nigelPath_{1}='\';
%     end
%     path = strjoin(nigelPath_(1:end-3),filesep);
% end