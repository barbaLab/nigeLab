classdef FeaturesUI < handle
   %%  FEATURESUI    Class for displaying features of a set of spikes
   %
   %  obj = FeaturesUI()
   %
   %  --------
   %   INPUTS
   %  --------
   %  --------
   %   OUTPUT
   %  --------
   %    obj       :     FeaturesUI object. Displays clusters in some features
   %                    space and other usefull elementsd as cluster quality
   %
   
   %%
   properties (Access = public)
      ChannelSelector
      SpikeImage
      
      CurClass
      
      Figure
      Features3D
      FeatX
      FeatY
      Features2D
      
      Data
      Parent
      
      
      Submit
      Confirm
      SpikePanel
      SpikePlot
      
      ClusterLabel
      Exclusions
      FeatureCombos
      Channels
      HasFocus
      ReCluster
      VisibleClusters
      TagLabels
      ZoomSlider
      Available = nan;
   end
   
   properties (Access = private)
      isVisible
      
      nFeat;
      
      nZtick = 6;
      zMax
      zTickLoc
      zTickLab
      
      sdMax       % Max. number of standard deviations to view
      sdMesh      % Struct with 'X' and 'Y' fields for meshgrid
      sdMeshEdges % Mesh edge values
      sdMeshPts   % Number of mesh points
      
      featInd = [1 2];
      
      SD_MAX_DEF = 3;
      SD_MESH_PTS_DEF = 31; % Square mesh, so same for each dimension
      FEAT_VIEW = [30 30];
      MINSPIKES = 30;
      NFEAT_PLOT_POINTS = 2000;
      NCLUS_MAX = 9;
      COLS = {[0,0,0]; ...
         [0.200000000000000,0.200000000000000,0.900000000000000];...
         [0.800000000000000,0.200000000000000,0.200000000000000];...
         [0.900000000000000,0.800000000000000,0.300000000000000];...
         [0.100000000000000,0.700000000000000,0.100000000000000];...
         [1,0,1];[0.930000000000000,0.690000000000000,0.130000000000000];...
         [0.300000000000000,0.950000000000000,0.950000000000000];...
         [0,0.450000000000000,0.750000000000000]};
      
   end
   
   events
      ClassAssigned
   end
   
   methods (Access = public)
      function obj = FeaturesUI(sortObj,varargin)
         %%
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(obj,varargin{iV});
            if isempty(p)
               continue
            end
            obj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% PARSE FIRST INPUT
         
         if isa(sortObj,'nigeLab.Sort')
            obj.Parent = sortObj;
            obj.ChannelSelector = sortObj.UI.ChannelSelector;
            obj.SpikeImage = sortObj.UI.SpikeImage;
            addlistener(obj.SpikeImage,'MainWindowClosed',@(~,~)obj.ExitFeatures);
            addlistener(obj.ChannelSelector,'NewChannel',@(~,~)obj.PlotFeatures);
            addlistener(obj.SpikeImage,'ClassAssigned',@obj.UpdateClasses);
            addlistener(obj.SpikeImage,'SpikeAxesSelected',@obj.SetCurrentCluster);
            addlistener(obj.SpikeImage,'VisionToggled',@obj.SetClusterVisibility);
            obj.Data = obj.Parent.spk;
         elseif isa(sortObj,'nigeLab.libs.ChannelUI')
            obj.Parent = [];
            obj.ChannelSelector = sortObj;
            % Needs 'SpikeImage'
            % Needs 'Data' and data struct name,value pair
         else
            obj.Parent = [];
            obj.ChannelSelector = struct('Channel',1);
            % Needs 'SpikeImage'
            % Needs 'Data' and data struct name,value pair
         end
         
         obj.Init(sortObj);
         obj.PlotFeatures;
      end
      
      PlotFeatures(obj)
      ResetFeatureAxes(obj);
      SetCurrentCluster(obj,~,evt);
      SetClusterVisibility(obj,~,evt);
      
   end
   
   methods (Access = private)
      
      CountExclusions(obj,ch);
      FeatPopCallback(obj,src,~);
      ExitFeatures(obj);
      
      function Init(obj,sortObj)
         
         %% init data
         obj.InitTimescale;
         obj.InitNewMeshMap;
         
         obj.VisibleClusters = cellfun(@(x) x.Value, ...
            sortObj.UI.SpikeImage.VisibleToggle);
         obj.nFeat = cellfun(@(x) size(x,2),obj.Data.feat);
         
         %% init graphical objects
         
         obj.Figure = figure('Name','Features', ... 'Units','Normalized',...
            'MenuBar','none',...
            'Units','Normalized',...
            'ToolBar','none',...
            'NumberTitle','off',...
            'Position',[0.050,0.075,0.4,0.450],...
            'Color','k'); 
         
         featureDisplayPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor','k',...
            'ForegroundColor','k', ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.01 0.17 0.98 0.82]);
         
         featureComboSelectorPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor','k',...
            'ForegroundColor','k', ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.01 0.01 0.4 0.15]);
         
         obj.Features3D = axes(featureDisplayPanel,...
            'Color','k', ...
            'XColor','w',...
            'YColor','w',...
            'ZColor','w',...
            'Units','Normalized',...
            'FontSmoothing','off',...
            'nextplot','add',...
            'Position',[0.6 0.125 0.4 0.8],...
            'View',[30 30]);
         
         vals=unique(sortObj.UI.feat.combo(:,1));
         str = sortObj.UI.feat.name(unique(sortObj.UI.feat.combo(:,1)));
         obj.FeatX = uicontrol(featureComboSelectorPanel,...
            'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[0.1  0.6  0.8 0.2],...
            'Tag','Dim1',...
            'UserData',vals,...
            'String',str,...
            'Value',find(vals==obj.featInd(1)));
         obj.FeatX.Callback = {@obj.FeatPopCallback};
         
         ind = sortObj.UI.feat.combo(:,1)==1;
         str = sortObj.UI.feat.name(unique(sortObj.UI.feat.combo(ind,2)));
         vals=unique(sortObj.UI.feat.combo(ind,2));
         
         obj.FeatY = uicontrol(featureComboSelectorPanel,...
            'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[0.1  0.2  0.8 0.2],...
            'Tag','Dim2',...
            'UserData',vals,...
            'String',str,...
            'Value',find(vals==obj.featInd(2)));
         obj.FeatY.Callback = {@obj.FeatPopCallback};
         
         obj.Features2D = axes(featureDisplayPanel,...
            'Color','k', ...
            'FontSmoothing','off',...
            'XColor','w',...
            'YColor','w',...
            'ZColor','w',...
            'Units','Normalized',...
            'nextplot','add',...
            'Position',[0.1 0.125 0.4 0.8],...
            'ButtonDownFcn',@obj.ButtonDownFcnSelect);
         
         obj.Exclusions = annotation(featureDisplayPanel,...
            'textbox','EdgeColor','none',... % Features label
            'Color','w',...
            'FontWeight','bold',...
            'FontName','Arial',...
            'FontSize',16,...
            'String','Features',...
            'HorizontalAlignment','Center',...
            'VerticalAlignment','bottom',...
            'Units','Normalized',...
            'Position',[0.1,0.9,0.8,0.1]);
         
         obj.InitEventListeners;
      end
      function InitNewMeshMap(obj,nSD,nMeshEdges)
         %% INITNEWMESHMAP    Initialize mesh for 2D featurespace
         
         if nargin < 3
            nSD = obj.SD_MAX_DEF;
         end
         
         if nargin < 2
            nMeshEdges = obj.SD_MESH_PTS_DEF;
         end
         
         obj.sdMax = nSD;
         obj.sdMeshPts = nMeshEdges;
         obj.sdMeshEdges = linspace(-nSD,nSD,nMeshEdges);
         [obj.sdMesh.X,obj.sdMesh.Y] = meshgrid(obj.sdMeshEdges,...
            obj.sdMeshEdges);
         
                  
      end
      
      function InitTimescale(obj)
         %% INITTIMESCALE  Initialize timescale for Z-axis on 3D scatter
         obj.zMax = obj.Data.tMax;
         obj.nZtick = min(obj.nZtick,round(obj.zMax));
         obj.zTickLoc = linspace(0,obj.zMax,obj.nZtick);
         obj.zTickLab = cell(numel(obj.zTickLoc),1);
         for iZ = 1:obj.nZtick
            obj.zTickLab{iZ,1} = sprintf('%3.1fm',...
               obj.zTickLoc(iZ));
         end
      end
      
      function InitEventListeners(obj)
         %% INITEVENTLISTENERS   Initalize event-listeners on other objects
         
         if isa(obj.SpikeImage,'nigeLab.libs.SpikeImage')
            obj.SpikeImage.NewAssignmentListener(obj,'ClassAssigned');
         end
         
      end
      
      
      function ButtonDownFcnSelect(obj,src,~)
         %% BUTTONDOWNFCNSELECT  Determine which callback to use for click
         
         % Make sure we're referring to the axes
         if isa(gco,'matlab.graphics.chart.primitive.Scatter')
            ax = src.Parent;
         else
            ax = src;
         end
         
         switch get(gcf,'SelectionType')
