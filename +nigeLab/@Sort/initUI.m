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

%% GET UNSUPERVISED CLASS ASSIGNMENTS & FEATURES
in = load('CRC_Tags.mat','TAGS');
pars.cl.tag.defs = in.TAGS;
in = load('CRC_Colors.mat','Colors');
pars.COLS = in.Colors;
in = load('CRC_Labels.mat','Labels');
pars.Labels = in.Labels;
pars.spk.feat = cell(pars.files.N,1);
pars.spk.include.in = cell(pars.files.N,1);
pars.spk.include.cur = cell(pars.files.N,1);
pars.spk.fs = nan(pars.files.N,1);
pars.spk.nfeat = nan(pars.files.N,1);
pars.spk.peak_train = cell(pars.files.N,1);
pars.cl.num.centroid=cell(pars.files.N,pars.NCLUS_MAX);
pars.cl.tag.name = cell(pars.files.N,1);
pars.cl.tag.val = cell(pars.files.N,1);
pars.cl.num.class.in=cell(pars.files.N,1);
pars.cl.num.class.cur = cell(pars.files.N,1);
pars.cl.sel.in = cell(pars.files.N,pars.NCLUS_MAX);
pars.cl.sel.base = cell(pars.files.N,pars.NCLUS_MAX);
pars.cl.sel.cur = cell(pars.files.N,pars.NCLUS_MAX);

pars.zmax = 0;
pars.nfeatmax = 0;
for iCh = 1:pars.files.N % get # clusters per channel   
   in_feat = load(pars.spk.fname{iCh},'features');
   pars.spk.feat{iCh,1} = in_feat.features; 
   
   pars.spk.include.in{iCh,1} = true(size(in_feat.features,1),1);
   pars.spk.include.cur{iCh,1} = true(size(in_feat.features,1),1);
   pars.spk.nfeat(iCh) = size(in_feat.features,2);
   
   pars.nfeatmax = max(pars.nfeatmax,pars.spk.nfeat(iCh));

   
   % Load classes. 1 == OUT; all others (up to NCLUS) are valid
   if sorted_flag
      in_class = load(pars.cl.fname{iCh},'class');
   else
      in_class = struct;
      in_class.class = ones(size(in_feat.features,1),1);
   end
   
   if min(in_class.class) < 1
      in_class.class = in_class.class + 1;
   end
   
   % Assign "other" clusters as OUT
   in_class.class(in_class.class > numel(pars.cl.tag.defs)) = 1;
   in_class.class(isnan(in_class.class)) = 1;
   
   % For "selected" make copy of original as well.
   pars.cl.num.class.in{iCh} = in_class.class;
   pars.cl.num.class.cur{iCh} = in_class.class;
   pars.cl.tag.name{iCh} = pars.cl.tag.defs(in_class.class);
   
   % Get each cluster centroid and membership
   val = [];
   for iN = 1:pars.NCLUS_MAX
      if isempty(pars.cl.tag.defs{iN})
         tags_val = 1;
      else
         tags_val = find(ismember(pars.Labels(2:end),...
            pars.cl.tag.defs(iN)),1,'first');
         if isempty(tags_val)
            tags_val = 1;
         else
            tags_val = tags_val + 1;
         end
      end
      val = [val, tags_val]; %#ok<AGROW>
      pars.cl.num.centroid{iCh,iN} = median(in_feat.features(...
         in_class.class==iN,:));
      pars.cl.sel.in{iCh,iN}=find(pars.cl.num.class.in{iCh}==iN);
      pars.cl.sel.base{iCh,iN}=find(pars.cl.num.class.in{iCh}==iN);
      pars.cl.sel.cur{iCh,iN}=find(pars.cl.num.class.in{iCh}==iN);
   end
   pars.cl.tag.val{iCh} = val;
   
end
clear features
fprintf(1,'complete.\n');

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

warning('on','MATLAB:load:variableNotFound');

end