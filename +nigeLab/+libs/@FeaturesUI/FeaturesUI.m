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
      
      CurClass = 1;
      
      Figure
      Features3D
      FeatX
      FeatY
      Features2D
      ClusterQuality
      Silhouette
      QualityIndx
      SilDist =         {'Euclidean',...
                         'sqEuclidean',...
                         'cityblock',...
                         'cosine',...
                         'correlation',...
                         'Hamming',...
                         'Jaccard'};
      SilScores                                  % Silhuette scores; nMethods x NCLUS_MAX (9, maximum number of clusters)
      QualityScores                              % A matrix nClusters by nQuality
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
      rotateImg
      rotateButton
      
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
         obj.PlotQuality;
      end
      
      PlotFeatures(obj)
      ResetFeatureAxes(obj);
      SetCurrentCluster(obj,~,evt);
      SetClusterVisibility(obj,~,evt);
      PlotQuality(obj);
      UpdateSil(obj)
      
      function ReopenWindow(obj)
         if ~isvalid(obj.Figure)
            obj.Init(obj.Parent);
            obj.PlotFeatures();
            obj.PlotQuality();
         end
      end
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
            'Color','k',...
            'SizeChangedFcn',@obj.ChangeSize);          
         
         featureComboSelectorPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor','k',...
            'ForegroundColor','k', ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.01 0.85 0.1 0.1]);
         
         featureDisplayPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor','k',...
            'ForegroundColor','k', ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.12 0.4 0.85 0.55]);
         
         QualityIndexes = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor','k',...
            'ForegroundColor','k', ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.01 0.05 0.2 0.3]);
         
          QualityPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor','k',...
            'ForegroundColor','k', ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.12 0.01 0.85 0.38]);
         
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
         
%          obj.rotateImg = sprintf('<html><img style=''height: 100%%; width: 100%%; object-fit: contain'' src="file:/%s">',fullfile(fileparts(mfilename('fullpath')),'private','rotate.png'));        
         obj.rotateImg = imread(fullfile(fileparts(mfilename('fullpath')),'private','rotate.png'));
        
         obj.rotateButton = uicontrol(featureDisplayPanel,...
            'Style','pushbutton',...
            'Units','Normalized',...
            'Position',[0.6 0 0.04 0.07],...
            'Callback',@obj.RotateBtnPress,...
            'BackgroundColor',[1 1 1]);
         sz = getpixelposition(obj.rotateButton);
         img = imresize(obj.rotateImg,sz(4:-1:3)-5);
         set(obj.rotateButton,'CData',img);
         
         vals=unique(sortObj.UI.feat.combo(:,1));
         str = sortObj.UI.feat.name(unique(sortObj.UI.feat.combo(:,1)));
         obj.FeatX = uicontrol(featureComboSelectorPanel,...
            'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[0.05  0.55  0.9 0.45],...
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
            'Position',[0.05  0.05  0.9 0.45],...
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
            'ButtonDownFcn',@obj.ButtonDownFcnSelect2D);
         
         
         rgb2Hex = ( @(rgbColour) reshape( dec2hex( rgbColour, 2 )',1, 6));
         post = '</FONT></HTML>';
         listboxStr = cell(numel( obj.SilDist ),1);
         active = false(1,numel(listboxStr));
         for i = 1:numel( listboxStr )
            if i==1
               pre = sprintf('<HTML><FONT color="%s">',rgb2Hex([0, 0, 0])); % black
               active(1)=true;
            else
               pre = sprintf('<HTML><FONT color="%s">',rgb2Hex([56, 62, 66])); % gray
            end
            listboxStr{i} = sprintf('%s%s%s',pre,obj.SilDist{i},post);
         end
         
         obj.QualityIndx = uicontrol(QualityIndexes,...
            'Style','list',...
            'Units','Normalized',...
            'Position',[0.05  0.05  0.9 0.9],...
            'Tag','Dim2',...
            'UserData',{obj.SilDist, active},...
            'String',listboxStr);
         
         obj.QualityIndx.ButtonDownFcn = {@obj.ListClick};
         obj.QualityIndx.Callback = {@obj.ListClick};
         
         obj.SilScores = zeros(numel(obj.SilDist),obj.NCLUS_MAX);
         obj.Silhouette = axes(QualityPanel,...
            'Color','k', ...
            'FontSmoothing','off',...
            'XColor','w',...
            'YColor','w',...
            'ZColor','w',...
            'Units','Normalized',...
            'nextplot','add',...
            'Position',[0.1 0.1 0.96 0.8]);
         
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
      
      function ButtonDownFcnSelect2D(obj,src,~)
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
      
      function RotateBtnPress(~,src,~)         
            ax = src.Parent.Children(3);         
            rotate3d(ax);
         
      end
      
      function ListClick(obj,src,~)
         f=src.Parent.Parent;
%          pause(0.2);
         
         switch get(f,'SelectionType')
            case 'normal'
               return;
            case 'alt'
               return;
            case 'open'
               if sum(src.UserData{2})==1 && src.UserData{2}(src.Value)
                  return;
               end
               src.UserData{2}(src.Value) = ~src.UserData{2}(src.Value);
               rgb2Hex = ( @(rgbColour) reshape( dec2hex( rgbColour, 2 )',1, 6));
               if src.UserData{2}(src.Value), col = [0 0 0];else, col = [56, 62, 66];end
               pre = sprintf('<HTML><FONT color="%s">',rgb2Hex(col)); % black
               post = '</FONT></HTML>';
               str = src.String{src.Value}(numel(pre)+1:end-numel(post));
               src.String{src.Value} = sprintf('%s%s%s',pre,str,post);               
         end
         obj.PlotQuality();
      end
      
      function ChangeSize(obj,src,~)
         if ~isempty(obj.rotateButton) && isvalid(obj.rotateButton)
            sz = getpixelposition(obj.rotateButton);
            img = imresize(obj.rotateImg,sz(4:-1:3)-5);
            set(obj.rotateButton,'CData',img);
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
         
         snipped_region = drawfreehand(ax,'Smoothing',5);
         pos = snipped_region.Position;
         delete(snipped_region);
         if isempty(pos), return; end
         cx = pos(:,1);
         cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = nigeLab.utils.InPolygon.InPolygon(obj.sdMesh.X,obj.sdMesh.Y,cx,cy);
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
         
         evtData = nigeLab.evt.assignmentEventData(iMove,obj.CurClass);
         notify(obj,'ClassAssigned',evtData);
         set(obj.Figure,'Pointer','arrow');
      end
      
      
   end
end