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

%% UI CONTROLLER VARIABLES
sortObj.UI.ch = 1;
sortObj.UI.cl = 1;
sortObj.UI.zm = ones(sortObj.NCLUS_MAX,1) * 100;
sortObj.UI.spk_ylim = repmat(sortObj.SPK_YLIM,sortObj.NCLUS_MAX,1);

% Initialize first set of spikes
% sortObj.plot = load(sortObj.spk.fname{sortObj.UI.ch},'spikes');
if ~getAllSpikeSnippets(sortObj)
   warning('Could not access spike waveforms.');
end
   
% Initialize cluster assignments
sortObj.cl.num.assign.cur = cell(sortObj.files.N,1);

% Initialize cluster radii and feature plots properties
sortObj.cl.num.rad = cell(sortObj.files.N,1);
fprintf(1,'->\tGetting spike times...');
for iCh = 1:sortObj.files.N
   in = load(sortObj.spk.fname{iCh},'pars','peak_train');
   sortObj.spk.fs(iCh) = in.pars.FS;
   sortObj.spk.peak_train{iCh,1} = in.peak_train;
   sortObj.zmax = max(sortObj.zmax,numel(in.peak_train)/in.pars.FS/60);
   
   sortObj.cl.num.assign.cur{iCh,1} = 1:sortObj.NCLUS_MAX;
   sortObj.cl.num.rad{iCh,1} = inf*ones(1,sortObj.NCLUS_MAX);
end
fprintf(1,'complete.\n');

% Initialize "features" info
sortObj.feat.this = 1;
sortObj.featcomb = flipud(...
   combnk(1:sortObj.spk.nfeat(sortObj.UI.ch),2));
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