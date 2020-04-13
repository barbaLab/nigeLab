function UNCPath = getUNCPath(varargin)
% GETUNCPATH  Returns UNC-formatted path of the input path
%
%  UNCPath = nigeLab.utils.getUNCPath(p)
%  UNCPath = nigeLab.utils.getUNCPath(p1,p2,...,pk)
%
%  -- Input --
%  p  ::  Char array of a mapped path of interest (e.g. 'C:\...');
%           --> Can also be provided as multiple inputs, with similar 
%               functionality to Matlab fullfile()
%
%  -- Output --
%  UNCPath  ::  Char array corresponding to "p" but with the universal
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
if nargin < 1
   p = [];
elseif nargin == 1
   p = fullfile(varargin{1});
else
   p = fullfile(varargin{:});
end

if isempty(p)
   UNCPath=p;
   return;
end

% Handle cell inputs
if iscell(p)
   UNCPath = cell(size(p));
   for i = 1:numel(p)
      UNCPath{i} = nigeLab.utils.getUNCPath(p{i});
   end
   return;
end

%% Return the Full path using FEX code
p = nigeLab.utils.GetFullPath.GetFullPath(p);
p = strrep(p,'\','/');
pathParts = strsplit(p,'/');
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

