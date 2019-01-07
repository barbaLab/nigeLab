function [y,lab] = uiMakeLabels(panel,labels,varargin)
%% UIMAKELABELS  Make labels at equally spaced increments along left of panel
%
%  y = UIMAKELABELS(panel,labels);
%  [y,lab] = UIMAKELABELS(panel,labels);
%  [y,lab] = UIMAKELABELS(panel,labels,'NAME',value,...);
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
%    lab       :     Label cell array
%
% By: Max Murphy  v1.0   08/08/2018    Original version (R2017b)

%% DEFAULTS
TOP = 0.025;
BOT = 0.025;

LEFT = 0.025;

BACKGROUND_COL = 'k';
FOREGROUND_COL = 'w';
FONTSIZE = 14;
FONTNAME = 'Arial';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% COMPUTE POSITIONS
n = numel(labels);
[x,w] = uiGetHorizontalSpacing(1,... % 1 column
   'LEFT',LEFT);
[y,h] = uiGetVerticalSpacing(n,...
   'TOP',TOP,...
   'BOT',BOT);


%% CREATE LABELS
lab = cell(n,1);
for ii = 1:n
   lab{ii} = uicontrol(panel,'Style','text',...
            'Units','Normalized',...
            'FontName',FONTNAME,...
            'FontSize',FONTSIZE,...
            'BackgroundColor',BACKGROUND_COL,...
            'ForegroundColor',FOREGROUND_COL,...
            'Position',[x, y(ii), w, h],...
            'String',labels{ii});
end

end