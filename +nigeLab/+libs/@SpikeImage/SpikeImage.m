classdef SpikeImage < handle
%% SPIKEIMAGE Quickly aggregates spikes into one image object.
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
%
% By: Max Murphy  v1.0  08/25/2017  Original version (R2017a)

%%
   properties (Access = public)
      Spikes % Contains all info relating to spike waves and classes
      Figure = figure('Name','Spike Profiles',... % Container for graphics
                      'Units','Normalized',...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'NumberTitle','off',...
                      'Position',[0.050,0.075,0.800,0.850],...
                      'Color','k'); 
      Labels   % Labels above the subplots
      Images   % Figure subplots that contain flattened spike image
      VisibleToggle % checkbox for selecting visiblity in the feature panel
      Axes     % Axes containers for images
      Parent   % Only set if called by nigeLab.Sort class object
   end
   
   properties (Access = public)
      PlotCB;
      NumClus_Max = 9;
      CMap;
      YLim = [-300 150];
      XPoints = 60;     % Number of points for X resolution
      YPoints = 101;    % Number of points for Y resolution
      T = 1.2;          % Approx. time (milliseconds) of waveform
      Defaults_File = 'SpikeImageDefaults.mat'; % Name of file with default
      PlotNames = cell(9,1);
      
      UnconfirmedChanges
      UnsavedChanges
   end
   
   events
      MainWindowClosed
      ClassAssigned
      ChannelConfirmed
      SaveData
   end

   methods (Access = public)
      function obj = SpikeImage(spikes,fs,class,varargin)
         %% SPIKEIMAGE Quickly aggregates spikes into one image object.
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
         
         %% PARSE VARARGIN
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
         if isa(spikes,'nigeLab.Sort')
            obj.Parent = spikes;
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
      
      function UpdateChannel(obj,~,~)
         %% UPDATECHANNEL  Update the spike data structure to new channel
         
         % Check if it's okay to lose changes if there are any
         if obj.UnconfirmedChanges
            str = questdlg('Unconfirmed changes will be lost. Change channel anyways?',...
               'Discard Sorting on this Channel?','Yes','No','Yes');
         else
            str = 'Yes';
         end
         
         if strcmp(str,'No')
            return;
         end
         
         % Interpolate spikes
         obj.Interpolate(obj.Parent.spk.spikes{obj.Parent.UI.ch});

         % Set spike classes
         obj.Assign(obj.Parent.spk.class{obj.Parent.UI.ch});
         
         % Flatten spike image
         obj.Flatten;
         
         % Construct figure
         obj.Build;
         
         % New channel; no changes exist here yet
         obj.UnconfirmedChanges = false; 
      end
      
      function Refresh(obj)
         %% REFRESH  Re-display all the spikes
         
         if isa(obj.Parent,'nigeLab.Sort')
            % Set spike classes
            obj.Assign(obj.Parent.spk.class{obj.Parent.UI.ch});
         end
         
         % Flatten spike image
         obj.Flatten;
         
         % Construct figure
         obj.Build;
      end
      
      function set(obj,NAME,value)
         %% SET   Overloaded class method
         
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
      
      function Assign(obj,class,subsetIndex)
         %% ASSIGN   Assign spikes to a given class
         
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
            subs = 1:size(obj.Spikes.Waves,1);

         else % Update spikes to a given class label (numeric)
            obj.Spikes.Class(subsetIndex) = class;
            subs = subsetIndex;

         end
         evtData = nigeLab.libs.assignmentEventData(subs,class);
         notify(obj,'ClassAssigned',evtData);
         
      end
      
   end
   
   methods (Access = private)    
      
      function Init(obj,fs)
         %% INIT  Initialize parameters
         
         % No changes have been made yet
         obj.UnconfirmedChanges = false;
         obj.UnsavedChanges = false;
         
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
      
      function SetPlotNames(obj,plotNum)
         %% SETPLOTNAMES   Set names (titles) of each plot
         
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
      
      function Interpolate(obj,spikes)
         %% INTERPOLATE    Interpolate spikes to make waveforms smoother
         
         x = [1, size(spikes,2)];
         xv = linspace(x(1),x(2),obj.XPoints);
         
         LoopFunction = @(xin) (interp1(x(1):x(2),spikes(xin,:),xv));
         
         % Make ProgressCircle object
         pcirc = nigeLab.libs.ProgressCircle(LoopFunction);
         
         % Run ProgressCircle Loop
         fprintf(1,'->\tInterpolating spikes...');
         obj.Spikes.Waves = pcirc.RunLoop(size(spikes,1),obj.XPoints);
         fprintf(1,'complete.\n');

      end
      
      function Build(obj)
         %% BUILD    Build the figure (if needed) and axes/images
         
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
                      'Color','k',...
                      'WindowKeyPressFcn',@obj.WindowKeyPress,...
                      'WindowScrollWheelFcn',@obj.WindowMouseWheel,...
                      'CloseRequestFcn',@obj.CloseSpikeImageFigure);
         else
            set(obj.Figure,'CloseRequestFcn',@obj.CloseSpikeImageFigure);
            set(obj.Figure,'WindowScrollWheelFcn',@obj.WindowMouseWheel);
            set(obj.Figure,'WindowKeyPressFcn',@obj.WindowKeyPress);
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
      end
      
      function InitCheckBoxes(obj,iC)
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
      
      function CheckCallBack(obj,this,evs)
         ind2D=([obj.Parent.UI.FeaturesUI.Features2D.Children.UserData] ==...
             this.UserData);
         ind3D=([obj.Parent.UI.FeaturesUI.Features3D.Children.UserData] ==...
             this.UserData);
         obj.Parent.UI.FeaturesUI.Features2D.Children(ind2D).Visible = this.Value;
         obj.Parent.UI.FeaturesUI.Features3D.Children(ind3D).Visible = this.Value;

      end
      
      function Draw(obj,plotNum)
         %% DRAW  Re-draw specified axis
         if nargin < 2
            plotNum = 1:obj.NumClus_Max;
         else
            plotNum = reshape(plotNum,1,numel(plotNum));
         end
            
         for iPlot = plotNum
            set(obj.Images{iPlot},'CData',obj.Spikes.C{iPlot});
            set(obj.Axes{iPlot}.Title,'String',obj.PlotNames{iPlot});
            if obj.Spikes.CurClass == iPlot
               obj.SetAxesHighlight(obj.Axes{iPlot},'m',20);
            else
               obj.SetAxesHighlight(obj.Axes{iPlot},'w',16);
            end
            drawnow;
         end
         
      end
      
      function initAxes(obj,plotNum)
         %% INITAXES    Initialize axes properties
         
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
            set(obj.Axes{iPlot},'YLim',obj.Spikes.Y([1,end]));

            set(obj.Axes{iPlot},'UserData',iPlot);
            set(obj.Axes{iPlot},'ButtonDownFcn',@obj.ButtonDownFcnSelect);

            colormap(obj.Axes{iPlot},obj.CMap{iPlot})
         end
      end
      
      function initImages(obj,plotNum)
         %% INITIMAGES  Init spike plot images
         
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
      
      function Flatten(obj,plotNum)
         %% FLATTEN   Condense spikes into matrix scaled from 0 to 1
         
         if nargin < 2
            
            obj.Spikes.C = cell(obj.NumClus_Max,1); % Colors (spike image)
            obj.Spikes.A = cell(obj.NumClus_Max,1); % Assignments
            for iC = 1:obj.NumClus_Max
               % Get bin edges
               y_edge = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints); 

               % Pre-allocate
               clus = obj.Spikes.Waves(obj.Spikes.Class==iC,:);
               obj.Spikes.C{iC} = zeros(obj.YPoints-1,obj.XPoints);
               obj.Spikes.A{iC} = nan(size(clus));
               for ii = 1:obj.XPoints
                  [obj.Spikes.C{iC}(:,ii),~,obj.Spikes.A{iC}(:,ii)] = ...
                     histcounts(clus(:,ii),y_edge);
               end

               % Normalize
               obj.Spikes.C{iC} = obj.Spikes.C{iC}./...
                  max(max(obj.Spikes.C{iC})); 
            end
         else
            plotNum = reshape(plotNum,1,numel(plotNum));
            for iC = plotNum
               % Get bin edges
               y_edge = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints); 

               % Pre-allocate
               clus = obj.Spikes.Waves(obj.Spikes.Class==iC,:);
               obj.Spikes.C{iC} = zeros(obj.YPoints-1,obj.XPoints);
               obj.Spikes.A{iC} = nan(size(clus));
               for ii = 1:obj.XPoints
                  [obj.Spikes.C{iC}(:,ii),~,obj.Spikes.A{iC}(:,ii)] = ...
                     histcounts(clus(:,ii),y_edge);
               end

               % Normalize
               obj.Spikes.C{iC} = obj.Spikes.C{iC}./...
                  max(max(obj.Spikes.C{iC})); 
            end
         end
      end
      
      function CloseSpikeImageFigure(obj,src,~)
         %% CLOSESPIKEIMAGEFIGURE  Trigger event when figure window closed
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
      
      function ButtonDownFcnSelect(obj,src,~)
         %% BUTTONDOWNFCNSELECT  Determine which callback to use for click
         
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
               obj.SetAxesHighlight(ax,'r');
               obj.GetSpikesToMove(ax);
               obj.SetAxesHighlight(ax,'w');
            otherwise
               return;
         end
         
      end
      
      function SetAxesWhereSpikesGo(obj,curAxes)
         %% SETAXESWHERESPIKESGO    Set current cluster to this axes
         
         plotNum = curAxes.UserData;
         pastNum = obj.Spikes.CurClass;
         obj.Spikes.CurClass = plotNum;
         
         % Change the border on both plots
         obj.Draw([plotNum,pastNum]);
         
                  
      end
      
      function GetSpikesToMove(obj,curAxes)
         %% GETSPIKESTOMOVE  Draw polygon, move spikes 

         % Track cluster assignment changes
         thisClass = curAxes.UserData;
         subsetIndex = find(obj.Spikes.Class == thisClass);
         set(obj.Figure,'Pointer','circle');
         
         snipped_region = imfreehand(curAxes);
         pos = getPosition(snipped_region);
         delete(snipped_region);

         [px,py] = meshgrid(obj.Spikes.X,obj.Spikes.Y);
         cx = pos(:,1);
         cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = InPolygon(px,py,cx,cy);
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

         obj.Assign(obj.Spikes.CurClass,subsetIndex(iMove));
         plotsToUpdate = [obj.Spikes.CurClass,thisClass];
         obj.SetPlotNames(plotsToUpdate);
         obj.Flatten(plotsToUpdate);
         obj.Draw(plotsToUpdate);
         
         % Indicate that there have been some changes in class ID
         obj.UnconfirmedChanges = true;
         obj.UnsavedChanges = true;
         
         set(obj.Figure,'Pointer','arrow');

      end
      
      function WindowKeyPress(obj,~,evt)
         %% WINDOWKEYPRESS    Issue different events on keyboard presses
         switch evt.Key
            case 'space'
               obj.ConfirmChanges;
            case 'z'
               if strcmpi(evt.Modifier,'control')
                  obj.UndoChanges;
               end
            case 's'
               if strcmpi(evt.Modifier,'control')
                  if obj.UnconfirmedChanges
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
            case 'escape'
               notify(obj,'MainWindowClosed');
            case {'x','c'}
               if strcmpi(evt.Modifier,'control')
                  notify(obj,'MainWindowClosed');
               end
            otherwise
               
         end
      end
      
      function SaveChanges(obj)
         %% SAVECHANGES    Save the scoring that has been done
         notify(obj,'SaveData');
         obj.UnsavedChanges = false;
      end
      
      function UndoChanges(obj)
         %% UNDOCHANGES    Undo sorting to class ID
         if isa(obj.Parent,'nigeLab.Sort')
            obj.Spikes.Class = obj.Parent.spk.class{get(obj.Parent,'channel')};
         else
            obj.Spikes.Class = obj.Parent.spk.class{1};
         end
         obj.UnconfirmedChanges = false;
         obj.Flatten;
         obj.SetPlotNames;
         obj.Draw;
      end
      
      function ConfirmChanges(obj)
         %% CONFIRMCHANGES    Confirm that changes to class ID are made
         if isa(obj.Parent,'nigeLab.Sort')
            obj.Parent.setClass(obj.Spikes.Class);
         else
            obj.Parent.spk.class{1} = obj.Spikes.Class;
         end
         obj.UnconfirmedChanges = false;
         notify(obj,'ChannelConfirmed');
         fprintf(1,'Scoring for channel %d confirmed.\n',...
            obj.Parent.UI.ChannelSelector.Channel);
      end
      
      function WindowMouseWheel(obj,~,evt)
         %% WINDOWMOUSEWHEEL     Zoom in or out on all plots
         obj.YLim(1) = min(obj.YLim(1) - 10*evt.VerticalScrollCount,10);
         obj.YLim(2) = max(obj.YLim(2) + 20*evt.VerticalScrollCount,20);
         obj.Flatten;
         obj.Draw;
      end
   
   end
   
   methods (Static = true, Access = private)
      function SetAxesHighlight(ax,col,fontSize)
         %% SETAXESHIGHLIGHT     Set highlight on an axes handle
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
end