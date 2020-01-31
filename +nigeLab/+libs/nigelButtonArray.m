classdef nigelButtonArray < handle
   %NIGELBUTTONARRAY (unused) Class that creates "column" array of buttons
   %   
   %  Implemented for the `nigeLab.libs.DashBoard` "plotRecapBubbles"
   %  method, to keep track of the rectangles etc.
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (Access=public)
      Axes     % "Parent" axes object
      Children % Child `nigeLab.libs.nigelButton` objects 
      Field    % Corresponds to 'Fields' of nigelObj
      Mask     % Mask where "true" is bright and "false" is dim
   end
   
   % PROTECTED
   properties (Access=protected)
      position (1,1) struct = struct('Horizontal',nan,'Width',nan);
      col (1,1) struct = struct('face_hi_mask',[],'face_hi_unmask',[],...
                                'face_lo_mask',[],'face_lo_unmask',[],...
                                'edge_en',[],'edge_dis',[]);
   end
   
   % DEPENDENT,PUBLIC/PROTECTED
   properties (Dependent,GetAccess=public,SetAccess=protected)
      N        % Number of child objects
      w        % width (axes coordinates)
      x        % horizontal center (axes coordinates)
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded)
   methods
      function delete(obj)
         if ~isempty(obj.Children)
            for i = 1:numel(obj.Children)
               if isvalid(obj.Children(i))
                  delete(obj.Children(i));
               end
            end
         end
      end
      
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      function value = get.N(obj)
         %GET.N  Returns number of children
         value = numel(obj.Children);
      end
      
      function value = get.w(obj)
         %GET.w  Returns width
         value = obj.position.Width;
      end
      
      function value = get.x(obj)
         %GET.x  Returns horizontal position
         value = obj.position.Horizontal;
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      function set.N(~,~)
         %SET.N Does nothing
      end
      
      function set.w(obj,value)
         %SET.w  Sets .w (width) property
         if isnumeric(value)
            obj.position.Width = value;
         end
      end
      
      function set.x(obj,value)
         %SET.x  Sets .x (horizontal position) property
         if isnumeric(value)
            obj.position.Horizontal = value;
         end
      end
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % PUBLIC (constructor)
   methods (Access=public)
      % Class constructor
      function obj = nigelButtonArray(ax,x,w,Field,info,status,mask)
         %NIGELBUTTON  Class constructor for `nigelButtonArray` object
         %
         %  obj = nigeLab.libs.nigelButtonArray(ax,x,w,Field,info,status,mask);
         %
         %  ax    -  Parent "container" axes
         %  x     -  Axes x-center for column (in axes data units)
         %  w     -  Width of column (in axes data units)
         %  Field -  Current processing stage (this column)
         %  info  -  Struct array with the following fields:
         %     --> 'Label' : (Char array corresponding to a button label)
         %     --> 'Print'  : (Char array corresponding to printed command
         %                       window text when button is clicked)
         %  status -  Logical indicator vector (progress)
         %  mask  -   Logical masking vector
         %
         %  The array spans the y-limits of ax and contains a number of
         %  buttons in it equal to the total number of array elements
         %  contained in 'info'
         
         if nargin < 1
            obj = nigeLab.libs.nigelButtonArray.empty();
            return;
         elseif isnumeric(ax)
            if numel(ax) < 2
               n = [zeros(1,2-numel(ax)),ax];
            else
               n = [0,max(ax)];
            end
            obj = repmat(obj,n);
            return;
         
         end
         if nargin < 2
            x = 1.5;
         end
         if nargin < 3
            w = 1;
         end
         if nargin < 4
            Field = 'Unknown';
         end
         
         obj.x = x;
         obj.w = w;
         obj.Axes = ax;
         obj.Field = Field;
         obj.col.face_hi_mask = nigeLab.defaults.nigelColors('g');
         obj.col.face_hi_unmask = obj.col.face_hi_mask*0.75;
         obj.col.face_lo_mask = nigeLab.defaults.nigelColors('dg');
         obj.col.face_lo_unmask = obj.col.face_lo_mask*0.75;
         obj.col.edge_en = nigeLab.defaults.nigelColors('surface');
         obj.col.edge_dis = 'none';
         if nargin >= 7
            obj.setButtonArray(info,status,mask);
         end
      end
      
      % Sets the button array for the array object, based on `info` struct
      function setButtonArray(obj,info)
         %SETBUTTONARRAY  Sets button array using struct array `info`
         %
         %  setButtonArray(obj,info);
         %
         %  --> info : Number of array elements == number of child buttons
         
         n = numel(info);         
         if ~isempty(obj.Children)
            delete(obj.Children);
         end
         obj.Children = nigeLab.libs.nigelButton.empty();
         ht = 1/n;
         hh = 0.97/n;
         for i = 1:n
            if info(i).status
               pos = [obj.x - (obj.w/2), (i-1)*ht, obj.w, hh];
               ec = obj.col.edge_en;
               if info(i).mask
                  fc = obj.col.face_hi_mask;
               else
                  fc = obj.col.face_hi_unmask;
               end
            else
               pos = [obj.x - (obj.w/2), (i-1)*ht, obj.w, ht];
               ec = obj.col.edge_dis;
               if info(i).mask
                  fc = obj.col.face_lo_mask;
               else
                  fc = obj.col.face_lo_unmask;
               end
            end
            obj.Children = [obj.Children,...
                  nigeLab.libs.nigelButton(obj.Axes,...
                  {'Position',pos,'FaceColor',fc,'EdgeColor',ec},...
                  {'String',info(i).Label,'Color','k'},...
                  @disp,info(i).Print)];
         end
         
      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      function obj = empty(n)
         %EMPTY  Create empty nigeLab.libs.nigelButtonArray object
         %
         %  obj = nigeLab.libs.nigelButtonArray.empty();
         %  --> Empty scalar
         %
         %  obj = nigeLab.libs.nigelButtonArray.empty(n);
         %  --> Empty array with n elements
         
         if nargin < 1
            n = [0,0];
         else
            n = [0,max(n)];
         end
         obj = nigeLab.libs.nigelButtonArray(n);         
      end
   end
   % % % % % % % % % % END METHODS% % %
end

