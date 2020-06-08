classdef SpikeImage < handle
%SPIKEIMAGE Quickly aggregates spikes into one image object.
%
%  obj = SPIKEIMAGE(spikes,fs,peak_train,class)
%
%  --------
%   INPUTS
%  --------
%   spikes     :     N x K matrix of waveform snippets for each
%                    detected candidate spike. Contains N rows,
%                    each of which corresponds K samples of a
%                    given spike waveform.
%
%      fs      :     Sampling frequency (Hz) of spike waveforms.
%
%  peak_train  :     M x 1 sparse vector that contains the total
%                    number of samples in the record, with sample
%                    indexes at which there is a candidate spike
%                    having a value equivalent ot the spike
%                    peak-to-peak amplitude.
%
%    class     :     N x 1 vector containing class label
%                    assignments for each spike waveform.
%
%  --------
%   OUTPUT
%  --------
%    obj       :     SPIKEIMAGE object that compresses the spike
%                    waveforms into flattened image objects that
%                    allows them to be visualized more easily.

   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (Access=public)
      Spikes % Contains all info relating to spike waves and classes
      Figure = figure('Name','Spike Profiles',... % Container for graphics
                      'Units','Normalized',...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'NumberTitle','off',...
                      'Position',[0.050,0.075,0.800,0.850],...
                      'Color',nigeLab.defaults.nigelColors('background')); 
      Labels   % Labels above the subplots
      Images   % Figure subplots that contain flattened spike image
      VisibleToggle % checkbox for selecting visiblity in the feature panel
      Axes     % Axes containers for images
      Parent   % Only set if called by nigeLab.Sort class object
      PropLinker  
      
      PlotCB;
      NumClus_Max = 9;
      CMap;
      YLim = [-300 150];
      XPoints = 60;     % Number of points for X resolution
      YPoints = 101;    % Number of points for Y resolution
      T = 1.2;          % Approx. time (milliseconds) of waveform
      Defaults_File = 'SpikeImageDefaults.mat'; % Name of file with default
      PlotNames = cell(9,1);
      
      ProgCatPars = struct(...
         'pawsInterval',0.100,...
         'progPctThresh',2,...
         'nImg',11);
      
      ConfirmedChanges
      UnsavedChanges
      
      CurrKeyPress = {};
   end
   
   % TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      Listeners  event.listener  % Event listener handles
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      MainWindowClosed
      ClassAssigned
      SpikeAxesSelected
      ChannelConfirmed
      SaveData
      VisionToggled
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded `delete` method
      function delete(obj)
         %DELETE  Ensure child objects are destroyed
         %
         %  delete(obj);
         
         if ~isempty(obj.Listeners)
            for i = 1:numel(obj.Listeners)
               if isvalid(obj.Listeners(i))
                  delete(obj.Listeners(i));
               end
            end
         end
         
         if ~isempty(obj.Figure)
            if isvalid(obj.Figure)
               delete(obj.Figure);
            end
         end
      end
   end
   
   % PUBLIC
   methods (Access=public)
      function obj = SpikeImage(spikes,fs,class,varargin)
         %SPIKEIMAGE Quickly aggregates spikes into one image object.
         %
         %  obj = SPIKEIMAGE(nigeLab.sortObj)
         %  -------------------------------------------
         %  obj = SPIKEIMAGE(spikes,fs,peak_train,class)
         %
         %  --------
         %   INPUTS
         %  --------
         %   sortObj    :     nigeLab.sortObj class object.
         %
         %  --------------------------------------------
         %
         %   spikes     :     N x K matrix of waveform snippets for each
         %                    detected candidate spike. Contains N rows,
         %                    each of which corresponds K samples of a
         %                    given spike waveform.
         %
         %      fs      :     Sampling frequency (Hz) of spike waveforms.
         %
         %    class     :     N x 1 vector containing class label
         %                    assignments for each spike waveform.
         %
         %  varargin    :     (Optional) 'NAME', value input argument pairs
         %
         %  --------
         %   OUTPUT
         %  --------
         %    obj       :     SPIKEIMAGE object that compresses the spike
         %                    waveforms into flattened image objects that
         %                    allows them to be visualized more easily.
         %
         % By: Max Murphy  v1.0  08/25/2017  Original version (R2017a)
         %                 v1.1  06/13/2018  Added varargin and parsing so
         %                                   that SpikeImage can be
         %                                   modified to have an
         %                                   appropriate number of subplots
         %                                   depending on the number of
         %                                   unique clusters.
         
         % Parse <'Name',value> pairs
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
         
         % First input class affects behavior
         if isa(spikes,'nigeLab.Sort')
            error(['nigeLab:' mfilename ':BadClass'],...
               ['nigeLab.libs.SpikeImage should be called by ' ...
                'nigeLab.libs.SortUI, not nigeLab.Sort']);
         elseif isa(spikes,'nigeLab.libs.SortUI')
            sortUI = spikes;
            obj.Parent = sortUI.Parent;
            fs = obj.Parent.spk.fs;
            class = obj.Parent.spk.class;
            spikes = obj.Parent.spk.spikes;
         else
            obj.Parent = struct(...
               'spk',struct('fs',fs,'class',[],'spikes',[]),...
               'UI',struct('ch',1));
            obj.Parent.spk.class = {class};
            obj.Parent.spk.spikes = {spikes};
         end
         
         % Initialize object properties
         obj.Init(fs);
         obj.UpdateChannel;
      end

      function flag = checkForConfirmedChanges(obj,askUser)
          % CHECKFORConfirmedChanges cheacks if there are any unconfirmed changes.
          % also asks the suer if it's ok to proceed anyway.
          
          % returns true if we unconfirmed changes are present, therefore
          % actions should be taken.

