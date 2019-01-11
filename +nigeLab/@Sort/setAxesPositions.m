function flag = setAxesPositions(sortObj)
%% SETAXESPOSITIONS Determine axes spacing for spike plots
%
%  flag = SETAXESPOSITIONS(sortObj)
%
%  --------
%   INPUTS
%  --------
%  sortObj     :  Sort class object.
%
%  --------
%   OUTPUT
%  --------
%    flag      :  Indicator of function successful completion.
%
% By: Max Murphy  v1.0  10/03/2017  Original version (R2017a)

%% GET NUMBER OF COLUMNS AND ROWS BASED ON TOTAL NUMBER OF PLOTS
flag = false;

ncol = ceil(sqrt(sortObj.pars.SpikePlotN));
nrow = ceil((sortObj.pars.SpikePlotN)/ncol);

%% DETERMINE WIDTH AND HEIGHT BASED ON COLUMNS AND ROWS
sortObj.UI.plot.pos= cell(sortObj.pars.SpikePlotN,1);
sortObj.UI.plot.labPos = cell(sortObj.pars.SpikePlotN,1);
w = sortObj.pars.SpikePlotXYExtent(1)/ncol - sortObj.pars.SpikePlotSpacing;
h = sortObj.pars.SpikePlotXYExtent(2)/nrow - sortObj.pars.SpikePlotSpacing;

%% LOOP AND CREATE POSITION VECTORS FOR EACH PLOT
iN = 1;
% Work backwards to get elements in correct order later
for iRow = nrow:-1:1 
   for iCol = 1:ncol
      % Compute spike plot position vector
      x = sortObj.pars.SpikePlotSpacing*iCol + xw*(iCol-1);
      y = sortObj.pars.SpikePlotSpacing*iRow + yw*(iRow-1);
      sortObj.UI.plot.pos{iN} = [x,y,w,h];
      
      % Compute spike plot label (title) position vector
      x = sortObj.pars.SpikePlotXYExtent{iN}(1);
      y = sortObj.pars.SpikePlotSpacing*(iRow)+yw*(iRow);
      sortObj.UI.plot.labPos{iN} = [x,y,w,sortObj.pars.SpikePlotLabOffset]; 
      
      iN = iN + 1;
   end
end

flag = true;
end