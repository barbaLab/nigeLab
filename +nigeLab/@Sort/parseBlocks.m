function flag = parseBlocks(sortObj,blockObj)
%% PARSEBLOCKS  Add blocks to Sort object
%
%  flag = PARSEBLOCKS(sortObj,blockObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%   blockObj   :     nigeLab.Block class object
%
%
% By: Max Murphy  v1.0    2019/01/08  Original version (R2017a)

%% INITIALIZE CHANNELS PROPERTY
flag = false;

sortObj.Channels.ID = blockObj(1).ChannelID;
sortObj.Channels.Mask = blockObj(1).Mask;
sortObj.Channels.Name = parseChannelName(sortObj);
sortObj.Channels.N = size(sortObj.Channels.ID,1);
sortObj.Channels.Idx = matchChannelID(blockObj,sortObj.Channels.ID);
sortObj.Channels.Sorted = false(sortObj.Channels.N,1);

%% FIND CORRESPONDING CHANNELS FOR REST OF BLOCK ELEMENTS
for ii = 1:numel(blockObj)
   if ~blockObj(ii).updateParams('Sort')
      warning('Parameters unset for %s. Skipping...',blockObj(ii).Name);
      continue;
   end
   
   % Check the format of files
   fprintf(1,'\nChecking SORTED for %s...000%%\n',blockObj(ii).Name);
   curCh = 0;
   nCh = numel(blockObj(ii).Mask);
   for iCh = blockObj(ii).Mask
      blockObj(ii).checkSpikeFile(blockObj(ii).Mask(iCh));
      curCh = curCh+1;
      pct = 100 * (curCh / nCh);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct));
   end
   
end
sortObj.Blocks = blockObj;
flag = true;

end

function set = intersectN(rows,varargin)
% Utility function to inteersect multiple arrays.
% skipping input validation cause I'm lazy.
if nargin-1 == 2
    if rows
        set = intersect(varargin{:},'rows','stable');
    else
        set = intersect(varargin{:},'stable');
    end
else
    set = intersectN(rows,varargin{1},intersectN(rows,varargin{2:end}));
end
end

function set = unionN(rows,varargin)
% Utility function to inteersect multiple arrays.
% skipping input validation cause I'm lazy.
if nargin-1 == 2
    if rows
        set = union(varargin{:},'rows','stable');
    else
        set = union(varargin{:},'stable');
    end
else
    set = unionN(rows,varargin{1},unionN(rows,varargin{2:end}));
end
end