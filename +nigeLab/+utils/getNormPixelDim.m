function normDims = getNormPixelDim(p,pixDimsMin,normDimsq)
% GETNORMPIXELDIM  "Fix" normalized dimensions based on minimum pixel
%                  constraints. Useful to keep everything in 'Normalized'
%                  units when dealing with nested graphics objects.
%
%  normDims = nigeLab.utils.getNormPixelDim(p,pixDimsMin,normDimsq);
%
%  OUTPUT
%  normDims  --  Dimensions in 'Normalized' units to fit some child object
%                 in parent object p with constrained minimum pixel
%                 dimensions ([x, y, width, height]) in pixDimsMin and
%                 desired normalized dimensions in normDimsq.
%
%  INPUT
%  p  --             Parent graphics object
%  pixDimsMin  --    [x, y, width, height] minimum dimensions (pixels)
%  normDimsq  --     [x, y, width, height] queried normalized dimensions

% Get child and parent PIXEL positions
pos = getPosition(p);

minPositionRequirements = ...
   [pixDimsMin(1) / pos(3), ... % horiz offset scaled by parent width
    pixDimsMin(2) / pos(4), ... % vert offset scaled by parent height
    pixDimsMin(3) / pos(3), ... % width scaled by parent width
    pixDimsMin(4) / pos(4)];    % height scaled by parent height
 
% For each element, the minimum to get at least "pixDimsMin" pixels in that
% dimension will be obtained by taking the max. between these two; if the
% normDimsq exceeds in each case then it will be selected.
normDims = max(minPositionRequirements,normDimsq);

   % Helper function to get pixel position
   function pos = getPosition(obj)
      % GETPOSITION Returns [x, y, width, height] vector of pixel position
      
      if isa(obj,'nigeLab.libs.nigelPanel')
         pos = obj.getPixelPosition();
      else
         try
            pos = getpixelposition(obj);
         catch
            set(obj,'Units','Pixels');
            pos = get(obj,'Position');
            set(obj,'Units','Normalized');
         end
      end
   end

end