% is the user is prompted and decides to proceed, this will return false as
% if there were no unconfirmed changes.
          flag = false;

          % Check if it's okay to lose changes if there are any
         if ~obj.ConfirmedChanges(obj.Parent.UI.ChannelSelector.Channel) && ...
             obj.UnsavedChanges(obj.Parent.UI.ChannelSelector.Channel)
             if askUser 
                 str = questdlg('Unconfirmed changes will be lost. Proceed anyways?',...
                     'Discard Sorting on this Channel?','Yes','No','Yes');
                 flag = strcmp(str,'No');
             else
                 flag = true;
             end
         end
      end
      
      function UpdateChannel(obj,~,~)
         %UPDATECHANNEL  Update the spike data structure to new channel
         
         % Interpolate spikes
         obj.Interpolate(obj.Parent.spk.spikes{obj.Parent.UI.ch});

         % Set spike classes
         obj.Assign(obj.Parent.spk.class{obj.Parent.UI.ch});
         
         % Flatten spike image
         obj.Flatten;
         
         % Construct figure
         obj.Build;        
   
      end
      
      function Refresh(obj)
         %REFRESH  Re-display all the spikes
         
         if isa(obj.Parent,'nigeLab.Sort')
            % Set spike classes
            evt = nigeLab.evt.assignClus(1:numel(obj.Spikes.Class),...
                obj.Parent.spk.class{obj.Parent.UI.ch},...
                obj.Spikes.Class);
            obj.UpdateClusterAssignments(nan,evt);
         end
      end
      
      % Add a listener for cluster assignments
      function NewAssignmentListener(obj,src,evt)
         %NEWASSIGNMENTLISTENER   Add a listener for cluster assignments
         if nargin < 3
            evt = 'ClassAssigned';
         end
         obj.Listeners = [obj.Listeners, ...
            addlistener(src,evt,@obj.UpdateClusterAssignments)];
      end
      
      % Overload `set` method
      function set(obj,NAME,value)
         %SET   Overloaded class method
         
         % Set 'numclus_max', 'ylim', or 'plotnames' properties and update.
         switch lower(NAME)
            case 'numclus_max'
               delete(obj.Figure.Axes);
               obj.NumClus_Max = value;
               obj.Build;
            case 'ylim'
               delete(obj.Figure.Axes);
               obj.YLim = value;
               obj.Spikes.Y = linspace(obj.YLim(1),...
                                       obj.YLim(2),...
                                       obj.YPoints-1);
               obj.Flatten;
               obj.Build;
            case 'plotnames'
               delete(obj.Figure.Axes);
               obj.PlotNames = value;
               obj.Flatten;
               obj.Build;
            case 'buttondownfcn'
               obj.PlotCB = value;
               obj.Refresh;
            otherwise
               error('%s is not a settable property of SpikeImage.',NAME);
         end
      end
      
      
      % Sets feature visibility for spikes of cluster index "clus"
      function SetVisibleFeatures(obj,clus,val)
         %SETVISIBLEFEATURES  Set visibility of scatter elements for spikes
         %  that belong to the cluster indexed by "clus"
         %
         %  obj.SetVisibleFeatures(clus,val);
         %
         %  e.g.
         %  >> obj.setVisibleFeatures(3,1); Makes scatter points for
         %                                  cluster "class" 3 visible
         
         if ~obj.checkFeaturesUI
            return;
         end
          
         if (val > 0)
            state = 'on';
         else
            state = 'off';
         end
         featureObj = obj.Parent.UI.FeaturesUI;
         ind2D=([featureObj.Features2D.Children.UserData] == clus);
         ind3D=([featureObj.Features3D.Children.UserData] == clus);
         
         % Update any potential listeners
         evt = nigeLab.evt.toggleClusterVisible(ind2D,ind3D,state,clus,val);
         notify(obj,'VisionToggled',evt);
      end
      
   end
   
   % PROTECTED
   methods (Access=protected)    
      % Check that FeaturesUI is valid
      function flag = checkFeaturesUI(obj)
         %CHECKFEATURESUI  Check to see if FeaturesUI is present
         flag = false;
         if ~isvalid(obj.Parent)
            return;
         end
         
         if ~isprop(obj.Parent.UI,'FeaturesUI')
            return;
         end
         
         if ~isvalid(obj.Parent.UI.FeaturesUI.Features2D)
            return;
         end
         flag = true;
      end
      
      % Initialize parameters
      function Init(obj,fs)
         %INIT  Initialize parameters
         %  
         %  obj.Init(fs);  
         %  fs: Sample rate
         
         % No changes have been made yet
         obj.ConfirmedChanges = false(1,numel(obj.Parent.UI.ChannelSelector.Menu.String));
         obj.UnsavedChanges = false(1,numel(obj.Parent.UI.ChannelSelector.Menu.String));
         
         % Add sampling frequency
         obj.Spikes.fs = fs;
         
         % Set Colormap for this image
         fname = fullfile(fileparts(mfilename('fullpath')),obj.Defaults_File);
         cm = load(fname,'ColorMap');
         obj.CMap = cm.ColorMap;
         obj.NumClus_Max = min(numel(obj.CMap),obj.NumClus_Max);   
         
         % Get X and Y vectors for image
         obj.Spikes.X = linspace(0,obj.T,obj.XPoints);      % Milliseconds
         obj.Spikes.Y = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints-1);
         
         obj.Spikes.CurClass = 1;
      end
      
      % Sets the names (titles) of spike plots
      function SetPlotNames(obj,plotNum)
         %SETPLOTNAMES   Set names (titles) of each plot
         %
         %  obj.SetPlotNames();
         %  --> Set names (titles) of all plots
         %
         %  obj.SetPlotNames(plotNum);
         %  --> Set names (titles) of plot indexed by plotNum
         
         if nargin < 2
            plotNum = 1:obj.NumClus_Max;
         else
            plotNum = reshape(plotNum,1,numel(plotNum));
         end
         
         for iPlot = plotNum
            if iPlot > 1
               obj.PlotNames{iPlot} = ...
                  sprintf('Cluster %d        N = %d',...
                  iPlot-1,sum(obj.Spikes.Class==iPlot));
            else
               obj.PlotNames{iPlot} = ...
                  sprintf('OUT        N = %d',...
                  sum(obj.Spikes.Class==iPlot));
            end
         end
      end
      
      % Interpolate and make waveforms smoother
      function Interpolate(obj,spikes)
         %INTERPOLATE    Interpolate spikes to make waveforms smoother
         
         x = [1, size(spikes,2)];
         xv = linspace(x(1),x(2),obj.XPoints);
         
         LoopFunction = @(xin) (nigeLab.utils.interp1qr((x(1):x(2))',spikes(xin,:)',xv'));
         
         % Make ProgressCircle object
         pcirc = nigeLab.libs.ProgressCircle(LoopFunction);
%          pCat = nigeLab.libs.ProgressCat(LoopFunction,obj.ProgCatPars);
%          obj.ProgCatPars.pawsInterval = ...
%             max(obj.ProgCatPars.pawsInterval*0.9,1e-6);
%          obj.ProgCatPars.progPctThresh = ...
%             min(obj.ProgCatPars.progPctThresh + 1, ...
%             floor(100/obj.ProgCatPars.nImg));
         
         % Run ProgressCircle Loop
         fprintf(1,'->\tInterpolating spikes...');
         obj.Spikes.Waves = pcirc.RunLoop(size(spikes,1),obj.XPoints);
%          obj.Spikes.Waves = pCat.RunLoop(size(spikes,1),obj.XPoints);
         fprintf(1,'complete.\n');

      end
      
      % Build graphics: (figure, if needed) and axes/images associated
      function Build(obj)
         %BUILD    Build the figure (if needed) and axes/images
         
         % Get plot names
         obj.SetPlotNames;
         
         % Make figure or update current figure with fast spike plots.
         if ~isvalid(obj.Figure)
            obj.Figure = figure('Name','SpikeImage',...
                      'Units','Normalized',...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'NumberTitle','off',...
                      'Position',[0.2 0.2 0.6 0.6],...
                      'Color',nigeLab.defaults.nigelColors('background'),...
                      'WindowKeyPressFcn',@obj.WindowKeyPress,...
                      'WindowScrollWheelFcn',@obj.WindowMouseWheel,...
                      'CloseRequestFcn',@obj.CloseSpikeImageFigure,...
                      'WindowKeyReleaseFcn',@obj.clearKurrKey);
         else
            set(obj.Figure,'CloseRequestFcn',@obj.CloseSpikeImageFigure);
            set(obj.Figure,'WindowScrollWheelFcn',@obj.WindowMouseWheel);
            set(obj.Figure,'WindowKeyPressFcn',@obj.WindowKeyPress);
            set(obj.Figure,'WindowKeyReleaseFcn',@obj.clearKurrKey);
         end
         % Set figure focus
         figure(obj.Figure);
         nrows = ceil(sqrt(obj.NumClus_Max));
         ncols = ceil(obj.NumClus_Max/nrows);
         
         % Initialize axes and images if necessary
         if isempty(obj.Axes)
            obj.Axes = cell(obj.NumClus_Max,1);
            obj.Images = cell(obj.NumClus_Max,1);
            for iC = 1:obj.NumClus_Max
               obj.Axes{iC} = subplot(nrows,ncols,iC);
               obj.initAxes(iC);
               obj.InitCheckBoxes(iC)
               obj.initImages(iC);
            end
         elseif ~isvalid(obj.Axes{1})
            obj.Axes = cell(obj.NumClus_Max,1);
            obj.Images = cell(obj.NumClus_Max,1);
            for iC = 1:obj.NumClus_Max
               obj.Axes{iC} = subplot(nrows,ncols,iC);
               obj.initAxes(iC);
               obj.InitCheckBoxes(iC)
               obj.initImages(iC);
            end
         end
         
         
         % Superimpose the image on everything
         fprintf(1,'->\tPlotting spikes');
         for iC = 1:obj.NumClus_Max
            fprintf(1,'. ');
            obj.Draw(iC);
         end
         fprintf(1,'complete.\n\n');
         obj.PropLinker = [linkprop([obj.Axes{:}],{'YLim'})... 
             linkprop([obj.Images{:}],{'YData'});];
      end
      
      function flag = clearKurrKey(obj,src,evt)
          if any(strcmp(evt.Key,{'control','alt'}))
               obj.CurrKeyPress={};
          else
              idx = strcmp(obj.CurrKeyPress,evt.Key);
              obj.CurrKeyPress(idx) = [];
          end
             flag = true;
      end
      
      
      % Initialize checkboxes on axes
      function InitCheckBoxes(obj,iC)
         %INITCHECKBOXES  Initialize all checkboxes on axes 
         %
         %  obj.InitCheckBoxes(iC);  
         %  --> Initializes checkbox on axes indexed by `iC`
         
          pos = obj.Axes{iC}.Position;
          pos(3:4) = 0.015;
          obj.VisibleToggle{iC} = uicontrol('Style','checkbox',...
              'Units','normalized',...
              'Position',pos,...
              'BackgroundColor','none',...
              'ForegroundColor','none',...
              'Value',true,...
              'CallBack',@obj.CheckCallBack,...
              'UserData',iC);
      end
      
      % CALLBACK: Checkbox (toggle visibility of features on 2D axes)
      function CheckCallBack(obj,this,~)
         %CHECKCALLBACK  Sets features as visible or not on Features axes
         if ~isvalid(obj.Parent.UI.FeaturesUI.Features2D)
            return;
         end
         
         obj.SetVisibleFeatures(this.UserData,this.Value);

      end
      
      % Re-draw spike image on all or a subset of axes
      function Draw(obj,plotNum)
         %DRAW  Re-draw specified axis
         %
         %  obj.Draw();
         %  --> Re-draws all axes
         %
         %  obj.Draw(plotNum);
         %  --> Re-draws axes indexed by plotNum
         
         if nargin < 2
            plotNum = 1:obj.NumClus_Max;
         else
            plotNum = plotNum(:)';
         end
         isThisAxes = plotNum == obj.Spikes.CurClass;

         cellfun(@(i,c)set(i,'CData',c),obj.Images(plotNum),obj.Spikes.C(plotNum))
         cellfun(@(a,t)set(a.Title,'String',t),obj.Axes(plotNum),obj.PlotNames(plotNum))
         cellfun(@(a)obj.SetAxesHighlight(a,nigeLab.defaults.nigelColors('primary'),20),obj.Axes(plotNum(isThisAxes)));
         cellfun(@(a)obj.SetAxesHighlight(a,nigeLab.defaults.nigelColors('onsurface'),16),obj.Axes(plotNum(~isThisAxes)));
         set(obj.Axes{1},'YLim',obj.YLim);
         set(obj.Images{1},'YData',obj.YLim);
         drawnow;
      end
      
      % Initializes a given axes (container for `SpikeImage` image)
      function initAxes(obj,plotNum)
         %INITAXES    Initialize axes properties
         %
         %  obj.initAxes(); 
         %  --> Initialize all axes
         %
         %  obj.initAxes(plotNum);
         %  --> Initialize axes subset indexed by `plotNum`
         
         if nargin < 2
            plotNum = 1:obj.NumClus_Max;
         else
            plotNum = reshape(plotNum,1,numel(plotNum));
         end
         
         for iPlot = plotNum
            set(obj.Axes{iPlot}.Title,'String',obj.PlotNames{iPlot});
            set(obj.Axes{iPlot}.Title,'FontName','Arial');
            set(obj.Axes{iPlot},'YDir','normal');
            set(obj.Axes{iPlot},'Box','on');            

            set(obj.Axes{iPlot}.XAxis,'LineWidth',4);
            set(obj.Axes{iPlot}.YAxis,'LineWidth',4);
            set(obj.Axes{iPlot},'NextPlot','replacechildren');
            
            set(obj.Axes{iPlot},'XLimMode','manual');
            set(obj.Axes{iPlot},'YLimMode','manual');
            set(obj.Axes{iPlot},'XLim',obj.Spikes.X([1,end]));

            set(obj.Axes{iPlot},'UserData',iPlot);
            set(obj.Axes{iPlot},'ButtonDownFcn',@obj.ButtonDownFcnSelect);

            colormap(obj.Axes{iPlot},obj.CMap{iPlot})
         end
      end
      
      % Initializes a given image ("flattened" graphics of Spike)
      function initImages(obj,plotNum)
         %INITIMAGES  Init spike plot images
         %
         %  obj.initImages();
         %  --> Initializes "flattened" spike image on all axes
         %
         %  obj.initImages(plotNum);
         %  --> Initializes "flattened" spike image on axes indexed by
         %      `plotNum` only
         
         if nargin < 2
            plotNum = 1:obj.NumClus_Max;
         else
            plotNum = reshape(plotNum,1,numel(plotNum));
         end
         
         for iPlot = plotNum
            % Factor 0.98 to make edges of graph more prominent
            obj.Images{iPlot} = imagesc(obj.Axes{iPlot},...
               obj.Spikes.X*0.98,obj.Spikes.Y*0.98,obj.Spikes.C{iPlot});
            set(obj.Images{iPlot},'UserData',iPlot);
            set(obj.Images{iPlot},'ButtonDownFcn',@obj.ButtonDownFcnSelect);
         end
      end
      
      % "Flatten" spikes (use mesh to 2D discretize them into an image)
      function Flatten(obj,plotNum)
         %FLATTEN   Condense spikes into matrix scaled from 0 to 1
         
         if nargin < 2
            plotNum = 1:obj.NumClus_Max;
            obj.Spikes.C = cell(obj.NumClus_Max,1); % Colors (spike image)
            obj.Spikes.A = cell(obj.NumClus_Max,1); % Assignments
         end

         plotNum = plotNum(:)';
         % Get bin edges
         y_edge = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints);
         
         for iC = plotNum
             % Pre-allocate
             clus = obj.Spikes.Waves(obj.Spikes.Class==iC,:);
             obj.Spikes.C{iC} = zeros(obj.YPoints-1,obj.XPoints);
             obj.Spikes.A{iC} = nan(size(clus));
             for ii = 1:obj.XPoints
                 [obj.Spikes.C{iC}(:,ii),obj.Spikes.A{iC}(:,ii)] = ...
                     matlab.internal.math.histcounts(clus(:,ii),y_edge);
             end
             
             % Normalize
             obj.Spikes.C{iC} = obj.Spikes.C{iC}./...
                 max(obj.Spikes.C{iC}(:));
         end
         
      end
      
      % CALLBACK: Triggered when figure window closes
      function CloseSpikeImageFigure(obj,src,~)
         %CLOSESPIKEIMAGEFIGURE  Trigger event when figure window closed
         if obj.UnsavedChanges
            str = questdlg('Unsaved changes on this channel. Exit anyways?',...
               'Exit?','Yes','No','Yes');
         else
            str = 'Yes';
         end
         if strcmpi(str,'Yes')
            notify(obj,'MainWindowClosed');
            delete(src);
            delete(obj);
         end
      end
      
      % CALLBACK: Determine method based on type of button click
      function ButtonDownFcnSelect(obj,src,~)
         %BUTTONDOWNFCNSELECT  Determine which callback to use for click
         
         % Make sure we're referring to the axes
         if isa(gco,'matlab.graphics.primitive.Image')
            ax = src.Parent;
         else
            ax = src;
         end
         
         % Don't do anything if it is the same axes as currently selected
         if ax.UserData == obj.Spikes.CurClass
            return;
         end
         
         switch get(gcf,'SelectionType')
            case 'normal' % Highlight clicked axes (L-Click)
               obj.SetAxesWhereSpikesGo(ax);
            case 'alt'    % Do "cluster cutting" (R-Click)
               obj.SetAxesHighlight(ax,nigeLab.defaults.nigelColors('quaternary'));
               obj.GetSpikesToMove(ax);
               obj.SetAxesHighlight(ax,nigeLab.defaults.nigelColors('onsurface'));
            otherwise
               return;
         end
         
      end
      
      % Determine which axes "selected" spikes will go to
      function SetAxesWhereSpikesGo(obj,curAxes)
         %SETAXESWHERESPIKESGO    Set current cluster to this axes
         %
         %  obj.SetAxesWhereSpikesGo(curAxes);
         %  --> curAxes indexes the axes that spikes "inside" the bounded
         %      convex hull polygon formed by "cluster cutting" will be
         %      moved into (effectively assigning them that "cluster"
         %      index)
         
         plotNum = curAxes.UserData;
         pastNum = obj.Spikes.CurClass;
         obj.Spikes.CurClass = plotNum;
         
         % Change the border on both plots
         obj.Draw([plotNum,pastNum]);
         
         visible = obj.VisibleToggle{plotNum}.Value;
         evtData = nigeLab.evt.spikeAxesClicked(plotNum,visible);
         notify(obj,'SpikeAxesSelected',evtData);   
      end
      
      % Determine which spikes to move using "cluster cutting"
      function GetSpikesToMove(obj,curAxes)
         %GETSPIKESTOMOVE  Draw polygon, move spikes 
         %
         %  obj.GetSpikesToMove(curAxes);
         %  --> curAxes indexes the axes where the cutting is being drawn,
         %      so that the corresponding spikes can be "subtracted" from
         %      association to that axes

         % Track cluster assignment changes
         thisClass = curAxes.UserData;
         subsetIndex = find(obj.Spikes.Class == thisClass);
         set(obj.Figure,'Pointer','circle');
         
%          snipped_region = imfreehand(curAxes);
         [h,x,y]=nigeLab.utils.freehanddraw(curAxes,'color',nigeLab.defaults.nigelColors('onsurface'));
%          pos = getPosition(snipped_region);
%          delete(snipped_region);
         delete(h);


         [px,py] = meshgrid(obj.Spikes.X,obj.Spikes.Y);
%          cx = pos(:,1);
%          cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = nigeLab.utils.InPolygon.InPolygon(px,py,x,y);
         pts = IN | ON;
         set(obj.Figure,'Pointer','watch');
         drawnow;
         

         % Match from SpikeImage Assignments        
         start = find(sum(pts,1),1,'first'); % Skip "empty" start
         last = find(sum(pts,1),1,'last'); % Skip "empty" end
         iMove = [];
         for ii = start:last
            addressVec = obj.Spikes.A{thisClass}(:,ii);
            inPolyVec = find(pts(:,ii));
            inPolyVec = repmat(inPolyVec.',numel(addressVec),1);
            iMove = [iMove; find(any(addressVec == inPolyVec,2))]; %#ok<AGROW>
         end
         iMove = unique(iMove);
         set(obj.Figure,'Pointer','arrow');
         
         
         evtData = nigeLab.evt.assignClus(subsetIndex(iMove),...
            obj.Spikes.CurClass,thisClass);
         obj.UpdateClusterAssignments(nan,evtData);
      end
      
      % CALLBACK: Execute keyboard shortcut on keyboard button press
      function WindowKeyPress(obj,src,evt)
         %WINDOWKEYPRESS    Issue different events on keyboard presses
         obj.CurrKeyPress = [obj.CurrKeyPress {evt.Key}];
         switch evt.Key
             case 'h'
                 thisClass =  obj.Spikes.CurClass;
                 thisAx = obj.Axes{thisClass}';
                 val = obj.VisibleToggle{thisClass}.Value;
                 obj.VisibleToggle{thisClass}.Value = ~val;
                 obj.SetVisibleFeatures(thisClass,~val);
             case {'n','0'}
                 if strcmpi(evt.Modifier,'control')
                     thisClass =  obj.Spikes.CurClass;
                     obj.Spikes.CurClass = 1;
                     subsetIndex = find(obj.Spikes.Class == thisClass);
                     evtData = nigeLab.evt.assignClus(subsetIndex,...
                         obj.Spikes.CurClass,thisClass);
                     obj.UpdateClusterAssignments(nan,evtData);
                 else
                 end
             case {'1','2','3','4','5','6','7','8'}
                 if strcmpi(evt.Modifier,'control')
                     thisClass =  obj.Spikes.CurClass;
                     obj.Spikes.CurClass = str2num(evt.Key)+1;
                     subsetIndex = find(obj.Spikes.Class == thisClass);
                     evtData = nigeLab.evt.assignClus(subsetIndex,...
                         obj.Spikes.CurClass,thisClass);
                     obj.UpdateClusterAssignments(nan,evtData);
                 else
                 end
            case 'space'
               obj.ConfirmChanges;
            case 'z'
               if strcmpi(evt.Modifier,'control')
%                   obj.UndoChanges;
               uiundo(obj.Figure,'execUndo');

               end
             case 'y'
                 if strcmpi(evt.Modifier,'control')
                     uiundo(obj.Figure,'execRedo');
                 end
            case 's'
               if strcmpi(evt.Modifier,'control')
                  if obj.UnsavedChanges(obj.Parent.UI.ChannelSelector.Channel) &&...
                          ~obj.ConfirmedChanges(obj.Parent.UI.ChannelSelector.Channel)
                     str = questdlg('Confirm current changes before save?',...
                        'Use Most Recent Scoring?','Yes','No','Yes');
                  else
                     str = 'No';
                  end
                  
                  if strcmp(str,'Yes')
                     obj.ConfirmChanges;
                  end
                  obj.SaveChanges;
                  
               end
            case {'x','c'}
               if strcmpi(evt.Modifier,'control')
                  notify(obj,'MainWindowClosed');
               end
            case 'r'
               if strcmpi(evt.Modifier,'control')
                  obj.Recluster;
               else
                   ButtonName = questdlg(sprintf('Reload data from disk?\nAll unsaved changes will be lost.'), ...
                         'Reload', ...
                         'Yes', 'No', 'No');
                     if strcmp(ButtonName,'Yes')
                         obj.Refresh;
                     end
               end
            case 'q'
               obj.Parent.UI.FeaturesUI.ReopenWindow;
            case 'uparrow'
               pastNum = obj.Spikes.CurClass;
               newNum = pastNum-3;
               newNum = mod(newNum,9);
               newNum = newNum + 9*(newNum==0);
               obj.SetAxesWhereSpikesGo(obj.Axes{newNum});
            case 'downarrow'
               pastNum = obj.Spikes.CurClass;
               newNum = pastNum+3;
               newNum = mod(newNum,9);
               newNum = newNum + 9*(newNum==0);
               obj.SetAxesWhereSpikesGo(obj.Axes{newNum});          
            case 'rightarrow'
               pastNum = obj.Spikes.CurClass;
               newNum = pastNum+1;
               newNum = mod(newNum,9);
               newNum = newNum + 9*(newNum==0);
               obj.SetAxesWhereSpikesGo(obj.Axes{newNum});
            case 'leftarrow'
               pastNum = obj.Spikes.CurClass;
               newNum = pastNum-1;
               newNum = mod(newNum,9);
               newNum = newNum + 9*(newNum==0);
               obj.SetAxesWhereSpikesGo(obj.Axes{newNum});  
            otherwise
               
         end
      end
      
      % Save changes based on scoring that has been done
      function SaveChanges(obj)
         %SAVECHANGES    Save the scoring that has been done
         %
         %  obj.SaveChanges();
         
         confirmedChans = find(obj.ConfirmedChanges);
         if isempty(confirmedChans)
            fprintf(1,'No changes were done to the scoring.\nNothing was saved!\n');
             return; 
         end
         evt = nigeLab.evt.saveData(confirmedChans);
         notify(obj,'SaveData',evt);
         obj.UnsavedChanges(confirmedChans) = false;
         obj.ConfirmedChanges(confirmedChans) = false;
         disp('Scoring saved.');
      end
      
      % Undo sorting of class ID
      function UndoChanges(obj)
         %UNDOCHANGES    Undo sorting to class ID
         %
         %  obj.UndoChanges();
         
         if isa(obj.Parent,'nigeLab.Sort')
            obj.Spikes.Class = obj.Parent.spk.class{get(obj.Parent,'channel')};
         else
            obj.Spikes.Class = obj.Parent.spk.class{1};
         end
         obj.ConfirmedChanges(obj.Parent.UI.ChannelSelector.Channel) = false;
         obj.UnsavedChanges(obj.Parent.UI.ChannelSelector.Channel) = false;
         obj.Flatten;
         obj.SetPlotNames;
         obj.Draw;
         
         subs = 1:numel(obj.Spikes.Class);
         class = obj.Spikes.Class;
         evtData = nigeLab.evt.assignClus(subs,class);
         
         notify(obj,'ClassAssigned',evtData);
      end
      
      % Confirms the changes to class ID for this channel
      function ConfirmChanges(obj)
         %CONFIRMCHANGES    Confirm that changes to class ID are made
         %
         %  obj.ConfirmChanges();
         
         if isa(obj.Parent,'nigeLab.Sort')
            obj.Parent.setClass(obj.Spikes.Class);
         else
            obj.Parent.spk.class{1} = obj.Spikes.Class;
         end
         obj.ConfirmedChanges(obj.Parent.UI.ChannelSelector.Channel) = true;
         notify(obj,'ChannelConfirmed');
         fprintf(1,'Scoring for channel %d confirmed.\n',...
            obj.Parent.UI.ChannelSelector.Channel);
      end
      
      % CALLBACK: Zoom in or out on an axes by mouse-wheel scroll
      function WindowMouseWheel(obj,~,evt)
         %WINDOWMOUSEWHEEL     Zoom in or out on all plots
         %
         %  fig.WindowScrollWheelFcn = @obj.WindowMouseWheel;
         modifier = obj.CurrKeyPress;         
         if ~isempty(modifier) && all(strcmp(modifier,'alt'))
             % only alt is pressed
             offset = 20*evt.VerticalScrollCount;
             obj.YLim = obj.YLim + offset;
             obj.Spikes.Y = obj.Spikes.Y + offset;
           
         else
             obj.YLim(1) = min(obj.YLim(1) + 20*evt.VerticalScrollCount,-20);
             obj.YLim(2) = max(obj.YLim(2) - 10*evt.VerticalScrollCount,10);
             obj.Spikes.Y = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints-1);
         end
         obj.Flatten;
         obj.Draw;
      end
      
      % CALLBACK: Updates cluster assignments
      function UpdateClusterAssignments(obj,~,evt,logundo)
         %UPDATECLUSTERASSIGNMENTS   Update cluster assigns and notify  
         if nargin<4
            logundo = true; 
         end
         if ~isprop(evt,'subs')
            return;
         elseif isempty(evt.subs)
             return;
         end
         % identify new classes to assign
         newClasses = unique(evt.class);
         newClasses = newClasses(:)';
         % log status quo for undo/redo
         oldEvt = nigeLab.evt.assignClus(evt.subs,...
             obj.Spikes.Class(evt.subs),...
             unique(evt.class));
      
         % Identify plots to update
         plotsToUpdate = unique(obj.Spikes.Class(evt.subs));
         plotsToUpdate = reshape(plotsToUpdate,1,numel(plotsToUpdate));
         plotsToUpdate = unique([plotsToUpdate, newClasses]); % in case
         if ~isnan(evt.otherClassToUpdate)
            plotsToUpdate = unique([plotsToUpdate, evt.otherClassToUpdate]);
         end
         for class = newClasses
             % Assign and redo graphics
             idx = evt.class == class;
             obj.Assign(class,evt.subs(idx));
         end
         obj.SetPlotNames(plotsToUpdate);
         obj.Flatten(plotsToUpdate);
         obj.Draw(plotsToUpdate);
         
         % Indicate that there have been some changes in class ID
         obj.ConfirmedChanges(obj.Parent.UI.ChannelSelector.Channel) = false;
         obj.UnsavedChanges(obj.Parent.UI.ChannelSelector.Channel) = true;
         
         notify(obj,'ClassAssigned',evt);
         
                  % Add undo redo functionality
         % Prepare an undo/redo action
         source = sprintf('%d,',plotsToUpdate);
         destination = sprintf('%d,',newClasses);
         cmd.Name = sprintf('Cluster assignment (%g to %g)',source(1:end-1),destination(1:end-1));
         
         cmd.Function        = @obj.UpdateClusterAssignments;       % Redo action
         cmd.Varargin        = {nan,evt,false};
         cmd.InverseFunction = @obj.UpdateClusterAssignments;        % Undo action
         
         cmd.InverseVarargin = {nan,oldEvt,false};
%          % Register the undo/redo action with the figure
        if logundo
            uiundo(obj.Figure,'function',cmd);
        end
         
      end
      
      % Assign spikes to a given class
      function Assign(obj,class,subsetIndex)
         %ASSIGN   Assign spikes to a given class
         %
         %  obj.Assign(class);
         %  --> Assigns all spikes to class indexed by `class`
         %
         %  obj.Assign(class,subsetIndex);
         %  --> Assign subset of spikes indexed by `subsetIndex` to `class`
         
         if nargin < 3
            if numel(class) == 1 % If only 1 value given assign all to that
               obj.Spikes.Class = ones(size(obj.Spikes.Waves,1),1) * class;
            elseif numel(class) ~= size(obj.Spikes.Waves,1)
               warning(sprintf(['Invalid class size (%d; should be %d).\n' ...
                  'Assigning all classes to class(1) (%d).'], ...
                  numel(class),size(obj.Spikes.Waves,1),class(1))); %#ok<SPWRN>
               
               obj.Spikes.Class=ones(size(obj.Spikes.Waves,1),1)*class(1);
            else
               % Otherwise just assign the given value
               obj.Spikes.Class = class;
            end
            obj.Spikes.Class(class > obj.NumClus_Max) = 1;

         else % Update spikes to a given class label (numeric)
            obj.Spikes.Class(subsetIndex) = class;

         end
         
      end
   
      Recluster(obj)
   end
   
   % PROTECTED
   methods (Static,Access=protected)
      function SetAxesHighlight(ax,col,fontSize)
         %SETAXESHIGHLIGHT     Set highlight on an axes handle
         %
         %  nigeLab.libs.SpikeImage.SetAxesHighlight(ax,col,fontSize);
         %  --> Sets axes `ax` to have a border of color "col" and if 3
         %      inputs are given, also changes fontSize of that axes to the
         %      `fontSize` input (otherwise, does not change).
         %
         %  --> If `fontSize` >  18, then it also becomes `bold`
         %  --> If `fontSize` <= 18, then it returns to `normal`
         
         set(ax,'XColor',col);
         set(ax,'YColor',col);
         set(ax,'Color',col);
         set(ax.Title,'Color',col);
         
         if nargin > 2
            set(ax.Title,'FontSize',fontSize);
            if fontSize > 18
               set(ax.Title,'FontWeight','bold');
            else
               set(ax.Title,'FontWeight','normal');
            end
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end