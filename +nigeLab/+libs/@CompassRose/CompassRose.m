classdef CompassRose < matlab.mixin.SetGet & matlab.mixin.Copyable
   %COMPASSROSE Creates a compass rose on an axes to give scale bars
   %
   %  h = CompassRose;
   %  --> Places CompassRose object handle (`h`) in current axes
   %
   %  h = CompassRose(ax);
   %  --> Places CompassRose object handle (`h`) in axes `ax`
   %
   %  h = CompassRose(ax,x,y,z);
   %  --> Creates lines from the origin in the specified dimensions
   %        indicating the scale of each dimension.
   %  --> If an element is a 2-element vector, then it demarcates the start
   %        and stop coordinate of the Compass in that dimension (instead
   %        of assuming rose should be at the origin).
   %
   %  h = CompassRose(___,'Name',value,...);
   %  --> Set line properties using 'Name',value syntax
   
   properties(Dependent) % Parsed from objects
      Color          
      FontName       char = 'Arial'
      FontSize       double = 14
      FontWeight     char = 'normal'
      LineProperties       cell
      XLabelOffsetFactor   (1,1) double = 1.15
      XUnit                      char = ''
      YLabelOffsetFactor   (1,1) double = 1.15
      YUnit                      char = ''
      ZLabelOffsetFactor   (1,1) double = 1.15
      ZUnit                      char = ''
      Parent               matlab.graphics.axis.Axes
      x                    double
      xlabel   
      y                    double
      ylabel
      z                    double
      zlabel
   end
   
   properties(Access=protected)
      Color_                 = 'k';
      FontName_         char = 'Arial'
      FontSize_         double = 14
      FontWeight_       char = 'normal'   
      LineProperties_   cell = {'Color','k','LineWidth',1.25,'LineStyle','-','PickableParts','none'}
      XLabelOffsetFactor_  (1,1) double = 1.15
      XUnit_                     char = ''
      YLabelOffsetFactor_  (1,1) double = 1.15
      YUnit_                     char = ''
      ZLabelOffsetFactor_  (1,1) double = 1.15
      ZUnit_                     char = ''
      ax_         matlab.graphics.axis.Axes
      hg_         matlab.graphics.primitive.Group
      scalebar_   matlab.graphics.primitive.Line
      label_      matlab.graphics.primitive.Text
   end
   
   methods(Access=public) % Constructor
      function obj = CompassRose(ax,x,y,z,varargin)
         %COMPASSROSE  Creates a compass rose on an axes to give scale bars
         %
         %  h = CompassRose;
         %  --> Places CompassRose object handle (`h`) in current axes
         %
         %  h = CompassRose(ax);
         %  --> Places CompassRose object handle (`h`) in axes `ax`
         %
         %  h = CompassRose(ax,x,y,z);
         %  --> Creates lines from the origin in the specified dimensions
         %        indicating the scale of each dimension.
         %  --> If an element is a 2-element vector, then it demarcates the start
         %        and stop coordinate of the Compass in that dimension (instead
         %        of assuming rose should be at the origin).
         %
         %  h = CompassRose(___,'Name',value,...);
         %  --> Set line properties using 'Name',value syntax  
         

         if isa(ax,'matlab.graphics.axis.Axes')
            obj.ax_ = ax;
         else
            error('First input argument must be axes');
         end
         
         hg = hggroup(obj.ax_,'Tag','CompassRose');
         h = gobjects(1,3);
         tx = gobjects(1,3);
         for i = 1:3
            h(i) = line(hg,[nan,nan],[nan,nan],[nan,nan],...
               obj.LineProperties_{:});
            h(i).Annotation.LegendInformation.IconDisplayStyle = 'off';
            tx(i) = text(hg,nan,nan,nan,'','FontName',obj.FontName,...
               'FontWeight',obj.FontWeight,'Color',obj.Color,...
               'PickableParts','none',...
               'VerticalAlignment','middle',...
               'HorizontalAlignment','center');
         end
         hg.Annotation.LegendInformation.IconDisplayStyle = 'off';
         obj.hg_ = hg;
         obj.scalebar_ = h;
         obj.label_ = tx;
         
         if numel(varargin) > 1
            obj.LineProperties = varargin;
         end

         if nargin < 2
            obj.x = nan;
         else
            obj.x = x;
         end
         
         if nargin < 3
            obj.y = nan;
         else
            obj.y = y;
         end
         
         if nargin < 4
            obj.z = nan;
         else
            obj.z = z;
         end        
         
      end
   end
   
   methods % Overloaded methods
      
      function delete(obj)
         if ~isempty(obj.hg_)
            if isvalid(obj.hg_)
               delete(obj.hg_);
            end
         end
      end
      
      function value = get.Color(obj)
         value = obj.Color_;
      end
      function set.Color(obj,value)
         obj.Color_ = value;
         for i = 1:3
            obj.label_(i).Color = value;
         end
      end
      
      function value = get.FontName(obj)
         value = obj.FontName_;
      end
      function set.FontName(obj,value)
         obj.FontName_ = value;
         for i = 1:3
            obj.label_(i).FontName = value;
         end
      end
      
      function value = get.FontSize(obj)
         value = obj.FontSize_;
      end
      function set.FontSize(obj,value)
         obj.FontSize_ = value;
         for i = 1:3
            obj.label_(i).FontSize = value;
         end
      end
      
      function value = get.FontWeight(obj)
         value = obj.FontWeight_;
      end
      function set.FontWeight(obj,value)
         obj.FontWeight_ = value;
         for i = 1:3
            obj.label_(i).FontWeight = value;
         end
      end
      
      function value = get.LineProperties(obj)
         value = obj.LineProperties_;
      end
      function set.LineProperties(obj,value)
         for i = 1:numel(obj.scalebar_)
            set(obj.scalebar_,value(1:2:end),value(2:2:end));
         end
         obj.LineProperties_ = value;
      end
      
      function value = get.XLabelOffsetFactor(obj)
         value = obj.XLabelOffsetFactor_;
      end
      function set.XLabelOffsetFactor(obj,value)
         xval = obj.x; 
         obj.label_(1).Position(1) = xval(1) + diff(xval)*value;
         obj.XLabelOffsetFactor_ = value;
      end
      
      function value = get.XUnit(obj)
         value = obj.XUnit_;
      end
      function set.XUnit(obj,value)
         xval = obj.x;
         if isempty(value)
            obj.label_(1).String = sprintf('%g',diff(xval));
         else
            obj.label_(1).String = sprintf('%g (%s)',diff(xval),value);
         end
         obj.XUnit_ = value;
      end
      
      function value = get.YLabelOffsetFactor(obj)
         value = obj.YLabelOffsetFactor_;
      end
      function set.YLabelOffsetFactor(obj,value)
         yval = obj.y;
         obj.label_(2).Position(2) = yval(1) + diff(yval)*value;
         obj.YLabelOffsetFactor_ = value;
      end
      
      function value = get.YUnit(obj)
         value = obj.YUnit_;
      end
      function set.YUnit(obj,value)
         yval = obj.y;
         if isempty(value)
            obj.label_(2).String = sprintf('%g',diff(yval));
         else
            obj.label_(2).String = sprintf('%g (%s)',diff(yval),value);
         end
         obj.YUnit_ = value;
      end
      
      function value = get.ZLabelOffsetFactor(obj)
         value = obj.ZLabelOffsetFactor_;
      end
      function set.ZLabelOffsetFactor(obj,value)
         zval = obj.z;
         obj.label_(3).Position(3) = zval(1) + diff(zval)*value;
         obj.ZLabelOffsetFactor_ = value;
      end
      
      function value = get.ZUnit(obj)
         value = obj.ZUnit_;
      end
      function set.ZUnit(obj,value)
         zval = obj.z;
         if isempty(value)
            obj.label_(3).String = sprintf('%g',diff(zval));
         else
            obj.label_(3).String = sprintf('%g (%s)',diff(zval),value);
         end
         obj.ZUnit_ = value;
      end
      
      function value = get.Parent(obj)
         value = obj.ax_;
      end
      function set.Parent(obj,value)
         obj.ax_ = value;
         set(obj.hg_,'Parent',value);
      end
      
      function value = get.x(obj)
         value = obj.scalebar_(1).XData;
      end
      function set.x(obj,value)
         if isscalar(value)
            value = [0,value];
         end
         d = diff(value);
         obj.label_(1).Position(1) = value(1) + d*obj.XLabelOffsetFactor;
         u = obj.XUnit;
         if isempty(u)
            obj.label_(1).String = sprintf('%g',d);
         else
            obj.label_(1).String = sprintf('%g (%s)',d,u);
         end
         obj.label_(2).Position(1) = value(1);
         obj.label_(3).Position(1) = value(1);
         
         obj.scalebar_(1).XData = value;
         obj.scalebar_(2).XData = [value(1), value(1)];
         obj.scalebar_(3).XData = [value(1), value(1)];
      end
      
      function value = get.y(obj)
         value = obj.scalebar_(2).YData;
      end
      function set.y(obj,value)
         if isscalar(value)
            value = [0,value];
         end
         d = diff(value);
         obj.label_(1).Position(2) = value(1);
         obj.label_(2).Position(2) = value(1) + d*obj.YLabelOffsetFactor;
         u = obj.YUnit;
         if isempty(u)
            obj.label_(2).String = sprintf('%g',d);
         else
            obj.label_(2).String = sprintf('%g (%s)',d,u);
         end
         obj.label_(3).Position(2) = value(1);
         
         obj.scalebar_(1).YData = [value(1), value(1)];
         obj.scalebar_(2).YData = value;
         obj.scalebar_(3).YData = [value(1), value(1)];
      end
      
      function value = get.z(obj)
         value = obj.scalebar_(3).ZData;
      end
      function set.z(obj,value)
         if isscalar(value)
            value = [0,value];
         end
         d = diff(value);
         obj.label_(1).Position(3) = value(1);
         obj.label_(2).Position(3) = value(1);
         obj.label_(3).Position(3) = value(1)+d*obj.ZLabelOffsetFactor;
         u = obj.ZUnit;
         if isempty(u)
            obj.label_(3).String = sprintf('%g',d);
         else
            obj.label_(3).String = sprintf('%g (%s)',d,u);
         end
         obj.scalebar_(1).ZData = [value(1), value(1)];
         obj.scalebar_(2).ZData = [value(1), value(1)];
         obj.scalebar_(3).ZData = value;
      end
   end
   
end

