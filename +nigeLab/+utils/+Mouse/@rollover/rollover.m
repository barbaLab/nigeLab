classdef rollover < handle
   %ROLLOVER  Class to monitor current "hovered" ui element via figure
   %           WindowButtonMotionFcn
   %
   %  ROLLOVER Properties:
   %     Handles  --  Array of PushButton UIControl handles that can
   %        be "hovered" over.
   %
   %     StringsDefault  --  Cell array of original PushButton Strings
   %
   %     IconsDefault  --  Cell array of original PushButton CData values
   %
   %     IconsOver  --  Cell array of CData to swap to when hovered
   %
   %     CurrentButtonHdl  -- If mouse is over PushButton, this is that one
   %
   %     NigelButtonHdl  -- If mouse is over NigelButton, this is that one
   %
   %  ROLLOVER Methods:
   %     rollover  --  Class constructor
   %        ro = nigeLab.utils.Mouse.rollover(fig_hdl,'pName1','pVal1',...)
   %
   %     display  --  Displays rollover values as a struct
   %
   %     get  --  Return a named property
   %
   %     roll  --  Method of rollover that is assigned to parent
   %        figure WindowButtonMotionFcn.
   %
   %     set  --  Set a named property to some value
   
   properties (Access = public)
      Handles              matlab.ui.control.UIControl
      StringsDefault       cell
      IconsDefault         cell
      StringsOver          cell
      IconsOver            cell
   end
   
   properties (Access = private, AbortSet = false, SetObservable = false)
      CurrentButtonHdl     matlab.ui.control.UIControl
      NigelButtonHdl       nigeLab.libs.nigelButton
   end
   
   properties (GetAccess = public, SetAccess = immutable)
      Parent               matlab.ui.Figure
   end
   
   methods (Access = public, Hidden = false)
      % Class constructor
      function ro = rollover(fig, varargin)
         %ROLLOVER Constructor for ROLLOVER objects
         
         % Default = current figure
         if nargin == 0
            fig_hdl = gcf;
         else
            if ~isa(fig,'matlab.ui.Figure')
               error(['nigeLab:' mfilename ':BadInputClass'],...
                  '"fig" input must be a figure handle.');
            end
         end
         
         % Read-only members
         ro.Parent = fig; 
         
         % Set figure's WindowButtonMotionFcn to activate rollover effect
         set(fig,'WindowButtonMotionFcn',@(~,~)ro.roll);
         
         % Parse property-value pairs
         if nargin > 2
            set(ro, varargin{:});
         end
         
      end
      
      roll(ro); % Method assigned to parent figure WindowButtonMotionFcn
   end
   
   methods (Access = public, Hidden = true)
      set(ro, varargin);   % Set a named property to some value
      val = get(ro, prop); % Return a named property value
      display(ro);         % Override display to display output as struct
   end
   
end