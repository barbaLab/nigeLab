function h = uiPanelizeTickBoxes(parent,nBox,pos,nCol,val,xOffset,yOffset)
%UIPANELIZETICKBOXES Returns axes cell array, with panelized axes objects
%
%  h = UIPANELIZETICKBOXES(parent,nBox,pos);
%  h = UIPANELIZETICKBOXES(parent,nBox,pos,nCol);
%  h = UIPANELIZETICKBOXES(parent,nBox,pos,nCol,val);
%  h = UIPANELIZETICKBOXES(parent,nBox,pos,nCol,val,xOffset);
%  h = UIPANELIZETICKBOXES(parent,nBox,pos,nCol,val,xOffset,yOffset);
%
%  --------
%   INPUTS
%  --------
%   parent     :     Handle to container object to panelize (such as
%                    uipanel)
%
%    nBox      :     Number of tickBox objects.
%
%    pos       :     4-element vector constraining position of tickBoxes
%
%    nCol      :     (optional) Number of columns of tickBoxes
%
%     val      :     (optional) Value (0 or 1) to default to (default 0)
%
%    xOffset   :     (optional) Offset between elements within a 
%                                row (and from edge).
%
%    yOffset   :     (optional) Offset between elements within a 
%                                column (and from edge).
%
%  --------
%   OUTPUT
%  --------
%    ax        :     Cell array of axes object handles.

% DEFAULTS
% For specified inputs
X_OFFSET = 0.0025;
Y_OFFSET = 0.0025;
N_COL = 1;
VAL = 0;

% PARSE INPUT
if exist('nCol','var')==0
   nCol = N_COL;
end

if exist('val','var')==0
   val = VAL;
end

if exist('xOffset','var')==0
   xOffset = X_OFFSET;
end

if exist('yOffset','var')==0
   yOffset = Y_OFFSET;
end



% GET NUMBER OF ROWS, COLUMNS, AND AXES WIDTH/HEIGHT
nRow = ceil(nBox/nCol);

widthBox  = (pos(3) - xOffset*(nCol + 1))/nCol;
widthPos = widthBox + xOffset;

[ypos,heightBox] = nigeLab.utils.uiGetVerticalSpacing(nRow,...
   'TOP',yOffset,'BOT',yOffset,...
   'YLIM',[pos(2) (pos(2)+pos(4))]);

% INITIALIZE AXES ARRAY

h = cell(nBox,1);
for ii = 1:nBox
   xpos = mod(ii-1,nCol)*widthPos + xOffset + pos(1);
   
   p = [xpos ypos(rem(ii-1,nRow-1)+1) widthBox heightBox];
   h{ii} = uicontrol(parent,...
                 'Style','checkbox',...
                 'Units','Normalized',...
                 'Position',p,...
                 'Value',val,...
                 'UserData',ii);
 
end

end