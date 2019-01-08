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

ncol = ceil(sqrt(sortObj.pars.NCLUS_MAX));
nrow = ceil((sortObj.pars.NCLUS_MAX)/ncol);

%% DETERMINE WIDTH AND HEIGHT BASED ON COLUMNS AND ROWS
sortObj.pars.AX_POS = cell(sortObj.pars.NCLUS_MAX,1);
sortObj.pars.LAB_POS = cell(sortObj.pars.NCLUS_MAX,1);
xw = sortObj.pars.SPK_AX(1)/ncol - sortObj.pars.AX_SPACE;
yw = sortObj.pars.SPK_AX(2)/nrow - sortObj.pars.AX_SPACE;

%% LOOP AND CREATE POSITION VECTORS FOR EACH PLOT
iN = 1;
for iRow = nrow:-1:1
   for iCol = 1:ncol
      sortObj.pars.AX_POS{iN} = [sortObj.pars.AX_SPACE*iCol + xw*(iCol-1), ...
         sortObj.pars.AX_SPACE*iRow + yw*(iRow-1), ...
         xw, ...
         yw];
      sortObj.pars.LAB_POS{iN} = [sortObj.pars.AX_POS{iN}(1), ...
         sortObj.pars.AX_SPACE*(iRow)+yw*(iRow), ...
         xw, ...
         0.03];
      iN = iN + 1;
   end
end

flag = true;
end