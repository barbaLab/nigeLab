function [ nigelPath ] = getNigelPath(mode)

NIGELPATH_ = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Scripts_Circuits\Communal_Code\ePhys_packages';
if nargin <1
    mode = '';
end

%% Returns the path to nigelab.
nigelPath = mfilename('fullpath');
nigelPath = strsplit(nigelPath,filesep);
if isempty(nigelPath{1}),nigelPath{1}='\';end
nigelPath = strjoin(nigelPath(1:end-3),filesep);

if strcmp(mode,'UNC')
    if isunix
        nigelPath = NIGELPATH_;
    else
        nigelPath = nigeLab.utils.getUNCPath(nigelPath);
    end
end



end




%% This version here saves the path on file. Might be useful in the future (maybe)
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