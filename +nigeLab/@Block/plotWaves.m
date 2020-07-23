function flag = plotWaves(blockObj,field,idx)
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
% blockObj.Pars.PlotPars = nigeLab.defaults.Plot();
%% FIGURE OUT WHAT TO PLOT
str_in = blockObj.getStatus;
if nargin < 2
    [~,idx] = nigeLab.utils.uidropdownbox('Choose Wave Type',...
        'Select type of waveform to plot:',...
        str_in);
    field = str_in{idx};
end

if strcmp(field,'Spikes')
   warning('Spikes overlay not yet supported.');
   return;
end

%% GET INDEXING VECTOR
if strcmp(field,'LFP')
    fs = blockObj.LFPPars.DownSampledRate;
else
    fs = blockObj.SampleRate;
end

if nargin < 3    
    tStart = (blockObj.PlotPars.DefTime - blockObj.PlotPars.PreAlign)/1000;
    iStart = max(1,round(tStart * fs));
    
    tStop = (blockObj.Pars.Plot.DefTime + blockObj.Pars.Plot.PostAlign)/1000;
    iStop = min(blockObj.Samples,round(tStop * fs));
    
    idx = iStart:iStop;
end
t = linspace(idx(1)./fs,idx(end)./fs,numel(idx));
dt = mode(diff(t));






%% ASSIGN CHANNEL COLORS BASED ON RMS
load(blockObj.Pars.Plot.ColorMapFile,'cm');
if isempty(blockObj.RMS)
   analyzeRMS(blockObj);
elseif ~ismember(field,blockObj.RMS.Properties.VariableNames)
   analyzeRMS(blockObj);
end
r = blockObj.RMS.(field);
ic = assignColors(r); 

%% MAKE FIGURE AND PLOT
fig = figure('Name',sprintf('Multi-Channel %s Snippets',field), ...
   'Units','Normalized', ...
   'Position',[0.05*rand+0.1,0.05*rand+0.1,0.8,0.8],...
   'Color','w','NumberTitle','off');

ax = axes(fig,'NextPlot','add');
tickLabs = cell(blockObj.NumChannels,1);
tickLocs = 1:blockObj.Pars.Plot.VertOffset:(blockObj.Pars.Plot.VertOffset*(...
   blockObj.NumChannels));
for iCh = 1:blockObj.NumChannels
   tickLabs{iCh} = blockObj.Channels(iCh).custom_channel_name;
   y = blockObj.Channels(iCh).(field)(idx)+tickLocs(iCh);
   line(ax,t,y, ...
      'Color',cm(ic(iCh),:), ...
      'LineWidth',1.75,...
      'UserData',iCh); %#ok<NODEF>
   
   text(ax,max(t)*1.01,tickLocs(iCh),...
         sprintf('RMS: %.3g',r(iCh)),...
         'FontName','Arial',...
         'FontWeight','bold',...
         'Color','k',...
         'FontSize',10,...
         'UserData',iCh);
   
end
ax.YTick = tickLocs;
ax.YTickLabel = tickLabs;
xlabel('Time (sec)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Channel','FontName','Arial','FontSize',14,'Color','k');
title(sprintf('Multi-Channel %s Snippets',field),'FontName','Arial',...
   'Color','k','FontSize',20);

xlim(ax,t([1,end]))
ylim(ax,tickLocs([1,end])+ diff(tickLocs([1,end]))*[-.05 .05])
% fname = fullfile(blockObj.paths.TW,...
%    [blockObj.Name sprintf(blockObj.Pars.Plot.SnippetString,str)]);
% 
% savefig(fig,[fname '.fig']);
% saveas(fig,[fname '.png']);
% blockObj.Graphics.Waves = fig; 
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