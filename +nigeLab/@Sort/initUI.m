function flag = initUI(sortObj)
%% INITUI  Initialize graphics handles for Spike Sorting UI.
%
%  flag = INITUI(sortObj);
%
% By: Max Murphy  v3.0    01/07/2019 Port to object-oriented architecture.
%                 v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% DETERMINE AXES POSITIONS
flag = false;

if ~isfield(sortObj.pars,'AX_POS')
   if ~sortObj.setAxesPositions
      warning('Could not set axes positions correctly.');
      return;
   end
end      

%% SET UI CONTROLLER VARIABLES
sortObj.UI.ch = 1;
sortObj.UI.cl = 1;
sortObj.UI.zm = ones(sortObj.NCLUS_MAX,1) * 100;
sortObj.UI.spk_ylim = repmat(sortObj.SPK_YLIM,sortObj.NCLUS_MAX,1);

% Initialize "features" info
sortObj.UI.feat = 1;
sortObj.featcomb = combnk(1:size(sortObj.spk.feat{1},2),2);
sortObj.featname = cell(sortObj.nfeatmax,1);
for iN = 1:size(sortObj.featcomb,1)
   sortObj.featname{iN,1} = sprintf('x: %s-%d || y: %s-%d',sortObj.sc,...
      sortObj.featcomb(iN,1),sortObj.sc,sortObj.featcomb(iN,2));
end

% Initialize string for channels in nice format for popupmenu
sortObj.UI.channels = cell(sortObj.files.N,1);
for iCh = 1:sortObj.files.N
   sortObj.UI.channels{iCh} = strrep(sortObj.files.spk.ch{iCh},'_',' ');
end

flag = true;

end