%             case 'normal' % Highlight clicked axes (L-Click)
%                obj.SetAxesWhereSpikesGo(ax);
            case 'alt'    % Do "cluster cutting" (R-Click)
               obj.GetSpikesToMove(ax);
            otherwise
               return;
         end
         
      end
      
      function GetSpikesToMove(obj,ax)
         %% GETSPIKESTOMOVE  Draw polygon, move spikes 
         if ~obj.isVisible % If it's not visible, can't do cutting here
            return;
         end
         
         % Get the potential features to move clusters
         curCh = obj.ChannelSelector.Channel;
         feat = obj.Data.feat{curCh}(:,obj.featInd);
         
         [~,~,~,binX,binY] = histcounts2(feat(:,1),feat(:,2),...
            obj.sdMeshEdges,obj.sdMeshEdges);
         
         % Draw polygon
         set(obj.Figure,'Pointer','circle');
         
         snipped_region = imfreehand(ax);
         pos = getPosition(snipped_region);
         delete(snipped_region);

         cx = pos(:,1);
         cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = InPolygon(obj.sdMesh.X,obj.sdMesh.Y,cx,cy);
         pts = IN | ON;
         set(obj.Figure,'Pointer','watch');
         drawnow;    

         % Match from Feature assignments     
         idxInside = find(pts);
         [row,col] = ind2sub(size(pts),idxInside);         
         
         iMove = [];
         for ii = 1:numel(row)
            moveIdx = find(binX == col(ii) & binY == row(ii));
            iMove = [iMove; moveIdx]; %#ok<AGROW>
         end
         iMove = unique(iMove);
         set(obj.Figure,'Pointer','arrow');
         
         evtData = nigeLab.evt.assignmentEventData(iMove,obj.CurClass);
         notify(obj,'ClassAssigned',evtData);

      end
      
      
   end
end