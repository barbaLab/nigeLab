classdef ChannelUI < handle
   %% CHANNELUI  Figure window for setting channel info of a parent object
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
   
   %% PROPERTIES
   properties (SetAccess = private, GetAccess = public)
      Channel     % (scalar) integer of channel index
      Parent      % Parent nigeLab class object.
      Figure      % Figure graphic handle
      Menu        % Menu graphic handle
   end
   
   properties (SetAccess = immutable, GetAccess = private)
      FIG_POS  = [0.750,0.850,0.150,0.065];  % Normalized figure position
      FIG_COL  = 'k';                        % Figure background color
      FIG_NAME = 'Channel Selector';         % Figure name
      
      MENU_POS = [0.100,0.100,0.800,0.800];  % Popup menu position in fig
      MENU_FONT = 'Arial';                   % Popup menu font
      MENU_FONT_COLOR = 'k';                 % Popup menu font color
      MENU_FONT_SIZE = 16;                   % Popup menu font size
   end
   
   %% EVENTS
   events
      NewChannel  % Notifies listeners when channel is changed
   end
   
   %% METHODS
   methods (Access = public)
      function obj = ChannelUI(parent)
         %% CHANNELUI  Figure window for setting channel info of a parent
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
         %
         % By: Max Murphy  v1.0  2019/01/10  Original version (R2017a)
         
         %% ASSOCIATE OBJECT WITH PARENT
         obj.Parent = parent;
         obj.Channel = get(obj.Parent,'channel');
         
         %% MAKE FIGURE & GRAPHICS
         obj.Open;
         
      end
      
      function Open(obj)
         %% OPEN  Open the figure and menu
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
         %% SETCHANNEL  Update the current channel and notify of this event
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
      
   end
end