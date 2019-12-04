function UNCPath = getUNCPath(p)
% GETUNCPATH  Returns UNC-formatted path of the input path
%
% UNCPath = getUNCPath(p)
%
%  p  --  Char array of a mapped path of interest (e.g. 'C:\...');
%  UNCPath  --  Char array corresponding to "p" but with the universal
%                 naming convention (UNC) applied.
%
%  Makes use of 'GetFullPath' package provided by Jan Simon via the Matlab
%  File Exchange:
%
%  Jan (2019) 
%  GetFullPath 
%  (https://www.mathworks.com/matlabcentral/fileexchange/28249-getfullpath)
%  MATLAB Central File Exchange. Retrieved December 4, 2019. 

%% Check inputs
if isempty(p)
   UNCPath=p;
   return;
end

% Handle cell inputs
if iscell(p)
   UNCPath = cell(size(p));
   for i = 1:numel(p)
      UNCPath{i} = getUNCPath(p{i});
   end
   return;
end

%% Return the Full path using FEX code
p = nigeLab.utils.GetFullPath.GetFullPath(p);
p = strrep(p,'\',filesep);
pathParts = strsplit(p,filesep);
if isempty(pathParts{1})
   % This means it is already in UNC
   UNCPath = p;      
   return;
end

try
   rootPath = getUncPathFromMappedDrive(pathParts{1});
catch
   rootPath = [];
end

if isempty(rootPath)
   % Output depends on whether system is unix
   if isunix % linux or mac
      if (exist(p,'dir')==0) && (exist(p,'file')==0)
         rootPath = ['~/' pathParts{1}];
      else
         rootPath = ['/' pathParts{1}];
      end
   else % windows
      driveLetter = lower(pathParts{1}(1));
      rootPath = ['\\localhost\' driveLetter '$'];
   end
end

% Concatenate everything back together
pathParts{1} = rootPath;
UNCPath = fullfile(pathParts{:});

end

