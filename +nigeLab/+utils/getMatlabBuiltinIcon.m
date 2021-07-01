function [icon,alpha] = getMatlabBuiltinIcon(iconName,varargin)
%GETMATLABBUILTINICON  Return icon CData for a .gif Matlab builtin icon
%
%  nigeLab.utils.getMatlabBuiltinIcon('help');
%  * Provides list of valid icon filenames
%
%  icon = nigeLab.utils.getMatlabBuiltinIcon(iconName);
%
%  >> icon = nigeLab.utils.getMatlabBuiltinIcon('greenarrow');
%  >> icon = nigeLab.utils.getMatlabBuiltinIcon('greenarrow.gif'); % equal
%
%  [icon,alpha] = nigeLab.utils.getMatlabBuiltinIcon(__);
%  * Returns alpha mapping for icon as well
%
%  icon = nigeLab.utils.getMatlabBuiltinIcon(iconName,'Name',value,...);
%
%  ## Name-Value Pairs ##
%     + 'Background': any value from nigeLab.defaults.nigelColors
%        --> Default: 'surface'
%
%     + 'BackgroundIndex': Index of default map to set to background
%        --> Default: max value of `img` returned by imread
%
%     + 'IconExtension': If not specified, icon extension for icon file
%        --> Default: '.gif'
%
%     + 'IconPath': If not specified, path where desired icons are located
%        --> Default: fullfile(matlabroot,'toolbox','matlab','icons');
%
%     + 'Map': Mapping of uint8 values to CData (N x 3, where first row
%                                      corresponds to uint8 value of zero)
%        --> Default: Second output from `imread` of icon file. 
%           * Note that if 'Map' is used, then 'Background' and
%             'BackgroundIndex' are ignored.
%
%     + 'Type': 'double' (def) Returns values as double scaled from 0 to 1
%               'uint8'        Returns values as uint8        
%
%     + 'ValidIconFileTypes': {'.gif', '.PNG'} Supported icon file types

% Defaults
p = struct;
p.Background = 'surface';
p.BackgroundIndex = [];
p.IconPath = fullfile(matlabroot,'toolbox','matlab','icons');
p.IconExtension = '.gif';
p.Map = [];
p.Type = 'double';
p.ValidIconFileTypes = {'.gif','.PNG'};

if ismember(lower(iconName),{'help','opts','opt','options','list'})
   nigeLab.sounds.play('pop',1.5,-40);
   for i = 1:numel(p.ValidIconFileTypes)
      fprintf(1,'\n<strong>%s Icons:</strong>\n\n',p.ValidIconFileTypes{i});
      dir(fullfile(p.IconPath,['*' p.ValidIconFileTypes{i}]));
      
   end
   return;
end

% Parse input
pars = nigeLab.utils.getopt(p,1,varargin{:});
[~,iconName,ext] = fileparts(iconName);
if isempty(ext)
   ext = pars.IconExtension;
end

if ~ismember(ext,pars.ValidIconFileTypes)
   nigeLab.utils.cprintf('Errors*','Valid Icon FileTypes:\n');
   nigeLab.utils.cprintf('[0.65 0.65 0.65]','\t->\t%s\n',...
      pars.ValidIconFileTypes{:});
   error(['nigeLab:' mfilename ':BadIconFileType'],...
      '[GET_ICON]: Bad icon filetype (''%s'')\n',ext);
end

if isempty(pars.Map) % Read Map from .gif
   [img,map] = imread(fullfile(pars.IconPath,[iconName ext]));
   if ~isempty(map)
      if isempty(pars.BackgroundIndex)
         pars.BackgroundIndex = max(max(img)) + 1;
      end
      map(pars.BackgroundIndex,:) = ...
         nigeLab.defaults.nigelColors(pars.Background);
      alpha = ones(size(img));
      alpha(img == pars.BackgroundIndex-1) = 0;
   end
else % Otherwise use user-provided map
   img = imread(fullfile(pars.IconPath,[iconName ext]));
   if numel(size(img))==3
      img = rgb2gray(img);
   end
   alpha = ones(size(img));
   alpha(img == 0) = 0;
   map = pars.Map;
end
if ~isempty(map)
   icon = ind2rgb(img,map);
else
    alpha = ones(size(img));
    col = nigeLab.defaults.nigelColors(pars.Background)*255;
    idx = all(~img,3);
    for ii =1:3
        thisCol = img(:,:,ii);
        thisCol(idx) = col(ii);
        alpha(idx,ii) = 0;
        img(:,:,ii) = thisCol;
    end
   icon = img; 
end

if ~strcmpi(pars.Type,'double')
   switch lower(pars.Type)
      case 'uint8'
         icon = uint8(round(icon .* 255));
      otherwise
         error(['nigeLab:' mfilename ':BadParam'],...
            '[GET_ICON]: Not configured for Type == ''%s''\n',...
            pars.Type);
   end
end

end