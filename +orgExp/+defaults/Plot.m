function pars = Plot()
%% PLOT   Template for initializing parameters for plotting data
%
%   pars = orgExp.defaults.Plot;
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%%
pars = struct;
pars.PreAlign = 1000;    % Time to plot prior to alignment (ms)
pars.PostAlign = 500;    % Time to plot after alignment (ms)
pars.DefTime =  2000;    % Default time to plot snippets (ms)
pars.VertOffset = 150;   % Vertical offset for multi-channel (uV)
pars.ColorMapFile = 'hotcoldmap.mat';
pars.SnippetString = '_%s_Snippets';

end

