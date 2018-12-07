function flag = plotWaves(blockObj)
%% PLOTWAVES  Plot multi-channel waveform snippets for BLOCK
%
%  flag = PLOTWAVES(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj :     BLOCK class object from orgExp package.
%
%  --------
%   OUTPUT
%  --------
%    flag   :     Returns true if the figure is successfully generated.
%
%  See also: PLOTCHANNELS
%
% By: Max Murphy  v1.1  06/14/2018  Added flag output.

%% DEFAULTS
flag = false;
blockObj.PlotPars = orgExp.defaults.Plot();

%% FIGURE OUT WHAT TO PLOT
str_in = blockObj.Fields(blockObj.Status);
[~,idx] = orgExp.utils.uidropdownbox('Choose Wave Type',...
   'Select type of waveform to plot:',...
   str_in);

str = str_in{idx};
if strcmp(str,'Spikes')
   warning('Spikes overlay not yet supported.');
   return;
end

%% GET INDEXING VECTOR
if strcmp(str,'LFP')
   fs = blockObj.LFPPars.DownSampledRate;
else
   fs = blockObj.SampleRate;
end
tStart = (blockObj.PlotPars.DefTime - blockObj.PlotPars.PreAlign)/1000;
iStart = max(1,round(tStart * fs));

tStop = (blockObj.PlotPars.DefTime + blockObj.PlotPars.PostAlign)/1000;
iStop = min(blockObj.Samples,round(tStop * fs));

vec = iStart:iStop;
t = linspace(tStart,tStop,numel(vec));
dt = mode(diff(t));

%% ASSIGN CHANNEL COLORS BASED ON RMS
load(blockObj.PlotPars.ColorMapFile,'cm');
if isempty(blockObj.RMS)
   if ~ismember('CAR',blockObj.RMS.Properties.VariableNames)
      analyzeRMS(blockObj);
   end
end
r = blockObj.RMS.CAR;
ic = assignColors(r); 

%% MAKE FIGURE AND PLOT
fig = figure('Name',sprintf('Multi-Channel %s Snippets',str), ...
   'Units','Normalized', ...
   'Position',[0.05*rand+0.1,0.05*rand+0.1,0.8,0.8],...
   'Color','w');

ax = axes(fig,'NextPlot','add');
tickLabs = cell(blockObj.NumChannels,1);
tickLocs = 0:blockObj.PlotPars.VertOffset:(blockObj.PlotPars.VertOffset*(...
   blockObj.NumChannels-1));
for iCh = 1:blockObj.NumChannels
   tickLabs{iCh} = blockObj.Channels(iCh).custom_channel_name;
   y = blockObj.Channels(iCh).(str)(vec)+tickLocs(iCh);
   plot(ax,t,y, ...
      'Color',cm(ic(iCh),:), ...
      'LineWidth',1.75); %#ok<NODEF>
   
   text(ax,max(t)+dt,tickLocs(iCh),...
         sprintf('RMS: %.3g',r(iCh)),...
         'FontName','Arial',...
         'FontWeight','bold',...
         'Color','k',...
         'FontSize',14);
   
end
ax.YTick = tickLocs;
ax.YTickLabel = tickLabs;
xlabel('Time (sec)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Channel','FontName','Arial','FontSize',14,'Color','k');
title(sprintf('Multi-Channel %s Snippets',str),'FontName','Arial',...
   'Color','k','FontSize',20);

fname = fullfile(blockObj.paths.TW,...
   [blockObj.Name sprintf(blockObj.PlotPars.SnippetString,str)]);

savefig(fig,[fname '.fig']);
saveas(fig,[fname '.png']);
blockObj.Graphics.Waves.(str) = [fname '.fig']; 
flag = true;


   function ic = assignColors(r)
      %% ASSIGNCOLORS   Assign "RMS BINS" different color values
      hvec = [-inf, ...
               linspace(0,14,3),...
               linspace(15,19.99,40),...
               linspace(20,35,20),...
               inf]; % Bin vector with 65 edges (64 bins)
      [~,~,ic] = histcounts(r,hvec);
      ic(isnan(ic)) = 64;
      ic(ic < 1) = 64;
   end

end