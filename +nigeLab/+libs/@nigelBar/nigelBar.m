classdef nigelBar < handle & matlab.mixin.SetGet
   %NIGELBAR   Bar that goes across title of nigelDash GUI
   %
   %  barObj = nigeLab.libs.nigelBar(parent);
   %  barObj = nigeLab.libs.nigelBar(parent,'propName1',propVal1,...);
   
   % % % PROPERTIES % % % % % % % % % %
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      BackgroundColor   (1,3) double = [0.00,0.00,0.00] % Panel face color
      FaceColor         (1,3) double = [0.26,0.51,0.76] % Button face color
      FontColor         (1,3) double = [1.00,0.81,0.27] % Font color
      FontName                char = 'Droid Sans'
      Position          (1,4) double = [.01,.93,.98,.06]
      String                  char = ''
      Substr                  char = ''
      Units                   char = 'normalized'
      Visible                 char = 'on'
   end
   
   % PUBLIC
   properties (Dependent,GetAccess=public,SetAccess=protected)
      LeftButtonContainer                       % Left-button container  (Children{1})
      RightButtonContainer                      % Right-button container (Children{2})
      Button           nigeLab.libs.nigelButton % Array of nigeLab.libs.nigelButton objects
   end
   
   % HIDDEN,PUBLIC/PROTECTED
   properties (Hidden,GetAccess=public,SetAccess=protected)
      Children   cell = cell(1,2);% {1} -> Always LEFT button container; {2} -> Always RIGHT button container; 3+ are ALWAYS buttons
   end
   
   % PUBLIC/PROTECTED
   properties(GetAccess=public,SetAccess=protected)
      Parent
      Tag        char = 'nigelBar'
   end
   
   % PROTECTED
   properties(Access=protected)
      ParentListener    event.listener
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods      
      % OVERRIDDEN "class" method
      function [cl,tag] = class(obj)
         % CLASS  Returns the "type" of nigelBar
         %
         %  [cl,tag] = obj.class;
         %
         %  cl  --  string of format sprintf('nigelBar (%s)',obj.Tag);
         %  tag  --  obj.Tag directly
         
         cl = sprintf('nigelBar (%s)', obj.Tag);
         tag = obj.Tag;
      end
      
      % Override `delete` to handle Children destructor
      function delete(obj)
         %DELETE Handles destruction of .Children members
         
         if ~isempty(obj.ParentListener)
            if isvalid(obj.ParentListener)
               delete(obj.ParentListener)
            end
         end
         
         if ~isempty(obj.Children)
            for i = 1:numel(obj.Children)
               if isvalid(obj.Children{i})
                  delete(obj.Children{i});
               end
            end
         end
         
      end
      
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      function value = get.BackgroundColor(obj)
         value = obj.Parent.Color.Panel;
      end
      
      function value = get.Button(obj)
         if numel(obj.Children) <= 2
            value = {};
            return;
         end
         value = obj.Children(3:end);
      end
      
      function value = get.FaceColor(obj)
         value = obj.Parent.Color.TitleBar;
      end
      
      function value = get.FontColor(obj)
         value = obj.Parent.Color.TitleText;
      end
      
      function value = get.FontName(obj)
         value = obj.Parent.FontName;
      end
      
      function value = get.LeftButtonContainer(obj)
         value = obj.Children{1};
      end
      
      function value = get.Position(obj)
         value = obj.Parent.OutPanel.Position;
      end
      
      function value = get.RightButtonContainer(obj)
         value = obj.Children{2};
      end
      
      function value = get.String(obj)
         value = obj.Parent.String;
      end
      
      % Returns all the Button Strings
      function value = get.Substr(obj)
         value = {};
         for k = 1:2 % First two are Left, Right (respectively)
            for i = 1:numel(obj.Children{k}.Children)
               h = findobj(obj.Children{k}.Children(i).Children,'Tag','Label');
               value = [value, h.String]; %#ok<AGROW>
            end
         end
      end
      
      function value = get.Units(obj)
         value = obj.Parent.OutPanel.Units;
      end
      
      function value = get.Visible(obj)
         value = obj.Parent.OutPanel.Visible;
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      function set.BackgroundColor(obj,value)
         obj.Parent.Color.Panel = value;
      end
      
      function set.Button(obj,value)
         if ~isscalar(value)
            error(['nigeLab:' mfilename ':BadAssignment'],...
               '.Button elements must be assigned as scalars');
         end
         obj.Children{end+1} = value;
      end
      
      function set.FaceColor(obj,value)
         if ~isnumeric(value)
            value = nigeLab.defaults.nigelColors(value);
         end
         obj.Parent.Color.TitleBar = value;
         if isempty(obj.Button)
            return;
         end
         for i = 1:numel(obj.Button)
            obj.Button{i}.FaceColorEnable = value;
            obj.Button{i}.FaceColorDisable = value * 0.75;
         end

      end
      
      function set.FontColor(obj,value)
         if ~isnumeric(value)
            value = nigeLab.defaults.nigelColors(value);
         end
         obj.Parent.Color.TitleText=value;
         if isempty(obj.Button)
            return;
         end
         for i = 1:numel(obj.Button)
            obj.Button{i}.FontColorEnable = value;
            obj.Button{i}.FontColorDisable = value * 0.75;
         end

      end
      
      function set.FontName(obj,value)
         obj.Parent.FontName = value;
         if isempty(obj.Button)
            return;
         end
         for i = 1:numel(obj.Button)
            obj.Button{i}.FaceColorEnable = value;
            obj.Button{i}.FaceColorDisable = value * 0.75;
         end
      end
      
      function set.LeftButtonContainer(obj,value)
         obj.Children{1} = value;
      end
      
      function set.Position(obj,value)
         obj.Parent.OutPanel.Position = value;
      end
      
      function set.RightButtonContainer(obj,value)
         obj.Children{2} = value;
      end
      
      function set.String(obj,value)
         obj.Parent.String = value;
      end
      
      % Sets all the Button Strings
      function set.Substr(obj,value)
         if isempty(obj.Button)
            return;
         elseif ~isequal(numel(obj.Button),numel(value))
            nigeLab.utils.cprintf('Errors',...
               ['Number of elements of value (%g) '...
               'must match number of buttons (%g)\n'],...
               numel(value),numel(obj.Button));
            return;
         end
         for i = 1:numel(obj.Button)
            obj.Button{i}.String = value{i};
         end
      end
      
      function set.Units(obj,value)
         obj.Parent.OutPanel.Units = value;
      end
      
      function set.Visible(obj,value)
         obj.Parent.OutPanel.Visible = value;
      end
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % PUBLIC (constructor)
   methods (Access=public)
      % Class constructor for nigeLab.libs.nigelBar handle class
      function obj = nigelBar(parent,varargin)
         %NIGELBAR   Create title bar object for figures
         %  barObj = nigeLab.libs.nigelBar(parent);
         %  barObj = nigeLab.libs.nigelBar(parent,'propName1',val1,...);
         
         if nargin < 1
            parent = nigeLab.libs.nigelPanel(gcf);
         end
         
         for i = 1:2:numel(varargin)
            if isprop(obj,varargin{i})
               set(obj,varargin{i},varargin{i+1});
            end
         end

         obj.Parent = parent;
         obj.ParentListener = addlistener(parent,'ObjectBeingDestroyed',...
            @(~,~)obj.delete);
         
         obj.Children{1} = axes('Units','normalized', ...
            'Tag','ButtonAxes',...
            'Position',[0.00 0.10 0.40 0.40],...
            'Color','none',...
            'XColor','none',...
            'YColor','none',...
            'NextPlot','add',...
            'XLimMode','manual',...
            'XLim',[-0.1 3],...
            'YLimMode','manual',...
            'YLim',[0 1],...
            'FontName','Droid Sans');
         nestObj(obj.Parent,obj.Children{1},'LeftButtonAxes');
         obj.Children{2} = axes('Units','normalized', ...
            'Tag','ButtonAxes',...
            'Position',[0.60 0.10 0.40 0.40],...
            'Color','none',...
            'XColor','none',...
            'YColor','none',...
            'NextPlot','add',...
            'XLimMode','manual',...
            'XLim',[-2.1 1],...
            'YLimMode','manual',...
            'YLim',[0 1],...
            'FontName','Droid Sans');
         nestObj(obj.Parent,obj.Children{2},'RightButtonAxes');
      end
      
      % Adds button to 'left' or 'right' container
      function addButton(obj,side,btn)
         %ADDBUTTON Add button to 'left' or 'right' container
         %
         %  obj.addButton(side,btn);
         %
         %  side: 'left' or 'right' (which side of title to add to)
         %  --> Buttons are always added so that the most-recent button is
         %      the furthest "inside" (regardless of which side)
         %  btn: struct with fields 'String' and 'Callback'
         %        --> Can be array struct

         if nargin < 3
            error(['nigeLab:' mfilename ':BadNumInputs'],...
               'Must provide all three input arguments.');
         end
         
         if ~isstruct(btn)
            error(['nigeLab:' mfilename ':BadClass'],...
               ['"btn" should be struct with ' ...
               'fields ''String'' and ''Callback''']);
         end
         
         if ~isfield(btn,'String')
            error(['nigeLab:' mfilename ':BadStruct'],...
               '"btn" is missing ''String'' field');
         end
         
         if ~isfield(btn,'Callback')
            error(['nigeLab:' mfilename ':BadStruct'],...
               '"btn" is missing ''Callback'' field');
         end
         
         side = strcmpi(side,'right') + 1; % Get index to correct .Children
         scl = -1*(side-1.5)*2;
         for i = 1:numel(btn)
            nButton = numel(obj.Children{side}.Children);
            pos = [scl*nButton 0.05 0.85 0.9];
            b = nigeLab.libs.nigelButton(obj.Children{side},pos,...
               btn(i).String,btn(i).Callback);
            obj.Button = b; 
         end
         
      end
   end
   % % % % % % % % % % END METHODS% % %
end
