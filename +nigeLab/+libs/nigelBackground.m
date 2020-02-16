classdef nigelBackground < matlab.mixin.SetGet & matlab.mixin.Copyable
   %NIGELBACKGROUND  Small class to force axes to have nice "shape" in bg
   %
   %  Because Mathworks does not have 'Curvature' property for Axes.
   %  Also, allows you to set the font color for X- and Y- axes
   %  independently of the axes colors.
   %
   %  >> obj = nigeLab.libs.nigelBackground(ax);
   %     --> ax is `matlab.graphics.axis.Axes` object (for example, gca)
   %
   %  >> obj = nigeLab.libs.nigelBackground(rectObj);
   %     --> ax is `matlab.graphics.primitive.Rectangle` object to be set 
   %         as "background" object
   %
   %  >> obj = nigeLab.libs.nigelBackground(__,'name',value,...);
   %     --> Constructor can take 'name',value property pair lists
   
   properties (Dependent,Access=public)
      Axes                       
      AlignVertexCenters         char   = 'off'
      BeingDeleted               char   = 'off'
      ButtonDownFcn              
      Children                   
      CurrentPoint               double
      Color                             = 'none'
      Curvature            (1,2) double = [0.2 0.2]
      EdgeColor                         = 'none'
      FaceColor                         = [0.9 0.9 0.9]
      FontName                   char   = 'DroidSans'
      FontSize                   double = 13
      FontWeight                 char   = 'bold'
      LineStyle                  char   = 'none'
      LineWidth            (1,1) double = 1
      NextPlot                   char   = 'replacechildren'
      Parent  
      Position             (1,4) double  % Axes Position
      RectPosition         (1,4) double  % Rectangle Position (data units)
      Title   
      Tag                        char
      UIContextMenu 
      Units                      char
      UserData
      View                 (1,2) double = [0 90]
      XAxisLocation              char   = 'bottom'
      XColor                            = [1 1 1]
      XLabel                       
      XLim                 (1,2) double  
      XLimMode                   char   = 'auto'
      XTick
      XTickLabelColor
      XTickLabelFont
      XTickLabels
      XTickMode                  char   = 'auto'
      YAxisLocation              char   = 'left'
      YColor                            = 'none'
      YLabel   
      YLim                 (1,2) double
      YLimMode                   char   = 'auto'
      YTick
      YTickLabelColor                   
      YTickLabelFont
      YTickLabels
      YTickMode                  char   = 'auto'
   end
   
   properties (Dependent,SetObservable,Access=public)
      Rectangle
   end
   
   properties (Hidden,Access=public)
      Rectangle_ 
   end
   
   properties (Access=protected)
      AlignVertexCenters_         char   = 'off'
      BeingDeleted_               char   = 'off'
      ButtonDownFcn_
      Children_
      Color_                             = 'none'
      CopiedRectangle_ 
      Curvature_            (1,2) double = [0.2 0.2]
      EdgeColor_                         = 'none'
      FaceColor_                         = [0.9 0.9 0.9]
      FontName_                   char   = 'DroidSans'
      FontSize_                   double = 13
      FontWeight_                 char   = 'bold'
      IsEmpty_              (1,1) logical = true
      LineStyle_                  char   = 'none'
      LineWidth_            (1,1) double = 1
      NextPlot_                   char   = 'replacechildren'
      Parent_                              % "Parent" Axes handle
      Position_             (1,4) double   % Position of "Parent" Axes
      RectPosition_         (1,4) double   % Position of rectangle
      Tag_                        char
      Title_          
      UIContextMenu_  
      Units_                      char
      UserData_
      View_                 (1,2) double = [0 90]
      XAxisLocation_              char   = 'bottom'
      XColor_                            = [1 1 1]
      XLabel_   
      XLim_                 (1,2) double
      XLimMode_                   char   = 'auto'
      XTick_
      XTickLabels_                
      XTickMode_                  char   = 'auto'
      YAxisLocation_              char   = 'left'
      YColor_                            = 'none'
      YLabel_   
      YLim_                 (1,2) double
      YLimMode_                   char   = 'auto'
      YTick_
      YTickLabels_                
      YTickMode_                  char   = 'auto'
   end
   
   properties (Transient,GetAccess=public,SetAccess=protected)
      Listener      % Listener that keeps the Rectangle the correct size
   end
   
   properties (Constant,Access=public)
      Clipping       char = 'off'
      HitTest        char = 'off'
      IconStyle      char = 'off'
      PickableParts  char = 'none'
      Type           char = 'nigelBackground'
   end
   
   methods (Access=public)
      % Constructor
      function obj = nigelBackground(ax,varargin)
         %NIGELBACKGROUND  Small class to force axes to have nice "shape"
         %
         %  >> obj = nigeLab.libs.nigelBackground(ax);
         %     --> ax is `matlab.graphics.axis.Axes` object (e.g. gca)
         %
         %  >> obj = nigeLab.libs.nigelBackground(rectObj);
         %     --> ax is `rectangle` object to be set as "background" object
         %
         %  >> obj = nigeLab.libs.nigelBackground(__,'name',value,...);
         %     --> Constructor can take 'name',value property pair lists
         
         if nargin < 1
            ax = gca;
         end
         
         switch class(ax)
            case 'matlab.graphics.axis.Axes'
               pos = [ax.XLim(1),ax.YLim(1),diff(ax.XLim),diff(ax.YLim)];
               obj.Rectangle = rectangle(ax,...
                  'Position',pos,...
                  'Curvature',obj.Curvature_,...
                  'LineStyle',obj.LineStyle_,...
                  'LineWidth',obj.LineWidth_,...
                  'AlignVertexCenters',obj.AlignVertexCenters_,...
                  'FaceColor',obj.FaceColor_,...
                  'EdgeColor',obj.EdgeColor_...
                  );
            case 'matlab.graphics.primitive.Rectangle'
               obj.Rectangle = ax;
               obj.Parent = ax.Parent;
            case 'matlab.ui.container.Panel'
               ax = axes(ax);
               ax.FontName = obj.FontName_;
               ax.FontSize = obj.FontSize_;
               ax.FontWeight = obj.FontWeight_;
               ax.NextPlot = obj.NextPlot_;
               ax.View = obj.View_;
               ax.XAxisLocation = obj.XAxisLocation_;
               ax.XColor = obj.XColor_;
               ax.YAxisLocation = obj.YAxisLocation_;
               ax.YColor = obj.YColor_;
               pos = [ax.XLim(1), ax.YLim(1), diff(ax.XLim), diff(ax.YLim)];
               obj.Rectangle = rectangle(ax,...
                  'Position',pos,...
                  'Curvature',obj.Curvature_,...
                  'LineStyle',obj.LineStyle_,...
                  'LineWidth',obj.LineWidth_,...
                  'AlignVertexCenters',obj.AlignVertexCenters_,...
                  'FaceColor',obj.FaceColor_,...
                  'EdgeColor',obj.EdgeColor_...
                  );
            case 'matlab.ui.Figure'
               ax = axes(ax);
               ax.FontName = obj.FontName_;
               ax.FontSize = obj.FontSize_;
               ax.FontWeight = obj.FontWeight_;
               ax.NextPlot = obj.NextPlot_;
               ax.View = obj.View_;
               ax.XAxisLocation = obj.XAxisLocation_;
               ax.XColor = obj.XColor_;
               ax.YAxisLocation = obj.YAxisLocation_;
               ax.YColor = obj.YColor_;
               pos = [ax.XLim(1), ax.YLim(1), diff(ax.XLim), diff(ax.YLim)];
               obj.Rectangle = rectangle(ax,...
                  'Position',pos,...
                  'Curvature',obj.Curvature_,...
                  'LineStyle',obj.LineStyle_,...
                  'LineWidth',obj.LineWidth_,...
                  'AlignVertexCenters',obj.AlignVertexCenters_,...
                  'FaceColor',obj.FaceColor_,...
                  'EdgeColor',obj.EdgeColor_...
                  );
            otherwise
               if isnumeric(ax)
                  if numel(ax) < 2
                     ax = [zeros(1,2-numel(ax)), ax];
                     obj = repmat(obj,ax);
                     for i = 2:numel(obj)
                        obj(i) = copy(obj(1));
                     end
                     return;
                  end
               elseif ischar(ax) % Then 'Name', value pairs already
                  varargin = [ax, varargin];
                  ax = gca;
                  ax.FontName = obj.FontName_;
                  ax.FontSize = obj.FontSize_;
                  ax.FontWeight = obj.FontWeight_;
                  ax.NextPlot = obj.NextPlot_;
                  ax.View = obj.View_;
                  ax.XAxisLocation = obj.XAxisLocation_;
                  ax.XColor = obj.XColor_;
                  ax.YAxisLocation = obj.YAxisLocation_;
                  ax.YColor = obj.YColor_;
                  obj.Rectangle = rectangle(ax,...
                     'Position',[0 0 1 1],...
                     'Curvature',obj.Curvature_,...
                     'LineStyle',obj.LineStyle_,...
                     'LineWidth',obj.LineWidth_,...
                     'AlignVertexCenters',obj.AlignVertexCenters_,...
                     'FaceColor',obj.FaceColor_,...
                     'EdgeColor',obj.EdgeColor_...
                     );
               else
                  error(['nigeLab:' mfilename ':BadClass'],...
                     '[NIGELBACKGROUND]: Bad input class');
               end
         end
         
         % Move Rectangle to bottom if it is not already
         if strcmp(obj.Parent.NextPlot,'replace')
            obj.Parent.NextPlot = 'replacechildren';
         end
         uistack(obj.Rectangle,'bottom');
         
         obj.Listener = [...
            addlistener(obj.Parent,'NextPlot','PostSet',@obj.fixNextPlot),...
            addlistener(obj.Parent,'XLim','PostSet',@obj.updateXPos), ...
            addlistener(obj.Parent,'YLim','PostSet',@obj.updateYPos), ...
            addlistener(obj,'Rectangle','PostSet',@obj.reAddRectangle)...
            ];
         
         for iV = 1:2:numel(varargin)
            set(obj,varargin{iV},varargin{iV+1});
         end
         obj.IsEmpty_ = false; % Has been properly constructed
      end
   end
   
   methods (Access=protected) 
      function fixNextPlot(obj,~,~)
         if strcmp(obj.Parent.NextPlot,'replace')
            obj.Parent.NextPlot = 'replacechildren';
         end
      end
      
      function holdRectangle(obj,~,~,state)
         switch state
            case 'on' % nigelBackgorund BeingDeleted: remove Rectangle
               if ~isempty(obj.Rectangle_)
                  if isvalid(obj.Rectangle_)
                     obj.Rectangle_.DeleteFcn = [];
                  end
               end
            case 'off' % nigelBackground not deleted: keep Rectangle
               obj.CopiedRectangle_ = rectangle(obj.Parent_);
               
               obj.CopiedRectangle_.AlignVertexCenters = obj.Rectangle.AlignVertexCenters;
               obj.CopiedRectangle_.Curvature = obj.Rectangle.Curvature;
               obj.CopiedRectangle_.EdgeColor = obj.Rectangle.EdgeColor;
               obj.CopiedRectangle_.FaceColor = obj.Rectangle.FaceColor;
               obj.CopiedRectangle_.LineStyle = obj.Rectangle.LineStyle;
               obj.CopiedRectangle_.LineWidth = obj.Rectangle.LineWidth;
               obj.CopiedRectangle_.Parent = obj.Rectangle.Parent;
               obj.CopiedRectangle_.Position = obj.Rectangle.Position;
               obj.CopiedRectangle_.Tag = obj.Rectangle.Tag;
               obj.CopiedRectangle_.UserData = obj.Rectangle.UserData;
               
               obj.Rectangle = [];
               % set(obj.Rectangle,_) should be called via external delete
         end
      end
      
      function reAddRectangle(obj,~,~)
         if isempty(obj.CopiedRectangle_)
            return;
         elseif ~isvalid(obj.CopiedRectangle_)
            return;
         else
            value = obj.CopiedRectangle_;
            obj.CopiedRectangle_(:) = [];
            obj.Rectangle = value;
         end
      end
      
      function updateXPos(obj,~,~)
         x = obj.Parent.XLim;
         pos = obj.RectPosition_;
         pos(1) = x(1);
         pos(3) = x(2) - x(1);
         obj.RectPosition = pos;
      end
      
      function updateYPos(obj,~,~)
         y = obj.Parent.YLim;
         pos = obj.RectPosition_;
         pos(2) = y(1);
         pos(4) = y(2) - y(1);
         obj.RectPosition = pos;
      end
   end
   
   methods
      % Set current axes
      function axes(obj)
         axes(obj.Axes);
      end
      
      % Clear axes
      function cla(obj)
         cla(obj.Axes);
      end
      
      % Overload delete to ensure Rectangle is destroyed
      function delete(obj)
         obj.BeingDeleted = 'on';
         
         if ~isempty(obj.Rectangle)
            if isvalid(obj.Rectangle)
               delete(obj.Rectangle);
            end
         end
         
         if ~isempty(obj.Listener)
            for i = 1:numel(obj.Listener)
               if isvalid(obj.Listener(i))
                  delete(obj.Listener(i));
               end
            end
         end
      end
      
      % Overload `isempty` 
      function tf = isempty(obj)
         tf = builtin('isempty',obj);
         if tf
            return;
         else
            if numel(obj) > 1
               tf = false(size(obj));
               for i = 1:numel(obj)
                  tf(i) = isempty(obj(i));
               end
               return;
            end
            tf = obj.IsEmpty_;
         end
      end
      
      % Add legend to axes
      function h = legend(obj,varargin)
         h = legend(obj.Axes,varargin{:});
      end
         
      % Add line object to axes
      function h = line(obj,x,y,varargin)
         h = line(obj.Axes,x,y,varargin{:});
      end
      
      % Add patch to axes
      function h = patch(obj,varargin)
         h = patch(obj.Axes,varargin{:});
      end
      
      % Plot on axes
      function h = plot(obj,x,y,varargin)
         if nargin < 3
            y = x;
            x = 1:numel(y);
         end
         h = plot(obj.Axes,x,y,varargin{:});
      end
      
      % Add rectangle to axes
      function h = rectangle(obj,varargin)
         h = rectangle(obj.Axes,varargin{:});
      end
      
      % Add stem to axes
      function h = stem(obj,x,y,varargin)
         if nargin < 3
            y = ones(size(x));
         end
         h = stem(obj.Axes,x,y,varargin{:});
      end
      
      % Add text to axes
      function h = text(obj,x,y,str,varargin)
         h = text(obj.Axes,x,y,str,varargin{:});
      end
      
      % Overload title
      function title(obj,str,varargin)
         obj.Title.String = str;
         for iV = 1:2:numel(varargin)
            set(obj.Title,varargin{iV},varargin{iV+1});
         end
      end
      
      % Overload xlabel
      function xlabel(obj,str,varargin)
         obj.XLabel.String = str;
         for iV = 1:2:numel(varargin)
            set(obj.XLabel,varargin{iV},varargin{iV+1});
         end
      end
      
      % Overload xlim
      function xlim(obj,XLim)
         xlim(obj.Axes,XLim);
      end
      
      % Overload ylabel
      function ylabel(obj,str,varargin)
         obj.YLabel.String = str;
         for iV = 1:2:numel(varargin)
            set(obj.YLabel,varargin{iV},varargin{iV+1});
         end
      end
      
      % Overload ylim
      function ylim(obj,YLim)
         ylim(obj.Axes,YLim);
      end
      
      function value = get.Axes(obj)
         value = obj.Parent_;
      end
      function set.Axes(obj,value)
         obj.Parent_ = value;
      end
      
      function value = get.AlignVertexCenters(obj)
         value = obj.AlignVertexCenters_;
      end
      function set.AlignVertexCenters(obj,value)
         obj.AlignVertexCenters_ = value;
         obj.Rectangle.AlignVertexCenters = value;
      end
      
      function value = get.BeingDeleted(obj)
         value = obj.BeingDeleted_;
      end
      function set.BeingDeleted(obj,value)
         obj.BeingDeleted_ = value;
         if isempty(obj.Rectangle_)
            return;
         elseif ~isvalid(obj.Rectangle_)
            return;
         end
         obj.Rectangle_.DeleteFcn = ...
            @(src,evt,state)obj.holdRectangle(src,evt,value);
      end
      
      function value = get.ButtonDownFcn(obj)
         value = obj.ButtonDownFcn_;
      end
      function set.ButtonDownFcn(obj,value)
         obj.ButtonDownFcn_ = value;
         obj.Parent_.ButtonDownFcn = value;
      end
      
      function value = get.Children(obj)
         value = obj.Children_;
      end
      function set.Children(obj,value)
         obj.Children_ = value;
         obj.Parent_.Children = value;
      end
      
      function value = get.Color(obj)
         value = obj.Color_;
      end
      function set.Color(obj,value)
         if ischar(value) && ~strcmpi(value,'none')
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         else
            C = value;
         end
         obj.Color_ = C;
         obj.Parent_.Color = C;
      end
      
      function value = get.CurrentPoint(obj)
         value = obj.Parent_.CurrentPoint;
      end
      function set.CurrentPoint(~,~)
         warning('Cannot set READ-ONLY property: <strong>CurrentPoint</strong>');
      end
      
      function value = get.Curvature(obj)
         value = obj.Curvature_;
      end
      function set.Curvature(obj,value)
         obj.Curvature_ = value;
         obj.Rectangle.Curvature = value;
      end
      
      function value = get.EdgeColor(obj)
         value = obj.EdgeColor_;
      end
      function set.EdgeColor(obj,value)
         if ischar(value) && ~strcmpi(value,'none')
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         else
            C = value;
         end
         obj.EdgeColor_ = C;
         obj.Rectangle.EdgeColor = C;
      end
      
      function value = get.FaceColor(obj)
         value = obj.FaceColor_;
      end
      function set.FaceColor(obj,value)
         
         if ischar(value) && ~strcmpi(value,'none')
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         else
            C = value;
         end
         obj.FaceColor_ = C;
         obj.Rectangle.FaceColor = C;
      end
      
      function value = get.FontName(obj)
         value = obj.FontName_;
      end
      function set.FontName(obj,value)
         obj.FontName_ = value;
         obj.Parent_.FontName = value;
         obj.Parent_.XAxis.FontName = value;
         obj.Parent_.YAxis.FontName = value;
      end
      
      function value = get.FontSize(obj)
         value = obj.FontSize_;
      end
      function set.FontSize(obj,value)
         obj.FontSize_ = value;
         obj.Parent_.FontSize = value;
         obj.Parent_.XAxis.FontSize = value;
         obj.Parent_.YAxis.FontSize = value;
      end
      
      function value = get.FontWeight(obj)
         value = obj.FontWeight_;
      end
      function set.FontWeight(obj,value)
         obj.FontWeight_ = value;
         obj.Parent_.FontWeight = value;
      end
      
      function value = get.LineStyle(obj)
         value = obj.LineStyle_;
      end
      function set.LineStyle(obj,value)
         obj.LineStyle_ = value;
         obj.Rectangle.LineStyle = value;
      end
      
      function value = get.LineWidth(obj)
         value = obj.LineWidth_;
      end
      function set.LineWidth(obj,value)
         obj.LineWidth_ = value;
         obj.Rectangle.LineWidth = value;
      end
      
      function value = get.NextPlot(obj)
         value = obj.NextPlot_;
      end
      function set.NextPlot(obj,value)
         obj.NextPlot_ = value;
         obj.Parent_.NextPlot = value;
      end
      
      function value = get.Parent(obj)
         value = obj.Parent_;
      end
      function set.Parent(obj,value)
         if isempty(value)
            return;
         elseif ~isvalid(value)
            return;
         end
         obj.ButtonDownFcn_ = value.ButtonDownFcn;
         obj.Children_ = value.Children;
         obj.Color_ = value.Color;
         obj.FontName_ = value.FontName;
         obj.FontSize_ = value.FontSize;
         obj.FontWeight_ = value.FontWeight;
         obj.NextPlot_ = value.NextPlot;
         obj.Position_ = value.Position;
         obj.Title_ = value.Title;
         obj.UIContextMenu_ = value.UIContextMenu;
         obj.Units_ = value.Units;
         obj.UserData_ = value.UserData;
         obj.View_ = value.View;
         obj.XAxisLocation_ = value.XAxisLocation;
         obj.XColor_ = value.XColor;
         obj.XLabel_ = value.XLabel;
         obj.XLim_ = value.XLim;
         obj.XLimMode = value.XLimMode;
         obj.XTick_ = value.XTick;
         obj.XTickLabels_ = value.XTickLabels;
         obj.XTickMode_ = value.XTickMode;
         obj.YAxisLocation_ = value.YAxisLocation;
         obj.YColor_ = value.YColor;
         obj.YLim_ = value.YLim;
         obj.YLabel_ = value.YLabel;
         obj.YLimMode_ = value.YLimMode;
         obj.YTick_ = value.YTick;
         obj.YTickLabels_ = value.YTickLabels;
         obj.YTickMode_ = value.YTickMode;
         
         obj.Parent_ = value;
         obj.Rectangle.Parent = value;
      end
      
      function value = get.Position(obj)
         value = obj.Position_;
      end
      function set.Position(obj,value)
         obj.Position_ = value;
         obj.Parent_.Position = value;
      end
      
      function value = get.Rectangle(obj)
         value = obj.Rectangle_;
      end
      function set.Rectangle(obj,value)
         % Need to check here in case it is set after deletion
         if isempty(value)
            return;
         elseif isstruct(value)
            return;
         elseif ~isvalid(value)
            return;
         elseif strcmpi(value.BeingDeleted,'on')
            return;
         end
         
         value.Clipping = obj.Clipping;
         value.HitTest = obj.HitTest;
         
         value.PickableParts = obj.PickableParts;   
         value.DeleteFcn = ...
            @(src,evt,state)obj.holdRectangle(src,evt,obj.BeingDeleted_);
         
         obj.AlignVertexCenters_ = value.AlignVertexCenters;
         obj.Curvature_ = value.Curvature;
         obj.EdgeColor_ = value.EdgeColor;
         obj.FaceColor_ = value.FaceColor;
         obj.LineStyle_ = value.LineStyle;
         obj.LineWidth_ = value.LineWidth;
         obj.RectPosition_ = value.Position;
         obj.Tag_ = value.Tag;
         obj.UserData_ = value.UserData;
         
         obj.Parent = value.Parent;
         
         obj.Rectangle_ = value;
      end
      
      function value = get.RectPosition(obj)
         value = obj.RectPosition_;
      end
      function set.RectPosition(obj,value)
         obj.RectPosition_ = value;
         obj.Rectangle.Position = value;
      end
      
      function value = get.Tag(obj)
         value = obj.Tag_;
      end
      function set.Tag(obj,value)
         obj.Tag_ = value;
         obj.Rectangle.Tag = value;
      end
      
      function value = get.Title(obj)
         value = obj.Title_;
      end
      function set.Title(obj,value)
         obj.Title_ = value;
         obj.Parent_.Title = value;
      end
      
      function value = get.UIContextMenu(obj)
         value = obj.UIContextMenu_;
      end
      function set.UIContextMenu(obj,value)
         obj.UIContextMenu_ = value;
         obj.Parent_.UIContextMenu = value;
      end
      
      function value = get.Units(obj)
         value = obj.Units_;
      end
      function set.Units(obj,value)
         obj.Units_ = value;
         obj.Parent_.Units = value;
      end
      
      function value = get.UserData(obj)
         value = obj.UserData_;
      end
      function set.UserData(obj,value)
         obj.UserData_ = value;
         obj.Rectangle.UserData = value;
      end
      
      function value = get.View(obj)
         value = obj.View_;
      end
      function set.View(obj,value)
         obj.View_ = value;
         obj.Parent_.View = value;
      end
      
      function value = get.XAxisLocation(obj)
         value = obj.XAXisLocation_;
      end
      function set.XAxisLocation(obj,value)
         obj.XAxisLocation_ = value;
         obj.Parent_.XAxisLocation = value;
      end
      
      function value = get.XColor(obj)
         value = obj.XColor_;
      end
      function set.XColor(obj,value)
         if ischar(value) && ~strcmpi(value,'none')
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         else
            C = value;
         end
         obj.XColor_ = C;
         obj.Parent_.XColor = C;
      end
      
      function value = get.XLabel(obj)
         value = obj.XLabel_;
      end
      function set.XLabel(obj,value)
         obj.XLabel_ = value;
         obj.Parent_.XLabel = value;
      end
      
      function value = get.XLim(obj)
         value = obj.XLim_;
      end
      function set.XLim(obj,value)
         obj.XLim_ = value;
         obj.Parent_.XLim = value;
         obj.XLimMode = 'manual';
      end
      
      function value = get.XLimMode(obj)
         value = obj.XLimMode_;
      end
      function set.XLimMode(obj,value)
         obj.XLimMode_ = value;
         obj.Parent_.XLimMode = value;
      end
      
      function value = get.XTick(obj)
         value = obj.XTick_;
      end
      function set.XTick(obj,value)
         obj.XTick_ = value;
         obj.Parent_.XTick = value;
         obj.XTickMode = 'manual';
      end
      
      function value = get.XTickLabelColor(obj)
         if isempty(obj.Axes.XTickLabels)
            value = obj.Axes.XColor;
            return;
         else
            str = obj.Axes.XTickLabels{1};
         end
         iStart = regexp(str,'\\color\[rgb\]{')+12;
         if isempty(iStart)
            value = obj.Axes.XColor;
            return;
         else
            iEnd = regexp(str,'}')-1;
         end
         strCol = str(iStart:iEnd);
         str = strsplit(strCol,',');
         value = zeros(1,3);
         for i = 1:3
            value(i) = str2double(str{i});
         end
      end
      function set.XTickLabelColor(obj,value)
         lab = obj.XTickLabels_;
         if isempty(lab)
            return;
         end
         
         if ischar(value)
            if strcmpi(value,'none')
               C = obj.Parent_.Color;
            elseif isempty(value)
               C = nan;
            else
               C = nigeLab.defaults.nigelColors(value);
            end
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && (max(value) > 1)
            C = value./256; 
         elseif isempty(value)
            C = nan;
         else
            C = value;
         end
         if isnan(C)
            str = '';
         else
            str = sprintf('%6.4f,%6.4f,%6.4f',C(1),C(2),C(3));
         end
         newLab = nigeLab.libs.nigelBackground.replaceColorLabels(lab,str);
         obj.XTickLabels_ = newLab;
         obj.Axes.XTickLabels = newLab;
         
         if isempty(str)
            return;
         end
         
         axCol = obj.Axes.XColor;
         if ischar(axCol) && strcmpi(axCol,'none')
            if ~isempty(obj.Axes.Parent)
               if isprop(obj.Axes.Parent,'Color')
                  obj.XColor = get(obj.Axes.Parent,'Color');
               else
                  obj.XColor = get(obj.Axes.Parent,'BackgroundColor');
               end
            end
         end
      end
      
      function value = get.XTickLabelFont(obj)
         if isempty(obj.Axes.XTickLabels)
            value = obj.Axes.FontName;
            return;
         else
            str = obj.Axes.XTickLabels{1};
         end
         iStart = regexp(str,'\\fontname{')+9;
         if isempty(iStart)
            value = obj.Axes.FontName;
         else
            iEnd = regexp(str,'}')-1;
            value = str(iStart:iEnd);
         end
      end
      function set.XTickLabelFont(obj,value)
         lab = obj.XTickLabels_;
         if isempty(lab)
            return;
         end
         newLab = nigeLab.libs.nigelBackground.replaceFontLabels(lab,value);
         obj.XTickLabels_ = newLab;
         obj.Axes.XTickLabels = newLab;
      end
      
      function value = get.XTickLabels(obj)
         value = obj.XTickLabels_;
      end
      function set.XTickLabels(obj,value)
         obj.XTickLabels_ = value;
         obj.Parent_.XTickLabels = value;
      end
      
      function value = get.XTickMode(obj)
         value = obj.XTickMode_;
      end
      function set.XTickMode(obj,value)
         obj.XTickMode_ = value;
         obj.Parent_.XTickMode = value;
      end
      
      function value = get.YAxisLocation(obj)
         value = obj.YAXisLocation_;
      end
      function set.YAxisLocation(obj,value)
         obj.YAxisLocation_ = value;
         obj.Parent_.YAxisLocation = value;
      end
      
      function value = get.YColor(obj)
         value = obj.YColor_;
      end
      function set.YColor(obj,value)
         if ischar(value) && ~strcmpi(value,'none')
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         else
            C = value;
         end
         obj.YColor_ = C;
         obj.Parent_.YColor = C;
      end
      
      function value = get.YLabel(obj)
         value = obj.YLabel_;
      end
      function set.YLabel(obj,value)
         obj.YLabel_ = value;
         obj.Parent_.YLabel = value;
      end
      
      function value = get.YLim(obj)
         value = obj.YLim_;
      end
      function set.YLim(obj,value)
         obj.YLim_ = value;
         obj.Parent_.YLim = value;
         obj.YLimMode = 'manual';
      end
      
      function value = get.YLimMode(obj)
         value = obj.YLimMode_;
      end
      function set.YLimMode(obj,value)
         obj.YLimMode_ = value;
         obj.Parent_.YLimMode = value;
      end
      
      function value = get.YTick(obj)
         value = obj.YTick_;
      end
      function set.YTick(obj,value)
         obj.YTick_ = value;
         obj.Parent_.YTick = value;
         obj.YTickMode = 'manual';
      end
      
      function value = get.YTickLabelColor(obj)
         if isempty(obj.Axes.YTickLabels)
            value = obj.Axes.YColor;
            return;
         else
            str = obj.Axes.YTickLabels{1};
         end
         
         iStart = regexp(str,'\\color\[rgb\]{')+12;
         if isempty(iStart)
            value = obj.Axes.YColor;
            return;
         else
            iEnd = regexp(str,'}')-1;
         end
         strCol = str(iStart:iEnd);
         str = strsplit(strCol,',');
         value = zeros(1,3);
         for i = 1:3
            value(i) = str2double(str{i});
         end
      end
      function set.YTickLabelColor(obj,value)
         lab = obj.YTickLabels_;
         if isempty(lab)
            return;
         end
         
         if ischar(value)
            if strcmpi(value,'none')
               C = obj.Parent_.Color;
            elseif isempty(value)
               C = nan;
            else
               C = nigeLab.defaults.nigelColors(value);
            end
         elseif isnumeric(value) && isscalar(value)
            C = nigeLab.defaults.nigelColors(value);
         elseif isnumeric(value) && (max(value) > 1)
            C = value./256; 
         elseif isempty(value)
            C = nan;
         else
            C = value;
         end
         
         if isnan(C)
            str = '';
         else
            str = sprintf('%6.4f,%6.4f,%6.4f',C(1),C(2),C(3));
         end
         
         newLab = nigeLab.libs.nigelBackground.replaceColorLabels(lab,str);
         obj.YTickLabels_ = newLab;
         obj.Axes.YTickLabels = newLab;
         
         if isempty(str)
            return;
         end
         
         axCol = obj.Axes.YColor;
         if ischar(axCol) && strcmpi(axCol,'none')
            if ~isempty(obj.Axes.Parent)
               if isprop(obj.Axes.Parent,'Color')
                  obj.YColor = get(obj.Axes.Parent,'Color');
               else
                  obj.YColor = get(obj.Axes.Parent,'BackgroundColor');
               end
            end
         end
      end
      
      function value = get.YTickLabelFont(obj)
         if isempty(obj.Axes.YTickLabels)
            value = obj.Axes.FontName;
            return;
         else
            str = obj.Axes.YTickLabels{1};
         end
         iStart = regexp(str,'\\fontname{')+9;
         if isempty(iStart)
            value = obj.Axes.FontName;
         else
            iEnd = regexp(str,'}')-1;
            value = str(iStart:iEnd);
         end
      end
      function set.YTickLabelFont(obj,value)
         lab = obj.YTickLabels_;
         if isempty(lab)
            return;
         end
         
         newLab = nigeLab.libs.nigelBackground.replaceFontLabels(lab,value);
         obj.YTickLabels_ = newLab;
         obj.Axes.YTickLabels = newLab;
      end
      
      function value = get.YTickLabels(obj)
         value = obj.YTickLabels_;
      end
      function set.YTickLabels(obj,value)
         obj.YTickLabels_ = value;
         obj.Parent_.YTickLabels = value;
      end
      
      function value = get.YTickMode(obj)
         value = obj.YTickMode_;
      end
      function set.YTickMode(obj,value)
         obj.YTickMode_ = value;
         obj.Parent_.YTickMode = value;
      end
   end
   
   methods (Static,Access=protected)
      function lab_out = replaceColorLabels(lab_in,str)
         lab_out = cell(size(lab_in));
         if isempty(str)
            for i = 1:numel(lab_in)
               iStart = regexp(lab_in{i},'\\color\[rgb\]');
               if ~isempty(iStart)
                  iStop = regexp(lab_in{i},'}');
                  iStop = iStop(find(iStop>iStart,1,'first'));
                  lab_in{i}(iStart:iStop) = [];
               end
               lab_out{i} = lab_in{i};
            end
         else
            for i = 1:numel(lab_in)
               iStart = regexp(lab_in{i},'\\color\[rgb\]');
               if ~isempty(iStart)
                  iStop = regexp(lab_in{i},'}');
                  iStop = iStop(find(iStop>iStart,1,'first'));
                  lab_in{i}(iStart:iStop) = [];
               end
               lab_out{i} = ['\color[rgb]{' str '} ' lab_in{i}];
            end
         end
      end
      
      function lab_out = replaceFontLabels(lab_in,str)
         lab_out = cell(size(lab_in));
         if isempty(str)
            for i = 1:numel(lab_in)
               iStart = regexp(lab_in{i},'\\fontname{');
               if ~isempty(iStart)
                  iStop = regexp(lab_in{i},'}');
                  iStop = iStop(find(iStop>iStart,1,'first'));
                  lab_in{i}(iStart:iStop) = [];
               end
               lab_out{i} = lab_in{i};
            end
         else
         
            for i = 1:numel(lab_in)
               iStart = regexp(lab_in{i},'\\fontname{');
               if ~isempty(iStart)
                  iStop = regexp(lab_in{i},'}');
                  iStop = iStop(find(iStop>iStart,1,'first'));
                  lab_in{i}(iStart:iStop) = [];
               end
               lab_out{i} = ['\fontname{' str '} ' lab_in{i}];
            end
         end
      end
   end
   
end

