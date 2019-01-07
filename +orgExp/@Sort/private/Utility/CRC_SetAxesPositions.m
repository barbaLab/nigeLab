function handles = CRC_SetAxesPositions(handles)
%% CRC_SETAXESPOSITIONS Determine axes spacing for spike plots
%
%  handles = CRC_SETAXESPOSITIONS(handles)
%
%  --------
%   INPUTS
%  --------
%   handles :  Object containing GUI parameters.
%
%  --------
%   OUTPUT
%  --------
%   handles :  Updated handles object with axes position parameters.
%
% By: Max Murphy  v1.0  10/03/2017  Original version (R2017a)

%% GET NUMBER OF COLUMNS AND ROWS BASED ON TOTAL NUMBER OF PLOTS
ncol = ceil(sqrt(handles.NCLUS_MAX));
nrow = ceil((handles.NCLUS_MAX)/ncol);

%% DETERMINE WIDTH AND HEIGHT BASED ON COLUMNS AND ROWS
handles.AX_POS = cell(handles.NCLUS_MAX,1);
handles.LAB_POS = cell(handles.NCLUS_MAX,1);
xw = handles.SPK_AX(1)/ncol - handles.AX_SPACE;
yw = handles.SPK_AX(2)/nrow - handles.AX_SPACE;

%% LOOP AND CREATE POSITION VECTORS FOR EACH PLOT
iN = 1;
for iRow = nrow:-1:1
   for iCol = 1:ncol
      handles.AX_POS{iN} = [handles.AX_SPACE*iCol + xw*(iCol-1), ...
         handles.AX_SPACE*iRow + yw*(iRow-1), ...
         xw, ...
         yw];
      handles.LAB_POS{iN} = [handles.AX_POS{iN}(1), ...
         handles.AX_SPACE*(iRow)+yw*(iRow), ...
         xw, ...
         0.03];
      iN = iN + 1;
   end
end

end