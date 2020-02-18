function [x,y,w,h,lab] = uiMakeLabels(panel,labels,varargin)
%UIMAKELABELS  Make labels at equally spaced increments along left of panel
%
%  [x,y] = UIMAKELABELS(panel,labels);
%  [x,y,w,h,lab] = UIMAKELABELS(panel,labels);
%  [__] = UIMAKELABELS(panel,labels,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%    panel     :     Uipanel object where the labels will go along the left
%                    side.
%
%    labels    :     Cell array of strings to use for the labels.
%
%   varargin   :     (Optional) 'NAME', value input argument pairs.
%
%                 -> 'LEFT' [def: 0.025] // Offset from left border
%                 (normalized from 0 to 1)
%
%                 -> 'RIGHT' [def: 0.475] // Offset from right border
%                 (normalized from 0 to 1)
%
%                 -> 'BOT' [def: 0.025] // Offset from bottom border
%                 (normalized from 0 to 1)
%
%                 -> 'TOP' [def: 0.025] // Offset from top border
%                 (normalized from 0 to 1)
%
%  --------
%   OUTPUT
%  --------
%     y        :     Y coordinate corresponding to each element of lab
%
%    lab       :     Label object array

% DEFAULTS
pars = struct;
pars.TOP = 0.025;
pars.BOT = 0.025;

pars.LEFT = 0.025;

pars.BACKGROUND_COL = nigeLab.defaults.nigelColors('surface');
pars.FOREGROUND_COL = nigeLab.defaults.nigelColors('onsurface');
pars.FONTSIZE = 12;
pars.FONTNAME = 'DroidSans';

% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   pars.(varargin{iV}) = varargin{iV+1};
end

% COMPUTE POSITIONS
n = numel(labels);
[x,w] = nigeLab.utils.uiGetHorizontalSpacing(1,... % 1 column
   'LEFT',pars.LEFT);
[y,h] = nigeLab.utils.uiGetVerticalSpacing(n,...
   'TOP',pars.TOP,...
   'BOT',pars.BOT);


% CREATE LABELS
lab = gobjects(1,n);
for ii = 1:n
   lab(ii) = uicontrol(panel,'Style','text',...
            'Units','Normalized',...
            'FontName',pars.FONTNAME,...
            'FontSize',pars.FONTSIZE,...
            'BackgroundColor',pars.BACKGROUND_COL,...
            'ForegroundColor',pars.FOREGROUND_COL,...
            'Position',[x, y(ii), w, h/2],...
            'String',labels{ii});
end

end