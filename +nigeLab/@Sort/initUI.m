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

if ~isfield(sortObj.pars,'SpikePlotXYExtent')
   if ~sortObj.setAxesPositions
      warning('Could not set axes positions correctly.');
      return;
   end
end

%% SET UI CONTROLLER VARIABLES
sortObj.UI.ch = 1;
sortObj.UI.cl = 1;

% Initialize parameters for spike plots
sortObj.UI.plot.zoom = ones(sortObj.pars.SpikePlotN,1) * 100;
sortObj.UI.plot.ylim = repmat(sortObj.pars.SpikePlotYLim,...
   sortObj.pars.SpikePlotN,1);

% Initialize "features" info
sortObj.UI.feat.cur = 1;
sortObj.UI.feat.combo = combnk(1:size(sortObj.spk.feat{1},2),2);
sortObj.UI.feat.n = size(sortObj.UI.feat.combo,1);
sortObj.UI.feat.name = parseFeatNames(sortObj);
sortObj.UI.feat.label = parseFeatLabels(sortObj);

%% USE EXISTING CLASSES TO BUILD INTERFACE WINDOWS
sortObj.UI.ChannelSelector = nigeLab.libs.ChannelUI(sortObj);
sortObj.UI.SpikeImage = nigeLab.libs.SpikeImage(sortObj);
addlistener(sortObj.UI.ChannelSelector,'NewChannel',@sortObj.setChannel);
addlistener(sortObj.UI.SpikeImage,'MainWindowClosed',@(~,~)sortObj.exitScoring);

flag = true;

   function featName = parseFeatNames(sortObj)
      % Get feature names from parameters struct or generate them if they
      % do not already exist (from an old version of SD code)
      pars = sortObj.Blocks(1).SDPars;
      n = size(sortObj.spk.feat{1},2);
      
      if isfield(pars,'FEAT_NAMES')
         featName = pars.FEAT_NAMES;
      else
         featName = cell(1,n);
         for i = 1:n
            featName{i} = sprintf('feat-%02g',i);
         end
      end
   end

   function featLabel = parseFeatLabels(sortObj)
      % Get feature name combinations for all possible 2D scatter
      % combinations, which will be used on the "features" plot axis to
      % visualize separation of clusters.
      featLabel = cell(sortObj.UI.feat.n,1);
      for i = 1:sortObj.UI.feat.n
         featLabel{i} = sprintf('x: %s || y: %s',...
            sortObj.UI.feat.name{sortObj.UI.feat.combo(i,1)},...
            sortObj.UI.feat.name{sortObj.UI.feat.combo(i,2)});
         
      end
   end

end