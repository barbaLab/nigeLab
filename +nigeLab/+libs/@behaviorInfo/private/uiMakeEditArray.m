function editArray = uiMakeEditArray(container,y,varargin)
%% UIMAKEEDITARRAY  Make array of edit boxes that corresponds to set of labels
%
%  editArray = UIMAKEEDITARRAY(container,y,);
%  editArray = UIMAKEEDITARRAY(container,y,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  container   :     Graphics container object (uipanel) to hold the array.
%
%     y        :     Vector of vertical positions normalized between 0 
%                    (bottom) and 1 (top).
%
%   varargin   :     (Optional) 'NAME', value input argument pairs that
%                             modify the uicontrol.
%
%                    -> 'X' [def: 0.500] // Normalized X (Position(1))
%
%                    -> 'W' [def: 0.475] // Normalized width (Position(3))
%
%                    -> 'H' [def: 0.150] // Normalized height (Position(4))
%
%  --------
%   OUTPUT
%  --------
%  editArray   :     k x 1 cell array of edit style uicontrols.
%
% By: Max Murphy  v1.0  08/30/2018   Original version (R2017b)
%
%                 v1.1  09/07/2018   Modified varargin format

%% DEFAULTS
% Normalized position coordinates
H = 0.150;
W = 0.475;
X = 0.500;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CONSTRUCT GRAPHICS ARRAY
editArray = cell(numel(y),1);

for ii = 1:numel(y)
   editArray{ii,1} = uicontrol(container,'Style','edit',...
      'Units','Normalized',...
      'Position',[X y(ii) W H],...
      'FontName','Arial',...
      'FontSize',14,...
      'Enable','off',...
      'String','N/A',...
      'UserData',ii);
   
end

end