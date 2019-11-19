classdef ratskull_plot < handle
   %RATSKULL_PLOT  Graphics object handle
   %
   % obj = ratskull_plot;        % Goes onto current axes
   % obj = ratskull_plot(ax);    %
   
   properties(GetAccess = public, SetAccess = public)
      Name
      Children
   end
   
   properties (GetAccess = public, SetAccess = private)
      Figure
      Axes
      Score
      Image
      Bregma
      Scale_Compass
   end
   
   properties (GetAccess = public, Hidden = true)
      XLim
      YLim
   end
   
   properties (Access = private)
      CData
   end
   
   methods (Access = public)
      % RATSKULL_PLOT Class constructor
      function obj = ratskull_plot(ax)
         % RATSKULL_PLOT   Class constructor: build rat skull image plot
         
         p = ratskull_plot.def('Image');
         if nargin == 0
            ax = gca;
            fig = ax.Parent;
         elseif isa(ax,'matlab.ui.Figure')
            fig = ax;
            ax = gca;
         elseif isa(ax,'matlab.graphics.axis.Axes')
            fig = ax.Parent;
         else
            if isnumeric(ax)
               dims = ax;
               if isscalar(ax)
                  obj = repmat(obj,dims,1);
               else
                  obj = repmat(obj,dims);
               end
               return;
            else
               error('Bad input type: %s',class(ax));
            end
         end
         
         obj.Image = matlab.graphics.primitive.Image(ax);
         obj.CData = p.CData;
         obj.Image.CData = obj.CData;
         obj.Image.XData = p.XData;
         obj.Image.YData = p.YData;
         
         % Add listener to axes and set axes properties
         addlistener(ax,'XLim','PostSet',@obj.handleAxesLimChange);
         addlistener(ax,'YLim','PostSet',@obj.handleAxesLimChange);
         ax = ratskull_plot.setAxProperties(ax);
         obj.Image.Parent = ax;
         obj.Axes = ax;
         
         % Set figure properties
         fig = ratskull_plot.setFigProperties(fig);
         obj.Figure = fig;
         
         % Make "Bregma" marker
         obj.Bregma = ratskull_plot.buildBregma(ax);
         
         % Make Scale bar/compass
         obj.Scale_Compass = ratskull_plot.buildScale_Compass(ax);
      end
      
      % Add a scatter plot group to the skull layout plot
      function hgg = addScatterGroup(obj,x,y,sizeData,ICMS)
         if nargin < 5
            ICMS = categorical(repmat({'O'},numel(x),1));
         end
         
         if nargin < 4
            sizeData = ones(size(x)) * 30;
         else
            if (numel(sizeData) == 1) && (numel(sizeData)~=numel(x))
               sizeData = ones(size(x)) * sizeData;
            end
         end
         icms_key = defaults.group('skull_icms_key');
         hgg = hggroup(obj.Axes);
         for ii = 1:numel(x)
            icms = strrep(char(ICMS(ii)),'-','');
            col = icms_key.(icms);
            scatter(obj,x(ii),y(ii),icms,...
               'MarkerFaceColor',col,...
               'MarkerEdgeColor','none',...
               'MarkerSize',sizeData(ii),...
               'Parent',hgg);
         end
         obj.Children = [obj.Children; hgg];
         
      end
      
      % Make the movie frame sequence as a tensor that can then be exported
      % one frame at a time. MV is a nRows x nColumns x 3 (RGB) x nFrames
      % tensor of class uint8.
      function MV = buildMovieFrameSequence(obj,sizeData,scoreData,scoreAx,scoreDays,t_orig_score,orig_score)
         set(obj.Figure,'Position',[0.3 0.3 0.2 0.5]);
         set(obj.Figure,'MenuBar','none');
         set(obj.Figure,'Toolbar','none');
         tmp = utils.screencapture(obj.Figure);
         MV = zeros(size(tmp,1),size(tmp,2),size(tmp,3),size(sizeData,2),...
            class(tmp));
         keepvec = true(size(sizeData,2),1);
         
         if nargin > 3
            obj.Score = struct;
            obj.Score.Axes = scoreAx;
            obj.Score.Axes.NextPlot = 'add';
            ylim(obj.Score.Axes,[0 100]);
            xlim(obj.Score.Axes,[1 31]);
            obj.Score.t = t_orig_score;
            obj.Score.pct = round(orig_score*100);
            ylabel(obj.Score.Axes,'% Successful',...
               'FontName','Arial',...
               'Color','k','FontSize',14);
            xlabel(obj.Score.Axes,'Post-Op Day',...
               'FontName','Arial',...
               'Color','k','FontSize',14);
            obj.Score.Trace = line(obj.Score.Axes,...
               scoreDays,nan(size(scoreDays)),...
               'Color','b',...
               'LineWidth',3,...
               'LineStyle','-');
            obj.Score.OrigPts = scatter(obj.Score.Axes,...
               obj.Score.t,obj.Score.pct,50,...
               'MarkerEdgeColor','b',...
               'MarkerFaceColor','flat',...
               'CData',ones(numel(obj.Score.t),3),...
               'LineWidth',2);
            obj.Score.OrigPts.SizeData = nan(numel(obj.Score.t),1);
            mindiff_scoreDays = false(size(scoreDays));
            for ii = 1:numel(obj.Score.t)
               [~,d] = min(abs(scoreDays - obj.Score.t(ii)));
               mindiff_scoreDays(d) = true;
            end
         end
         iCount = 0;
         for ii = 1:size(sizeData,2)
            if nargin > 2
               s = round(scoreData(ii)*100);
               title(obj.Axes,...
                  [obj.Name sprintf(' (%g%%)',s)],...
                  'FontName','Arial','FontSize',14,'Color','k');
            end
            if nargin > 3
               obj.Score.Trace.YData(ii) = s;
               if mindiff_scoreDays(ii)
                  iCount = iCount + 1;
                  %                   obj.Score.OrigPts.YData(iCount) = obj.Score.pct(iCount);
                  obj.Score.OrigPts.SizeData(iCount) = 100;
                  obj.Score.OrigPts.CData(iCount,:) = [1 1 0];
                  if iCount > 1
                     obj.Score.OrigPts.SizeData(iCount-1) = 50;
                     obj.Score.OrigPts.CData(iCount-1,:) = [1 1 1];
                  end
                  drawnow;
               end
            end
            obj.changeScatterGroupSizeData(sizeData(:,ii));
            MV(:,:,:,ii) = utils.screencapture(obj.Figure);
         end
      end
      
      % Change the sizes for data on an existing scatter group of electrode
      % channels
      function changeScatterGroupSizeData(obj,sizeData,groupIdx)
         if nargin < 3
            groupIdx = 1;
         end
         for ii = 1:numel(sizeData)
            obj.Children(groupIdx).Children(ii).SizeData = sizeData(ii);
         end
      end
      
      % MV(:,:,:,fi) = getMovieFrame(obj);
      function MV = getMovieFrame(obj)
         MV = utils.screencapture(obj.Axes);
      end
      
      % Overloads SCATTER method
      function hgg = scatter(obj,x,y,scattername,varargin)
         p = ratskull_plot.def('Scatter');
         if nargin < 4
            scattername = p.GroupName;
         end
         
         if numel(obj) > 1
            if iscell(x)
               for ii = 1:numel(obj)
                  scatter(obj(ii),x{ii},y{ii},varargin);
               end
            else
               for ii = 1:numel(obj)
                  scatter(obj(ii),x,y,varargin);
               end
            end
            return;
         end
         
         % Parse variable 'Name' value pairs
         f = fieldnames(p);
         if ~isempty(varargin)
            if (numel(varargin)==1)&&(iscell(varargin{1}))
               varargin = varargin{1};
            end
            for iV = 1:2:numel(varargin)
               % Check that it is a correct property
               if isfield(p,varargin{iV})
                  p.(varargin{iV}) = varargin{iV+1};
               else
                  idx = find(ismember(lower(f),lower(varargin{iV})),1,'first');
                  if isempty(idx)
                     error('%s is not a valid Scatter Property.',varargin{iV});
                  else
                     p.(f{idx}) = varargin{iV+1};
                  end
               end
            end
         end
         
         if isempty(p.Parent)
            hgg = hggroup(obj.Axes,'DisplayName',scattername);
            scatter(obj.Axes,x,y,p.MarkerSize,...
               'MarkerEdgeColor',p.MarkerEdgeColor,...
               'Marker',p.Marker,...
               'MarkerFaceColor',p.MarkerFaceColor,...
               'MarkerFaceAlpha',p.MarkerFaceAlpha,...
               'Parent',hgg);
         else
            scatter(obj.Axes,x,y,p.MarkerSize,...
               'MarkerEdgeColor',p.MarkerEdgeColor,...
               'Marker',p.Marker,...
               'MarkerFaceColor',p.MarkerFaceColor,...
               'MarkerFaceAlpha',p.MarkerFaceAlpha,...
               'Parent',p.Parent);
         end
      end
      
      function setProp(obj,propName,propVal)
         % Parse input arrays
         if numel(obj) > 1
            if (numel(propName) > 1)
               for ii = 1:numel(obj)
                  for iP = 1:numel(propName)
                     setProp(obj(ii),propName{iP},propVal{iP});
                  end
               end
            else
               if numel(propVal)==numel(obj)
                  for ii = 1:numel(obj)
                     setProp(obj(ii),propName,propVal(ii));
                  end
               else
                  for ii = 1:numel(obj)
                     setProp(obj(ii),propName,propVal);
                  end
               end
            end
            return;
         end
         
         % Find the correct property and set it
         if isprop(obj,propName)
            obj.(propName) = propVal;
         else
            p = properties(obj);
            idx = find(ismember(lower(p),lower(propName)),1,'first');
            if isempty(idx)
               return;
            else
               obj.(p{idx}) = propVal;
            end
         end
      end
   end
   
   methods (Access = private)
      % Listener function that handles changes in axes limits
      function handleAxesLimChange(obj,src,evt)
         setProp(obj,src.Name,evt.AffectedObject.(src.Name));
      end
      
   end
   
   methods (Access = private, Static = true)
      % Make property struct with graphics object and graphics text label
      function bregma = buildBregma(ax)
         p = ratskull_plot.def('Bregma');
         bregma.Marker = fill(ax,p.X,p.Y,p.C);
         bregma.Label = text(ax,0,0,'Bregma','FontName','Arial',...
            'Color','k','FontWeight','bold','FontSize',14);
      end
      
      % Make Scale_Compass property using graphics objects and text labels
      function scale_compass = buildScale_Compass(ax)
         p = ratskull_plot.def('Scale');
         scale_compass = hggroup(ax,'DisplayName','Compass');
         
         % Horizontal arrow component
         hh = line(ax,[p.Pos(1),p.Pos(1)+p.X],[p.Pos(2),p.Pos(2)],...
            'Parent',scale_compass,...
            'Color',p.Arrow_Col,...
            'Marker','>',...
            'MarkerIndices',2,...
            'MarkerFaceColor',p.Arrow_Col,...
            'LineWidth',p.Arrow_W);
         th = text(ax,p.Pos(1)+p.X*1.1,p.Pos(2)+p.Y*0.1,p.Up_Str,...
            'Color',p.Str_Col,...
            'FontName','Arial',...
            'FontSize',14,...
            'Parent',scale_compass);
         
         hv = line(ax,[p.Pos(1),p.Pos(1)],[p.Pos(2),p.Pos(2)+p.Y],...
            'Parent',scale_compass,...
            'Color',p.Arrow_Col,...
            'Marker','^',...
            'MarkerIndices',2,...
            'MarkerFaceColor',p.Arrow_Col,...
            'LineWidth',p.Arrow_W);
         tv = text(ax,p.Pos(1)+p.X*0.1,p.Pos(2)+p.Y*1.1,p.Up_Str,...
            'Color',p.Str_Col,...
            'FontName','Arial',...
            'FontSize',14,...
            'Parent',scale_compass);
         
         
      end
      
      % Set axes properties in constructor
      function ax = setAxProperties(ax)
         p = ratskull_plot.def('Axes');
         ax.XLim = p.XLim;
         ax.YLim = p.YLim;
         ax.XTick = p.XTick;
         ax.YTick = p.YTick;
         ax.NextPlot = p.NextPlot;
      end
      
      % Set figure properties in constructor
      function fig = setFigProperties(fig)
         p = ratskull_plot.def('Fig');
         if isempty(get(fig,'Name'))
            set(fig,'Name',p.Name);
         end
         
         fig.Color = p.Col;
         fig.Units = p.Units;
         fig.Position = p.Pos;
      end
   end
   
   methods (Access = public, Static = true)
      function param = def(name)
         % DEF  Static method to return ratskull_plot defaults
         
         % Defaults struct
         p = struct;
         
         % Image
         p.Image.CData = utils.load_ratskull_plot_img('low');
         p.Image.XData = [-11, 9.65];    % mm
         p.Image.YData = [-6.10 7.00];    % mm
         
         % Axes
         p.Axes.XLim = [-6.50 6.50]; % mm
         p.Axes.YLim = [-5.50 5.50]; % mm
         p.Axes.XTick = [];
         p.Axes.YTick = [];
         p.Axes.NextPlot = 'add';
         
         % Bregma
         p.Bregma.Theta = linspace(-pi,pi,180);
         p.Bregma.R = 0.20;
         p.Bregma.X = cos(p.Bregma.Theta) * p.Bregma.R;
         p.Bregma.Y = sin(p.Bregma.Theta) * p.Bregma.R;
         p.Bregma.C = 'r';
         
         % Figure
         p.Fig.Name = 'Rat Skull Plot';
         p.Fig.Col = 'w';
         p.Fig.Units = 'Normalized';
         p.Fig.Pos = [0.15+randn*0.01 0.1+randn*0.01 0.55 0.75]; % jitter
         
         % Scale_Compass
         p.Scale.X = 1.0; % mm
         p.Scale.Y = 1.0; % mm
         p.Scale.Pos = [-5.00,-5.00]; % mm
         p.Scale.Up_Str = '1 mm';
         p.Scale.R_Str = '1 mm (Rostral)';
         p.Scale.Arrow_Col = [0 0 0];
         p.Scale.Arrow_W = 1.25;
         p.Scale.Str_Col = [0 0 0];
         
         % Scatter
         p.Scatter.MarkerSize = 100;
         p.Scatter.MarkerEdgeColor = 'none';
         p.Scatter.MarkerFaceColor = 'k';
         p.Scatter.Marker = 'o';
         p.Scatter.MarkerFaceAlpha = 0.6;
         p.Scatter.Parent = [];
         p.Scatter.GroupName = 'Electrodes';
         
         % Parse output
         if nargin == 1
            if ismember(name,fieldnames(p))
               param = p.(name);
            else % Check capitalization just in case
               f = fieldnames(p);
               idx = ismember(lower(f),lower(name));
               if any(idx)
                  param = p.(f{find(idx,1,'first')});
               else % OK it just isn't a field:
                  error('%s is not a valid parameter. Check spelling?',lower(name));
               end
            end
         elseif nargin == 0
            param = p;
         end
      end
   end
   
end

