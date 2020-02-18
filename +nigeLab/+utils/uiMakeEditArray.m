function editArray = uiMakeEditArray(container,y,varargin)
%UIMAKEEDITARRAY  Make array of edit boxes that corresponds to set of labels
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
%  editArray   :     1 x k  Array of edit style
%                       'matlab.ui.control.UIControl' objects.

% DEFAULTS
% Normalized position coordinates
pars = struct;
pars.H = 0.150;
pars.W = 0.475;
pars.X = 0.500;
pars.TAG = repmat({''},numel(y),1);

% PARSE VARARGIN
if (numel(varargin) == 1)
   if isstruct(varargin{1})
      pars = varargin{1};
   else
      error(['nigeLab:' mfilename ':BadNumInputs'],...
         '[UIMAKEEDITARRAY]: Must either specify varargin as pars struct or name, value pairs');
   end
end
for iV = 1:2:numel(varargin)
   pars.(upper(varargin{iV})) = varargin{iV+1};
end

% CONSTRUCT GRAPHICS ARRAY
editArray = gobjects(1,numel(y));

for ii = 1:numel(y)
   editArray(ii) = uicontrol(container,'Style','edit',...
      'Units','Normalized',...
      'Position',[pars.X y(ii) pars.W pars.H],...
      'FontName','DroidSans',...
      'FontSize',13,...
      'Enable','off',...
      'String','N/A',...
      'Tag',pars.TAG{ii},...
      'UserData',ii);
   
end

end