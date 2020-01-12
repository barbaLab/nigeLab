classdef FeaturesUI < handle
   %FEATURESUI    Class for displaying features of a set of spikes
   %
   %  obj = FeaturesUI()
   %
   %  --------
   %   INPUTS
   %  --------
   %   sortObj    :     * nigeLab.Sort class object or
   %                    * nigeLab.libs.ChannelsUI class object
   %                    --> Requires 'Name', value pairs for:
   %                       + 'SpikeImage'
   %                       + 'Data'
   %
   %                    --> Can also not be specified, if given correct
   %                        'Name',value pairs
   %  
   %  --------
   %   OUTPUT
   %  --------
   %    obj       :     FeaturesUI object. Displays clusters in some 
   %                    features space and other useful elements, such as
   %                    cluster quality, etc
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (Access=public)
      ChannelSelector
      SpikeImage
      HighDimsUI
      HighDims
      
      Pars
      
      CurClass = 1;
      
      Figure
      Features3D
      FeatX
      FeatY
      
      HighDimsParams
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
      SilScores           % Silhouette scores; nMethods x NCLUS_MAX (9, maximum number of clusters)
      QualityScores       % A matrix nClusters by nQuality
      QualityBars
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
      
      projVecs
      COLS = {[0,0,0]; ...
         [0.200000000000000,0.200000000000000,0.900000000000000];...
         [0.800000000000000,0.200000000000000,0.200000000000000];...
         [0.900000000000000,0.800000000000000,0.300000000000000];...
         [0.100000000000000,0.700000000000000,0.100000000000000];...
         [1,0,1];[0.930000000000000,0.690000000000000,0.130000000000000];...
         [0.300000000000000,0.950000000000000,0.950000000000000];...
         [0,0.450000000000000,0.750000000000000]};
   end
   
   % PROTECTED
   properties (Access=protected)
      rotateImg
      rotateButton
      rsel
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
      
   end
   
   % TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      Listeners  event.listener
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      ClassAssigned
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded delete method
      function delete(obj)
         %DELETE  Overloaded delete to ensure child destruction
         %
         %  delete(obj);
         
         % Destroy any listener handles
         if ~isempty(obj.Listeners)
            for i = 1:numel(obj.Listeners)
               if isvalid(obj.Listeners(i))
                  delete(obj.Listeners(i));
               end
            end
         end
         
         % Destroy HighDimsUI "child"
         if ~isempty(obj.HighDimsUI)
            if isvalid(obj.HighDimsUI)
               delete(obj.HighDimsUI);
            end
         end
         
         % Destroy Figure
         if ~isempty(obj.Figure)
            if isvalid(obj.Figure)
               delete(obj.Figure);
            end
         end
         
      end
   end
   
   % PUBLIC
   methods (Access=public)
      function obj = FeaturesUI(SpikeImage,Data,Pars,ChannelSelector,varargin)
         %FEATURESUI  Constructor to build UI displaying derived features
         %
         %  obj = nigeLab.libs.FeaturesUI(SpikeImage,Data,Pars,ChannelSelector);
         %  --> Standard
         %
         %  obj = nigeLab.libs.FeaturesUI(sortObj); 
         %  --> Parses first 3 inputs from nigeLab.Sort object
         %
         %  obj = nigeLab.libs.FeaturesUI(SortUI);
         %  --> Parses first 3 inputs from nigeLab.libs.SortUI object
         %
         %  obj = nigeLab.libs.FeaturesUI(___);
         %  --> As long as 'SpikeImage', and 'Pars' can
         %      be parsed then this will work.
         
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
         
         % Behavior depends upon class of `sortObj` input
         if isa(SpikeImage,'nigeLab.Sort')
            error(['nigeLab:' mfilename ':BadClass'],...
               ['nigeLab.libs.FeaturesUI should be called by ' ...
                'nigeLab.libs.SortUI, not nigeLab.Sort']);
         elseif isa(SpikeImage,'nigeLab.libs.SortUI')
            sortUI = SpikeImage;
            obj.Parent = sortUI;
            obj.ChannelSelector = sortUI.ChannelSelector;
            obj.SpikeImage = sortUI.SpikeImage;
            obj.Pars = sortUI.feat;
            obj.Data = sortUI.Parent.spk;
         elseif isa(SpikeImage,'nigeLab.libs.SpikeImage')
            obj.Parent = [];
            obj.ChannelSelector = ChannelSelector;
            obj.SpikeImage = SpikeImage;
            obj.Data = Data;
            obj.Pars = Pars;
            
         else
            obj.Parent = [];
            obj.ChannelSelector = struct('Channel',1);
            obj.SpikeImage = SpikeImage;
            obj.Data = Data;
         end
         
         obj.HighDimsUI = nigeLab.libs.HighDimsUI(obj);
         
         obj.Listeners(1) = addlistener(obj.SpikeImage,'MainWindowClosed',@(~,~)obj.ExitFeatures);
         obj.Listeners(2) = addlistener(obj.SpikeImage,'ClassAssigned',@obj.UpdateClasses);
         obj.Listeners(3) = addlistener(obj.SpikeImage,'SpikeAxesSelected',@obj.SetCurrentCluster);
         obj.Listeners(4) = addlistener(obj.SpikeImage,'VisionToggled',@obj.SetClusterVisibility);
               
         if isa(obj.ChannelSelector,'nigeLab.libs.ChannelUI')
            obj.Listeners(5) = addlistener(obj.ChannelSelector,'NewChannel',@(~,~)obj.PlotQuality);
            obj.Listeners(6) = addlistener(obj.ChannelSelector,'NewChannel',@(~,~)obj.PlotFeatures);
         end
         
         obj.Init();
         obj.PlotFeatures();
         obj.PlotQuality();
      end
      
      PlotFeatures(obj)
      ResetFeatureAxes(obj);
      SetCurrentCluster(obj,~,evt);
      SetClusterVisibility(obj,~,evt);
      PlotQuality(obj);
      UpdateSil(obj)
      
      function ReopenWindow(obj)
         if ~isvalid(obj.Figure)
            obj.Init();
            obj.PlotFeatures();
            obj.PlotQuality();
         end
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      
      CountExclusions(obj,ch);
      FeatPopCallback(obj,src,~);
      ExitFeatures(obj);
      
      function Init(obj)
         
         % Initialize data
         obj.InitTimescale;
         obj.InitNewMeshMap;
         
         obj.VisibleClusters = cellfun(@(x) x.Value, ...
            obj.SpikeImage.VisibleToggle);
         obj.nFeat = cellfun(@(x) size(x,2),obj.Data.feat);
         obj.projVecs = zeros(2,obj.nFeat(obj.ChannelSelector.Channel));
 
         % Initialize graphical objects
         obj.Figure = figure('Name','Features', ... 'Units','Normalized',...
            'MenuBar','none',...
            'Units','Normalized',...
            'ToolBar','none',...
            'NumberTitle','off',...
            'Position',[0.050,0.075,0.4,0.450],...
            'Color',nigeLab.defaults.nigelColors('background'),...
            'SizeChangedFcn',@obj.ChangeSize,...
            'CloseRequestFcn',@(~,~)obj.ExitFeatures);          
         
         featureComboSelectorPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor',nigeLab.defaults.nigelColors('background'),...
            'ForegroundColor',nigeLab.defaults.nigelColors('background'), ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.01 0.65 0.1 0.3]);
         
         featureDisplayPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor',nigeLab.defaults.nigelColors('background'),...
            'ForegroundColor',nigeLab.defaults.nigelColors('background'), ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.12 0.4 0.85 0.55]);
         
         QualityIndexes = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor',nigeLab.defaults.nigelColors('background'),...
            'ForegroundColor',nigeLab.defaults.nigelColors('background'), ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.01 0.05 0.2 0.3]);
         
          QualityPanel = uipanel(obj.Figure, ...
            'Units', 'Normalized', ...
            'BackgroundColor',nigeLab.defaults.nigelColors('background'),...
            'ForegroundColor',nigeLab.defaults.nigelColors('background'), ...
            'FontSize', 16, ...
            'FontName','Arial',...
            'BorderType','none',...
            'Position',[0.12 0.01 0.85 0.38]);
         
         obj.Features3D = axes(featureDisplayPanel,...
            'Color',nigeLab.defaults.nigelColors('background'), ...
            'XColor',nigeLab.defaults.nigelColors('onsurface'),...
            'YColor',nigeLab.defaults.nigelColors('onsurface'),...
            'ZColor',nigeLab.defaults.nigelColors('onsurface'),...
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
         
         obj.projVecs(1,obj.featInd(1)) = 1;
         obj.projVecs(2,obj.featInd(2)) = 1;
         if ~isempty(obj.Pars)
            vals=unique(obj.Pars.combo(:,1));
            str = obj.Pars.name(unique(obj.Pars.combo(:,1)));
            obj.FeatX = uicontrol(featureComboSelectorPanel,...
               'Style','popupmenu',...
               'Units','Normalized',...
               'Position',[0.05  0.7  0.9 0.25],...
               'Tag','Dim1',...
               'UserData',vals,...
               'String',str,...
               'Value',find(vals==obj.featInd(1)));
            obj.FeatX.Callback = {@obj.FeatPopCallback};

            ind = obj.Pars.combo(:,1)==1;
            str = obj.Pars.name(unique(obj.Pars.combo(ind,2)));
            vals=unique(obj.Pars.combo(ind,2));

            obj.FeatY = uicontrol(featureComboSelectorPanel,...
               'Style','popupmenu',...
               'Units','Normalized',...
               'Position',[0.05  0.5  0.9 0.25],...
               'Tag','Dim2',...
               'UserData',vals,...
               'String',str,...
               'Value',find(vals==obj.featInd(2)));
            obj.FeatY.Callback = {@obj.FeatPopCallback};
         end

         
         obj.HighDims = uicontrol(featureComboSelectorPanel,...
            'Style','pushbutton',...
            'Units','Normalized',...
            'Position',[0.05  0.05  0.9 0.25],...
            'Tag','Dim2',...
            'String','HighDims');
        tmpfcn = @(a,b,x) x.PlotFig;
        obj.HighDims.Callback = {tmpfcn,obj.HighDimsUI};
         
         obj.Features2D = axes(featureDisplayPanel,...
            'Color',nigeLab.defaults.nigelColors('background'), ...
            'FontSmoothing','off',...
            'XColor',nigeLab.defaults.nigelColors('onsurface'),...
            'YColor',nigeLab.defaults.nigelColors('onsurface'),...
            'ZColor',nigeLab.defaults.nigelColors('onsurface'),...
            'Units','Normalized',...
            'nextplot','add',...
            'UserData',1,...
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
            'Color',nigeLab.defaults.nigelColors('background'), ...
            'FontSmoothing','off',...
            'XColor',nigeLab.defaults.nigelColors('onsurface'),...
            'YColor',nigeLab.defaults.nigelColors('onsurface'),...
            'ZColor',nigeLab.defaults.nigelColors('onsurface'),...
            'Units','Normalized',...
            'nextplot','add',...
            'Position',[0.1 0.1 0.96 0.8]);
         
         obj.Exclusions = annotation(featureDisplayPanel,...
            'textbox','EdgeColor','none',... % Features label
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
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
      
      % Initializes mesh map for the 2D featurespace
      function InitNewMeshMap(obj,nSD,nMeshEdges)
         %INITNEWMESHMAP    Initialize mesh for 2D featurespace
         %
         %  obj.InitNewMeshMap(nSD,nMeshEdges);
         %  nSD : # Standard Deviations for axes limits of 2D feature axes
         %  nMeshEdges : Number of edges on binning vector for features
         %               mesh, which allows selection of spikes by
         %               co-registration with features meeting <x,y> values
         %               for the selected features.
         
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
      
      % Initialize timescale for Z-axis on 3D scatter
      function InitTimescale(obj)
         %INITTIMESCALE  Initialize timescale for Z-axis on 3D scatter
         %
         %  obj.InitTimescale();
         
         obj.zMax = obj.Data.tMax;
         obj.nZtick = min(obj.nZtick,round(obj.zMax));
         obj.zTickLoc = linspace(0,obj.zMax,obj.nZtick);
         obj.zTickLab = cell(numel(obj.zTickLoc),1);
         for iZ = 1:obj.nZtick
            obj.zTickLab{iZ,1} = sprintf('%3.1fm',...
               obj.zTickLoc(iZ));
         end
      end
      
      % Initialize all event listeners
      function InitEventListeners(obj)
         %INITEVENTLISTENERS   Initalize event-listeners on other objects
         
         if isa(obj.SpikeImage,'nigeLab.libs.SpikeImage')
            obj.SpikeImage.NewAssignmentListener(obj,'ClassAssigned');
         end
      end
      
      % CALLBACK: On button down, based on type of click, invoke a method
      function ButtonDownFcnSelect2D(obj,src,~)
         %BUTTONDOWNFCNSELECT  Determine which callback to use for click
         
         % Make sure we're referring to the axes
         if isa(src,'matlab.graphics.primitive.Line')
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
      
      % CALLBACK: Rotate button click
      function RotateBtnPress(~,src,~)    
         %ROTATEBTNPRESS  Callback when "rotate button" is pressed
         %
         %  --> Rotates axes in 3D space
         
         ax = src.Parent.Children(3);         
         rotate3d(ax);
      end
      
      % CALLBACK: Double-click on Silhouette listbox
      function ListClick(obj,src,~)
         %LISTCLICK  Callback for double-click on Silhouette distances list
         %
         %  --> Adds or removes that particular distance metric to the
         %      Silhouette score calculation.
         
         f=src.Parent.Parent;
         
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
      
      % Change size of display
      function ChangeSize(obj,~,~)
         %CHANGESIZE  Callback for change of size of image when
         %            rotateButton is clicked
         %
         %  Changes size of obj.rotateImg
         
         if ~isempty(obj.rotateButton) && isvalid(obj.rotateButton)
            sz = getpixelposition(obj.rotateButton);
            img = imresize(obj.rotateImg,sz(4:-1:3)-5);
            set(obj.rotateButton,'CData',img);
         end
      end
      
      % Find subset of spikes to move based on convex-hull polygon
      function GetSpikesToMove(obj,ax)
         %GETSPIKESTOMOVE  Draw polygon, move spikes 
         if ~obj.isVisible % If it's not visible, can't do cutting here
            return;
         end
         
         % Get the potential features to move clusters
         curCh = obj.ChannelSelector.Channel;
         feat = obj.Data.feat{curCh};
         fi = ismember( obj.Data.class{curCh},find(obj.VisibleClusters));
         X = feat*obj.projVecs';
         [~,~,~,binX,binY] = histcounts2(X(:,1),X(:,2),...
            obj.sdMeshEdges,obj.sdMeshEdges);
         
         % Draw polygon
         set(obj.Figure,'Pointer','circle');
         
%          snipped_region = drawfreehand(ax,'Smoothing',5);
          axes(ax);
         [h,x,y]=nigeLab.utils.freehanddraw(ax);
%          pos = snipped_region.Position;
%          delete(snipped_region);
         delete(h)
         if isempty([x,y]), return; end
%          cx = pos(:,1);
%          cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = nigeLab.utils.InPolygon.InPolygon(obj.sdMesh.X,obj.sdMesh.Y,x,y);
         pts = IN | ON;
         set(obj.Figure,'Pointer','watch');
         drawnow;    

         % Match from Feature assignments     
         idxInside = find(pts);
         [row,col] = ind2sub(size(pts),idxInside);         
         
         iMove = [];
         for ii = 1:numel(row)
            moveIdx = find(binX == col(ii) & binY == row(ii) & fi);
            iMove = [iMove; moveIdx]; %#ok<AGROW>
         end
         iMove = unique(iMove);
         
         evtData = nigeLab.evt.assignClus(iMove,obj.CurClass);
         notify(obj,'ClassAssigned',evtData);
         set(obj.Figure,'Pointer','arrow');
      end
      
      PlotHighDims(obj,~,~) % Callback to plot features in "High-Dims UI"
      
   end
   % % % % % % % % % % END METHODS% % %
end