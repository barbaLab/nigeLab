function pars = Plot()
%% PLOT   Template for initializing parameters for plotting data
%
%   pars = nigeLab.defaults.Plot;

%%
pars = struct;

% Parameters for plot methods that require epochs of data aligned to an
% event of interest:
pars.PreAlign = 1000;    % Time to plot prior to alignment (ms)
pars.PostAlign = 500;    % Time to plot after alignment (ms)
pars.DefTime =  2000;    % Default time to plot snippets (ms)
pars.VertOffset = 150;   % Vertical offset for multi-channel (uV)
pars.ColorMapFile = 'hotcoldmap.mat';
pars.SnippetString = '_%s_Snippets';

% Parameters for plotOverlay method:
[pname,~,~] = fileparts(mfilename('fullpath'));
pars.OverlayImage = fullfile(pname,'Skull-Brain.png');
pars.Bregma = [5100 1750]; % pixel location of bregma
pars.XScale = 350; % pixels for 1 mm
pars.YScale = 150; % pixels for 1 mm
pars.Size = 18;    % pixels

end

