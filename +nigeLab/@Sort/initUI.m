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
pars.UI.ch = 1;
pars.UI.cl = 1;
pars.UI.zm = ones(pars.NCLUS_MAX,1) * 100;
pars.UI.spk_ylim = repmat(pars.SPK_YLIM,pars.NCLUS_MAX,1);

% Initialize first set of spikes
pars.plot = load(pars.spk.fname{pars.UI.ch},'spikes');

% Initialize cluster assignments
pars.cl.num.assign.cur = cell(pars.files.N,1);

% Initialize cluster radii and feature plots properties
pars.cl.num.rad = cell(pars.files.N,1);
fprintf(1,'->\tGetting spike times...');
for iCh = 1:pars.files.N
   in = load(pars.spk.fname{iCh},'pars','peak_train');
   pars.spk.fs(iCh) = in.pars.FS;
   pars.spk.peak_train{iCh,1} = in.peak_train;
   pars.zmax = max(pars.zmax,numel(in.peak_train)/in.pars.FS/60);
   
   pars.cl.num.assign.cur{iCh,1} = 1:pars.NCLUS_MAX;
   pars.cl.num.rad{iCh,1} = inf*ones(1,pars.NCLUS_MAX);
end
fprintf(1,'complete.\n');

% Initialize "features" info
pars.feat.this = 1;
pars.featcomb = flipud(...
   combnk(1:pars.spk.nfeat(pars.UI.ch),2));
pars.featname = cell(pars.nfeatmax,1);
for iN = 1:size(pars.featcomb,1)
   pars.featname{iN,1} = sprintf('x: %s-%d || y: %s-%d',pars.sc,...
      pars.featcomb(iN,1),pars.sc,pars.featcomb(iN,2));
end

% Initialize string for channels in nice format for popupmenu
pars.UI.channels = cell(pars.files.N,1);
for iCh = 1:pars.files.N
   pars.UI.channels{iCh} = strrep(pars.files.spk.ch{iCh},'_',' ');
end


end