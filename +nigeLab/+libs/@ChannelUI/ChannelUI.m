classdef ChannelUI < handle
   % CHANNELUI  Figure window for setting channel info of a parent object
   %
   %  obj = CHANNELUI(parent)
   %
   %  --------
   %   INPUTS
   %  --------
   %   parent     :     Parent class, which has a "UI" property with a "ch"
   %                       field that stores the current channel; and, 
   %                       which has a listener for the 'NewChannel' event.
   %
   %  --------
   %   OUTPUT
   %  --------
   %    obj       :     CHANNELUI object that is a figure with a 
   %                       dropdownbox for setting the current channel.
   %
   % By: Max Murphy  v1.0  2019/01/10  Original version (R2017a)
   
   % % % PROPERTIES % % % % % % % % % %
   % PROTECTED/IMMUTABLE
   properties (GetAccess=protected,SetAccess=immutable)
      FIG_POS  = [0.750,0.850,0.150,0.065];  % Normalized figure position
      FIG_COL  = 'k';                        % Figure background color
      FIG_NAME = 'Channel Selector';         % Figure name
      
      MENU_POS = [0.100,0.100,0.800,0.800];  % Popup menu position in fig
      MENU_FONT = 'Arial';                   % Popup menu font
      MENU_FONT_COLOR = 'k';                 % Popup menu font color
      MENU_FONT_SIZE = 16;                   % Popup menu font size
   end
   
   % PUBLIC/PROTECTED
   properties (GetAccess=public,SetAccess=protected)
      Channel     % (scalar) integer of channel index
      Parent      % Parent nigeLab class object.
      Figure      % Figure graphic handle
      Menu        % Menu graphic handle
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      NewChannel  % Notifies listeners when channel is changed
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded `delete` method to handle Children
      function delete(obj)
         %DELETE  Handles Children destruction
         %
         %  delete(obj);
         
         if ~isempty(obj.Figure)
            if isvalid(obj.Figure)
               delete(obj.Figure);
            end
         end
      end
   end
   
   % PUBLIC
   methods (Access = public)
      function obj = ChannelUI(parent)
         %CHANNELUI  Figure window for setting channel info of a parent
         %
         %  obj = CHANNELUI(parent)
         %
         %  --------
         %   INPUTS
         %  --------
         %   parent     :     Parent class, which has a "UI" property with 
         %                       a "ch" field that stores the current 
         %                       channel; and, which has a listener for 
         %                       the 'NewChannel' event.
         %
         %  --------
         %   OUTPUT
         %  --------
         %    obj       :     CHANNELUI object that is a figure with a 
         %                       dropdownbox for setting the current 
         %                       channel.
         
         % ASSOCIATE OBJECT WITH PARENT
         if isa(parent,'nigeLab.Sort')
            error(['nigeLab:' mfilename ':BadClass'],...
               ['nigeLab.libs.ChannelUI should be called by ' ...
                'nigeLab.libs.SortUI, not nigeLab.Sort']);
         end
         obj.Parent = parent.Parent;
         obj.Channel = parent.channel;
         
         % MAKE FIGURE & GRAPHICS
         obj.Open;
         
      end
      
      function Open(obj)
         % OPEN  Open the figure and menu
         obj.Figure = figure('Name',obj.FIG_NAME, ...
            'ToolBar', 'none', ...
            'NumberTitle','off', ...
            'MenuBar', 'none', ...
            'Units','Normalized',...
            'Color',obj.FIG_COL, ...
            'Position',obj.FIG_POS);
         
         obj.Menu = uicontrol(obj.Figure,...
            'Style','popupmenu',...
            'Units','Normalized',...
            'BackgroundColor','w',...
            'ForegroundColor',obj.MENU_FONT_COLOR,...
            'FontSize',obj.MENU_FONT_SIZE,...
            'FontName',obj.MENU_FONT,...
            'String',obj.Parent.Channels.Name,...
            'Value',obj.Channel,...
            'Callback',@obj.setChannel,...
            'Position',obj.MENU_POS); 
      end
      
      function setChannel(obj,src,~)
         % SETCHANNEL  Update the current channel and notify of this event
         if src.Value ~= obj.Channel
            % Update the parent channel property, and check that it was
            % successful; if so, set the ChannelUI property and notify
            % other potential listeners.
            if set(obj.Parent,'channel',src.Value)
               obj.Channel = src.Value;
               notify(obj,'NewChannel');
            end
         end
      end
       % % % % % % % % % % END METHODS% % %
   end
end